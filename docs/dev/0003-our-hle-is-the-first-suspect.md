# 0003 -- Our HLE is the first suspect

**Date:** 2026-11-10
**Status:** measured

## The defect

Menu text rendered as noise. The glyph atlas reached the GPU looking like static.

## What was tried first, and was wrong

Ten rounds went to the GPU: the shaders, the texture UVs, the swizzle, the component remap, the vertex format. Every
one of them was correct. The bug was ten steps upstream, in **our** `cellPngDec`:

- `outputColorSpace` was read at the wrong offset, so the requested colour space was indeterminate;
- one image state was shared between all sub-handles instead of one per handle;
- `CellPngDecInfo` was written at wrong offsets;
- a sub-handle was dereferenced instead of being read by value.

## What settled it

An external oracle, byte for byte. The decoder's output was compared against a standard image library on the same
input, not against what the screen showed. A wrong pixel is a symptom; a wrong byte is a cause.

## The rule

**A defect that shows on screen is not evidence that the renderer is at fault.** Before touching the GPU, check the
producer of the data with an oracle that does not involve the GPU at all.

The same shape recurs across this port's history: callbacks delivered with the wrong argument order (`cellSysutil`
must be called `(fn, event, param, arg)`), constants taken from the wrong table
(`CELL_NET_CTL_STATE_IPObtained` is 3), a save-list enumeration that ignored the disk. All of them looked like game
behaviour and none of them were.
