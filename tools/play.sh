#!/bin/sh
# play.sh -- run the game in a window.
#
# Deliberately NOT wrapped in a timeout: a run you watch must not be closed by
# its own launcher. Kill it by process group when you are done.
#
# It also fixes the two things a launcher cannot guess: the folder it is
# started from (the runtime writes gowa.log and shader_cache/ there) and the
# settings folder, so a setting changed in one place is the same in every other.
set -eu
. "$(dirname "$0")/env.sh"

[ -x "$BUILD/ps3base" ] || die "no binary at $BUILD/ps3base; run tools/build.sh first"
[ -d "$VFS/dev_bdvd" ] || die "no VFS at $VFS; run tools/setup-vfs.sh first"

cd "$ROOT"

# The lifted table names the game's images as Game/EBOOT.elf and Game/fw/...,
# relative to the folder the runtime is started from. In a checkout Game/ is
# the player's own folder and already there; in an installed release it is
# somewhere else, so it is linked in rather than copied. A Game/ that exists is
# never touched.
if [ ! -e "$ROOT/Game" ]; then
    if [ -d "$GAME" ]; then
        ln -s "$GAME" "$ROOT/Game"
    else
        die "no Game/ beside the tools and none at $GAME; run tools/setup-vfs.sh first"
    fi
fi

export PS3BASE_DISC_DIR="$VFS/dev_bdvd"
export PS3BASE_VFS_DIR="$VFS"
export GOWA_USER_DIR="$WORK/user"
export PS3BASE_LOG=${PS3BASE_LOG:-info}
exec "$BUILD/ps3base" --no-launcher "$@"
