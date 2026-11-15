# Gravity and soft-drop reference — Downstack

Research checked 12 November 2026; current settings updated 14 November 2026. This document distinguishes Downstack’s numerical settings from behavior that still needs direct measurement. It does not claim that other falling-block games have identical timing.

## Downstack defaults — 14 November 2026

The default at slider **0** uses a soft-drop interval equal to the normal fall interval divided by 20. At Downstack’s starting and Sprint gravity, that means **20 cells/second**, or **50 ms per cell**; it scales with normal gravity in versus. The historical source for this choice is preserved in the development source record. No licensing certification or frame-perfect match to another game is claimed.

Normal gravity uses the level-based interval: `1000 × (0.8 − (L − 1) × 0.007)^(L − 1)` milliseconds per cell. Versus advances a level every ten cleared lines. The previous gentler curve and 40 ms minimum interval are removed. Since versus continues until top-out, Downstack holds the last documented level, **15**, from 140 cleared lines onward; that continuation is a Downstack policy. Sprint remains at starting gravity throughout.

The separate **Instant soft drop** toggle reaches the floor in one simulation tick while retaining lock delay. It is an additional option, not the default setting. At high gravity the default can also cross multiple cells per tick; fractional timing is retained. Finite custom settings cannot slow faster normal gravity.

All **1117 assertions** passed in Godot 4.6.3 on Linux. The 90-check gravity suite covers the complete curve, level boundaries, the versus cap, Sprint, actual falling distances, multiple-cell ticks, default and Instant behavior, release and lock delay. Existing input checks cover continued hold across pieces and slider-zero persistence. The public document does not fully specify first-cell/re-press cadence; Downstack retains its tested anti-burst input behavior. Protocol **8** prevents clients using the old gravity curve from joining the same room.

A multiplier and a fixed rate are different. At 1 cell/second normal gravity,
20× means 20 cells/second; at 2 cells/second it means 40. A multiplier should
not be relabeled as a fixed rate or confused with instant movement.

## Downstack's resulting behavior

The default remains 20× current gravity. In the menu review update, slider level 0 selects that default, while levels 1–10 explicitly select fixed minimum rates of 5, 10, 15, 20, 30, 45, 60, 75, 90 or 120 cells/second; faster normal gravity is never slowed. These are Downstack options, not a claim of exact parity with another game. Instant is a separate opt-in toggle. Hard drop remains a separate action that locks immediately.

In 0.4, every release/repress restarted the first-cell bonus. With simulated intermittent controller input, a piece set to 20 cells/second traversed 20 rows in 400 ms without locking, versus 9 with a steady hold. In 0.5 the same intermittent input advances 8 rows; the steady hold still advances 9. A separate cadence timer survives brief releases, so controller chatter cannot multiply the selected rate. Idle and grounded time cannot accumulate a burst. Invalid negative or nonnumeric rates now fall back to the default rather than enabling Instant.

This reproduces and fixes a matching software failure. It does not prove that the user's physical controller produced exactly that input pattern. Physical controller and Windows testing remain necessary.

## Development references

The original comparisons, source links and verification limits are retained
in [the development source record](docs/RESEARCH_SOURCES.md). These settings
are not a certification or a claim of exact parity with another game.
