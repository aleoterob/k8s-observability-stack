#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MONITORING_NAMESPACE="monitoring"
SENTRY_NAMESPACE="sentry"
DEMO_NAMESPACE="observability-demo"

ENABLE_LOKI="${ENABLE_LOKI:-false}"
ENABLE_TEMPO="${ENABLE_TEMPO:-false}"
ENABLE_OTEL="${ENABLE_OTEL:-false}"
SENTRY_HELM_TIMEOUT="${SENTRY_HELM_TIMEOUT:-45m}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

apply_secret_or_example() {
  local target="$1"
  local example="$2"

  if [[ -f "$target" ]]; then
    kubectl apply -f "$target"
  else
    echo "Using example secret: $example"
    kubectl apply -f "$example"
  fi
}

wait_for_deployment_if_exists() {
  local namespace="$1"
  local deployment="$2"
  if kubectl get deploy "$deployment" -n "$namespace" >/dev/null 2>&1; then
    kubectl rollout status deploy/"$deployment" -n "$namespace" --timeout=10m
  fi
}

require_command kubectl
require_command helm

echo "Applying namespaces"
kubectl apply -f "$ROOT_DIR/k8s/namespaces"

echo "Adding Helm repositories"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add sentry https://sentry-kubernetes.github.io/charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

echo "Applying local secrets"
apply_secret_or_example "$ROOT_DIR/k8s/secrets/grafana-admin-secret.yaml" "$ROOT_DIR/k8s/secrets/grafana-admin-secret.example.yaml"
apply_secret_or_example "$ROOT_DIR/k8s/secrets/sentry-secret.yaml" "$ROOT_DIR/k8s/secrets/sentry-secret.example.yaml"

echo "Installing Prometheus"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace "$MONITORING_NAMESPACE" \
  --values "$ROOT_DIR/helm/prometheus/values.yaml" \
  --wait \
  --timeout 15m

echo "Applying dashboards and example metrics app"
kubectl apply -f "$ROOT_DIR/k8s/configs"

echo "Installing Grafana"
helm upgrade --install grafana grafana/grafana \
  --namespace "$MONITORING_NAMESPACE" \
  --values "$ROOT_DIR/helm/grafana/values.yaml" \
  --wait \
  --timeout 10m

echo "Installing Sentry"
helm upgrade --install sentry sentry/sentry \
  --namespace "$SENTRY_NAMESPACE" \
  --values "$ROOT_DIR/helm/sentry/values.yaml" \
  --wait \
  --timeout "$SENTRY_HELM_TIMEOUT"

if [[ "$ENABLE_LOKI" == "true" ]]; then
  echo "Installing optional Loki"
  helm upgrade --install loki grafana/loki \
    --namespace "$MONITORING_NAMESPACE" \
    --values "$ROOT_DIR/helm/loki/values.yaml" \
    --set enabled=true \
    --wait \
    --timeout 10m
fi

if [[ "$ENABLE_TEMPO" == "true" ]]; then
  echo "Installing optional Tempo"
  helm upgrade --install tempo grafana/tempo \
    --namespace "$MONITORING_NAMESPACE" \
    --values "$ROOT_DIR/helm/tempo/values.yaml" \
    --set enabled=true \
    --wait \
    --timeout 10m
fi

if [[ "$ENABLE_OTEL" == "true" ]]; then
  echo "Installing optional OpenTelemetry Collector"
  helm upgrade --install opentelemetry-collector open-telemetry/opentelemetry-collector \
    --namespace "$MONITORING_NAMESPACE" \
    --values "$ROOT_DIR/helm/opentelemetry-collector/values.yaml" \
    --set enabled=true \
    --wait \
    --timeout 10m
fi

echo "Validating rollouts"
wait_for_deployment_if_exists "$MONITORING_NAMESPACE" grafana
wait_for_deployment_if_exists "$DEMO_NAMESPACE" example-metrics-app
wait_for_deployment_if_exists "$SENTRY_NAMESPACE" sentry-web

echo
echo "Useful access commands"
echo "Grafana:    kubectl port-forward svc/grafana -n monitoring 3000:80"
echo "Prometheus: kubectl port-forward svc/prometheus-prometheus -n monitoring 9090:9090"
echo "Sentry:     kubectl port-forward svc/sentry-web -n sentry 9000:9000"
echo
echo "Grafana NodePort: kubectl get svc grafana -n monitoring"
