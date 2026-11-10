# Getting your files

**You need your own copy of the game.** Project Creeper ships no game material of any kind, ever: no executable, no
data, no asset, no key, no firmware. What follows says what you must have and how the scripts check it. It does not
explain how to obtain or decrypt anything; that is yours to do, with your own tools, from your own disc.

## What you need

| What | Which | Checked by |
|---|---|---|
| `EBOOT.elf` | a plain ELF from your own **BLES01976** disc (Europe, v01.02) | the lift asserts `ELF64 MSB PowerPC64` and reads the text range; `tools/check-tree.sh` refuses any `.elf` inside the repository |
| firmware modules | the decrypted modules of your own PS3 dump, at least `liblv2`, `libsysmodule`, `libsre`, `libgcm_sys`, `libfs`, `libvdec`, `libsmvd2` and `libspurs_jq` | `tools/lift.sh` refuses to start without them and names the ones missing |

Put them in `Game/`, which is git-ignored:

```
Game/
  EBOOT.elf
  fw/
    liblv2.elf  libsysmodule.elf  libsre.elf  libgcm_sys.elf
    libfs.elf   libvdec.elf      libsmvd2.elf  libspurs_jq.elf
```

## Version matters

The port targets **v01.02**. A different revision of the executable is a different binary with different function
addresses, and the recovered addresses in this tree would not describe it. The lift prints the ELF's SHA-256; if it
does not match the value in [dev/0001](dev/0001-the-title.md), the port will not behave as documented.

## What you do not need to supply

The SPU blocks. The game's own recorded captures are not shipped here (they are the game's code); `tools/lift.sh`
compiles what is in the executable and the firmware, and `tools/converge.sh` discovers the rest by running your copy.
The first build will therefore interpret more SPU code than later ones — that is expected, and it is the convergence
loop's job.
