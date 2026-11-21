#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin"
export PATH="$SCRIPT_BIN:$HOME/.local/bin:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-devops-capstone}"
NAMESPACE="${NAMESPACE:-devops-capstone}"
log(){ printf '\033[1;34m[capstone]\033[0m %s\n' "$*"; }
ok(){ printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
need(){ command -v "$1" >/dev/null 2>&1 || { warn "$1 is missing. Run bash setup.sh"; return 1; }; }
