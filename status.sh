#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; source "$ROOT/scripts/lib.sh"; cd "$ROOT"
[[ -f reports/runtime.env ]] && source reports/runtime.env
APP_PORT=${APP_PORT:-8080}; GRAFANA_PORT=${GRAFANA_PORT:-3000}; PROMETHEUS_PORT=${PROMETHEUS_PORT:-9090}
printf '\n%-14s %-38s %s\n' SERVICE URL STATUS
for spec in "Application|http://localhost:$APP_PORT/health" "Grafana|http://localhost:$GRAFANA_PORT/api/health" "Prometheus|http://localhost:$PROMETHEUS_PORT/-/healthy"; do IFS='|' read -r name url <<< "$spec"; if curl -fsS --max-time 3 "$url" >/dev/null; then state=HEALTHY; else state=DOWN; fi; printf '%-14s %-38s %s\n' "$name" "$url" "$state"; done
echo; docker compose --env-file reports/runtime.env ps || true; echo; kubectl get pods,svc,hpa -n "$NAMESPACE" 2>/dev/null || true
