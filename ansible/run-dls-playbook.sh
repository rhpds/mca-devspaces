#!/usr/bin/env bash
# Run devspaces_devworkspace.yml using .venv for kubernetes.core (avoids local PEP 668 / missing kubernetes).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
VPY="$ROOT/.venv/bin/python3"
if [[ ! -x "$VPY" ]]; then
  echo "error: $VPY missing. Run:  cd $ROOT && ./setup-venv.sh" >&2
  exit 1
fi
exec ansible-playbook \
  -e "ansible_python_interpreter=$VPY" \
  -i "$ROOT/inventory/localhost" \
  "$ROOT/devspaces_devworkspace.yml" \
  "$@"
