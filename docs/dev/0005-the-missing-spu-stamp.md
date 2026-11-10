# 0005 -- A fresh build could not configure: the missing SPU stamp

**Date:** 2026-11-10
**Status:** fixed, verified by a clean run of the documented sequence

## What was measured

A clean build from the documented path, with only the player's own files and no captures:

```
tools/setup-vfs.sh -> ok
tools/lift.sh      -> PPU 22,685 functions; "lift: no SPU captures yet, starting with an empty table"
tools/build.sh     -> CMake Error at CMakeLists.txt:65: No generated SPU natives in work/lift/spu
```

So the port could not be built at all on a machine that had not already run a convergence round. The lift
itself was fine: `recomp/spu/codegen.py` wrote `spu_registry.cpp` with an empty block table, which is the
correct output for "no blocks yet". What was missing was the stamp that says so.

## Why the runtime asks for it

`PS3BASE_SPU_NATIVE_GEN_DIR` is globbed for `*.cpp` by subdirectory, and the runtime's CMake refuses to
configure unless `generated.txt` exists in it. That is deliberate: a glob over a folder that was never
generated becomes a library with no sources and a link error hundreds of lines later. `tools/setup.py`
writes the stamp as `sha256 path` lines after it generates the natives, and its own error message names
the way out: create the stamp with an empty file to say "there are none".

## What was refuted

The first hypothesis was that `lift.sh` should skip `recomp/spu/codegen.py` when there are no captures.
Refuted by reading the generator: it writes the registry unconditionally and an empty table is a supported
output (`compiled_blocks()` returns `nullptr, 0`). Skipping it would have removed a file the build needs.

The second was that the build should pass an empty `PS3BASE_SPU_NATIVE_GEN_DIR`. Refuted by the CMake
source: the directory is globbed per subdirectory and `jwhole` is globbed separately, so the check cannot
be bypassed by pointing it somewhere empty without also breaking the runtime's own SPU sources.

## The fix

`tools/lift.sh` writes `work/lift/spu/generated.txt` itself, in `tools/setup.py`'s format (`sha256`, then
the relative path, sorted), covering what the generator just wrote. It does this whether or not there are
captures, because the stamp describes the directory rather than the captures.

## What proves it

The same clean sequence now configures and builds. The interpreted-share measurements in
[0002](0002-spu-convergence.md) are unaffected: the stamp changes nothing about what is compiled, only
whether CMake is told the truth about an empty table.
