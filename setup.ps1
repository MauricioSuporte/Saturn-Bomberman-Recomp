# setup.ps1 -- prepares Saturn Bomberman to run through SaturnRecomp on Windows.
#
#   1. fetches the SaturnRecomp submodule
#   2. converts your CHD to CUE/BIN (SaturnRecomp cannot read CHD)
#   3. builds the runtime, shaders and SaturnBomberman.exe with MSYS2 MinGW-w64
#   4. generates game\game.toml from YOUR disc and BIOS and validates it
#
# Usage (PowerShell, from the repository root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
#
# Optional parameters:
#   -Disc    path to a .chd or .cue   (default: the .chd in the repository root)
#   -Bios    path to a 512 KiB BIOS   (default: picked from .\BIOS)
#   -Chdman  path to chdman.exe       (default: PATH, repo root, .\tools)
#   -MingwBin path to mingw64\bin     (default: SATURN_MINGW_BIN or C:\msys64\mingw64\bin)
#   -SkipBuild  reuse the existing build
#   -Force      convert the CHD again even if disc\SaturnBomberman.cue exists
#
# This file is ASCII on purpose: Windows PowerShell 5.1 misreads UTF-8 without BOM.
param(
    [string]$Disc,
    [string]$Bios,
    [string]$Chdman,
    [string]$MingwBin = $env:SATURN_MINGW_BIN,
    [switch]$SkipBuild,
    [switch]$Force
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
# Path written into game.toml: relative to game\ when inside the repository
# (so the folder can be moved), absolute otherwise. Always forward slashes.
function TomlPath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    if ($full.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) {
        return '../' + $full.Substring($base.Length).Replace('\', '/')
    }
    return $full.Replace('\', '/')
}

$Recomp   = Join-Path $Root 'external\SaturnRecomp'
$DiscDir  = Join-Path $Root 'disc'
$GameDir  = Join-Path $Root 'game'
$BuildDir = Join-Path $Root 'build'
$Runner   = Join-Path $Recomp 'runner'

# ---------------------------------------------------------------- 1. submodule
Step 'SaturnRecomp (submodulo)'
if (-not (Test-Path -LiteralPath (Join-Path $Recomp 'tools\build_runtime.ps1'))) {
    & git submodule update --init --recursive
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath (Join-Path $Recomp 'tools\build_runtime.ps1'))) {
        Fail 'Nao foi possivel baixar external\SaturnRecomp. Rode: git submodule update --init --recursive'
    }
}
Write-Host "ok: $Recomp"

# Runtime fixes this game needs that are not upstream yet (patches\*.patch).
# Each is applied once; an already applied patch is detected and skipped.
$patchFiles = @(Get-ChildItem -LiteralPath (Join-Path $Root 'patches') -Filter '*.patch' -File -ErrorAction SilentlyContinue | Sort-Object Name)
foreach ($patch in $patchFiles) {
    & git -C $Recomp apply --ignore-whitespace --reverse --check $patch.FullName 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Host "patch ja aplicado: $($patch.Name)"; continue }
    & git -C $Recomp apply --ignore-whitespace $patch.FullName
    if ($LASTEXITCODE -ne 0) {
        Fail "Nao foi possivel aplicar $($patch.Name). Restaure o submodulo com: git -C external/SaturnRecomp checkout -- . e rode o setup de novo."
    }
    Write-Host "patch aplicado: $($patch.Name)"
}

# ------------------------------------------------------------------ 2. MinGW
Step 'Compilador (MSYS2 MinGW-w64)'
if (-not $MingwBin -and (Test-Path -LiteralPath 'C:\msys64\mingw64\bin\gcc.exe')) {
    $MingwBin = 'C:\msys64\mingw64\bin'
}
if (-not $MingwBin) {
    $gccCommand = Get-Command gcc -ErrorAction SilentlyContinue
    if ($gccCommand) { $MingwBin = Split-Path -Parent $gccCommand.Source }
}
$Pacman = 'pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-SDL2 mingw-w64-x86_64-mpg123 mingw-w64-x86_64-vulkan-headers mingw-w64-x86_64-vulkan-loader mingw-w64-x86_64-shaderc'
if (-not $MingwBin -or -not (Test-Path -LiteralPath (Join-Path $MingwBin 'gcc.exe'))) {
    Fail "gcc.exe do MinGW-w64 nao encontrado. Instale o MSYS2 (https://www.msys2.org) e, no terminal 'MSYS2 MINGW64', rode:`n  $Pacman`nSe o MSYS2 nao estiver em C:\msys64, use -MingwBin 'X:\msys64\mingw64\bin'."
}
$MingwRoot = Split-Path -Parent $MingwBin
$needed = @(
    @{ Path = (Join-Path $MingwBin 'SDL2.dll');                       Package = 'mingw-w64-x86_64-SDL2' },
    @{ Path = (Join-Path $MingwBin 'glslc.exe');                      Package = 'mingw-w64-x86_64-shaderc' },
    @{ Path = (Join-Path $MingwRoot 'include\vulkan\vulkan.h');       Package = 'mingw-w64-x86_64-vulkan-headers' },
    @{ Path = (Join-Path $MingwRoot 'lib\libvulkan-1.dll.a');         Package = 'mingw-w64-x86_64-vulkan-loader' }
)
$missingPackages = @()
foreach ($item in $needed) {
    if (-not (Test-Path -LiteralPath $item.Path)) { $missingPackages += $item.Package }
}
if ($missingPackages.Count -gt 0 -and -not $SkipBuild) {
    Fail "Pacotes do MSYS2 ausentes: $($missingPackages -join ', ').`nNo terminal 'MSYS2 MINGW64', rode:`n  $Pacman"
}
$env:Path = "$MingwBin;$env:Path"
$env:SATURN_MINGW_BIN = $MingwBin
Write-Host "ok: $MingwBin"

