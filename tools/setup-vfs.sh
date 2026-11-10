#!/bin/sh
# setup-vfs.sh -- build the folder the game runs from, out of the player's own files.
#
# The title reads its own files through its own file system code; the runtime
# serves them through this VFS. Nothing is extracted or converted here.
#
# If the player's folder also holds their disc tree (PS3_GAME/), it is linked in
# beside the executable, because the runtime mounts /dev_bdvd at this folder and
# the title looks for PS3_GAME there. A folder that has only EBOOT.elf and fw/
# works as before; add your disc tree to it to give the title its data files.
set -eu
. "$(dirname "$0")/env.sh"

note "checking your files in $GAME"
require_file "$GAME/EBOOT.elf"
[ -d "$GAME/fw" ] || die "missing $GAME/fw (the decrypted firmware modules) -- see docs/GETTING-FILES.md"

note "building $VFS"
# Only the folders this script owns are rebuilt. The save data under dev_hdd0
# is the player's and survives, so re-running setup -- which a launcher does
# whenever the player changes their copy -- never deletes a world.
mkdir -p "$VFS/dev_bdvd" "$VFS/dev_hdd0/home/00000001/savedata" "$VFS/dev_flash/sys/external"
rm -rf "$VFS/dev_bdvd"
mkdir -p "$VFS/dev_bdvd"
cp "$GAME/EBOOT.elf" "$VFS/dev_bdvd/EBOOT.elf"
# The disc tree, when the player keeps it beside their files: linked, never
# copied, so a 4 GB disc costs no disk and no time.
if [ -d "$GAME/PS3_GAME" ]; then
    ln -s "$GAME/PS3_GAME" "$VFS/dev_bdvd/PS3_GAME"
    if [ -f "$GAME/PS3_DISC.SFB" ]; then
        ln -s "$GAME/PS3_DISC.SFB" "$VFS/dev_bdvd/PS3_DISC.SFB"
    fi
    echo "setup-vfs: linked your disc tree from $GAME/PS3_GAME"
fi
# The firmware modules are served from where the title expects them.
for m in "$GAME"/fw/*.elf; do
    [ -e "$m" ] || continue
    cp "$m" "$VFS/dev_flash/sys/external/$(basename "$m" .elf).sprx"
done
echo "setup-vfs: $VFS ready"
