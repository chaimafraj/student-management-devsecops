# Met a jour l'application locale avec les dernieres images publiees par le pipeline (GHCR).
# Les images apparaissent alors dans Docker Desktop et l'application est relancee.
#
# Usage (depuis la racine du projet) :
#   .\scripts\update-local.ps1                      # une seule mise a jour
#   .\scripts\update-local.ps1 -IntervalMinutes 5   # verifie toutes les 5 minutes
param([int]$IntervalMinutes = 0)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$files = @("-f", "docker-compose.yml", "-f", "docker-compose.ghcr.yml")

function Update-App {
    docker compose @files pull
    if ($LASTEXITCODE -ne 0) { throw "Echec du pull (verifier docker login ghcr.io ou la visibilite des packages)" }
    docker compose @files up -d --no-build
    if ($LASTEXITCODE -ne 0) { throw "Echec du demarrage de l'application" }
    docker image prune -f | Out-Null
    Write-Host ("[{0}] Application a jour." -f (Get-Date -Format "dd/MM/yyyy HH:mm"))
}

if ($IntervalMinutes -gt 0) {
    Write-Host "Surveillance toutes les $IntervalMinutes minute(s). Ctrl+C pour arreter."
    while ($true) {
        try { Update-App } catch { Write-Warning $_ }
        Start-Sleep -Seconds ($IntervalMinutes * 60)
    }
} else {
    Update-App
}