# ------------------------------------------------------------------- 3. disc
Step 'Disco do jogo'
$Cue = Join-Path $DiscDir 'SaturnBomberman.cue'
$Bin = Join-Path $DiscDir 'SaturnBomberman.bin'

if (-not $Disc) {
    $candidates = @(Get-ChildItem -LiteralPath $Root -Filter '*.chd' -File -ErrorAction SilentlyContinue)
    $preferred  = @($candidates | Where-Object { $_.Name -like '*Bomberman*' })
    if ($preferred.Count -gt 0)      { $Disc = $preferred[0].FullName }
    elseif ($candidates.Count -gt 0) { $Disc = $candidates[0].FullName }
}
if ($Disc -and -not (Test-Path -LiteralPath $Disc)) { Fail "Disco nao encontrado: $Disc" }

if ($Disc -and [IO.Path]::GetExtension($Disc) -ieq '.cue') {
    # A CUE/BIN dump is used where it is; nothing to convert.
    $Cue = (Resolve-Path -LiteralPath $Disc).Path
    Write-Host "usando CUE: $Cue"
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
        foreach ($guess in @((Join-Path $Root 'chdman.exe'), (Join-Path $Root 'tools\chdman.exe'), (Join-Path $MingwBin 'chdman.exe'))) {
            if (Test-Path -LiteralPath $guess) { $Chdman = $guess; break }
        }
    }
    if (-not $Chdman -or -not (Test-Path -LiteralPath $Chdman)) {
        Fail "chdman.exe nao encontrado. O SaturnRecomp nao le CHD, entao o disco precisa virar CUE/BIN.`nO chdman vem junto com o MAME (https://www.mamedev.org/release.html): extraia o pacote e copie chdman.exe`npara a raiz deste repositorio (ou use -Chdman 'caminho\chdman.exe') e rode o setup de novo."
    }
    New-Item -ItemType Directory -Force -Path $DiscDir | Out-Null
    Write-Host "convertendo: $Disc"
    & $Chdman extractcd -i $Disc -o $Cue -ob $Bin -f
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Cue) -or -not (Test-Path -LiteralPath $Bin)) {
        Fail 'chdman extractcd falhou. Confira se o .chd esta integro (chdman verify -i arquivo.chd).'
    }
    Write-Host "ok: $Cue"
}

# ------------------------------------------------------------------- 4. BIOS
Step 'BIOS'
$BiosSize = 524288
if (-not $Bios) {
    $biosDir = Join-Path $Root 'BIOS'
    if (-not (Test-Path -LiteralPath $biosDir)) {
        Fail "Pasta $biosDir nao encontrada. Coloque nela o dump da BIOS do Saturn (512 KiB) ou use -Bios 'caminho\bios.bin'."
    }
    $dumps = @(Get-ChildItem -LiteralPath $biosDir -File -Recurse | Where-Object { $_.Length -eq $BiosSize } | Sort-Object Name)
    if ($dumps.Count -eq 0) {
        Fail "Nenhum arquivo de exatamente $BiosSize bytes em $biosDir. A BIOS precisa ser o dump cru de 512 KiB (descompacte se estiver em .zip)."
    }
    # The disc is the USA release, so prefer a dump whose name says so.
    $american = @($dumps | Where-Object { $_.Name -match '(?i)(usa|america|\(u\)|\(us\)|[ _\-\.]us[ _\-\.]|_na[_\.]|101a|100a)' })
    if ($american.Count -gt 0) { $Bios = $american[0].FullName } else { $Bios = $dumps[0].FullName }
    if ($dumps.Count -gt 1) {
        Write-Host 'BIOS encontradas:'
        foreach ($dump in $dumps) { Write-Host "  $($dump.Name)" }
        Write-Host "Para escolher outra: .\setup.ps1 -SkipBuild -Bios 'BIOS\arquivo.bin'"
    }
}
if (-not (Test-Path -LiteralPath $Bios)) { Fail "BIOS nao encontrada: $Bios" }
$Bios = (Resolve-Path -LiteralPath $Bios).Path
if ((Get-Item -LiteralPath $Bios).Length -ne $BiosSize) {
    Fail "$Bios nao tem $BiosSize bytes; nao e um dump cru da BIOS do Saturn."
}
Write-Host "ok: $Bios"

