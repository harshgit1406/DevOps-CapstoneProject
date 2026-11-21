#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
source "$ROOT/scripts/lib.sh"
cd "$ROOT"

RELEASE="devops-capstone"
DEPLOYMENT="devops-capstone-devsecops-app"
SERVICE="devops-capstone-devsecops-app"
DEMO_PORT="${DEMO_PORT:-8083}"
BASE_VERSION="${BASE_VERSION:-1.0.0}"
DEMO_VERSION="${DEMO_VERSION:-2.0.0}"
VENV="${CAPSTONE_VENV:-$HOME/.local/share/devops-capstone/venv}"
PF_PID=""

title(){ clear 2>/dev/null || true; printf '\n\033[1;36m============================================================\n  %s\n============================================================\033[0m\n\n' "$1"; }
step(){ printf '\n\033[1;34m[DEMO]\033[0m %s\n' "$1"; }
success(){ printf '\033[1;32m[SUCCESS]\033[0m %s\n' "$1"; }
pause(){ [[ "${FACULTY_DEMO_NO_PAUSE:-0}" == "1" ]] && return 0; printf '\n'; read -r -p "Press Enter when you are ready to continue..." _; }

cleanup_demo(){
  if [[ -n "$PF_PID" ]] && kill -0 "$PF_PID" 2>/dev/null; then kill "$PF_PID" 2>/dev/null || true; fi
}
trap cleanup_demo EXIT

require_tools(){
  for tool in docker kubectl helm curl; do need "$tool" || exit 1; done
  docker info >/dev/null 2>&1 || { warn "Docker Desktop is not running."; exit 1; }
  kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || { warn "Project is not running. Run: bash start.sh"; exit 1; }
}

wait_for_version(){
  local expected="$1"
  for _ in {1..30}; do
    if curl -fsS "http://localhost:$DEMO_PORT/api/status" 2>/dev/null | grep -q "\"version\":\"$expected\""; then return 0; fi
    sleep 2
  done
  return 1
}

start_forward(){
  if curl -fsS "http://localhost:$DEMO_PORT/health" >/dev/null 2>&1; then
    success "Kubernetes application is already available on port $DEMO_PORT."
    return
  fi
  step "Starting Kubernetes access at http://localhost:$DEMO_PORT"
  kubectl port-forward "service/$SERVICE" "$DEMO_PORT:5000" -n "$NAMESPACE" > reports/faculty-port-forward.log 2>&1 &
  PF_PID=$!
  for _ in {1..20}; do curl -fsS "http://localhost:$DEMO_PORT/health" >/dev/null 2>&1 && break; sleep 1; done
  curl -fsS "http://localhost:$DEMO_PORT/health" >/dev/null || { warn "Port-forward failed. See reports/faculty-port-forward.log"; exit 1; }
}

show_status(){
  title "1. PLATFORM STATUS"
  bash status.sh
  printf '\nKubernetes demo URL: http://localhost:%s\nStatus API:          http://localhost:%s/api/status\n' "$DEMO_PORT" "$DEMO_PORT"
  pause
}

run_tests(){
  title "2. AUTOMATED TESTS"
  step "Running endpoint and Prometheus metric tests"
  "$VENV/bin/pytest" -q app/tests
  success "All automated tests passed."
  pause
}

version_demo(){
  title "3. VERSION CHANGE, ROLLING UPDATE, AND ROLLBACK"
  step "Setting a known baseline version: $BASE_VERSION"
  helm upgrade "$RELEASE" helm/devsecops-app -n "$NAMESPACE" --reuse-values --set "app.version=$BASE_VERSION" --wait --timeout 180s
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s
  start_forward
  wait_for_version "$BASE_VERSION"
  printf '\nBaseline response:\n'; curl -fsS "http://localhost:$DEMO_PORT/api/status"; printf '\n'
  printf '\nOpen this in the browser: \033[1;36mhttp://localhost:%s/api/status\033[0m\n' "$DEMO_PORT"
  pause

  local baseline_revision
  baseline_revision=$(helm history "$RELEASE" -n "$NAMESPACE" | awk 'NR > 1 { revision=$1 } END { print revision }')
  step "Deploying visible version change: $BASE_VERSION -> $DEMO_VERSION"
  helm upgrade "$RELEASE" helm/devsecops-app -n "$NAMESPACE" --reuse-values --set "app.version=$DEMO_VERSION" --wait --timeout 180s
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s
  start_forward
  wait_for_version "$DEMO_VERSION"
  printf '\nNew response:\n'; curl -fsS "http://localhost:$DEMO_PORT/api/status"; printf '\n\nPods after rolling update:\n'
  kubectl get pods -n "$NAMESPACE" -o wide
  printf '\nThe browser must now show version \033[1;32m%s\033[0m.\n' "$DEMO_VERSION"
  pause

  step "Showing Helm release history"
  helm history "$RELEASE" -n "$NAMESPACE"
  pause

  step "Rolling back to Helm revision $baseline_revision"
  helm rollback "$RELEASE" "$baseline_revision" -n "$NAMESPACE" --wait --timeout 180s
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s
  start_forward
  wait_for_version "$BASE_VERSION"
  printf '\nRolled-back response:\n'; curl -fsS "http://localhost:$DEMO_PORT/api/status"; printf '\n'
  success "Rollback complete. Version is back to $BASE_VERSION."
  pause
}

