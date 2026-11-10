# How it works

Project Creeper runs the game's own PowerPC and Cell SPU code natively. Nothing interprets a CPU at play time, and no
game logic is rewritten: the code that runs is the code on the disc, translated to C++ ahead of time.

## The three layers

**Lifted game code.** `tools/lift.sh` reads your decrypted `EBOOT.elf` and emits one C++ function per PowerPC
function, plus C for the SPU blocks it can find in the executable and in the firmware modules. clang compiles that
into the program. A lifted function reads like the original instruction stream, one C statement per instruction,
which is why a fault in it can be read against the disc's own disassembly.

**The runtime.** Around the lifted code sits a runtime that provides what the game expects from the console's system
software: LV2 syscalls (threads, memory, synchronisation, files, SPU groups), the RSX graphics command stream replayed
on Vulkan, and the system libraries the title imports.

**The port's own code** (`port/creeper/`) sits on top: boot, platform glue, and the corrections this title needs that
are not general enough to belong in the runtime.

## The hard part: SPU code the game uploads at run time

Most PS3 ports spend their time here, and this one is no exception. The SPU programs that run on the Cell's
synergistic units are not all present in the executable as a fixed list. The game **uploads** SPU code while it runs:
the SPURS job system, and world generation in particular, push blocks the lift has never seen.

A block that was never compiled falls back to the interpreter, which is correct but slow, and the share of interpreted
instructions is therefore the number that matters. It is measured, not estimated:

- `GOWA_SPU_JOBS=1` prints the interpreted share;
- `GOWA_SPU_RECORD=<file>` records every unknown block once, keyed by hash of its contents;
- `GOWA_SPU_STRICT=1` fails a run at the first interpreted block;
- `GOWA_SPU_SHADOW=1` runs a compiled block against the interpreter on a copy of the state and reports a divergence.

The loop (`tools/converge.sh`): run with recording on, compile what was captured, rebuild, repeat until a round adds
nothing. It is run across a matrix of scenarios, not one: creative and survival worlds, several seeds, loading a save,
and time playing rather than only booting.

**Measured result:** during world generation the interpreted share went **65.01% → 0.00%**, over about a thousand
distinct blocks the table had never seen. `docs/dev/0002` has the numbers and the loop.

Two traps are recorded there as well, both learned the hard way: a table keyed only by address loses the variants of
the same address with different contents, and a manifest can contain PPU code mistaken for SPU, which has to be
dropped by rejecting wholly illegal entries rather than by a majority heuristic that throws away real code.

## SPURS

The title creates a SPURS kernel group (`MinecraftCellSpursKernelGroup`, five SPUs) and then uses SPURS tasksets,
job chains and event flags. SPURS runs on host threads. The subtlety worth knowing: for a SPURS event flag the
**information is in the structure in memory**, and the event only wakes a waiter — so "the event was empty" is normal
and says nothing, while the structure says everything. Dump the structure, and count entries *and* exits of every
wait before concluding a wakeup was lost.

## Data

The game reads its own files through its own file system code, which the runtime serves through a VFS. All guest
paths go through it; a decoder or a loader opening a guest path on the host is a defect, not a shortcut.
