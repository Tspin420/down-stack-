# Soft-drop comparison — Downstack 0.5

Checked 12 November 2026. This audit distinguishes published behavior, numerical settings, and parameters that still need direct measurement. It does not claim that every falling-block games has identical timing.

A multiplier and a fixed rate are different. At 1 cell/second normal gravity, 20× means 20 cells/second; at 2 cells/second it means 40. TETR.IO's SDF values should not be relabeled as fixed cells/second, and 20× should not be confused with instant 20G gravity.

## Downstack's resulting behavior

The default remains 20× current gravity. The slider explicitly selects fixed minimum rates of 5, 10, 15, 20, 30, 45, 60, 90 or 120 cells/second; faster normal gravity is never slowed. These are Downstack options, not a claim of exact comparison-game or TETR.IO parity. Instant is a separate opt-in toggle. Hard drop remains a separate action that locks immediately.

In 0.4, every release/repress restarted the first-cell bonus. With simulated intermittent controller input, a piece set to 20 cells/second traversed 20 rows in 400 ms without locking, versus 9 with a steady hold. In 0.5 the same intermittent input advances 8 rows; the steady hold still advances 9. A separate cadence timer survives brief releases, so controller chatter cannot multiply the selected rate. Idle and grounded time cannot accumulate a burst. Invalid negative or nonnumeric rates now fall back to the default rather than enabling Instant.

This reproduces and fixes a matching software failure. It does not prove that the user's physical controller produced exactly that input pattern. Physical controller and Windows testing remain necessary.