scaling_demo(){
  title "4. KUBERNETES SCALING: 2 TO 5 TO 2"
  step "Temporarily removing HPA so manual scaling remains visible"
  kubectl delete hpa "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found
  kubectl scale "deployment/$DEPLOYMENT" -n "$NAMESPACE" --replicas=5
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s
  kubectl get pods -n "$NAMESPACE"
  success "Five replicas are running."
  pause
  step "Restoring two replicas and HPA"
  kubectl scale "deployment/$DEPLOYMENT" -n "$NAMESPACE" --replicas=2
  helm upgrade "$RELEASE" helm/devsecops-app -n "$NAMESPACE" --reuse-values --wait --timeout 180s
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s
  kubectl get deployment,pods,hpa -n "$NAMESPACE"
  success "Healthy two-replica state restored."
  pause
}

self_healing_demo(){
  title "5. SELF-HEALING"
  local before victim
  before=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[*].metadata.name}')
  victim=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE" -o jsonpath='{.items[0].metadata.name}')
  printf 'Current pods: %s\n' "$before"
  step "Deleting pod: $victim"
  kubectl delete pod "$victim" -n "$NAMESPACE" --wait=false
  sleep 3
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s
  kubectl get pods -n "$NAMESPACE"
  success "Kubernetes automatically created a replacement pod."
  pause
}

monitoring_demo(){
  title "6. LIVE MONITORING"
  step "Generating 300 real HTTP requests"
  for _ in {1..300}; do curl -fsS http://localhost:8082/api/status >/dev/null; done
  printf '\nOpen Grafana:    \033[1;36mhttp://localhost:3001\033[0m  (admin / admin)\n'
  printf 'Open Prometheus: \033[1;36mhttp://localhost:9090/targets\033[0m\n\n'
  printf 'Grafana dashboard: DevSecOps Application Overview\n'
  success "Traffic generated. Request-rate and latency graphs now contain live data."
  pause
}

infrastructure_demo(){
  title "7. TERRAFORM INFRASTRUCTURE AUTOMATION"
  terraform -chdir=terraform plan -input=false -var="app_port=8082" -var="grafana_port=3001" -var="prometheus_port=9090"
  success "Terraform compared declared and actual infrastructure."
  pause
}

security_demo(){
  title "8. SECURITY SCANNING"
  mkdir -p reports
  step "Running Semgrep SAST"
  "$VENV/bin/semgrep" --config .semgrep.yml app --json -o reports/semgrep.json
  step "Running Trivy HIGH/CRITICAL container scan"
  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/trivy -v "$ROOT/reports:/reports" aquasec/trivy:0.67.2 image --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --format json -o /reports/trivy.json devops-capstone:local
  success "Semgrep and Trivy passed. Reports are saved under reports/."
  pause
}

final_state(){
  title "FINAL HEALTHY STATE"
  kubectl scale "deployment/$DEPLOYMENT" -n "$NAMESPACE" --replicas=2 >/dev/null
  helm upgrade "$RELEASE" helm/devsecops-app -n "$NAMESPACE" --reuse-values --set "app.version=$BASE_VERSION" --wait --timeout 180s >/dev/null
  kubectl rollout status "deployment/$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s
  bash status.sh
  success "Demonstration finished. Version $BASE_VERSION and two replicas are restored."
}

require_tools
mkdir -p reports
start_forward

if [[ "${FACULTY_DEMO_SMOKE_TEST:-0}" == "1" ]]; then
  final_state
  exit 0
fi

if [[ "${FACULTY_DEMO_AUTO_OPTION:-}" == "3" ]]; then
  version_demo
  final_state
  exit 0
fi

while true; do
  title "DEVOPS CAPSTONE - FACULTY DEMONSTRATION"
  printf 'Kubernetes demo: http://localhost:%s\n\n' "$DEMO_PORT"
  printf '  1. Platform status\n  2. Automated tests\n  3. Version change + rolling update + rollback\n'
  printf '  4. Scale 2 -> 5 -> 2\n  5. Delete pod + self-healing\n  6. Live Grafana monitoring\n'
  printf '  7. Terraform plan\n  8. Security scans\n  9. Run complete guided demonstration\n'
  printf '  0. Restore healthy state and exit\n\n'
  read -r -p "Select an option: " choice
  case "$choice" in
    1) show_status;; 2) run_tests;; 3) version_demo;; 4) scaling_demo;;
    5) self_healing_demo;; 6) monitoring_demo;; 7) infrastructure_demo;; 8) security_demo;;
    9) show_status; run_tests; version_demo; scaling_demo; self_healing_demo; monitoring_demo; infrastructure_demo; security_demo; final_state; pause;;
    0) final_state; exit 0;;
    *) warn "Choose a number from 0 to 9."; sleep 1;;
  esac
done
