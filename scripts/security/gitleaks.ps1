[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Path
)

$ErrorActionPreference = 'Stop'
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$pinnedBinary = $null
if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    $pinnedBinary = Join-Path $env:LOCALAPPDATA 'Programs\gitleaks-8.18.4\gitleaks.exe'
}

if ($pinnedBinary -and (Test-Path -LiteralPath $pinnedBinary)) {
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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$config = Join-Path $PSScriptRoot 'gitleaks.toml'
if (-not (Test-Path -LiteralPath $config)) {
    throw "Gitleaks config not found: $config"
}

function Invoke-Gitleaks {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    & $gitleaks @ArgumentList | Out-Host
    return $LASTEXITCODE
}

# No paths: commit-time scan of the index. Paths: the files pre-commit passed
# (staged files, or the whole tree with --all-files).
if (-not $Path -or $Path.Count -eq 0) {
    $code = Invoke-Gitleaks -ArgumentList @(
        'protect', '--staged', '--source', $repoRoot,
        '--config', $config, '--redact', '--verbose', '--no-banner'
    )
    exit $code
}

$exitCode = 0
foreach ($file in $Path) {
    if ([string]::IsNullOrWhiteSpace($file) -or -not (Test-Path -LiteralPath $file)) {
        continue
    }

    $code = Invoke-Gitleaks -ArgumentList @(
        'detect', '--no-git', '--source', $file,
        '--config', $config, '--redact', '--verbose', '--no-banner'
    )
    if ($code -ne 0) {
        $exitCode = $code
    }
}

exit $exitCode
