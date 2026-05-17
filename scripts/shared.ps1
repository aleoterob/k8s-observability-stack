function Add-WinGetCommandPath {
    param(
        [string]$PackagePattern,
        [string]$ExecutableName
    )

    $packagesDir = Join-Path $env:LOCALAPPDATA "Microsoft/WinGet/Packages"
    if (-not (Test-Path $packagesDir)) {
        return
    }

    $exe = Get-ChildItem $packagesDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $PackagePattern } |
        ForEach-Object { Get-ChildItem $_.FullName -Recurse -Filter $ExecutableName -ErrorAction SilentlyContinue } |
        Select-Object -First 1

    if ($exe) {
        $dir = Split-Path -Parent $exe.FullName
        $pathParts = $env:Path -split ";"
        if ($pathParts -notcontains $dir) {
            $env:Path = "$env:Path;$dir"
        }
    }
}

function Add-KnownToolPaths {
    Add-WinGetCommandPath "Kubernetes.kind*" "kind.exe"
    Add-WinGetCommandPath "Helm.Helm*" "helm.exe"
}

function Require-Command {
    param([string]$Name)

    Add-KnownToolPaths

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing required command: $Name. Install it with winget and open a new PowerShell window."
    }
}
