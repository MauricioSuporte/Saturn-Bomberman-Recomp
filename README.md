# Saturn Bomberman Recomp

An unofficial, noncommercial way to play **Saturn Bomberman (USA)** on Windows, built on the
[SaturnRecomp](https://github.com/sonsegajp/SaturnRecomp) runtime. It boots **your own** Sega
Saturn BIOS and **your own** copy of the game.

<p align="center">
  <a href="https://github.com/MauricioSuporte/Saturn-Bomberman-Recomp/releases/download/v1.0.0/saturnbomberman-1.0.0-windows-x64.zip"><img alt="Download for Windows" height="44" src="https://img.shields.io/badge/Download-Windows%20x64-0078D6?style=for-the-badge&logo=windows&logoColor=white"></a>
  <br>
  <a href="https://github.com/MauricioSuporte/Saturn-Bomberman-Recomp/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/MauricioSuporte/Saturn-Bomberman-Recomp?style=flat-square&label=latest"></a>
</p>

[All releases](https://github.com/MauricioSuporte/Saturn-Bomberman-Recomp/releases) · [English](#english) · [Português](#português) · [Third-party notices](THIRD_PARTY_NOTICES.md)

> **Bring your own BIOS and disc.** This repository and its releases contain no BIOS, no disc
> image, no game code and no extracted game files, only the runtime, a launcher and scripts.
> The game data is read from your files on your PC and never leaves it. Not affiliated with
> SEGA, Hudson Soft or Konami.

---

## English

### Highlights

- Boots through the real Saturn BIOS, passes the SEGA licence screen, plays the intro movie,
  reaches the title screen and menus, and starts Normal Game (story mode).
- Vulkan renderer by default, with a software renderer as a fallback.
- Keyboard and gamepad (Xbox-style) on player 1, plus an **F1** settings overlay (window size,
  fullscreen, internal resolution, filtering, volume).
- Ready-made Windows package: download, add your BIOS and disc, run one script, play. No
  compiler needed.

### What "recompilation" means here (read this first)

Projects such as Super Bomberman 5 Recompiled translate the game's code into C and compile
it on your PC. **This project does not do that yet**, because SaturnRecomp's public version
has no SH-2 → C translator. What happens instead:

1. `setup.ps1` reads **your** disc. If it is a `.chd`, it converts it to `.cue` + `.bin`
   first, because the runtime cannot read CHD. Then it writes a small configuration file,
   `game\game.toml`, saying where the disc and the BIOS are and how the game boots.
2. `SaturnBomberman.exe` starts the SaturnRecomp runtime with that file. The runtime boots
   your BIOS and runs the game straight from the disc on a fast SH-2 **interpreter**,
   together with emulated video (VDP1/VDP2), sound (SCSP/68000) and CD hardware.

So the only thing you "generate" is `game\game.toml` (plus the converted disc). You never
compile anything if you use a release. If you build from source, you compile the runtime
once, and that build does not depend on the game.

### What you need

| Item | Details |
| --- | --- |
| Windows 10 or 11, 64-bit | With a GPU and driver that support **Vulkan** (any GPU from roughly 2016 on with up-to-date drivers). Otherwise use the software renderer (see Troubleshooting). |
| Your Saturn BIOS | The raw dump of a Sega Saturn BIOS, exactly **524,288 bytes (512 KiB)**. A USA/North American BIOS is preferred (the disc is the USA release). If it came zipped, unzip it. |
| Your Saturn Bomberman (USA) disc | As a **`.chd`** file, or as a **`.cue` + `.bin`** pair. The tested dump is `Saturn Bomberman (USA) (1S).chd` (product MK-81070). |
| `chdman.exe` (only for `.chd`) | Comes with **MAME**. See [Getting chdman](#getting-chdman). Not needed if your disc is already `.cue` + `.bin`. |

### Install from a release (recommended)

1. **Download** `saturnbomberman-1.0.0-windows-x64.zip` from the
   [latest release](https://github.com/MauricioSuporte/Saturn-Bomberman-Recomp/releases/latest).
2. **Extract the whole ZIP** into a folder you can write to, for example
   `C:\Games\SaturnBomberman`. Do not run it from inside the ZIP, and avoid `C:\Program Files`.
   You get a folder `saturnbomberman-1.0.0-windows-x64` containing `SaturnBomberman.exe`,
   `setup.ps1`, a `BIOS` folder and others.
3. **Add your BIOS:** copy the 512 KiB BIOS file into the `BIOS` folder. Any file name works.
   If there are several, the script prefers one whose name contains `USA`, `US` or `NA`.
4. **Add your disc:** copy the `.chd` into the main folder, next to `SaturnBomberman.exe`.
   For a `.cue` + `.bin` dump, see step 6.
5. **If your disc is a `.chd`:** put `chdman.exe` in the same main folder (see
   [Getting chdman](#getting-chdman)).
6. **Run the setup.** In the main folder, click the address bar of File Explorer, type
   `powershell` and press Enter. A blue/black window opens in that folder. Paste:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
   ```

   For a `.cue` + `.bin` dump, point to the `.cue` instead (keep the `.bin` next to it):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -Disc "D:\Saturn\Saturn Bomberman (USA).cue"
   ```

   The script prints each step (`==> Disco do jogo`, `==> BIOS`, `==> Gerando game\game.toml...`)
   and ends with **`Tudo pronto.`** (Portuguese for "All set"). Converting a CHD takes a minute
   or two and creates the `disc` folder (about 550 MB). The `game` folder holds `game.toml`,
   your settings, the log and the emulated console memory.
7. **Play:** double-click `SaturnBomberman.exe`. On the very first boot the BIOS shows its
   own **language and clock** screens. Choose a language, set the clock and exit. This happens
   once, the same as on a real console. The SEGA logo, the intro and the title screen follow.
   Press **Enter** (Start).

Optional parameters of `setup.ps1`: `-Disc <file.chd|file.cue>`, `-Bios <file>`,
`-Chdman <path\chdman.exe>`, `-Force` (convert the CHD again).

### Getting chdman

`chdman` is MAME's CHD tool. It is **not** included here (MAME is a separate GPL project).

1. Open <https://www.mamedev.org/release.html> and download the Windows 64-bit package
   (`mame0XXXb_x64.exe`). It is a self-extracting archive.
2. Extract it into a folder **outside** this project, for example `C:\Tools\mame`.
3. Copy only `chdman.exe` from there into the game's main folder, or run the setup with
   `-Chdman "C:\Tools\mame\chdman.exe"`. Having `chdman` on your `PATH` also works.

You only need chdman once. After the conversion, `disc\SaturnBomberman.cue` is reused.

### Controls

| Saturn | Keyboard | Gamepad (Xbox style) |
| --- | --- | --- |
| D-pad | Arrow keys or W/A/S/D | D-pad or left stick |
| Start | Enter | Start |
| A / B / C | Z / X / C | A / B / RB |
| X / Y / Z | R / T / Y | X / Y / LB |
| L / R | Q / E | LT / RT |

**F1** settings · **F2** frame interpolation on/off · **Space** pause · **Esc** quit.

### Troubleshooting

- **`setup.ps1` cannot be run / "running scripts is disabled":** use exactly the command above
  (`powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1`). It only bypasses the
  policy for that one run.
- **`ERRO: Nenhum .chd encontrado`:** the `.chd` is not in the main folder. Move it there or
  use `-Disc`.
- **`chdman.exe nao encontrado`:** see [Getting chdman](#getting-chdman).
- **`Nenhum arquivo de exatamente 524288 bytes`:** the BIOS file is missing, still zipped or
  not a raw dump.
- **It stops in the BIOS menu / CD player:** the disc dump may be incomplete
  (`chdman verify -i file.chd`) or the BIOS may be unsuitable. Try another one with `-Bios`.
- **Black window or Vulkan error:** update your GPU driver. To use the software renderer, open
  PowerShell in the folder and run:

  ```powershell
  $env:SATURN_RENDERER='software'; .\play.ps1
  ```

- **See the log:** `.\play.ps1` runs the game with the log in the console. Double-clicking the
  exe writes it to `game\runtime.log`. `.\diagnose.ps1` runs the game headless and writes
  `game\diagnose.log`.

When reporting a problem, send only `game\runtime.log` (or `diagnose.log`) and where it
stopped. Never send the BIOS, the disc, `game\wram_high.bin` or extracted files.

### Build from source (step by step)

Do this only if you want to change the code. Players should use a release.

1. **Install Git:** <https://git-scm.com/download/win> (default options).
2. **Install MSYS2:** <https://www.msys2.org>. Keep the default folder `C:\msys64`.
3. **Install the compiler and libraries:** open **"MSYS2 MINGW64"** from the Start menu (the
   blue icon) and run:

   ```sh
   pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-SDL2 mingw-w64-x86_64-mpg123 mingw-w64-x86_64-vulkan-headers mingw-w64-x86_64-vulkan-loader mingw-w64-x86_64-shaderc
   ```

   Answer `Y` when asked.
4. **Clone with submodules** (in PowerShell or Git Bash):

   ```powershell
   git clone --recursive https://github.com/MauricioSuporte/Saturn-Bomberman-Recomp.git
   cd Saturn-Bomberman-Recomp
   ```

   If you cloned without `--recursive`, run `git submodule update --init --recursive`.
5. **Add your files** in the repository folder (all of them are ignored by git and are never
   committed):

   ```text
   Saturn-Bomberman-Recomp\
     Saturn Bomberman (USA) (1S).chd      <- your disc (or use -Disc with a .cue)
     chdman.exe                           <- only for .chd (or use -Chdman)
     BIOS\<your 512 KiB BIOS>
   ```

6. **Run the setup:**

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
   ```

   What it does, in order:
   1. Restores `external\SaturnRecomp` to its pinned commit and applies `patches\*.patch`
      (the runtime fixes this game needs, see below).
   2. Finds MSYS2 (`C:\msys64\mingw64\bin`, or `-MingwBin <path>`).
   3. Compiles the SaturnRecomp CLI (`saturnrecomp.exe`), `build\mkgame.exe` (the `game.toml`
      generator), `SaturnBomberman.exe` (the launcher), the runtime (`saturnwin.exe` with a
      window, `saturnboot.exe` without one), and the Vulkan shaders. It copies the needed DLLs
      next to the runtime. The first build takes a few minutes.
   4. Converts the disc, finds the BIOS, writes `game\game.toml` and validates it.

   Re-run with `-SkipBuild` to only regenerate `game.toml`. Use `-BuildOnly` to compile without
   a disc or BIOS.
7. **Play:** `.\SaturnBomberman.exe`, or `.\play.ps1` to see the log.

**Runtime tests.** The patches are tested by SaturnRecomp's own test suite:

```powershell
cd external\SaturnRecomp
powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\run_all.ps1
```

**Changing the runtime.** Edit inside `external\SaturnRecomp`, then save your change as a new
patch with `git -C external/SaturnRecomp diff > patches\000N-name.patch`. Do not commit inside
the submodule. `setup.ps1` resets the submodule and re-applies all patches in name order on
every run.

### Runtime fixes (patches/)

Generic hardware-behaviour fixes, with the Ymir emulator as reference. Each one has tests and
has been proposed upstream in
[sonsegajp/SaturnRecomp#2](https://github.com/sonsegajp/SaturnRecomp/pull/2):

- `0001-netlink-probe.patch`: an opt-in NetLink modem register stub (`SATURN_NETLINK=1`).
  It is off by default, which matches a console without the modem, as the game expects.
- `0002-sh2-frt-compare-and-wdt-interrupts.patch`: FRT compare and overflow interrupts on
  the master SH-2, and the SH7604 watchdog timer. The game times its modem probe with the
  FRT and services file loading from the watchdog interrupt. Without these it froze on the
  SEGA screen.
- `0003-cdblock-current-directory.patch`: the CD block "Change Directory" command, so file
  IDs are relative to the current directory (the game enters `/BOMSS`).
- `0004-vdp1-gpu-draw-cost.patch`: correct VDP1 draw timing in the Vulkan renderer. Before
  this fix, the "sprite draw end" interrupt fired too early and the screen stayed black
  after the intro.

### Publishing a release (maintainers)

1. Bump `VERSION` (e.g. `1.0.1`) and add `docs/release-notes/v1.0.1.md`. Commit both to `main`.
2. On GitHub: **Actions → Release → Run workflow**, version `1.0.1`:
   - with **publish_release off**, it builds, audits and tests, and keeps the ZIP as a
     workflow artifact (a dry run);
   - with **publish_release on**, it also creates the tag `v1.0.1` and the release with
     `saturnbomberman-1.0.1-windows-x64.zip` and `SHA256SUMS`.
3. Update the download link at the top of this README.

The workflow builds for any x86-64-v2 CPU (`setup.ps1 -Portable`). It packages with
`tools\package_release.ps1`, which refuses BIOS, disc, `.toml`, `.ini` and log files. You can
run the same two commands locally to get the ZIP in `dist\`.

### Status and limits

- The game code runs on SaturnRecomp's SH-2 interpreter, not as statically recompiled C.
- Verified: licence screen, intro, title screen, menus and the start of Normal Game, on both
  renderers. Full stages, Battle mode and audio have only been lightly tested.
- One controller only (player 1): no second player, no multitap.
- Backup RAM is not saved to disk, so in-game saves may be lost when you close the game.

### Project layout

```text
setup.ps1                 prepares everything (patches, build, disc, game.toml)
play.ps1                  runs the game with the log in the console
diagnose.ps1              headless run that records where the game stops
tools/mkgame.c            writes game\game.toml from your disc
tools/launcher.c          source of SaturnBomberman.exe
tools/package_release.ps1 builds the release ZIP (dist\)
patches/                  runtime fixes applied on top of SaturnRecomp
external/SaturnRecomp     the runtime (git submodule, pinned commit)
.github/workflows/        release workflow
```

### Credits and license

This repository is MIT-licensed ([LICENSE](LICENSE)). SaturnRecomp belongs to its authors and
is only referenced as a submodule. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for
what the release package contains. Saturn Bomberman, Sega Saturn and related marks belong to
their owners.

---

## Português

### Destaques

- Dá boot pela BIOS real do Saturn, passa da tela de licença da SEGA, mostra a abertura em
  vídeo, chega à tela de título e aos menus e inicia o Normal Game (modo história).
- Renderer Vulkan por padrão e renderer por software como alternativa.
- Teclado e controle (estilo Xbox) no jogador 1. **F1** abre as configurações (tamanho da
  janela, tela cheia, resolução interna, filtro, volume).
- Pacote pronto para Windows: baixe, coloque sua BIOS e seu disco, rode um script e jogue.
  Não precisa de compilador.

### O que "recompilação" quer dizer aqui (leia primeiro)

Projetos como o Super Bomberman 5 Recompiled traduzem o código do jogo para C e compilam no
seu PC. **Este projeto ainda não faz isso**, porque a versão pública do SaturnRecomp não tem
tradutor de SH-2 para C. O que acontece de fato:

1. O `setup.ps1` lê o **seu** disco. Se for `.chd`, primeiro converte para `.cue` + `.bin`,
   porque o runtime não lê CHD. Depois escreve um arquivo pequeno de configuração,
   `game\game.toml`, que diz onde estão o disco e a BIOS e como o jogo dá boot.
2. O `SaturnBomberman.exe` abre o runtime do SaturnRecomp com esse arquivo. O runtime dá boot
   na sua BIOS e roda o jogo direto do disco num **interpretador** de SH-2 otimizado, junto
   com a emulação de vídeo (VDP1/VDP2), som (SCSP/68000) e CD.

Ou seja: a única coisa "gerada" é o `game\game.toml` (mais o disco convertido). Com a release
você não compila nada. Se compilar do código-fonte, o runtime é compilado uma vez e não
depende do jogo.

### O que você precisa

| Item | Detalhes |
| --- | --- |
| Windows 10 ou 11, 64 bits | Com placa de vídeo e driver compatíveis com **Vulkan** (praticamente qualquer GPU de 2016 em diante com driver atualizado). Sem Vulkan, use o renderer por software (veja Problemas comuns). |
| Sua BIOS do Saturn | O dump cru de uma BIOS do Sega Saturn, com exatamente **524.288 bytes (512 KiB)**. A americana (USA) é a preferida, porque o disco é a versão USA. Se veio em .zip, descompacte. |
| Seu disco Saturn Bomberman (USA) | Como arquivo **`.chd`** ou como o par **`.cue` + `.bin`**. O dump testado é `Saturn Bomberman (USA) (1S).chd` (produto MK-81070). |
| `chdman.exe` (só para `.chd`) | Vem com o **MAME**. Veja [Como obter o chdman](#como-obter-o-chdman). Não precisa se o disco já for `.cue` + `.bin`. |

### Instalar pela release (recomendado)

1. **Baixe** o `saturnbomberman-1.0.0-windows-x64.zip` da
   [última release](https://github.com/MauricioSuporte/Saturn-Bomberman-Recomp/releases/latest).
2. **Extraia o ZIP inteiro** numa pasta onde você possa gravar, por exemplo
   `C:\Jogos\SaturnBomberman`. Não rode de dentro do ZIP e evite `C:\Arquivos de Programas`.
   Aparece a pasta `saturnbomberman-1.0.0-windows-x64`, com o `SaturnBomberman.exe`, o
   `setup.ps1`, uma pasta `BIOS` e outros arquivos.
3. **Coloque a BIOS:** copie o arquivo de 512 KiB para a pasta `BIOS`. O nome não importa. Se
   houver várias, o script prefere a que tiver `USA`, `US` ou `NA` no nome.
4. **Coloque o disco:** copie o `.chd` para a pasta principal, ao lado do
   `SaturnBomberman.exe`. Para um dump `.cue` + `.bin`, veja o passo 6.
5. **Se o disco for `.chd`:** coloque o `chdman.exe` na mesma pasta principal (veja
   [Como obter o chdman](#como-obter-o-chdman)).
6. **Rode o setup.** Na pasta principal, clique na barra de endereço do Explorador de Arquivos,
   digite `powershell` e aperte Enter. Abre uma janela azul/preta já nessa pasta. Cole:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
   ```

   Para um dump `.cue` + `.bin`, aponte para o `.cue` (deixe o `.bin` ao lado dele):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -Disc "D:\Saturn\Saturn Bomberman (USA).cue"
   ```

   O script mostra cada etapa (`==> Disco do jogo`, `==> BIOS`,
   `==> Gerando game\game.toml...`) e termina com **`Tudo pronto.`**. A conversão do CHD leva
   um ou dois minutos e cria a pasta `disc` (cerca de 550 MB). A pasta `game` guarda o
   `game.toml`, suas configurações, o log e a memória do console emulado.
7. **Jogue:** dê dois cliques no `SaturnBomberman.exe`. No primeiro boot a BIOS mostra as
   próprias telas de **idioma e relógio**. Escolha o idioma, acerte o relógio e saia. Isso
   acontece uma vez só, como num console de verdade. Depois vêm o logo da SEGA, a abertura e
   a tela de título. Aperte **Enter** (Start).

Parâmetros opcionais do `setup.ps1`: `-Disc <arquivo.chd|arquivo.cue>`, `-Bios <arquivo>`,
`-Chdman <caminho\chdman.exe>`, `-Force` (converte o CHD de novo).

### Como obter o chdman

O `chdman` é a ferramenta de CHD do MAME. Ele **não** vem aqui (o MAME é um projeto GPL à parte).

1. Abra <https://www.mamedev.org/release.html> e baixe o pacote Windows 64 bits
   (`mame0XXXb_x64.exe`). Ele é um arquivo autoextraível.
2. Extraia numa pasta **fora** deste projeto, por exemplo `C:\Ferramentas\mame`.
3. Copie só o `chdman.exe` de lá para a pasta principal do jogo, ou rode o setup com
   `-Chdman "C:\Ferramentas\mame\chdman.exe"`. Ter o `chdman` no `PATH` também funciona.

O chdman só é usado uma vez. Depois da conversão, o `disc\SaturnBomberman.cue` é reaproveitado.

### Controles

| Saturn | Teclado | Controle (estilo Xbox) |
| --- | --- | --- |
| Direcional | Setas ou W/A/S/D | D-pad ou analógico esquerdo |
| Start | Enter | Start |
| A / B / C | Z / X / C | A / B / RB |
| X / Y / Z | R / T / Y | X / Y / LB |
| L / R | Q / E | LT / RT |

**F1** configurações · **F2** liga/desliga interpolação de quadros · **Espaço** pausa · **Esc** sai.

### Problemas comuns

- **O `setup.ps1` não roda / "a execução de scripts foi desabilitada":** use exatamente o
  comando acima (`powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1`). Ele só
  libera a política para aquela execução.
- **`ERRO: Nenhum .chd encontrado`:** o `.chd` não está na pasta principal. Mova para lá ou
  use `-Disc`.
- **`chdman.exe nao encontrado`:** veja [Como obter o chdman](#como-obter-o-chdman).
- **`Nenhum arquivo de exatamente 524288 bytes`:** a BIOS está faltando, ainda compactada ou
  não é um dump cru.
- **Cai no menu/CD player da BIOS:** o dump do disco pode estar incompleto
  (`chdman verify -i arquivo.chd`) ou a BIOS não serve. Tente outra com `-Bios`.
- **Janela preta ou erro de Vulkan:** atualize o driver de vídeo. Para usar o renderer por
  software, abra o PowerShell na pasta e rode:

  ```powershell
  $env:SATURN_RENDERER='software'; .\play.ps1
  ```

- **Ver o log:** o `.\play.ps1` roda o jogo com o log no console. Com dois cliques no exe, o
  log vai para `game\runtime.log`. O `.\diagnose.ps1` roda sem janela e grava
  `game\diagnose.log`.

Ao relatar um problema, envie só o `game\runtime.log` (ou o `diagnose.log`) e onde parou.
Nunca envie a BIOS, o disco, o `game\wram_high.bin` ou arquivos extraídos.

### Compilar do código-fonte (passo a passo)

Só é preciso se você quiser mexer no código. Para jogar, use a release.

1. **Instale o Git:** <https://git-scm.com/download/win> (opções padrão).
2. **Instale o MSYS2:** <https://www.msys2.org>. Mantenha a pasta padrão `C:\msys64`.
3. **Instale o compilador e as bibliotecas:** abra o **"MSYS2 MINGW64"** pelo menu Iniciar (o
   ícone azul) e rode:

   ```sh
   pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-SDL2 mingw-w64-x86_64-mpg123 mingw-w64-x86_64-vulkan-headers mingw-w64-x86_64-vulkan-loader mingw-w64-x86_64-shaderc
   ```

   Responda `Y` quando perguntar.
4. **Clone com os submódulos** (no PowerShell ou no Git Bash):

   ```powershell
   git clone --recursive https://github.com/MauricioSuporte/Saturn-Bomberman-Recomp.git
   cd Saturn-Bomberman-Recomp
   ```

   Se clonou sem `--recursive`, rode `git submodule update --init --recursive`.
5. **Coloque seus arquivos** na pasta do repositório (todos são ignorados pelo git e nunca
   vão para commit):

   ```text
   Saturn-Bomberman-Recomp\
     Saturn Bomberman (USA) (1S).chd      <- seu disco (ou use -Disc com um .cue)
     chdman.exe                           <- só para .chd (ou use -Chdman)
     BIOS\<sua BIOS de 512 KiB>
   ```

6. **Rode o setup:**

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
   ```

   O que ele faz, em ordem:
   1. Volta o `external\SaturnRecomp` ao commit fixado e aplica os `patches\*.patch` (as
      correções de runtime que o jogo precisa, veja abaixo).
   2. Acha o MSYS2 (`C:\msys64\mingw64\bin`, ou `-MingwBin <caminho>`).
   3. Compila a CLI do SaturnRecomp (`saturnrecomp.exe`), o `build\mkgame.exe` (gerador do
      `game.toml`), o `SaturnBomberman.exe` (launcher), o runtime (`saturnwin.exe` com janela,
      `saturnboot.exe` sem janela) e os shaders Vulkan. Copia as DLLs necessárias para junto
      do runtime. A primeira compilação leva alguns minutos.
   4. Converte o disco, acha a BIOS, escreve o `game\game.toml` e valida.

   Rode de novo com `-SkipBuild` para só regenerar o `game.toml`. Use `-BuildOnly` para
   compilar sem disco nem BIOS.
7. **Jogue:** `.\SaturnBomberman.exe`, ou `.\play.ps1` para ver o log.

**Testes do runtime.** Os patches são testados pela própria suíte de testes do SaturnRecomp:

```powershell
cd external\SaturnRecomp
powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\run_all.ps1
```

**Mudando o runtime.** Edite dentro de `external\SaturnRecomp` e salve a mudança como um patch
novo com `git -C external/SaturnRecomp diff > patches\000N-nome.patch`. Não faça commit
dentro do submódulo. A cada execução, o `setup.ps1` restaura o submódulo e reaplica todos os
patches em ordem de nome.

### Correções no runtime (patches/)

São correções genéricas de comportamento do hardware, com o emulador Ymir como referência.
Todas têm testes e foram propostas no projeto original em
[sonsegajp/SaturnRecomp#2](https://github.com/sonsegajp/SaturnRecomp/pull/2):

- `0001-netlink-probe.patch`: stub opcional dos registradores do modem NetLink
  (`SATURN_NETLINK=1`). Fica desligado por padrão: o jogo espera um console sem modem.
- `0002-sh2-frt-compare-and-wdt-interrupts.patch`: interrupções de comparação e overflow do
  FRT no SH-2 mestre, mais o watchdog (WDT) do SH7604. O jogo usa o FRT para medir o tempo
  da procura pelo modem e a interrupção do watchdog para carregar arquivos. Sem isso, ele
  congelava na tela da SEGA.
- `0003-cdblock-current-directory.patch`: o comando "Change Directory" do CD block, para que
  os IDs de arquivo sejam relativos ao diretório atual (o jogo entra em `/BOMSS`).
- `0004-vdp1-gpu-draw-cost.patch`: tempo de desenho do VDP1 corrigido no renderer Vulkan.
  Antes, o aviso de "desenho terminado" chegava cedo demais e a tela ficava preta depois da
  abertura.

### Publicar uma release (mantenedores)

1. Aumente o `VERSION` (por exemplo `1.0.1`) e crie o `docs/release-notes/v1.0.1.md`. Faça
   commit dos dois na `main`.
2. No GitHub: **Actions → Release → Run workflow**, versão `1.0.1`:
   - com **publish_release desligado**, ele compila, audita e testa, e deixa o ZIP como
     artefato do workflow (um ensaio);
   - com **publish_release ligado**, também cria a tag `v1.0.1` e a release com o
     `saturnbomberman-1.0.1-windows-x64.zip` e o `SHA256SUMS`.
3. Atualize o link de download no topo deste README.

O workflow compila para qualquer CPU x86-64-v2 (`setup.ps1 -Portable`). O empacotamento é
feito pelo `tools\package_release.ps1`, que recusa BIOS, disco, `.toml`, `.ini` e logs. Dá
para rodar os mesmos dois comandos localmente e obter o ZIP em `dist\`.

### Estado e limites

- O código do jogo roda no interpretador de SH-2 do SaturnRecomp, não como C recompilado.
- Verificado: tela de licença, abertura, título, menus e início do Normal Game, nos dois
  renderers. Fases inteiras, o modo Battle e o áudio só foram testados por alto.
- Um controle só (jogador 1): sem segundo jogador e sem multitap.
- A memória de backup não é gravada em disco, então o save do jogo pode se perder ao fechar.

### Créditos e licença

Este repositório está sob a licença MIT ([LICENSE](LICENSE)). O SaturnRecomp pertence aos seus
autores e é apenas referenciado como submódulo. Veja o [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
para saber o que o pacote de release contém. Saturn Bomberman, Sega Saturn e marcas
relacionadas pertencem aos seus donos.
