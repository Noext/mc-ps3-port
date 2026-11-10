# 0002 -- Compiling the SPU code the game uploads

**Date:** 2026-11-10
**Status:** measured, 65% -> 0%

## The problem

The SPU programs this game runs are not a fixed list. SPURS jobs and world generation **upload** blocks while the game
runs, and a block that has never been compiled falls back to the interpreter. It is correct and it is slow, and the
share of interpreted instructions is therefore the number that matters.

## The measurement

Same binary, same VFS, seeded world creation, `GOWA_SPU_JOBS=1` printing the interpreted share and
`GOWA_SPU_LOUD_INTERP=1` naming each unknown block by hash.

**Before compiling the generation blocks:**

```
interpreted 65.01% of 670283600
interpreted 68.47% of 731355309
distinct never-compiled blocks: 1129
```

**After:**

```
interpreted 0.00% of 333052819
interpreted 0.00% of 373294753
distinct never-compiled blocks: 1
```

So the question "does the interpreted share rise during generation" had the answer **yes**, and that was the reason a
world took minutes: the table had been built from what the executable and the firmware contain, and generation
uploads about a thousand blocks no manifest had ever named.

## The loop

1. Run with `GOWA_SPU_RECORD=<file>`: every unknown block is saved once, keyed by the hash of `{lsa, n, words}`.
   A full seeded generation captured **3502 blocks** — the recorder counts distinct hashes, and generation re-uploads
   shared code paths many times.
2. `spu_blocks.py make` turns the captures into a manifest of `lsa words source offset` lines, located against the
   player's own executable and firmware. A block that cannot be located falls back to an arithmetic `seq` line; one
   that is neither is reported and skipped.
3. `recomp/spu/codegen.py` compiles the manifest into the AOT table.
4. Rebuild and repeat until a round captures nothing new.

Measuring only at boot hides all of this: the interpreted share at boot was 0%, and 65% during generation. **Measure
where the game actually works.**

## Three traps that cost rounds

**A table keyed only by address loses variants.** The same LSA can carry different code in different sessions. The
table must accept several blocks at the same address, distinguished by their contents.

**A manifest can contain PPU code mistaken for SPU.** It has to be dropped by rejecting entries that are entirely
illegal, **not** by a "majority of words are legal" heuristic: that heuristic throws away real code.

**A new block that differs from an old one by a few words is usually the same code relocated**, or data inside a
block. Compare before assuming a new job.

## Proving correctness, not just coverage

Coverage is not correctness. `GOWA_SPU_SHADOW=1` runs a compiled block against the interpreter on a copy of the state
— registers, local store, channels, MFC commands — and reports any divergence. A second check: load the same save in
both modes and the result must match; that comparison must **fail** when the inputs differ, or it proves nothing.

`GOWA_SPU_STRICT=1` fails a run at the first interpreted block, which is what turns "mostly compiled" into a gate.
The end-of-run verdict always prints the number of interpreted blocks.
