# Changelog

All notable changes to this port are recorded here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- The port: boot, the lifted PPU and SPU translation of BLES01976 v01.02, and the HLE modules this title needs.
- RecompLauncher support: `recomplauncher.json` (setup from the player's own folder, the runtime's settings on the
  game's page, saves and logs named) and `tools/package.sh`, which ships it at the top of every release zip.
- `tools/install.sh --game <folder>` and `--prepare`, the windowless setup step a launcher runs. Without them the
  script behaves exactly as before.
- `tools/converge.sh`, the loop that compiles the SPU code the game uploads at run time, with `SPU_STRICT` and
  `SPU_SHADOW` as its gates.
- Documentation: how it works, how to build, how to supply your own files, known issues, roadmap, and engineering
  notes on the title's numbers, the SPU convergence, the "our HLE is the first suspect" rule, and how to judge a run.

### Known at this version
- World creation proven 10/10; movement, mining, the inventory and block placement in Survival all work.
- The interpreted share of SPU instructions went from 65.01% to 0.00% during world generation.
- The server faults on long sessions (`f_0064c044`); the writer that corrupts the node's `+28` field is unidentified.
- Loading an existing world returns `-2` after `THUMB`.
- Audio is initialised but unverified by ear.
