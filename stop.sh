#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; source "$ROOT/scripts/lib.sh"; cd "$ROOT"
docker compose --env-file reports/runtime.env down || true
pkill -f "kubectl.*port-forward.*devops-capstone" 2>/dev/null || true
ok "Project services stopped; Kind cluster preserved"
