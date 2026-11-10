#!/bin/sh
# lift.sh -- translate the player's EBOOT.elf and firmware modules into C++.
#
# Two manifests decide what is compiled, and confusing them is the classic
# mistake on this project:
#
#   - the IMAGE manifest names the guest images to lift. Its first entry is the
#     game; the rest are firmware modules.
#   - the SPU BLOCK manifest lists SPU blocks by their offset IN A NAMED IMAGE.
#     Every line is a fact about one specific binary. Feeding one title's
#     manifest to another does not fail politely: it either reads out of range
#     or produces blocks that are wrong.
#
# The block manifest is NOT shipped, because it describes the game's own code
# layout and is derived from captures of it. This script generates it from your
# own files once you have captures; until then it starts empty and the game
# interprets the SPU code it has not been given. tools/converge.sh closes that
# gap round by round.
set -eu
. "$(dirname "$0")/env.sh"

require_file "$GAME/EBOOT.elf"
[ -d "$GAME/fw" ] || die "missing $GAME/fw -- see docs/GETTING-FILES.md"
[ -d "$PS3BASE" ] || die "no runtime at $PS3BASE; set PS3BASE to your ps3base checkout"

note "lifting into $LIFT"
rm -rf "$LIFT"
mkdir -p "$LIFT/blocks"

python3 - "$PS3BASE" "$GAME" "$LIFT" "$ROOT" <<'PY'
import glob, json, os, subprocess, sys

pkg, game, lift, root = sys.argv[1:5]

# The image manifest the lifter reads, with absolute paths so it does not
# depend on where it is written.
specs = json.load(open(os.path.join(root, "port", "manifests", "images-creeper.json")))
resolved = []
for spec in specs:
    spec = dict(spec)
    spec["elf"] = os.path.join(game, spec["elf"])
    resolved.append(spec)
manifest = os.path.join(lift, "images.json")
json.dump(resolved, open(manifest, "w"), indent=1)

# 1. PPU: every function in the game and in the firmware modules.
subprocess.run([sys.executable, os.path.join(pkg, "recomp", "ppu", "codegen.py"),
                manifest, os.path.join(pkg, "ref", "nid_db.json"),
                os.path.join(lift, "ppu")], check=True)

# 2. SPU: whatever captures the player has, compiled into a table.
captures = sorted(glob.glob(os.path.join(root, "work", "spu-captures", "round_*.bin")))
blocks_bin = os.path.join(lift, "blocks", "run_manifest.bin")
blocks_manifest = os.path.join(lift, "blocks", "manifest.txt")
if captures:
    # spu_blocks.py make turns capture hashes into a manifest of
    # (lsa, words, source, offset) lines, located against the player's own
    # executable and firmware.
    open(blocks_manifest, "w").close()
    subprocess.run([sys.executable, os.path.join(pkg, "tools", "spu_blocks.py"), "make",
                    "--elf", os.path.join(game, "EBOOT.elf"),
                    "--fw", os.path.join(game, "fw"),
                    "--blocks", os.path.join(root, "work", "spu-captures"),
                    "--manifest", blocks_manifest], check=True)
    subprocess.run([sys.executable, os.path.join(pkg, "tools", "spu_blocks.py"), "build",
                    "--elf", os.path.join(game, "EBOOT.elf"),
                    "--fw", os.path.join(game, "fw"),
                    "--manifest", blocks_manifest,
                    "--out", blocks_bin], check=True)
else:
    print("lift: no SPU captures yet, starting with an empty table")
    os.makedirs(os.path.dirname(blocks_bin), exist_ok=True)
    open(blocks_bin, "wb").close()

subprocess.run([sys.executable, os.path.join(pkg, "recomp", "spu", "codegen.py"),
                os.path.join(lift, "spu"), blocks_bin], check=True)

# The runtime's CMake refuses to configure without this stamp, and it is right
# to: a glob over an empty folder would otherwise become a link error hundreds
# of lines later. The stamp says "these are all the native SPU sources there
# are", so an empty table is a stated fact rather than a missing file. Format
# and content are tools/setup.py's (sha256, then the path).
import hashlib
gen = os.path.join(lift, "spu")
rows = []
for base, _, names in os.walk(gen):
    for n in names:
        if n.endswith((".cpp", ".h", ".inc")):
            p = os.path.join(base, n)
            with open(p, "rb") as f:
                rows.append((hashlib.sha256(f.read()).hexdigest(),
                             os.path.relpath(p, gen).replace(os.sep, "/")))
rows.sort()
with open(os.path.join(gen, "generated.txt"), "w", newline="\n") as f:
    f.writelines("%s %s\n" % (h, p) for h, p in rows)
print("lift: %d native SPU source(s) stamped" % len(rows))
print("lift: done")
PY

echo "lift: PPU in $LIFT/ppu, SPU in $LIFT/spu"
echo "lift: the game uploads more SPU code at run time; run tools/converge.sh to compile it"
