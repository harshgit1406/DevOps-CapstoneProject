#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; source "$ROOT/scripts/lib.sh"; cd "$ROOT"
for tool in docker kind kubectl helm terraform; do need "$tool"; done
docker info >/dev/null || { warn "Docker engine is not running. Start Docker Desktop."; exit 1; }
mkdir -p reports
find_port(){ local port="$1"; while (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1; do port=$((port+1)); done; echo "$port"; }
existing_port(){ docker port "$1" "$2/tcp" 2>/dev/null | head -1 | sed 's/.*://' || true; }
APP_PORT=$(existing_port capstone-app 5000); APP_PORT=${APP_PORT:-$(find_port 8080)}
GRAFANA_PORT=$(existing_port capstone-grafana 3000); GRAFANA_PORT=${GRAFANA_PORT:-$(find_port 3000)}
PROMETHEUS_PORT=$(existing_port capstone-prometheus 9090); PROMETHEUS_PORT=${PROMETHEUS_PORT:-$(find_port 9090)}
printf 'APP_PORT=%s\nGRAFANA_PORT=%s\nPROMETHEUS_PORT=%s\n' "$APP_PORT" "$GRAFANA_PORT" "$PROMETHEUS_PORT" > reports/runtime.env
log "Starting application, Prometheus, and Grafana"
docker compose --env-file reports/runtime.env up -d --build
if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then log "Creating Kind cluster"; kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml; fi
if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
  log "Installing Metrics Server for HPA"
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  kubectl patch deployment metrics-server -n kube-system --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi
log "Loading application image and deploying Helm release"
docker build -t devops-capstone:local .
kind load docker-image devops-capstone:local --name "$CLUSTER_NAME"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install devops-capstone helm/devsecops-app -n "$NAMESPACE" --set image.repository=devops-capstone --set image.tag=local --set image.pullPolicy=IfNotPresent --wait --timeout 180s
terraform -chdir=terraform apply -auto-approve -input=false -var="app_port=$APP_PORT" -var="grafana_port=$GRAFANA_PORT" -var="prometheus_port=$PROMETHEUS_PORT"
kubectl rollout restart deployment/devops-capstone-devsecops-app -n "$NAMESPACE"
kubectl rollout status deployment/devops-capstone-devsecops-app -n "$NAMESPACE" --timeout=120s
ok "Started: App http://localhost:$APP_PORT | Grafana http://localhost:$GRAFANA_PORT | Prometheus http://localhost:$PROMETHEUS_PORT"
