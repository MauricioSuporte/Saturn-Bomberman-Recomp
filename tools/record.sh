#!/bin/sh
# Builds up the block database (work/saturn_bomberman/blocks.txt): the list of the game's code that
# `make` translates to C++. The game is run without a window several times at once, each run going
# through the menus by an input movie (games/saturn_bomberman/movies) and then playing with random
# input; every block of code a run reaches is written down, and the lists are merged.
#
#   tools/record.sh [FRAMES] [SEED]      (from the repository's top, in an MSYS2 MINGW64 shell)
#
# FRAMES: how long each run is (default 12000, a little over three minutes of play).
# SEED:   another number gives other random input, so other code is reached (default 1).
#
# Run `make` afterwards to translate what was found. Code that no run reached still works: it is run
# by the interpreter, and `--stats` counts it. Playing with `./play.ps1 -Record` adds what you reach.
set -eu
GAME=${GAME:-saturn_bomberman}
SR=${SR:-satrecomp}
FRAMES=${1:-12000}
SEED=${2:-1}
if [ "$SR" = satrecomp ]; then B=build/$GAME; else B=build/$GAME-dev; fi
PORT=$B/$GAME
WORK=work/$GAME
DISC=${DISC:-$(ls disc/*.cue disc/*.iso 2>/dev/null | head -1)}
[ -n "$DISC" ] || { echo "record: no disc image in disc/ (run setup.ps1, or set DISC)" >&2; exit 1; }
[ -x "$PORT" ] || [ -x "$PORT.exe" ] || { echo "record: no $PORT (run make first)" >&2; exit 1; }
mkdir -p "$WORK/record"
rm -f "$WORK"/record/*.txt "$WORK"/record/*.bin

# name, movie, the frame random input starts at
run() {
    name=$1
    "$PORT" --disc "$DISC" --backup "$WORK/record/$name.bin" --headless --frames "$FRAMES" --stats \
        --movie "games/$GAME/movies/$2.txt" ${3:+--auto "$((SEED * 100 + $4)):$3"} \
        --record-blocks "$WORK/record/$name.txt" > "$WORK/record/$name.log" 2>&1 &
}
run normal menu_normal 3700 1
run battle menu_battle 2500 2
run master menu_master 2800 3
run option menu_option 2400 4
run twoplayers menu_2p 2700 5
run attract no_input
wait

status=0
for log in "$WORK"/record/*.log; do
    name=$(basename "$log" .log)
    if grep -q "block runs" "$log"; then
        echo "$name: $(grep 'block runs' "$log" | sed 's/^satrecomp: //')"
    else
        echo "record: the '$name' run failed (see $log)" >&2
        status=1
    fi
done
[ -f "$WORK/blocks.txt" ] || : > "$WORK/blocks.txt"
"$SR/tools/merge_blocks.sh" "$WORK/blocks.txt" "$WORK/blocks.txt" "$WORK"/record/*.txt
exit $status
