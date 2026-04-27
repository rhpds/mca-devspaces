#!/usr/bin/env bash
# Create a DevWorkspace from a local devfile 2.2.0 and set started=true. Uses the
# Kubernetes API (DevWorkspace) — the supported automation path for OpenShift Dev
# Spaces 3.x, not a legacy Che REST endpoint.
#
# Usage:
#   devspaces-create-and-start.sh [options]
#   devspaces-create-and-start.sh factory-url [--raw-devfile-url URL] [--devspaces-base URL]
#
# Options (create):
#   -f FILE       Path to devfile (default: devfile.yaml in current directory)
#   -n NAMESPACE  Target namespace (default: current oc project)
#   -w NAME       DevWorkspace name (default: from devfile metadata.name, lowercased & sanitized)
#   -t SECONDS    Wait timeout for phase Running (default: 600)
#   --dry-run     Print generated YAML, do not apply
#   --no-wait     Apply but do not wait for Running
#   --no-editor-fragment
#                 Omit spec.contributions (che-code). Not recommended for Dev Spaces;
#                 the cluster will use defaults if any.
#   --skip-vscode-editor-config
#                 Do not apply the Che vscode-editor-configurations ConfigMap (normally first).
#
# Environment:
#   VSCODE_EDITOR_CONFIG_DIR   Directory with settings.json, extensions.json, product.json,
#                              configurations.json, policy.json (default: <repo>/config/che-editor)
#   VSCODE_EDITOR_CONFIGMAP_NAME  ConfigMap name (default: vscode-editor-configurations)
#   EDITOR_DEVFILE_URI
#     Devfile URL for the IDE contribution (fetched in-cluster by the operator).
#     Default is the in-cluster devspaces-dashboard Service (works on typical OpenShift).
#   EDITOR_DEVFILE_INTERNAL_URI
#     Override for the default above if your install differs, e.g. a public route:
#     https://<devspaces-route-host>/dashboard/api/editors/devfile?che-editor=che-incubator/che-code/latest
#
# Che Code OSS editor config (ConfigMap) — applied before DevWorkspace:
#   https://eclipse.dev/che/docs/stable/administration-guide/editor-configurations-for-microsoft-visual-studio-code/
#
# Requirements: oc (or kubectl), mikefarah yq v4+ (https://github.com/mikefarah/yq)
#   (not the PyPI "yq" package that wraps jq), and a cluster login.
# Run with bash: ./this-script.sh  or  bash this-script.sh  (not: sh this-script.sh)

set -euo pipefail

# POSIX sh drops bash features ([[ ]], etc.); the shebang is ignored when you run: sh this-script
[[ -n "${BASH_VERSION:-}" ]] || { echo "error: run with bash, not sh:  bash \"\$0\" ..." >&2; exit 1; }

