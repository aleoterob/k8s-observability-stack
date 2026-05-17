#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/stop.sh"

kubectl delete -f "$ROOT_DIR/k8s/namespaces" --ignore-not-found=true

rm -f "$ROOT_DIR/k8s/secrets/grafana-admin-secret.yaml"

echo "Stack reset completed."
