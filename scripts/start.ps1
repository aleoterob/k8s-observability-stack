$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir "scripts/shared.ps1")

$MonitoringNamespace = "monitoring"
$DemoNamespace = "monitoring-demo"

$EnableLoki = ($env:ENABLE_LOKI -eq "true")
$EnableTempo = ($env:ENABLE_TEMPO -eq "true")
$EnableOtel = ($env:ENABLE_OTEL -eq "true")

function Apply-SecretOrExample {
    param(
        [string]$Target,
        [string]$Example
    )

    if (Test-Path $Target) {
        kubectl apply -f $Target
    }
    else {
        Write-Host "Using example secret: $Example"
        kubectl apply -f $Example
    }
}

function Wait-ForDeploymentIfExists {
    param(
        [string]$Namespace,
        [string]$Deployment
    )

    kubectl get deploy $Deployment -n $Namespace *> $null
    if ($LASTEXITCODE -eq 0) {
        kubectl rollout status "deploy/$Deployment" -n $Namespace --timeout=10m
    }
}

Require-Command kubectl
Require-Command helm

kubectl cluster-info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "No reachable Kubernetes cluster found. Run .\scripts\create-cluster.ps1 first."
}

Write-Host "Applying namespaces"
kubectl apply -f (Join-Path $RootDir "k8s/namespaces")

Write-Host "Adding Helm repositories"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

Write-Host "Applying local secrets"
Apply-SecretOrExample `
    (Join-Path $RootDir "k8s/secrets/grafana-admin-secret.yaml") `
    (Join-Path $RootDir "k8s/secrets/grafana-admin-secret.example.yaml")

Write-Host "Installing Prometheus"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack `
    --namespace $MonitoringNamespace `
    --values (Join-Path $RootDir "helm/prometheus/values.yaml") `
    --wait `
    --timeout 15m

Write-Host "Applying dashboards and example metrics app"
kubectl apply -f (Join-Path $RootDir "k8s/configs")

Write-Host "Installing Grafana"
helm upgrade --install grafana grafana/grafana `
    --namespace $MonitoringNamespace `
    --values (Join-Path $RootDir "helm/grafana/values.yaml") `
    --wait `
    --timeout 10m

if ($EnableLoki) {
    Write-Host "Installing optional Loki"
    helm upgrade --install loki grafana/loki `
        --namespace $MonitoringNamespace `
        --values (Join-Path $RootDir "helm/loki/values.yaml") `
        --set enabled=true `
        --wait `
        --timeout 10m
}

if ($EnableTempo) {
    Write-Host "Installing optional Tempo"
    helm upgrade --install tempo grafana/tempo `
        --namespace $MonitoringNamespace `
        --values (Join-Path $RootDir "helm/tempo/values.yaml") `
        --set enabled=true `
        --wait `
        --timeout 10m
}

if ($EnableOtel) {
    Write-Host "Installing optional OpenTelemetry Collector"
    helm upgrade --install opentelemetry-collector open-telemetry/opentelemetry-collector `
        --namespace $MonitoringNamespace `
        --values (Join-Path $RootDir "helm/opentelemetry-collector/values.yaml") `
        --set enabled=true `
        --wait `
        --timeout 10m
}

Write-Host "Validating rollouts"
Wait-ForDeploymentIfExists $MonitoringNamespace grafana
Wait-ForDeploymentIfExists $DemoNamespace example-metrics-app

Write-Host ""
Write-Host "Useful access commands"
Write-Host "Grafana:    kubectl port-forward svc/grafana -n monitoring 3000:80"
Write-Host "Prometheus: kubectl port-forward svc/prometheus-prometheus -n monitoring 9090:9090"
Write-Host ""
Write-Host "Grafana NodePort: kubectl get svc grafana -n monitoring"
