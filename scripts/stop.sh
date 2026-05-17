#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

helm uninstall opentelemetry-collector -n monitoring --ignore-not-found
helm uninstall tempo -n monitoring --ignore-not-found
helm uninstall loki -n monitoring --ignore-not-found
helm uninstall grafana -n monitoring --ignore-not-found
helm uninstall prometheus -n monitoring --ignore-not-found

kubectl delete -f "$ROOT_DIR/k8s/configs" --ignore-not-found=true

echo "Stack releases removed. Namespaces and generated secret files were kept."
