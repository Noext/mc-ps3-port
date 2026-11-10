# Known issues

Measured problems, with what is known about each. Nothing here is a guess presented as a fact.

## The server faults on long sessions

`(4J) Server` crashes on long sessions, at `lr=0x64c0fc` inside `f_0064c044`. What is known: a linked-list walk
follows a field at `+28` of a node that has been corrupted, and the pointer is then read as if it were a node. What is
**not** known: which writer corrupts it. Two hypotheses have already been refuted by measurement — the write was not a
second writer, and the `lr` seen at the fault is a `lwmutex_lock` return rather than a store. Recorded honestly as
unresolved.

## Loading an existing world returns -2

The file callback reports `-2` after `METADATA` and `THUMB` and before `GAMEDATA`. `THUMB` is announced as
`NORMALFILE` where the reference implementation uses a content type. Creating a world is unaffected.

## The D-pad does not change the hotbar slot

Measured negative: Right x3 and Left x3 arrive at the pad (the bytes are there in the log) and the hotbar is identical
to the pixel. No keyboard binding exists for slot selection. Not blocking, because a pickup lands in slot 1.

## Frame rate measured only under Xvfb

Every figure in [FEATURES.md](FEATURES.md) was taken with software presentation. The rasterisation is on the GPU but
presentation goes through Xvfb, which costs frame time. A real-display measurement is missing.

## Text was once noise, and the cause was ours

Kept here because it is the shape of most long defects in a port like this: the glyph atlas reached the GPU as noise
because our `cellPngDec` read `outputColorSpace` at the wrong offset, shared one image state between sub-handles, and
wrote `CellPngDecInfo` at wrong offsets. Ten rounds were spent on the GPU, the shaders, the UVs and the swizzle before
anyone checked the decoder. The decoder was then tested byte-for-byte against an external image library. **Our own HLE
is the first suspect, not the last.**
