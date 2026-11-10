#!/bin/sh
# setup-vfs.sh -- build the folder the game runs from, out of the player's own files.
#
# The title reads its own files through its own file system code; the runtime
# serves them through this VFS. Nothing is extracted or converted here.
set -eu
. "$(dirname "$0")/env.sh"

note "checking your files in $GAME"
require_file "$GAME/EBOOT.elf"
[ -d "$GAME/fw" ] || die "missing $GAME/fw (the decrypted firmware modules) -- see docs/GETTING-FILES.md"

note "building $VFS"
rm -rf "$VFS"
mkdir -p "$VFS/dev_bdvd" "$VFS/dev_hdd0/home/00000001/savedata" "$VFS/dev_flash/sys/external"
cp "$GAME/EBOOT.elf" "$VFS/dev_bdvd/EBOOT.elf"
# The firmware modules are served from where the title expects them.
for m in "$GAME"/fw/*.elf; do
    [ -e "$m" ] || continue
    cp "$m" "$VFS/dev_flash/sys/external/$(basename "$m" .elf).sprx"
done
echo "setup-vfs: $VFS ready"
