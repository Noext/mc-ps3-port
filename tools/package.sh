#!/bin/sh
# package.sh -- build the release zip a player installs.
#
#   tools/package.sh [--version X.Y.Z] [--out DIR]
#
# The zip carries the port's own files only -- never a game file -- plus
# recomplauncher.json at its top, next to the tools, which is where
# RecompLauncher looks for it. The player's own copy of the game is turned
# into a build by tools/install.sh, which the launcher runs as its setup step.
set -eu
. "$(dirname "$0")/env.sh"

VERSION=$(cat "$ROOT/VERSION")
OUT="$ROOT/dist"
while [ $# -gt 0 ]; do
    case "$1" in
        --version) [ $# -ge 2 ] || { echo "error: --version needs a value" >&2; exit 2; }; VERSION=$2; shift 2 ;;
        --out) [ $# -ge 2 ] || { echo "error: --out needs a folder" >&2; exit 2; }; OUT=$2; shift 2 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "error: unknown option $1 (try --help)" >&2; exit 2 ;;
    esac
done

[ -f "$ROOT/recomplauncher.json" ] || die "no recomplauncher.json at the top of the tree"
# The launcher reads this file before it runs anything, so a broken one is a
# silent "the recomp did not set itself up". Checked here, not in a release.
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$ROOT/recomplauncher.json" \
    || die "recomplauncher.json is not valid JSON"

"$ROOT/tools/check-tree.sh"

NAME="ProjectCreeper-v$VERSION-Linux-x64"
STAGE="$OUT/$NAME"
rm -rf "$STAGE"
mkdir -p "$STAGE"

# What a release is: the port's own code, tools and docs. Everything under work/
# is made on the player's machine from their own files and stays out.
for item in recomplauncher.json VERSION LICENSE NOTICE.md README.md CHANGELOG.md CITATION.cff \
            docs port tools .recomp.json; do
    [ -e "$ROOT/$item" ] || die "missing $item"
    cp -a "$ROOT/$item" "$STAGE/"
done

# The runtime the port is built against, when it is checked out where env.sh
# looks for it. Without it a released zip can be installed but not built, and
# the setup step stops with the message tools/install.sh gives about PS3BASE.
# Only the runtime's own sources travel: its bin/ and fw/ are the game, and
# every build output under it is made again on the player's machine.
if [ -d "$PS3BASE" ]; then
    RUNTIME="$STAGE/third_party/ps3base"
    mkdir -p "$RUNTIME"
    for item in CMakeLists.txt LICENSE README.md THIRD_PARTY_NOTICES.txt \
                runtime recomp ref tools third_party; do
        [ -e "$PS3BASE/$item" ] || continue
        cp -a "$PS3BASE/$item" "$RUNTIME/"
    done
    # Its own caches are not source, and a stale one in a release is a support call.
    find "$RUNTIME" -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null || true
else
    echo "package: note: no runtime at $PS3BASE, so this zip will not build on its own" >&2
fi

mkdir -p "$OUT"
rm -f "$OUT/$NAME.zip"
( cd "$STAGE" && zip -qr "$OUT/$NAME.zip" . )
rm -rf "$STAGE"
echo "package: $OUT/$NAME.zip"
