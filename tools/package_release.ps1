# package_release.ps1 -- builds the Windows release ZIP from an already built tree.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -BuildOnly -Portable
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\package_release.ps1
#
# Output: dist\saturnbomberman-<version>-windows-x64.zip and dist\SHA256SUMS.
# The package holds the runtime, the launcher and the scripts that convert the
# player's own disc and generate game\game.toml. It never holds a BIOS, a disc
# image, game.toml or anything read from the game: the audit below fails the
# build if such a file slips in.
#
# (ASCII on purpose, see setup.ps1.)
param([string]$Version)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $Root

if (-not $Version) { $Version = (Get-Content -LiteralPath 'VERSION' -Raw).Trim() }
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Versao invalida: $Version" }
if ((Get-Content -LiteralPath 'VERSION' -Raw).Trim() -ne $Version) { throw "VERSION nao e $Version" }

$Name    = "saturnbomberman-$Version-windows-x64"
$Dist    = Join-Path $Root 'dist'
$Stage   = Join-Path $Dist $Name
$Zip     = Join-Path $Dist "$Name.zip"
$Runner  = 'external\SaturnRecomp\runner'

$files = @(
    'SaturnBomberman.exe',
    'setup.ps1', 'play.ps1', 'diagnose.ps1',
    'README.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'VERSION',
    'build\mkgame.exe',
    'external\SaturnRecomp\recompiler\saturnrecomp.exe',
    "$Runner\saturnwin.exe", "$Runner\saturnboot.exe",
    "$Runner\shaders\vdp1.comp.spv", "$Runner\shaders\vdp2.comp.spv",
    "$Runner\shaders\postprocess.comp.spv",
    "$Runner\shaders\game_overlay.vert.spv", "$Runner\shaders\game_overlay.frag.spv"
)
$files += @(Get-ChildItem -LiteralPath $Runner -Filter '*.dll' -File | ForEach-Object { "$Runner\$($_.Name)" })

if (Test-Path -LiteralPath $Stage) { Remove-Item -LiteralPath $Stage -Recurse -Force }
if (Test-Path -LiteralPath $Zip)   { Remove-Item -LiteralPath $Zip -Force }
New-Item -ItemType Directory -Force -Path $Stage | Out-Null

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file)) { throw "Arquivo ausente (rode setup.ps1 -BuildOnly antes): $file" }
    $target = Join-Path $Stage $file
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $file -Destination $target
}

# Empty folders the player fills in, each with a note saying what goes there.
New-Item -ItemType Directory -Force -Path (Join-Path $Stage 'BIOS') | Out-Null
Set-Content -LiteralPath (Join-Path $Stage 'BIOS\PUT-YOUR-BIOS-HERE.txt') -Encoding ascii -Value @(
    'Put the raw 512 KiB dump of YOUR Sega Saturn BIOS in this folder.',
    'Coloque nesta pasta o dump cru de 512 KiB da BIOS do SEU Sega Saturn.',
    'See README.md / Veja o README.md.'
)

# Audit: nothing from a BIOS, a disc or a generated configuration.
$forbidden = '\.(chd|cue|bin|iso|img|ccd|sub|mdf|mds|wav|mp3|toml|state|dmp|ini|log)$'
$bad = @(Get-ChildItem -LiteralPath $Stage -Recurse -File | Where-Object { $_.Name -match $forbidden })
if ($bad.Count -gt 0) { throw "Arquivo proibido no pacote: $($bad.FullName -join ', ')" }
foreach ($dir in @('disc', 'game')) {
    if (Test-Path -LiteralPath (Join-Path $Stage $dir)) { throw "Pasta proibida no pacote: $dir" }
}

# Zip entries with '/' separators (Compress-Archive in PowerShell 5.1 writes
# '\', which other unzip tools treat as part of the file name).
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($Zip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($item in Get-ChildItem -LiteralPath $Stage -Recurse -File) {
        $entry = $Name + '/' + $item.FullName.Substring($Stage.Length + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $item.FullName, $entry,
            [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
$hash = (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLower()
# LF line ending, so `sha256sum -c SHA256SUMS` works everywhere.
[IO.File]::WriteAllText((Join-Path $Dist 'SHA256SUMS'), "$hash  $Name.zip`n")
Remove-Item -LiteralPath $Stage -Recurse -Force

$size = [math]::Round((Get-Item -LiteralPath $Zip).Length / 1MB, 1)
Write-Host "ok: $Zip ($size MB)"
Write-Host "sha256: $hash"
