# setup.ps1 -- builds Saturn Bomberman as a static recompilation with the satrecomp toolkit.
#
#   1. checks MSYS2 and installs the compiler and libraries it needs
#   2. converts your CHD to CUE/BIN (or uses your .cue), into .\disc
#   3. builds the game with no translated code, and runs it without a window to find the
#      game's code (tools/record.sh: the block database, work\saturn_bomberman\blocks.txt)
#   4. translates that code from SH-2 to C++ and builds the game again, twice (the second
#      pass plays further with the fast build and finds more)
#   5. builds the launcher and copies the DLLs beside the programs
#
# No BIOS is needed. Nothing made from your disc leaves your PC or goes into git.
#
# Usage (PowerShell, from the repository root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
#
# Optional parameters:
#   -Disc    path to a .chd or .cue   (default: the .chd in the repository root, or disc\*.cue)
#   -Chdman  path to chdman.exe       (default: PATH, repository root, .\tools)
#   -Msys    MSYS2 folder             (default: SATURN_MSYS or C:\msys64)
#   -Force       convert the CHD again even if disc\SaturnBomberman.cue exists
#   -SkipRecord  build only with the block database that is already there (no recording runs)
#   -Frames  length of each recording run in frames (default 12000 and 30000)
#
# This file is ASCII on purpose: Windows PowerShell 5.1 misreads UTF-8 without BOM.
param(
    [string]$Disc,
    [string]$Chdman,
    [string]$Msys = $env:SATURN_MSYS,
    [switch]$Force,
    [switch]$SkipRecord,
    [int]$Frames = 0
)

# 'Continue', not 'Stop': PowerShell 5.1 turns compiler warnings on stderr into
# terminating errors under 'Stop'. Every native call is checked by exit code.
$ErrorActionPreference = 'Continue'
$Root = $PSScriptRoot
Set-Location -LiteralPath $Root

function Fail([string]$Message) {
    Write-Host ''
    Write-Host "ERRO: $Message" -ForegroundColor Red
    exit 1
}
function Step([string]$Message) {
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$Game     = 'saturn_bomberman'
$DiscDir  = Join-Path $Root 'disc'
$Cue      = Join-Path $DiscDir 'SaturnBomberman.cue'
$Bin      = Join-Path $DiscDir 'SaturnBomberman.bin'
$BuildDir = Join-Path $Root "build\$Game"
$Blocks   = Join-Path $Root "work\$Game\blocks.txt"

# ------------------------------------------------------------------ 1. MSYS2
Step 'MSYS2 (compilador e bibliotecas)'
if (-not $Msys) { $Msys = 'C:\msys64' }
$Bash = Join-Path $Msys 'usr\bin\bash.exe'
if (-not (Test-Path -LiteralPath $Bash)) {
    Fail "MSYS2 nao encontrado em $Msys. Instale de https://www.msys2.org (pasta padrao C:\msys64) ou use -Msys 'caminho'."
}
$env:MSYSTEM = 'MINGW64'
$env:CHERE_INVOKING = '1'
# Runs a command line in the MSYS2 MINGW64 shell, in the repository's folder
function Sh([string]$Command) {
    # (the output goes to the console, not into the function's result, which is the exit code alone)
    & $Bash -lc $Command | Out-Host
    return $LASTEXITCODE
}
$Packages = 'make git diffutils mingw-w64-x86_64-gcc mingw-w64-x86_64-cmake mingw-w64-x86_64-ninja ' +
            'mingw-w64-x86_64-python mingw-w64-x86_64-sdl3 mingw-w64-x86_64-zlib'
if ((Sh "pacman -S --needed --noconfirm $Packages") -ne 0) {
    Fail "Nao foi possivel instalar os pacotes do MSYS2. Abra 'MSYS2 MINGW64' e rode: pacman -S --needed $Packages"
}

# ------------------------------------------------------------------- 2. disc
Step 'Disco do jogo'
if (-not $Disc) {
    $chds = @(Get-ChildItem -LiteralPath $Root -Filter '*.chd' -File | Sort-Object Name)
    if ($chds.Count -gt 0) { $Disc = $chds[0].FullName }
}
if ($Disc -and -not (Test-Path -LiteralPath $Disc)) { Fail "Disco nao encontrado: $Disc" }

if ($Disc -and [IO.Path]::GetExtension($Disc) -ieq '.cue') {
    # A .cue of yours: the game is built and run from it where it is
    $Cue = (Resolve-Path -LiteralPath $Disc).Path
    Write-Host "usando: $Cue"
} elseif ((Test-Path -LiteralPath $Cue) -and (Test-Path -LiteralPath $Bin) -and -not $Force) {
    Write-Host "ja convertido: $Cue  (use -Force para converter de novo)"
} else {
    if (-not $Disc) {
        Fail "Nenhum .chd encontrado em $Root. Coloque o arquivo na raiz do repositorio ou use -Disc 'caminho\jogo.chd' (ou um .cue)."
    }
    if ([IO.Path]::GetExtension($Disc) -ine '.chd') { Fail "Formato nao suportado: $Disc (use .chd ou .cue)" }
    if (-not $Chdman) {
        $chdmanCommand = Get-Command chdman -ErrorAction SilentlyContinue
        if ($chdmanCommand) { $Chdman = $chdmanCommand.Source }
    }
    if (-not $Chdman) {
        foreach ($guess in @((Join-Path $Root 'chdman.exe'), (Join-Path $Root 'tools\chdman.exe'))) {
            if (Test-Path -LiteralPath $guess) { $Chdman = $guess; break }
        }
    }
    if (-not $Chdman -or -not (Test-Path -LiteralPath $Chdman)) {
        Fail "chdman.exe nao encontrado. O disco em CHD precisa virar CUE/BIN.`nO chdman vem junto com o MAME (https://www.mamedev.org/release.html): extraia o pacote e copie chdman.exe`npara a raiz deste repositorio (ou use -Chdman 'caminho\chdman.exe') e rode o setup de novo."
    }
    New-Item -ItemType Directory -Force -Path $DiscDir | Out-Null
    Write-Host "convertendo: $Disc"
    & $Chdman extractcd -i $Disc -o $Cue -ob $Bin -f
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Cue) -or -not (Test-Path -LiteralPath $Bin)) {
        Fail 'chdman extractcd falhou. Confira se o .chd esta integro (chdman verify -i arquivo.chd).'
    }
    Write-Host "ok: $Cue"
}
# The path as the MSYS2 tools take it, remembered for play.ps1
$CueUnix = (& $Bash -lc "cygpath -u '$($Cue.Replace('\', '/'))'").Trim()
New-Item -ItemType Directory -Force -Path (Join-Path $Root 'user') | Out-Null
Set-Content -LiteralPath (Join-Path $Root 'user\disc.txt') -Value $Cue -Encoding ASCII