die() { echo "error: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

have yq  || die "yq (mike farah, v4+) is required. Install: https://github.com/mikefarah/yq"
# Guard against PyPI yq (kislyuk) that shells out to jq and uses a different CLI
if yq --version 2>&1 | grep -q 'kislyuk'; then
  die "wrong yq: the PyPI/jq 'yq' is not supported; install mikefarah/yq v4+"
fi
KUBE="$(command -v oc || true)"
KUBE="${KUBE:-$(command -v kubectl || true)}"
[[ -n "$KUBE" ]] || die "oc or kubectl is required in PATH"
have sed || die "sed is required"
have tr  || die "tr is required"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VSCODE_EDITOR_CONFIG_DIR="${VSCODE_EDITOR_CONFIG_DIR:-$REPO_ROOT/config/che-editor}"
VSCODE_EDITOR_CONFIGMAP_NAME="${VSCODE_EDITOR_CONFIGMAP_NAME:-vscode-editor-configurations}"

# Default: internal devspaces-dashboard; the controller fetches this in-cluster
DEFAULT_EDITOR_DEVFILE_INTERNAL_URI="http://devspaces-dashboard.openshift-devspaces.svc:8080/dashboard/api/editors/devfile?che-editor=che-incubator/che-code/latest"

sanitize_name() {
  tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr -cd 'a-z0-9-' | head -c 57
}

k8s_apply_from_stdin() {
  "$KUBE" apply -f - "$@"
}

# https://eclipse.dev/che/docs/stable/administration-guide/editor-configurations-for-microsoft-visual-studio-code/
render_vscode_editor_configmap_yaml() {
  local ns=$1
  local f
  local -a from_args=()
  for f in settings.json extensions.json product.json configurations.json policy.json; do
    [[ -f "$VSCODE_EDITOR_CONFIG_DIR/$f" ]] || die "missing $VSCODE_EDITOR_CONFIG_DIR/$f (see Che editor ConfigMap doc)"
    from_args+=(--from-file="$VSCODE_EDITOR_CONFIG_DIR/$f")
  done
  "$KUBE" create configmap "$VSCODE_EDITOR_CONFIGMAP_NAME" "${from_args[@]}" \
    -n "$ns" -o yaml --dry-run=client | yq e '
    .metadata.labels["app.kubernetes.io/part-of"] = "che.eclipse.org"
  '
}

apply_vscode_editor_configmap() {
  local ns=$1
  render_vscode_editor_configmap_yaml "$ns" | k8s_apply_from_stdin
}

k8s_wait_running() {
  local ns=$1 name=$2 timeout_s=$3
  "$KUBE" wait --for=jsonpath='{.status.phase}'=Running "devworkspace/${name}" -n "$ns" --timeout="${timeout_s}s"
}

print_main_url() {
  local ns=$1 name=$2
  # primary field on recent operators
  if url=$("$KUBE" get "devworkspace/${name}" -n "$ns" -o jsonpath='{.status.mainUrl}' 2>/dev/null) && [[ -n "${url// }" ]]; then
    echo "Workspace URL: $url"
    return 0
  fi
  echo "No status.mainUrl yet; check the Dev Spaces dashboard for this namespace."
}

usage() {
  sed -n '1,35p' "$0" | sed -e 's/^# \{0,1\}//'
  exit 0
}

devworkspace_from_devfile() {
  local devfile=$1 namespace=$2 k8s_name=$3 include_contributions=$4 editor_uri=$5
  local tmp
  tmp="$(mktemp)"
  # mike yq: use "yq eval" / "yq e" and load()+strenv; bare "yq -n --arg" fails (unknown flag: --arg)
  # in v4.50+ because --arg is only valid on the eval subcommand.
  yq e 'del(.schemaVersion)' "$devfile" > "$tmp"
  if [[ "$include_contributions" == true ]]; then
    YQ_NS="$namespace" YQ_N="$k8s_name" YQ_ED="$editor_uri" YQ_TMP="$tmp" yq e -n -o yaml --no-doc \
      'load(strenv(YQ_TMP)) as $b | {
        "apiVersion": "workspace.devfile.io/v1alpha2",
        "kind": "DevWorkspace",
        "metadata": { "name": strenv(YQ_N), "namespace": strenv(YQ_NS) },
        "spec": {
          "routingClass": "che",
          "started": true,
          "contributions": [ { "name": "ide", "uri": strenv(YQ_ED) } ],
          "template": $b
        }
      }'
  else
    YQ_NS="$namespace" YQ_N="$k8s_name" YQ_TMP="$tmp" yq e -n -o yaml --no-doc \
      'load(strenv(YQ_TMP)) as $b | {
        "apiVersion": "workspace.devfile.io/v1alpha2",
        "kind": "DevWorkspace",
        "metadata": { "name": strenv(YQ_N), "namespace": strenv(YQ_NS) },
        "spec": {
          "routingClass": "che",
          "started": true,
          "template": $b
        }
      }'
  fi
  rm -f "$tmp"
}

