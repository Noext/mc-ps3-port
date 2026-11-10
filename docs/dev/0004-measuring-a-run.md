# 0004 -- How to judge a run

**Date:** 2026-11-10
**Status:** rules that cost days

## The mechanical verdict

A run is **alive** when the process reaches its budget with the flip counter rising, and **crashed** when it ends
early on a signal. Never grep for the word "crash".

This is not pedantry. A single handled page fault once printed sixteen lines of stack dump, which a `grep 'crash:'`
counted as sixteen crashes, and two days went into "the game crashes 16/16" while it was running fine.

```
grep -ac 'crash: signal' log     # events, one per line
grep -a  'rsx: flip' log | tail -1
```

Some `crash: signal` lines are **repaired** faults that the runtime handles and continues from. The reliable signals of
a dead run are the exit code and a flip count that stops rising.

## Never judge from a capped log

Three separate conclusions in this port were wrong because the log was capped: `sys_fs_read` looked like a hang,
`cellSpursEventFlagSet` looked like it was never called, and the SPURS loop looked like it stopped, each because a
counter stopped printing at 30 or 60 lines. **"The log ends here" is not "the title stopped".**

## Never count presses as a contract

An input script with a fixed press count desynchronises. The new-world form here wraps, and the Seed field takes
keyboard focus and swallows the navigation keys, so a count that worked on one run fails on the next. Drive by reading
the screen, and screenshot between presses.

## Never let two runs share a display

Two instances on one X display steal each other's focus and pad input, and a capture can photograph the other run's
game. One display per run, derived from the VFS path; kill by process group (`kill -9 -- -$PID`), never by image name.

## Launch detached when the run is being watched

A process started from a tool call dies when the call returns. `nohup setsid ... & disown` survives. And a run
someone is playing must not be wrapped in `timeout`: that closes their window, and the log will say
`gpu: window closed, exiting` at exactly the budget, which looks like a crash and is not.
