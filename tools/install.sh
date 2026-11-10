#!/bin/sh
# install.sh -- the one command: check your files, set up, lift, build.
#
#   tools/install.sh                     your files from Game/
#   tools/install.sh --game DIR          your files from DIR instead
#   tools/install.sh --prepare           no questions, no window: the setup
#                                        step a launcher runs before the first
#                                        start. Prints "progress 0.4 Text"
#                                        lines and exits non-zero on failure.
set -eu

GAME_ARG=""
PREPARE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --game) [ $# -ge 2 ] || { echo "error: --game needs a folder" >&2; exit 2; }; GAME_ARG=$2; shift 2 ;;
        --prepare) PREPARE=1; shift ;;
        -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "error: unknown option $1 (try --help)" >&2; exit 2 ;;
    esac
done

# env.sh keeps GAME when it is already in the environment, so setting it here
# is all it takes for every script below to use the player's own folder.
if [ -n "$GAME_ARG" ]; then
    GAME=$GAME_ARG
    export GAME
fi
. "$(dirname "$0")/env.sh"

# The launcher shows the text after the number under its setup step; without
# --prepare the same lines are the ordinary stage notes.
step() {
    if [ "$PREPARE" = 1 ]; then
        echo "progress $1 $2"
    else
        note "$2"
    fi
}

echo "Project Creeper -- one-command build"
echo
if [ ! -f "$GAME/EBOOT.elf" ]; then
    echo "Put your own files in $GAME first:"
    echo "  EBOOT.elf and the fw/ folder of decrypted firmware modules"
    echo "  see docs/GETTING-FILES.md"
    exit 2
fi
[ -d "$PS3BASE" ] || die "no runtime at $PS3BASE; set PS3BASE to your ps3base checkout"

step 0.05 "Checking your files"
"$ROOT/tools/setup-vfs.sh"

step 0.30 "Translating and compiling the game's own code"
"$ROOT/tools/lift.sh"
"$ROOT/tools/build.sh"

step 1.0 "Done"
echo
echo "done. tools/play.sh plays."
