# Building

## Requirements

- Linux x64
- clang and clang++ (gcc is not supported: the runtime's SPU float helpers use a macro named `slow` that gcc
  mishandles)
- CMake 3.20 or newer, Ninja
- Python 3.10 or newer
- SDL3 and the Vulkan headers (SDK)
- a CPU with AVX2 (`x86-64-v3`) and a Vulkan-capable GPU
- disk: the lift and the build together take a few gigabytes, and the SPU compilation is the bulk of the build time

## One command

```sh
tools/install.sh
```

It asks where your files are, checks them, lifts the game, builds, and remembers the paths.

Two options are for a launcher or a script rather than a person:

```sh
tools/install.sh --game /path/to/your/files   # take the game files from there, not Game/
tools/install.sh --prepare --game /path/to/your/files
```

`--prepare` is the same work with no questions and no window: it prints `progress 0.4 Text` lines as it
goes and exits non-zero if anything failed, which is the shape a launcher's setup step needs. Without the
option nothing changes: the same script, the same prompts, the same output.

## Step by step

```sh
tools/setup-vfs.sh    # the folder the game runs from, in work/vfs
tools/lift.sh         # translates your EBOOT.elf and firmware into work/lift
tools/build.sh        # work/build/ps3base
tools/play.sh         # plays in a window
```

## Compiling the SPU code the game uploads

The first build compiles only what is visible in the executable and the firmware. The game uploads more while it
runs, and those blocks fall back to the interpreter until they are compiled. To close the gap:

```sh
tools/converge.sh     # run, record, compile, rebuild, repeat until a round adds nothing
```

It needs a working build and a playable scenario. See [HOW-IT-WORKS.md](HOW-IT-WORKS.md) for what it measures.

## Never trust an incremental tree

A `build/` carried through many edits can produce a binary that segfaults while the same commit in a clean tree runs
fine. If a crash is new and unexplained, `rm -rf work/build` and rebuild before investigating. The tell is a binary
much smaller than it should be.

## Making a release

```sh
tools/package.sh --version 1.2.0
```

Writes `dist/ProjectCreeper-v1.2.0-Linux-x64.zip`: the port's own files, with `recomplauncher.json` at
the top of the zip next to the tools, which is where RecompLauncher looks for it. It runs
`tools/check-tree.sh` first, so a release cannot carry a game file. The zip holds no game material: the
player's own copy is turned into a build by `tools/install.sh` on their machine.

## Parallelism

Cap builds at `-j 8`. On a shared machine higher values make it unusable for everything else.