factory_url() {
  local raw devspaces_base
  raw=""
  devspaces_base=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --raw-devfile-url) raw=$2; shift 2 ;;
      --devspaces-base) devspaces_base=$2; shift 2 ;;
      -h|--help) usage ;;
      *) die "unknown arg: $1" ;;
    esac
  done
  [[ -n "$raw" && -n "$devspaces_base" ]] || die "factory-url requires --raw-devfile-url and --devspaces-base (e.g. https://devspaces.apps.mycluster.com)"
  # Factory link (browser; you must be logged into OpenShift in the same session)
  local enc
  if have python3; then
    enc=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=':/'))' "$raw")
  else
    enc=$raw
  fi
  echo "${devspaces_base%/}/f?url=${enc}"
}

# --- main: create
DRY=false
NO_WAIT=false
CONTRIBS=true
SKIP_VSCODE_EDITOR_CM=false
DEVFILE="${DEVFILE:-devfile.yaml}"
NAMESPACE=""
K8S_NAME=""
WAIT=600

if [[ "${1:-}" == factory-url ]]; then
  shift
  factory_url "$@"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) DEVFILE=$2; shift 2 ;;
    -n) NAMESPACE=$2; shift 2 ;;
    -w) K8S_NAME=$2; shift 2 ;;
    -t) WAIT=$2; shift 2 ;;
    --dry-run) DRY=true; shift ;;
    --no-wait) NO_WAIT=true; shift ;;
    --no-editor-fragment) CONTRIBS=false; shift ;;
    --skip-vscode-editor-config) SKIP_VSCODE_EDITOR_CM=true; shift ;;
    -h|--help) usage ;;
    *) die "unknown option: $1 (use -h)" ;;
  esac
done

[[ -f "$DEVFILE" ]] || die "devfile not found: $DEVFILE"

NAMESPACE="${NAMESPACE:-$("$KUBE" project -q 2>/dev/null || true)}"
[[ -n "$NAMESPACE" ]] || die "set a namespace: oc new-project <ns> or pass -n NAMESPACE"

if ! yq e '.' "$DEVFILE" >/dev/null 2>&1; then
  die "yq could not parse $DEVFILE as YAML"
fi

if [[ -z "$K8S_NAME" ]]; then
  K8S_NAME=$(yq e '.metadata.name // "workspace"' "$DEVFILE" | sanitize_name)
  [[ -n "$K8S_NAME" ]] || K8S_NAME=workspace
fi

# Resolve editor devfile for spec.contributions (Dev Spaces che-code)
EDITOR_CONTRIB_URI=""
if [[ $CONTRIBS == true ]]; then
  EDITOR_CONTRIB_URI="${EDITOR_DEVFILE_URI:-${EDITOR_DEVFILE_INTERNAL_URI:-$DEFAULT_EDITOR_DEVFILE_INTERNAL_URI}}"
fi

YAML_OUT=$(devworkspace_from_devfile "$DEVFILE" "$NAMESPACE" "$K8S_NAME" "$CONTRIBS" "$EDITOR_CONTRIB_URI")

if [[ $DRY == true ]]; then
  if [[ $SKIP_VSCODE_EDITOR_CM != true ]]; then
    echo "# --- ConfigMap $VSCODE_EDITOR_CONFIGMAP_NAME (Che editor config, dry-run) ---"
    render_vscode_editor_configmap_yaml "$NAMESPACE"
    echo "# --- DevWorkspace ---"
  fi
  echo "$YAML_OUT"
  exit 0
fi

if [[ $SKIP_VSCODE_EDITOR_CM != true ]]; then
  apply_vscode_editor_configmap "$NAMESPACE"
  echo "Applied ConfigMap $VSCODE_EDITOR_CONFIGMAP_NAME (Che VS Code editor configuration)."
fi

echo "$YAML_OUT" | k8s_apply_from_stdin

echo "Applied DevWorkspace $NAMESPACE/$K8S_NAME (started=true)."

if [[ $NO_WAIT == true ]]; then
  exit 0
fi

echo "Waiting until phase=Running (timeout ${WAIT}s)..."
if k8s_wait_running "$NAMESPACE" "$K8S_NAME" "$WAIT"; then
  print_main_url "$NAMESPACE" "$K8S_NAME"
else
  die "timeout or failure waiting for Running. Check: $KUBE describe devworkspace \"$K8S_NAME\" -n \"$NAMESPACE\""
fi
