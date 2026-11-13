# Saturn Bomberman Recomp

An unofficial, noncommercial **static recompilation** of **Saturn Bomberman (USA)** for Windows.
The game's SH-2 code is translated to C++ on your PC, from **your own** disc, with the
[satrecomp](https://github.com/tmcleroy/satrecomp) toolkit, and compiled into a native program.
No BIOS is needed.

[English](#english) · [Português](#português) · [Third-party notices](THIRD_PARTY_NOTICES.md)

> **Bring your own disc.** This repository contains no disc image, no game code, no translated
> game code and no BIOS: only the toolkit, scripts, a few input movies and the game's
> configuration. Everything made from your disc stays in `work/` and `build/` on your PC, which
> git ignores. Not affiliated with SEGA, Hudson Soft or Konami.

---

## English

### What this is

Version 1 of this project ran the game on an SH-2 **interpreter** behind a real Saturn BIOS.
Version 2 is a real recompilation:

1. The game is first built with no translated code and run without a window, driven by input
   movies and random input. Every block of SH-2 code it reaches is written to a **block
   database** (`work/saturn_bomberman/blocks.txt`).
2. `satrecomp/tools/recomp.py` translates those blocks to C++, and the game is built again.
3. Code that no run reached still works: it falls back to the built-in interpreter, and
   `--stats` counts how often. The aim is to bring that count to zero; playing with
   `.\play.ps1 -Record` adds what you reach to the database.

The BIOS is replaced by native code (no BIOS image), and the machine around the CPU (video,
sound, CD drive, controllers) is satrecomp's own.

What is and is not translated:

- **SH-2 (the game's program):** translated to C++, block by block, by a tool. It is generated
  code, not a hand-written port.
- **The interpreter stays in the program** as the fallback for code not recorded yet, and for
  `make check`, which compares it with the translated code. With a complete block database it
  is never used, but it is not removed.
- **68000 (the sound driver):** interpreted. The toolkit translates it only in its reference
  build, which this project does not use.

### State

Tested with `Saturn Bomberman (USA) (1S)`, product **MK-81070**, version **V1.003**:

- Boots, plays the opening movies, reaches the title and the menus.
- Normal Game (first stage), Battle Game, Master Game, Options and two players start and play,
  with sound and CD music.
- The recording runs (six runs, menus plus random input) end with **100.00% of block runs
  translated, 0 interpreted**. A longer check of 30,000 frames per run ended with 0 to 60
  interpreted block runs out of about 1.2 billion.
- The interpreter and the translated code give the same machine state frame by frame for 6000
  frames (`make check`), and so do the software and the GPU renderers.

Known limits:

- The SEGA licence screen is empty (the ROM routines that draw it do nothing).
- Later stages have not been played through. Code first reached there is interpreted until it
  is recorded; if the game stops there, please open an issue.
- The game's error path (`SYS_EXECDMP`) is not implemented: an error it would report stops it.
- Only this disc version was tested.

### What you need

| Item | Details |
| --- | --- |
| Windows 10 or 11, 64-bit | |
| [MSYS2](https://www.msys2.org) | Installed in `C:\msys64` (or pass `-Msys`). `setup.ps1` installs the packages it needs with `pacman`: gcc, cmake, ninja, make, python, SDL3, zlib, diffutils, git. |
| Your Saturn Bomberman (USA) disc | As a `.chd`, or as `.cue` + `.bin`. |
| `chdman.exe` (only for `.chd`) | Comes with [MAME](https://www.mamedev.org/release.html). Copy it to the repository root or pass `-Chdman`. |
| Internet, once | The launcher's build downloads Dear ImGui. The game builds without it. |

### Build

Put your `.chd` in the repository root (or pass `-Disc path\to\game.cue`) and run, in PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

It converts the disc, builds the game with the interpreter alone, records the block database
(two rounds of six runs without a window), translates and builds again, and builds the launcher.
Expect 20 to 40 minutes the first time, most of it compiling the generated C++.

| Parameter | Meaning |
| --- | --- |
| `-Disc` | A `.chd` or `.cue` (default: the `.chd` in the repository root) |
| `-Chdman` | Path to `chdman.exe` |
| `-Msys` | MSYS2 folder (default `C:\msys64`) |
| `-SkipRecord` | Build with the block database as it is |
| `-Frames` | Length of each recording run |
| `-Force` | Convert the CHD again |

### Play

```powershell
.\play.ps1              # the game (or double-click SaturnBomberman.cmd)
.\play.ps1 -Launcher    # disc, display, controllers, then Play
.\play.ps1 -Stats       # prints translated / interpreted counts at exit
.\play.ps1 -Record      # adds the code you reach to the block database
```

After `-Record`, run `.\setup.ps1 -SkipRecord` to translate what was found.

Keyboard: arrows, **Enter** = Start, **Z / X / C** = A / B / C, **A / S / D** = X / Y / Z,
**Q / E** = L / R. **F1** or **Esc** opens the in-game menu, **F11** switches full screen.
Gamepads work too. Saves and settings are in `user\`.

### Layout

| Path | What |
| --- | --- |
| `Makefile`, `games/saturn_bomberman/` | The game's configuration and input movies |
| `satrecomp/` | A copy of the toolkit (its commit is in `satrecomp/COMMIT`), made by its `tools/sync-toolkit.sh` |
| `tools/record.sh` | The recording runs |
| `work/`, `build/`, `disc/`, `user/` | Generated on your PC, ignored by git |

For development against a toolkit checkout: `make SR=../satrecomp`, and
`make check FRAMES=6000 MOVIE=games/saturn_bomberman/movies/menu_normal.txt` (in an MSYS2 MINGW64 shell).

### Toolkit changes

Saturn Bomberman needed parts of the machine the toolkit did not have yet: the SH-2 watchdog
timer, the CD drive's file system and selector commands, play by track, and the drive's address
decoding. None is specific to the game. They are in the fork
[MauricioSuporte/satrecomp](https://github.com/MauricioSuporte/satrecomp) (branch
`saturn-bomberman`) and proposed upstream in
[tmcleroy/satrecomp#13](https://github.com/tmcleroy/satrecomp/pull/13).

### Releases

A release here is the source of this repository at a version: scripts, configuration and the
toolkit copy. It has no program to download, because a built program contains code translated
from the game. You build it on your PC with `setup.ps1`. To move a build to another PC of
yours, copy `build\saturn_bomberman\saturn_bomberman.exe`, `saturn_bomberman-launcher.exe` and
the `.dll` files beside them, plus your disc as `.cue` + `.bin`.

### Licence

The files of this repository outside `satrecomp/` are under the MIT licence ([LICENSE](LICENSE)).
`satrecomp/` is a copy of the toolkit under GPL-3.0-only, so a program built here is under the
GPL as well, and it also contains code translated from the game, which is not yours or mine to
distribute. This repository publishes no binaries.

---

## Português

### O que é

A versão 1 deste projeto rodava o jogo em um **interpretador** SH-2 atrás de uma BIOS real do
Saturn. A versão 2 é uma recompilação de verdade:

1. O jogo é compilado primeiro sem código traduzido e executado sem janela, guiado por filmes
   de entrada e entrada aleatória. Cada bloco de código SH-2 alcançado é anotado no **banco de
   blocos** (`work/saturn_bomberman/blocks.txt`).
2. `satrecomp/tools/recomp.py` traduz esses blocos para C++ e o jogo é compilado de novo.
3. Código que nenhuma execução alcançou continua funcionando: cai no interpretador embutido, e
   `--stats` conta quantas vezes. O objetivo é zerar essa contagem; jogar com
   `.\play.ps1 -Record` acrescenta ao banco o que você alcançar.

A BIOS é substituída por código nativo (nenhuma imagem de BIOS), e a máquina em volta da CPU
(vídeo, som, CD, controles) é a do próprio satrecomp.

O que é e o que não é traduzido:

- **SH-2 (o programa do jogo):** traduzido para C++, bloco a bloco, por uma ferramenta. É
  código gerado, não um port escrito à mão.
- **O interpretador continua dentro do programa** como reserva para código ainda não gravado,
  e para o `make check`, que o compara com o código traduzido. Com o banco de blocos completo
  ele nunca é usado, mas não é removido.
- **68000 (o driver de som):** interpretado. O toolkit só o traduz na sua compilação de
  referência, que este projeto não usa.

### Estado

Testado com `Saturn Bomberman (USA) (1S)`, produto **MK-81070**, versão **V1.003**:

- Inicia, toca os filmes de abertura, chega ao título e aos menus.
- Normal Game (primeira fase), Battle Game, Master Game, Options e dois jogadores iniciam e
  jogam, com som e música do CD.
- As execuções de gravação (seis, menus mais entrada aleatória) terminam com **100,00% das
  execuções de bloco traduzidas, 0 interpretadas**. Uma verificação mais longa, de 30.000
  quadros por execução, terminou com 0 a 60 blocos interpretados em cerca de 1,2 bilhão.
- O interpretador e o código traduzido dão o mesmo estado da máquina quadro a quadro por 6000
  quadros (`make check`), assim como os renderizadores por software e por GPU.

Limites conhecidos:

- A tela de licença da SEGA fica vazia (as rotinas da ROM que a desenham não fazem nada).
- As fases seguintes não foram jogadas até o fim. Código alcançado lá pela primeira vez é
  interpretado até ser gravado; se o jogo parar, abra uma issue.
- O caminho de erro do jogo (`SYS_EXECDMP`) não está implementado: um erro que ele reportaria
  encerra o jogo.
- Só esta versão do disco foi testada.

### O que você precisa

| Item | Detalhes |
| --- | --- |
| Windows 10 ou 11, 64 bits | |
| [MSYS2](https://www.msys2.org) | Instalado em `C:\msys64` (ou use `-Msys`). O `setup.ps1` instala com `pacman` o que precisa: gcc, cmake, ninja, make, python, SDL3, zlib, diffutils, git. |
| Seu disco do Saturn Bomberman (USA) | Em `.chd`, ou em `.cue` + `.bin`. |
| `chdman.exe` (só para `.chd`) | Vem com o [MAME](https://www.mamedev.org/release.html). Copie para a raiz do repositório ou use `-Chdman`. |
| Internet, uma vez | A compilação do launcher baixa o Dear ImGui. O jogo compila sem ele. |

### Compilar

Coloque o seu `.chd` na raiz do repositório (ou use `-Disc caminho\jogo.cue`) e rode no
PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

Ele converte o disco, compila o jogo só com o interpretador, grava o banco de blocos (duas
rodadas de seis execuções sem janela), traduz e compila de novo, e compila o launcher. Conte
com 20 a 40 minutos na primeira vez, quase tudo compilando o C++ gerado.

| Parâmetro | Significado |
| --- | --- |
| `-Disc` | Um `.chd` ou `.cue` (padrão: o `.chd` na raiz do repositório) |
| `-Chdman` | Caminho do `chdman.exe` |
| `-Msys` | Pasta do MSYS2 (padrão `C:\msys64`) |
| `-SkipRecord` | Compila com o banco de blocos como está |
| `-Frames` | Duração de cada execução de gravação |
| `-Force` | Converte o CHD de novo |

### Jogar

```powershell
.\play.ps1              # o jogo (ou dois cliques em SaturnBomberman.cmd)
.\play.ps1 -Launcher    # disco, vídeo, controles, depois Play
.\play.ps1 -Stats       # mostra ao sair quanto rodou traduzido / interpretado
.\play.ps1 -Record      # acrescenta ao banco de blocos o código que você alcançar
```

Depois de `-Record`, rode `.\setup.ps1 -SkipRecord` para traduzir o que foi encontrado.

Teclado: setas, **Enter** = Start, **Z / X / C** = A / B / C, **A / S / D** = X / Y / Z,
**Q / E** = L / R. **F1** ou **Esc** abre o menu do jogo, **F11** alterna a tela cheia.
Controles (gamepads) também funcionam. Saves e configurações ficam em `user\`.

### Organização

| Caminho | O que é |
| --- | --- |
| `Makefile`, `games/saturn_bomberman/` | A configuração do jogo e os filmes de entrada |
| `satrecomp/` | Uma cópia do toolkit (o commit está em `satrecomp/COMMIT`), feita pelo `tools/sync-toolkit.sh` dele |
| `tools/record.sh` | As execuções de gravação |
| `work/`, `build/`, `disc/`, `user/` | Gerados no seu PC, ignorados pelo git |

Para desenvolver contra um checkout do toolkit: `make SR=../satrecomp` e
`make check FRAMES=6000 MOVIE=games/saturn_bomberman/movies/menu_normal.txt` (em um shell MSYS2 MINGW64).

### Mudanças no toolkit

O Saturn Bomberman precisou de partes da máquina que o toolkit ainda não tinha: o watchdog
timer do SH-2, os comandos de sistema de arquivos e de seletor do drive de CD, tocar por faixa,
e a decodificação de endereços do drive. Nada é específico do jogo. Estão no fork
[MauricioSuporte/satrecomp](https://github.com/MauricioSuporte/satrecomp) (branch
`saturn-bomberman`) e propostas ao projeto original em
[tmcleroy/satrecomp#13](https://github.com/tmcleroy/satrecomp/pull/13).

### Releases

Uma release aqui é o código-fonte deste repositório em uma versão: scripts, configuração e a
cópia do toolkit. Não há programa para baixar, porque um programa compilado contém código
traduzido do jogo. Você compila no seu PC com o `setup.ps1`. Para levar uma compilação para
outro PC seu, copie `build\saturn_bomberman\saturn_bomberman.exe`,
`saturn_bomberman-launcher.exe` e os `.dll` ao lado deles, mais o seu disco em `.cue` + `.bin`.

### Licença

Os arquivos deste repositório fora de `satrecomp/` estão sob a licença MIT ([LICENSE](LICENSE)).
`satrecomp/` é uma cópia do toolkit sob GPL-3.0-only, então um programa compilado aqui também
fica sob a GPL, e ele contém código traduzido do jogo, que nem você nem eu podemos distribuir.
Este repositório não publica binários.
