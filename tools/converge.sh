#!/bin/sh
# converge.sh -- compile the SPU code the game uploads at run time.
#
# The game pushes SPU blocks the lift has never seen (SPURS jobs, and world
# generation in particular). Each one costs interpreter time until it is
# compiled. This loop closes the gap:
#
#   run with recording on -> compile what was captured -> rebuild -> repeat
#
# It stops when a round captures nothing new. The captured blocks are the game's
# own code: they live under work/ and are git-ignored by rule.
set -eu
. "$(dirname "$0")/env.sh"

[ -x "$BUILD/ps3base" ] || die "no binary at $BUILD/ps3base; run tools/build.sh first"
[ -d "$VFS/dev_bdvd" ] || die "no VFS at $VFS; run tools/setup-vfs.sh first"

CAPTURES="$WORK/spu-captures"
mkdir -p "$CAPTURES"
ROUND=${ROUND:-1}
MAX_ROUNDS=${MAX_ROUNDS:-6}

while [ "$ROUND" -le "$MAX_ROUNDS" ]; do
    CAP="$CAPTURES/round_$ROUND.bin"
    note "round $ROUND: recording to $CAP"
    rm -f "$CAP"
    # A bounded run: this one is measured, not watched.
    PS3BASE_DISC_DIR="$VFS/dev_bdvd" GOWA_SPU_RECORD="$CAP" \
        timeout "${SECONDS_BUDGET:-600}" "$BUILD/ps3base" --no-launcher >"$WORK/round_$ROUND.log" 2>&1 || true

    if [ ! -s "$CAP" ]; then
        echo "converge: round $ROUND captured nothing -- converged after $((ROUND - 1)) round(s)"
        exit 0
    fi
    size=$(wc -c <"$CAP")
    echo "converge: round $ROUND captured $size bytes"

    note "round $ROUND: compiling"
    # Re-lift: lift.sh turns every capture collected so far into a block
    # manifest located against your own files, then rebuilds the SPU table.
    "$ROOT/tools/lift.sh"
    "$ROOT/tools/build.sh"
    ROUND=$((ROUND + 1))
done

echo "converge: stopped after MAX_ROUNDS=$MAX_ROUNDS; run again, or check work/round_*.log" >&2
exit 1
