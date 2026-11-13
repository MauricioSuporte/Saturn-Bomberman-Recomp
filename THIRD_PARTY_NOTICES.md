# Third-party notices

The files of this repository outside `satrecomp/` are under the MIT licence in [LICENSE](LICENSE).
This repository publishes no binaries; the table lists what a program built here contains or
loads.

| Component | Where | Upstream | Licence |
| --- | --- | --- | --- |
| satrecomp toolkit (translator, runtime, machine, launcher) | `satrecomp/`, a copy of the commit named in `satrecomp/COMMIT` | <https://github.com/tmcleroy/satrecomp>, with the changes of <https://github.com/MauricioSuporte/satrecomp> (branch `saturn-bomberman`) | GPL-3.0-only (`satrecomp/LICENSE`) |
| SDL3 | `SDL3.dll`, copied beside the programs by `setup.ps1` | <https://www.libsdl.org> | zlib |
| Dear ImGui (launcher) | downloaded by the launcher's build, compiled into it | <https://github.com/ocornut/imgui> | MIT |
| zlib | `zlib1.dll` | <https://zlib.net> | zlib |
| libiconv (needed by SDL3's MSYS2 build) | `libiconv-2.dll` | <https://www.gnu.org/software/libiconv/> | LGPL-2.1-or-later (dynamically linked, replaceable) |
| GCC and MinGW-w64 runtimes | `libstdc++-6.dll`, `libgcc_s_seh-1.dll`, `libwinpthread-1.dll` | <https://gcc.gnu.org>, <https://www.mingw-w64.org> | GPL-3.0 with the GCC Runtime Library Exception; MinGW-w64 runtime licences |

Other files the toolkit copy carries (fonts, for one) keep the notices found beside them in
`satrecomp/`.

Because the toolkit is under GPL-3.0-only, a program built from this repository is under the GPL
as a whole. It also contains code translated from your disc, which belongs to the game's owners:
build it for yourself and do not distribute it.

Not included and never distributed: the game disc, anything extracted or translated from it, a
Sega Saturn BIOS (none is needed), and `chdman` (part of [MAME](https://www.mamedev.org),
GPL-2.0+), which you download yourself if your disc is a `.chd`.

Saturn Bomberman is a trademark of its respective owners (Hudson Soft / Konami).
Sega Saturn is a trademark of SEGA. This project is not affiliated with either.
