$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $RootDir "scripts/shared.ps1")

$ClusterName = if ($env:KIND_CLUSTER_NAME) { $env:KIND_CLUSTER_NAME } else { "observability" }

Require-Command kind
Require-Command docker

kind delete cluster --name $ClusterName
