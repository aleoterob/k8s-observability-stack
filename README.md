# Kubernetes Prometheus Grafana

Local Kubernetes monitoring stack built with Helm charts for Prometheus and Grafana. The defaults are intentionally small for Minikube and Kind, while keeping production-friendly conventions: isolated namespaces, externalized secrets, persistent volumes, resource requests and limits, and repeatable scripts.

## Architecture

```text
cluster
├── monitoring
│   ├── kube-prometheus-stack
│   ├── Grafana
│   └── optional Loki, Tempo, OpenTelemetry Collector
└── monitoring-demo
    └── sample metrics app scraped by Prometheus
```

Prometheus is installed with `prometheus-community/kube-prometheus-stack` and scrapes cluster metrics plus the included example application. Grafana is installed with the official `grafana/grafana` chart and provisions Prometheus as a datasource automatically.

## Prerequisites

- Kubernetes cluster from Minikube or Kind
- `kubectl`
- `helm` 3.x or 4.x
- Linux, macOS, or Windows PowerShell

For Minikube:

```bash
minikube start --cpus 4 --memory 8192
```

For Kind on Windows PowerShell:

```powershell
.\scripts\create-cluster.ps1
```

For Kind on Linux/macOS:

```bash
kind create cluster --name prometheus-grafana
```

## Install

Create local Grafana credentials from the example before installing:

```bash
cp k8s/secrets/grafana-admin-secret.example.yaml k8s/secrets/grafana-admin-secret.yaml
```

On Windows PowerShell:

```powershell
Copy-Item k8s/secrets/grafana-admin-secret.example.yaml k8s/secrets/grafana-admin-secret.yaml
```

Edit the generated secret if you want custom credentials, then run:

```bash
./scripts/start.sh
```

On Windows PowerShell:

```powershell
.\scripts\start.ps1
```

The script creates namespaces, adds Helm repositories, applies secrets and supporting manifests, installs charts, waits for rollouts, and prints useful access commands.

## Access

Grafana is exposed through NodePort by default:

```bash
kubectl get svc grafana -n monitoring
```

Grafana port-forward:

```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
```

Prometheus is ClusterIP by default:

```bash
kubectl port-forward svc/prometheus-prometheus -n monitoring 9090:9090
```

URLs:

- Grafana: <http://localhost:3000>
- Prometheus: <http://localhost:9090>

## Credentials

Grafana reads admin credentials from `k8s/secrets/grafana-admin-secret.yaml`.

Default example values:

- Username: `admin`
- Password: `admin`

Replace the example before using this outside a disposable local cluster.

## Optional Add-ons

Optional components are disabled by default and can be enabled with environment variables:

```bash
ENABLE_LOKI=true ./scripts/start.sh
ENABLE_TEMPO=true ./scripts/start.sh
ENABLE_OTEL=true ./scripts/start.sh
```

On Windows PowerShell:

```powershell
$env:ENABLE_LOKI = "true"
.\scripts\start.ps1
```

Their values live in:

- `helm/loki/values.yaml`
- `helm/tempo/values.yaml`
- `helm/opentelemetry-collector/values.yaml`

## Useful Commands

Check health:

```bash
kubectl get pods -A
kubectl get servicemonitors -n monitoring
kubectl get prometheus -n monitoring
```

Logs:

```bash
kubectl logs -n monitoring deploy/grafana
kubectl logs -n monitoring-demo deploy/example-metrics-app
```

Restart pods:

```bash
kubectl rollout restart deploy/grafana -n monitoring
kubectl rollout restart statefulset/prometheus-prometheus-prometheus -n monitoring
kubectl rollout restart deploy/example-metrics-app -n monitoring-demo
```

Troubleshooting Helm:

```bash
helm list -A
helm status prometheus -n monitoring
helm status grafana -n monitoring
```

## Cleanup

Stop installed releases and keep namespaces:

```bash
./scripts/stop.sh
```

On Windows PowerShell:

```powershell
.\scripts\stop.ps1
```

Remove releases, namespaces, and local generated secret files:

```bash
./scripts/reset.sh
```

On Windows PowerShell:

```powershell
.\scripts\reset.ps1
```

Delete the local Kind cluster:

```powershell
.\scripts\delete-cluster.ps1
```

## Repository Layout

```text
helm/                       Helm values per service
k8s/namespaces/             Namespace manifests
k8s/ingress/                Optional ingress manifests
k8s/secrets/                Secret templates and examples
k8s/configs/                Auxiliary Kubernetes manifests
docs/                       Operational documentation
scripts/                    Local automation
.github/workflows/          CI validation
```

## CI

GitHub Actions validates YAML, repository structure, Helm values with `helm lint`, and rendered manifests with `kubeconform` where possible.