# ------------------------------------------------------------------ 3. build
function Build([string]$What) {
    Step $What
    if ((Sh "make DISC='$CueUnix'") -ne 0) { Fail 'A compilacao falhou (veja as mensagens acima).' }
}
function Record([int]$Length, [int]$Seed) {
    Step "Procurando o codigo do jogo: 6 execucoes sem janela de $Length quadros (alguns minutos)"
    if ((Sh "DISC='$CueUnix' tools/record.sh $Length $Seed") -ne 0) {
        Fail "Uma execucao de gravacao falhou (veja work\$Game\record\*.log)."
    }
}

if ($SkipRecord) {
    Build 'Compilando o jogo com o banco de blocos existente'
} else {
    if (-not (Test-Path -LiteralPath $Blocks)) {
        Build 'Compilando o jogo sem codigo traduzido (so o interpretador)'
        Record $(if ($Frames) { $Frames } else { 12000 }) 1
    }
    Build 'Traduzindo o codigo do jogo (SH-2 -> C++) e compilando: 1a passada'
    Record $(if ($Frames) { $Frames } else { 30000 }) 2
    Build 'Traduzindo o codigo do jogo (SH-2 -> C++) e compilando: 2a passada'
}

# --------------------------------------------------------------- 4. launcher
Step 'Launcher'
if ((Sh "make DISC='$CueUnix' launcher") -ne 0) {
    Write-Host 'AVISO: o launcher nao compilou (ele baixa o Dear ImGui na primeira vez; precisa de internet).' -ForegroundColor Yellow
    Write-Host '       O jogo funciona sem ele: use .\play.ps1' -ForegroundColor Yellow
}

# ------------------------------------------------------------------- 5. DLLs
Step 'DLLs'
$MingwBin = Join-Path $Msys 'mingw64\bin'
foreach ($dll in @('SDL3.dll', 'libiconv-2.dll', 'zlib1.dll', 'libstdc++-6.dll', 'libgcc_s_seh-1.dll', 'libwinpthread-1.dll')) {
    $from = Join-Path $MingwBin $dll
    if (-not (Test-Path -LiteralPath $from)) { Fail "DLL nao encontrada: $from" }
    Copy-Item -LiteralPath $from -Destination $BuildDir -Force
}
Write-Host "ok: $BuildDir"

Write-Host ''
Write-Host 'Tudo pronto.' -ForegroundColor Green
Write-Host '  Jogar:                  .\play.ps1          (ou dois cliques em SaturnBomberman.cmd)'
Write-Host '  Launcher (opcoes):      .\play.ps1 -Launcher'
Write-Host '  Jogar gravando blocos:  .\play.ps1 -Record  (depois rode .\setup.ps1 -SkipRecord)'
