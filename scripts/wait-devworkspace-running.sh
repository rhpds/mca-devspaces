#!/usr/bin/env bash
# Wait until a DevWorkspace reaches phase Running (workspace pod + editor lifecycle started).
# Usage: ./wait-devworkspace-running.sh <namespace> <devworkspace-name> [timeout_seconds]
# Requires: kubectl or oc in PATH, with an active context.

set -euo pipefail

ns="${1:?namespace}"
name="${2:?devworkspace name}"
timeout="${3:-600}"

bin="$(command -v oc || command -v kubectl)"
if [[ -z "${bin}" ]]; then
  echo "Install kubectl or oc" >&2
  exit 1
fi

echo "Waiting for DevWorkspace ${ns}/${name} (timeout ${timeout}s)..."
"${bin}" wait --for=jsonpath='{.status.phase}'=Running \
  "devworkspace/${name}" -n "${ns}" --timeout="${timeout}s"
echo "Phase is Running."
