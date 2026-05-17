$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir "scripts/shared.ps1")

Require-Command kubectl

& (Join-Path $RootDir "scripts/stop.ps1")

kubectl delete -f (Join-Path $RootDir "k8s/namespaces") --ignore-not-found=true

Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $RootDir "k8s/secrets/grafana-admin-secret.yaml")
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $RootDir "k8s/secrets/sentry-secret.yaml")

Write-Host "Stack reset completed."
