#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; source "$ROOT/scripts/lib.sh"
BIN="$HOME/.local/bin"; mkdir -p "$BIN" "$ROOT/reports"; export PATH="$BIN:$PATH"
install_bin(){ local name="$1" url="$2"; if command -v "$name" >/dev/null; then ok "$name already installed"; return; fi; log "Installing $name in $BIN"; curl -fsSL "$url" -o "$BIN/$name"; chmod +x "$BIN/$name"; }
need curl
ARCH=$(uname -m); [[ "$ARCH" == x86_64 ]] && ARCH=amd64
install_bin kind "https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-$ARCH"
if [[ ! -x "$BIN/kubectl" ]]; then
  log "Installing Linux kubectl in $BIN"
  curl -fsSL "https://dl.k8s.io/release/v1.34.1/bin/linux/$ARCH/kubectl" -o "$BIN/kubectl"
  chmod +x "$BIN/kubectl"
else
  ok "kubectl already installed in $BIN"
fi
if ! command -v helm >/dev/null; then log "Installing Helm"; tmp=$(mktemp -d); curl -fsSL https://get.helm.sh/helm-v3.19.0-linux-$ARCH.tar.gz | tar -xz -C "$tmp"; install -m 0755 "$tmp/linux-$ARCH/helm" "$BIN/helm"; rm -rf "$tmp"; else ok "helm already installed"; fi
if ! command -v terraform >/dev/null; then need python3; log "Installing Terraform"; tmp=$(mktemp -d); curl -fsSL "https://releases.hashicorp.com/terraform/1.13.4/terraform_1.13.4_linux_$ARCH.zip" -o "$tmp/t.zip"; python3 -m zipfile -e "$tmp/t.zip" "$tmp"; install -m 0755 "$tmp/terraform" "$BIN/terraform"; rm -rf "$tmp"; else ok "terraform already installed"; fi
VENV="${CAPSTONE_VENV:-$HOME/.local/share/devops-capstone/venv}"
mkdir -p "$(dirname "$VENV")"
if ! python3 -m venv "$VENV" 2>/dev/null; then
  warn "python3-venv is unavailable; bootstrapping an isolated virtualenv without system changes"
  curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/capstone-get-pip.py
  python3 /tmp/capstone-get-pip.py --user --break-system-packages
  python3 -m pip install --user --break-system-packages virtualenv
  python3 -m virtualenv "$VENV"
fi
"$VENV/bin/pip" install -q -r "$ROOT/app/requirements.txt" pytest semgrep
terraform -chdir="$ROOT/terraform" init -input=false
ok "Setup complete. Ensure Docker Desktop WSL integration is enabled, then run: bash start.sh"
