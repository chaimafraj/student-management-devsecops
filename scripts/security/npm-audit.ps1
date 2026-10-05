[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$frontend = Join-Path $projectRoot 'frontend'

Push-Location $frontend
try {
    # Production-only dependencies; --audit-level=critical makes the hook
    # fail only when npm reports at least one critical vulnerability.
    & npm audit --omit=dev --audit-level=critical
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}