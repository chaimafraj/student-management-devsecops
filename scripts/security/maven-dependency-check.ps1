[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$backend = Join-Path $projectRoot 'backend'
$mavenWrapper = Join-Path $backend 'mvnw.cmd'

if (-not (Test-Path -LiteralPath $mavenWrapper)) {
    throw "Maven Wrapper not found: $mavenWrapper"
}

# Dependency-Check rejects an empty NVD_API_KEY inherited from the shell.
# Preserve a non-empty key, but ignore an empty one.
if ((Test-Path Env:NVD_API_KEY) -and [string]::IsNullOrWhiteSpace($env:NVD_API_KEY)) {
    Remove-Item Env:NVD_API_KEY
}

# CVSS 9.0+ is Critical. Reports remain in backend/target (already gitignored).
Push-Location $backend
try {
    & $mavenWrapper -B org.owasp:dependency-check-maven:12.1.9:check `
        '-DfailBuildOnCVSS=9' `
        '-Dformat=HTML' `
        '-Dformat=JSON'
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}