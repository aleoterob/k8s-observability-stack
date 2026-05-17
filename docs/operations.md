# Operations Guide

## Health Checks

```bash
kubectl get pods -n monitoring
kubectl get pods -n monitoring-demo
kubectl get servicemonitor -n monitoring
```

## Windows PowerShell

Use the PowerShell scripts when running from Windows:

```powershell
.\scripts\create-cluster.ps1
.\scripts\start.ps1
.\scripts\stop.ps1
.\scripts\reset.ps1
.\scripts\delete-cluster.ps1
```

## Port Forwarding

```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
kubectl port-forward svc/prometheus-prometheus -n monitoring 9090:9090
```

## Logs

```bash
kubectl logs -n monitoring deploy/grafana
kubectl logs -n monitoring-demo deploy/example-metrics-app
```

## Troubleshooting

Check Helm releases:

```bash
helm list -A
helm status prometheus -n monitoring
helm status grafana -n monitoring
```

Inspect Prometheus targets:

```bash
kubectl port-forward svc/prometheus-prometheus -n monitoring 9090:9090
open http://localhost:9090/targets
```

Restart workloads:

```bash
kubectl rollout restart deploy/grafana -n monitoring
kubectl rollout restart deploy/example-metrics-app -n monitoring-demo
```
