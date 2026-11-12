# Third-party notices

The Windows release package contains binaries built from the projects below.
The source of this repository is under the MIT license in [LICENSE](LICENSE).

| Component | Where in the package | Upstream | License |
| --- | --- | --- | --- |
| SaturnRecomp runtime (`saturnwin.exe`, `saturnboot.exe`, `saturnrecomp.exe`, shaders), with the patches in `patches/` | `external/SaturnRecomp/` | <https://github.com/sonsegajp/SaturnRecomp> | No license file published upstream; all rights remain with its authors. Built from the pinned commit of the `external/SaturnRecomp` submodule. |
| sh2-recomp-core (SH-2 decoder, compiled into the runtime) | inside the runtime executables | submodule of SaturnRecomp | see upstream |
| Nuklear (launcher/overlay UI, compiled into the runtime) | inside `saturnwin.exe` | <https://github.com/Immediate-Mode-UI/Nuklear> | MIT or Public Domain (Unlicense) |
| SDL2 | `external/SaturnRecomp/runner/SDL2.dll` | <https://www.libsdl.org> | zlib |
| Vulkan loader | `external/SaturnRecomp/runner/vulkan-1.dll` | <https://github.com/KhronosGroup/Vulkan-Loader> | Apache-2.0 |
| mpg123 | `external/SaturnRecomp/runner/libmpg123-0.dll` | <https://www.mpg123.de> | LGPL-2.1 (dynamically linked, replaceable) |
| MinGW-w64 runtime | linked into the executables | <https://www.mingw-w64.org> | MinGW-w64 runtime licenses (ZPL/MIT-style) |

Not included and never distributed: the Sega Saturn BIOS, the game disc, anything
extracted from it, and `chdman` (part of [MAME](https://www.mamedev.org), GPL-2.0+),
which you download yourself if your disc is a `.chd`.

Saturn Bomberman is a trademark of its respective owners (Hudson Soft / Konami).
Sega Saturn is a trademark of SEGA. This project is not affiliated with either.
