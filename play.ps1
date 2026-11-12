# play.ps1 -- runs the game in this console so the runtime log is visible.
# Extra arguments go to the runtime, e.g.:  .\play.ps1 nobios
# (ASCII on purpose, see setup.ps1.)
$ErrorActionPreference = 'Continue'
$Root    = $PSScriptRoot
$Runtime = Join-Path $Root 'external\SaturnRecomp\runner\saturnwin.exe'
$GameDir = Join-Path $Root 'game'

if (-not (Test-Path -LiteralPath $Runtime) -or -not (Test-Path -LiteralPath (Join-Path $GameDir 'game.toml'))) {
    Write-Host 'ERRO: rode .\setup.ps1 primeiro.' -ForegroundColor Red
    exit 1
}
# Same settings file SaturnBomberman.exe uses, so F1 changes are shared.
$env:SATURN_SETTINGS_FILE = Join-Path $GameDir 'settings.ini'
Set-Location -LiteralPath $GameDir
& $Runtime 'game.toml' @args
exit $LASTEXITCODE
