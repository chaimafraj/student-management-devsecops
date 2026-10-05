[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$pinnedBinary = Join-Path $env:LOCALAPPDATA 'Programs\gitleaks-8.18.4\gitleaks.exe'

if (Test-Path -LiteralPath $pinnedBinary) {
    $gitleaks = $pinnedBinary
}
else {
    $command = Get-Command gitleaks -ErrorAction SilentlyContinue
    if (-not $command) {
        throw 'Gitleaks 8.18.4 is required. Follow docs/shift-left-security.md.'
    }
    $gitleaks = $command.Source
}

$version = & $gitleaks version
if ($version -ne '8.18.4') {
    throw "Unsupported Gitleaks version '$version'. Version 8.18.4 is required until the 8.30.x default-rule regression is fixed."
}

& $gitleaks protect --staged --redact --verbose
exit $LASTEXITCODE