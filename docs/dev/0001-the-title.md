# 0001 -- The title, and its numbers

**Date:** 2026-11-10
**Status:** verified against the disc

Numbers recovered from the binary, kept here so a build can be checked against them.

## Identity

| Field | Value | Source |
|---|---|---|
| TITLE_ID | **BLES01976** | `PARAM.SFO` |
| TITLE | Minecraft: PlayStation®3 Edition | `PARAM.SFO` |
| VERSION | 01.02 | `PARAM.SFO` |
| CAT | DG (disc) | `PARAM.SFO` |
| PS3_SYSTEM_VER | 04.5500 | `PARAM.SFO` |
| NP_COMMUNICATION_ID | NPWR05636_00 | `PARAM.SFO` |

## Executable

| Field | Value |
|---|---|
| `mc.elf` size | 12,452,792 |
| ELF class | ELF64, MSB, PowerPC64 |
| entry point | `0xbbe520` |
| TOC | `0xbd7998` |
| text start | `0x00010200` |
| program headers | 8 |
| SHA-256 of the ELF | `bc352e0a954b4b59767ff7643dd9edf68e15239cb45557c05729ed23ec6b27f4` |

## Translation

| | |
|---|---|
| PPU functions | 20,682 for the title (22,685 with the firmware images) |
| imports | **345**, all resolved |
| exports | 0 |
| SPU translation units | 170, about 18 MB of generated C++ |

## Import table, the largest modules

| Module | Imports | Note |
|---|---|---|
| `sceNp` | 40 | must answer "not connected" coherently |
| `sceNpCommerce2` | 32 | store paths, never taken |
| `cellSysutil` | 28 | menus, system dialogs |
| `sceNp2` | 28 | |
| `cellSpurs` | 23 | the SPU job system; this is the load-bearing one |
| `cellGcmSys` | 21 | |
| `sysPrxForUser` | 19 | |
| `cellSysutilAvc2` | 17 | |
| `cellSpursJq` | 15 | job queues |
| `cellHttp` | 12 | |
| `sceNpTrophy` | 11 | |
| `sys_fs` | 11 | |
| `cellPngDec` / `cellPngEnc` / `cellJpgDec` / `cellJpgEnc` | 7 each | the image decoders were the source of the unreadable-text defect |
| `cellAudio` | 6 | |
| `cellRtc` | 6 | |
| `cellNetCtl` | 6 | |

345 imports across 40+ modules is the shape of this title's difficulty: the surface is wide, and the networking
modules alone account for more than a hundred entries that must answer coherently while remaining offline.

## SPU

The title creates a SPURS kernel group named `MinecraftCellSpursKernelGroup` with **5 SPUs**, and registers 12 SPURS
entities during startup. This is the opposite situation to a title with no SPU code at all: here the SPU work is the
main cost and the main source of speed.
