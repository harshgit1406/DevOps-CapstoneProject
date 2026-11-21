#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; source "$ROOT/scripts/lib.sh"; cd "$ROOT"
DEPLOYMENT=devops-capstone-devsecops-app
pause(){ read -r -p "Press Enter to continue..." _; }
VENV="${CAPSTONE_VENV:-$HOME/.local/share/devops-capstone/venv}"
tests(){ "$VENV/bin/pytest" -q app/tests; }
baseline(){ bash status.sh; kubectl get pods -n "$NAMESPACE" -o wide; }
scale(){ log "Scaling 2 to 5"; kubectl delete hpa "$DEPLOYMENT" -n "$NAMESPACE" --ignore-not-found; kubectl scale deployment "$DEPLOYMENT" -n "$NAMESPACE" --replicas=5; kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE"; kubectl get pods -n "$NAMESPACE"; pause; kubectl scale deployment "$DEPLOYMENT" -n "$NAMESPACE" --replicas=2; helm upgrade devops-capstone helm/devsecops-app -n "$NAMESPACE" --reuse-values --wait; }
selfheal(){ pod=$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/instance=devops-capstone -o jsonpath='{.items[0].metadata.name}'); log "Deleting $pod"; kubectl delete pod "$pod" -n "$NAMESPACE"; kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE"; kubectl get pods -n "$NAMESPACE"; }
rollout(){ kubectl set env deployment/"$DEPLOYMENT" -n "$NAMESPACE" DEMO_REVISION="$(date +%s)"; kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE"; pause; kubectl rollout undo deployment/"$DEPLOYMENT" -n "$NAMESPACE"; kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE"; }
security(){ mkdir -p reports; "$VENV/bin/semgrep" --config .semgrep.yml app --json -o reports/semgrep.json; if command -v trivy >/dev/null; then trivy image --severity HIGH,CRITICAL --format json -o reports/trivy.json devops-capstone:local; else docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$ROOT/reports:/reports" aquasec/trivy:0.67.2 image --severity HIGH,CRITICAL --format json -o /reports/trivy.json devops-capstone:local; fi; ok "Reports saved under reports/"; }
infra(){ terraform -chdir=terraform plan; terraform -chdir=terraform apply -auto-approve; }
while true; do printf '\n1 Status  2 Tests  3 Scale 2->5  4 Self-heal  5 Rollout+rollback\n6 Terraform  7 Security scans  8 URLs  9 Full demo  0 Exit\n'; read -r -p "> " choice; case "$choice" in 1) baseline;;2) tests;;3) scale;;4) selfheal;;5) rollout;;6) infra;;7) security;;8) printf 'App: http://localhost:8080\nGrafana: http://localhost:3000 (admin/admin)\nPrometheus: http://localhost:9090\n';;9) baseline; tests; scale; selfheal; rollout; infra; security; baseline;;0) exit;;*) warn "Unknown choice";; esac; done
