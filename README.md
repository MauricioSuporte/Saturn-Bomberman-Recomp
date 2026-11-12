# Saturn Bomberman Recomp

Projeto para rodar **Saturn Bomberman (USA)** no PC com Windows usando o
[SaturnRecomp](https://github.com/sonsegajp/SaturnRecomp), a partir do **seu próprio**
disco e da **sua própria** BIOS.

Este repositório não contém BIOS, imagem de disco, arquivos extraídos nem código do jogo —
só scripts, um gerador de configuração e um executável de entrada. Não é afiliado à Sega
nem à Hudson Soft.

## Estado atual (leia antes)

- **Ainda não é uma recompilação estática de verdade.** O SaturnRecomp, na versão pública
  fixada aqui, executa o código SH-2 do jogo por um **interpretador** otimizado; o emissor
  AOT (SH-2 → C) ainda não existe no projeto. Na prática o resultado é um `SaturnBomberman.exe`
  que sobe o runtime do SaturnRecomp, dá boot pela BIOS real e roda o jogo direto do disco.
  Quando o emissor AOT for publicado, a estrutura daqui (submódulo + `game.toml`) é o ponto
  de partida para usá-lo.
- **Não foi testado com o jogo.** Tudo foi montado sem acesso ao disco e à BIOS. Foi
  verificado: a conversão CHD → CUE/BIN e a geração/validação do `game.toml` com um disco
  sintético, e a compilação para Windows de `tools/mkgame.c`, `tools/launcher.c`, da CLI e
  do runtime sem janela. Os scripts PowerShell **não** foram executados. Saturn Bomberman
  não aparece na lista de jogos testados do SaturnRecomp, então pode travar, ter falhas
  gráficas ou de áudio.
- **Só um controle.** O runtime hoje emula um único controle digital na porta 1: sem
  segundo jogador e sem multitap. Dá para jogar o modo história e batalha contra a CPU.
- **Saves:** o runtime não grava a memória de backup do Saturn em disco, então o progresso
  salvo no jogo provavelmente se perde ao fechar.

## O que você precisa

1. Windows 64 bits com placa/driver compatível com Vulkan.
2. [MSYS2](https://www.msys2.org). No terminal **MSYS2 MINGW64**:

   ```sh
   pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-SDL2 mingw-w64-x86_64-mpg123 mingw-w64-x86_64-vulkan-headers mingw-w64-x86_64-vulkan-loader mingw-w64-x86_64-shaderc
   ```

3. `chdman.exe` — o SaturnRecomp não lê CHD, então o disco é convertido para CUE/BIN.
   Ele vem no pacote do [MAME](https://www.mamedev.org/release.html); copie `chdman.exe`
   para a raiz deste repositório.
4. Seus arquivos, na pasta do repositório (todos ignorados pelo git):

   ```text
   Saturn-Bomberman-Recomp\
     Saturn Bomberman (USA) (1S).chd
     BIOS\<dump cru de 512 KiB da BIOS do Saturn>
     chdman.exe
   ```

## Instalação

No PowerShell, na raiz do repositório:

```powershell
git submodule update --init --recursive
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

O `setup.ps1`:

1. baixa o submódulo `external/SaturnRecomp`;
2. converte o `.chd` para `disc\SaturnBomberman.cue` + `.bin` (preserva as faixas de áudio);
3. compila o runtime, os shaders Vulkan e o `SaturnBomberman.exe`;
4. lê o cabeçalho IP.BIN e o diretório do disco e gera `game\game.toml`, depois valida.

Parâmetros úteis: `-Disc` (um `.chd` ou `.cue` em outro lugar), `-Bios` (escolher o
arquivo da BIOS), `-Chdman`, `-MingwBin` (MSYS2 fora de `C:\msys64`), `-SkipBuild`, `-Force`.

## Jogar

Dê dois cliques em `SaturnBomberman.exe` (log em `game\runtime.log`), ou, para ver o log
no console:

```powershell
.\play.ps1
```

Na primeira vez a BIOS pode pedir idioma e relógio; conclua uma vez.

| Saturn | Teclado | Controle (estilo Xbox) |
| --- | --- | --- |
| Direcional | Setas ou W/A/S/D | D-pad ou analógico esquerdo |
| Start | Enter | Start |
| A / B / C | Z / X / C | A / B / RB |
| X / Y / Z | R / T / Y | X / Y / LB |
| L / R | Q / E | LT / RT |

**F1** abre as configurações (resolução, tela cheia, resolução interna, filtro, volume),
**F2** liga/desliga interpolação de quadros, **Espaço** pausa, **Esc** sai.

## Se algo der errado

- **Cai no menu/CD player da BIOS:** o dump do disco pode estar incompleto
  (`chdman verify -i arquivo.chd`) ou a BIOS não é adequada; tente outra com `-Bios`.
- **Janela não abre / erro de Vulkan:** atualize o driver de vídeo. Para diagnóstico,
  `$env:SATURN_RENDERER='software'` antes de `.\play.ps1` usa o compositor por software.
- **Sem música:** confira se `disc\SaturnBomberman.cue` lista as faixas `AUDIO`.
- Para comparar com o boot sem BIOS (diagnóstico): `.\play.ps1 nobios`.

Ao relatar um problema, envie só o `game\runtime.log` e o ponto onde parou — nunca a BIOS,
o disco ou arquivos extraídos.

## Estrutura

```text
setup.ps1            prepara tudo (conversão, build, game.toml)
play.ps1             roda o jogo com o log no console
tools/mkgame.c       gera game\game.toml lendo o seu disco
tools/launcher.c     fonte do SaturnBomberman.exe
external/SaturnRecomp  runtime (submódulo, commit fixado)
```

## Licença

O conteúdo deste repositório está sob a licença do arquivo `LICENSE`. O SaturnRecomp
pertence aos seus autores e é apenas referenciado como submódulo (o código dele não é
copiado para cá). Saturn Bomberman, Sega Saturn e marcas relacionadas pertencem
aos seus respectivos donos.

## Correções no runtime

O `setup.ps1` aplica os patches de `patches/` sobre o SaturnRecomp fixado, antes de compilar:

- `0001-netlink-probe.patch`: o Saturn Bomberman procura o modem NetLink logo depois da tela
  de licença da Sega e travava ali. O patch emula os registradores que essa verificação usa,
  com o mesmo comportamento do emulador Ymir.
