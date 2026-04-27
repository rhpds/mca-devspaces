#!/usr/bin/env bash
# Create ansible/.venv and install PyPI "kubernetes" for kubernetes.core.
# Use when Homebrew (or other) Python is "externally managed" (PEP 668) and
# `pip install` without a venv fails.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
PY="${PYTHON:-python3}"
"$PY" -m venv .venv
./.venv/bin/pip install -U pip
./.venv/bin/pip install -r requirements.txt
./.venv/bin/python3 -c "import kubernetes; print('kubernetes', kubernetes.__version__)"
echo "Venv ready: $ROOT/.venv/bin/python3"
echo "Run: ./run-dls-playbook.sh  ...  (or: ansible-playbook -e \"ansible_python_interpreter=$ROOT/.venv/bin/python3\" ...)"
