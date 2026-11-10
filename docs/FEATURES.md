# Features

What works, measured. Anything unmeasured is marked so.

## Works

| | |
|---|---|
| Boot | the title loads, starts its SPURS kernel group (`MinecraftCellSpursKernelGroup`, 5 SPUs) and presents frames |
| Text rendering | legible menu text |
| Menus | main menu, the "Online ID currently not online" dialogue, Start Game, and the full world-creation form are reachable and driven by real input |
| World creation | a new world is created, saves are written to the VFS, proven **10 out of 10** |
| SPU compilation | the interpreted share during world generation went 65.01% → 0.00% after compiling the recorded blocks |
| Movement | works |
| Breaking a block | works; the HUD confirms "R2 Mine" |
| Inventory | works: player model, armour slots, the 9x3 grid |
| Placing a block | works **in Survival** (see the note below) |
| Input | keyboard drives the pad through the runtime's latch; the game reads it through `cellPadGetData` |

## Partial

| | |
|---|---|
| Frame rate | around 24 to 30 fps in game, **under Xvfb** (software presentation). Not measured on a real display |
| Loading a saved world | returns `-2` from the file callback after `METADATA` and `THUMB`, before `GAMEDATA` |
| Audio | imported and initialised; not verified by ear in this environment |
| Hotbar | the D-pad does not change the selected slot in this build, and there is no keyboard binding for it. Not blocking: a pickup lands in slot 1, which is already selected |

## Placing a block works in Survival, not in Creative

Measured, and not an input problem. In **Creative** the broken block vanishes and drops nothing, so the hotbar stays
empty and there is nothing to place. In **Survival** the broken block becomes a pickup that fills slot 1 and placing
then works. This is the game's behaviour, not the port's.

## Not reached

| | |
|---|---|
| Long sessions | a known server crash (`f_0064c044`) can end a long session; see [KNOWN_ISSUES.md](KNOWN_ISSUES.md) |
| Online play | out of scope. The port answers "not connected" and must never leave the game on an online code path |
