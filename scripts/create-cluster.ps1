$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir "scripts/shared.ps1")

$ClusterName = if ($env:KIND_CLUSTER_NAME) { $env:KIND_CLUSTER_NAME } else { "prometheus-grafana" }

Require-Command kind
Require-Command kubectl
Require-Command docker

$Clusters = @(kind get clusters 2>$null)
if ($Clusters -contains $ClusterName) {
    Write-Host "Kind cluster '$ClusterName' already exists."
}
else {
    kind create cluster --name $ClusterName
}

kubectl cluster-info --context "kind-$ClusterName"
