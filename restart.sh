#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"; bash "$ROOT/stop.sh"; bash "$ROOT/start.sh"
