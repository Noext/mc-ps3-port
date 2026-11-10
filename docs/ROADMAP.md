# Roadmap

Ordered by what unblocks the most, not by what is easiest.

## Now

1. **The server crash.** `f_0064c044` ends long sessions. The deliverable is the leaf: which writer corrupts the node's
   `+28` field, its arguments and its value. A forced value is a debt, not a fix.
2. **Loading an existing world.** The `-2` after `THUMB`, and the content type that should be announced instead of
   `NORMALFILE`.
3. **Audio**, confirmed on a machine with a sound device.

## Next

4. **The hotbar.** A slot binding, if the game has one, or a documented statement that it does not.
5. **A real display.** Measure the frame rate without Xvfb's software presentation.
6. **Long-session stability.** An hour of play across several scenarios, reproduced on a clean build.

## Later

7. **Split the corrections out of the runtime.** This port was built against the runtime directly, so the fixes it
   needs live there rather than as numbered patches in `port/patches/`. That makes it hard to see what belongs to
   this title and hard to reuse a fix elsewhere. The deliverable: the same behaviour, expressed as patches a clean
   runtime checkout can apply.
8. **Windows.** The runtime builds there; this port has not been tried on it.
9. **Performance.** Profile on an idle machine, on real presentation, and name the bottlenecks instead of guessing.

## Not a goal

Rewriting the game's logic, and online play.
