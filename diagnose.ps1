# diagnose.ps1 -- headless run that records WHERE the game stops.
#
# Runs SaturnRecomp's windowless runner for a fixed number of instructions and
# writes its end-of-run report (CPU registers, the few instructions around the
# program counter, CD block and video register state) to game\diagnose.log.
# The log holds runtime state only: no BIOS, no disc data.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\diagnose.ps1
#   ... -Instructions 3000000000     run longer
#
# (ASCII on purpose, see setup.ps1.)
param([string]$Instructions = '1500000000')

$ErrorActionPreference = 'Continue'
$Root    = $PSScriptRoot
$Boot    = Join-Path $Root 'external\SaturnRecomp\runner\saturnboot.exe'
$GameDir = Join-Path $Root 'game'
$Log     = Join-Path $GameDir 'diagnose.log'

if (-not (Test-Path -LiteralPath $Boot) -or -not (Test-Path -LiteralPath (Join-Path $GameDir 'game.toml'))) {
    Write-Host 'ERRO: rode .\setup.ps1 primeiro.' -ForegroundColor Red
    exit 1
}
if ($Instructions -notmatch '^\d+$') {
    Write-Host 'ERRO: -Instructions precisa ser um numero.' -ForegroundColor Red
    exit 1
}
$env:SATURN_HOT       = '1'   # histogram of the most executed addresses
$env:SATURN_ILLLOG    = '1'   # illegal-instruction exceptions
$env:SATURN_SMPC_CMDS = '1'   # system-manager commands (reset, clock change...)
# Disassembly of the loop the game is stuck in (PC 0x06051C3E..0x06051D3A in
# the first report) and the last writer of the unmapped byte it hammers.
$env:SATURN_DUMP      = '0x06051B00:0x300'
$env:SATURN_WWATCH    = '0x0582503D'

Set-Location -LiteralPath $GameDir
Write-Host "Rodando $Instructions instrucoes sem janela (pode levar alguns minutos)..."
# cmd does the redirection: PowerShell 5.1 would wrap every stderr line in an
# error record and reorder the two streams.
& cmd.exe /d /c "`"$Boot`" game.toml $Instructions > diagnose.log 2>&1"
$status = $LASTEXITCODE

$size = 0
if (Test-Path -LiteralPath $Log) { $size = (Get-Item -LiteralPath $Log).Length }
Write-Host "Terminou (codigo $status). Log: $Log ($size bytes)"
Write-Host 'Envie esse arquivo (ou as ultimas ~300 linhas dele).'
exit 0
