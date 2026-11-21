#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; source "$ROOT/scripts/lib.sh"; cd "$ROOT"
read -r -p "Remove only devops-capstone containers, volumes, Kind cluster, and Terraform state? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { warn "Cancelled"; exit 0; }
docker compose down -v --remove-orphans || true
kind delete cluster --name "$CLUSTER_NAME" || true
terraform -chdir=terraform destroy -auto-approve -input=false || true
ok "Project-specific resources removed"
