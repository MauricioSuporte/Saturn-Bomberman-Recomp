# play.ps1 -- runs the game built by setup.ps1, with its log in this console.
#
#   .\play.ps1              the game, in a window (F1 or Esc: the in-game menu)
#   .\play.ps1 -Launcher    the launcher: disc, display, controllers, features, then Play
#   .\play.ps1 -Record      the game, adding every block of code you reach that has no translation
#                           yet to the block database; run .\setup.ps1 -SkipRecord afterwards
#   .\play.ps1 -Stats       prints at exit how much ran translated and how much was interpreted
#
# Anything else goes to the game as it is, e.g.:  .\play.ps1 --fullscreen   .\play.ps1 --video software
# (ASCII on purpose, see setup.ps1.)
param(
    [switch]$Launcher,
    [switch]$Record,
    [switch]$Stats,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)
$ErrorActionPreference = 'Continue'
$Root  = $PSScriptRoot
$Game  = 'saturn_bomberman'
$Build = Join-Path $Root "build\$Game"
$Exe   = Join-Path $Build "$Game.exe"
$User  = Join-Path $Root 'user'
$DiscNote = Join-Path $User 'disc.txt'

if (-not (Test-Path -LiteralPath $Exe) -or -not (Test-Path -LiteralPath $DiscNote)) {
    Write-Host 'ERRO: rode .\setup.ps1 primeiro.' -ForegroundColor Red
    exit 1
}
if ($Launcher) {
    $LauncherExe = Join-Path $Build "$Game-launcher.exe"
    if (-not (Test-Path -LiteralPath $LauncherExe)) {
        Write-Host 'ERRO: o launcher nao foi compilado (rode .\setup.ps1).' -ForegroundColor Red
        exit 1
    }
    & $LauncherExe
    exit $LASTEXITCODE
}
$Disc = (Get-Content -LiteralPath $DiscNote -TotalCount 1).Trim()
if (-not (Test-Path -LiteralPath $Disc)) {
    Write-Host "ERRO: disco nao encontrado: $Disc (rode .\setup.ps1 de novo)." -ForegroundColor Red
    exit 1
}
$GameArgs = @('--disc', $Disc, '--backup', (Join-Path $User 'backup.bin'), '--settings', (Join-Path $User 'settings.ini'))
if ($Record) { $GameArgs += @('--record-blocks', (Join-Path $Root "work\$Game\blocks.txt"), '--stats') }
if ($Stats -and -not $Record) { $GameArgs += '--stats' }
if ($Rest) { $GameArgs += $Rest }
& $Exe @GameArgs
exit $LASTEXITCODE
