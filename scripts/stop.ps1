$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir "scripts/shared.ps1")

Require-Command helm
Require-Command kubectl

helm uninstall opentelemetry-collector -n monitoring --ignore-not-found
helm uninstall tempo -n monitoring --ignore-not-found
helm uninstall loki -n monitoring --ignore-not-found
helm uninstall sentry -n sentry --ignore-not-found
helm uninstall grafana -n monitoring --ignore-not-found
helm uninstall prometheus -n monitoring --ignore-not-found

kubectl delete -f (Join-Path $RootDir "k8s/configs") --ignore-not-found=true

Write-Host "Stack releases removed. Namespaces and generated secret files were kept."