# ------------------------------------------------------------------ 5. build
$Cli      = Join-Path $Recomp 'recompiler\saturnrecomp.exe'
$MkGame   = Join-Path $BuildDir 'mkgame.exe'
$Runtime  = Join-Path $Runner 'saturnwin.exe'
$Launcher = Join-Path $Root 'SaturnBomberman.exe'

if (-not $SkipBuild) {
    Step 'Compilando (a primeira vez leva alguns minutos)'
    New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

    Push-Location -LiteralPath $Recomp
    & gcc -O2 -std=c11 -Irecompiler/include -o recompiler/saturnrecomp.exe `
        recompiler/src/main.c recompiler/src/disc.c recompiler/src/game_config.c `
        external/sh2-recomp-core/common/sh2_decoder.c
    $cliStatus = $LASTEXITCODE
    Pop-Location
    if ($cliStatus -ne 0) { Fail 'Falha ao compilar o saturnrecomp.exe (CLI).' }

    & gcc -O2 -std=c11 -Iexternal/SaturnRecomp/recompiler/include -o build/mkgame.exe `
        tools/mkgame.c external/SaturnRecomp/recompiler/src/disc.c
    if ($LASTEXITCODE -ne 0) { Fail 'Falha ao compilar tools\mkgame.c.' }

    & gcc -O2 -std=c11 -municode -mwindows -o SaturnBomberman.exe tools/launcher.c
    if ($LASTEXITCODE -ne 0) { Fail 'Falha ao compilar tools\launcher.c.' }

    # The shared runtime (SH-2/68000 cores, VDP1/VDP2, SCSP, Vulkan presenter).
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Recomp 'tools\build_runtime.ps1') `
        -Output runner/saturnwin.exe -BootOutput runner/saturnboot.exe
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Runtime)) { Fail 'Falha ao compilar o runtime (saturnwin.exe).' }

    $glslc = Join-Path $MingwBin 'glslc.exe'
    foreach ($shader in @('vdp1.comp', 'vdp2.comp', 'postprocess.comp', 'game_overlay.vert', 'game_overlay.frag')) {
        $source = Join-Path $Runner "shaders\$shader"
        & $glslc $source -O -o "$source.spv"
        if ($LASTEXITCODE -ne 0) { Fail "Falha ao compilar o shader $shader." }
    }

    # Copy every MinGW DLL the runtime imports (SDL2, the Vulkan loader and
    # whatever they pull in) beside it, so it starts without MSYS2 on PATH.
    $objdump = Join-Path $MingwBin 'objdump.exe'
    if (Test-Path -LiteralPath $objdump) {
        $queue  = New-Object System.Collections.Queue
        $copied = @{}
        $queue.Enqueue($Runtime)
        while ($queue.Count -gt 0) {
            $binary = $queue.Dequeue()
            $imports = @(& $objdump -p $binary 2>$null | Select-String -Pattern 'DLL Name:\s*(\S+)')
            foreach ($import in $imports) {
                $name = $import.Matches[0].Groups[1].Value
                $from = Join-Path $MingwBin $name
                if ($copied.ContainsKey($name.ToLower()) -or -not (Test-Path -LiteralPath $from)) { continue }
                $copied[$name.ToLower()] = $true
                Copy-Item -LiteralPath $from -Destination (Join-Path $Runner $name) -Force
                $queue.Enqueue($from)
            }
        }
    } else {
        Copy-Item -LiteralPath (Join-Path $MingwBin 'SDL2.dll') -Destination (Join-Path $Runner 'SDL2.dll') -Force
    }
    # Optional: only needed for CUE sheets whose audio tracks are MP3 files.
    $mpg123 = Join-Path $MingwBin 'libmpg123-0.dll'
    if (Test-Path -LiteralPath $mpg123) { Copy-Item -LiteralPath $mpg123 -Destination (Join-Path $Runner 'libmpg123-0.dll') -Force }
    Write-Host 'build ok'
}
foreach ($built in @($Cli, $MkGame, $Runtime, $Launcher)) {
    if (-not (Test-Path -LiteralPath $built)) { Fail "Arquivo de build ausente: $built (rode o setup sem -SkipBuild)." }
}

# -------------------------------------------------------------- 6. game.toml
Step 'Gerando game\game.toml a partir do seu disco'
New-Item -ItemType Directory -Force -Path $GameDir | Out-Null
$Toml = Join-Path $GameDir 'game.toml'
& $MkGame $Cue (TomlPath $Cue) (TomlPath $Bios) $Toml
if ($LASTEXITCODE -ne 0) { Fail 'Nao foi possivel ler o disco. O dump esta completo?' }

& $Cli modules $Toml
if ($LASTEXITCODE -ne 0) { Fail 'A validacao do game.toml falhou (veja a saida acima).' }

Write-Host ''
Write-Host 'Tudo pronto.' -ForegroundColor Green
Write-Host '  Jogar:            .\SaturnBomberman.exe   (log em game\runtime.log)'
Write-Host '  Jogar com log:    .\play.ps1'
Write-Host '  Enter = Start, Z/X/C = A/B/C, setas = direcional, F1 = configuracoes, Esc = sair'
exit 0
