# Gravity and soft-drop reference — Downstack

Checked 12 November 2026. This audit distinguishes published behavior, numerical settings, and parameters that still need direct measurement. It does not claim that every falling-block games has identical timing.

## Guideline defaults — 14 November 2026

The default at slider **0** follows the publicly reproduced **March 2009 historical design reference**, sections **5.5** (page 17) and **7.1** (page 20): soft-drop interval = normal fall interval / 20. Section 7.1 presents this as a suggested speed. At Downstack's starting and Sprint gravity, that means **20 cells/second**, or **50 ms per cell**; it scales with normal gravity in versus. This is a historical guideline baseline, not a verified numerical match for comparison-game or a claim about the latest private guideline.

Normal gravity now follows section **7**: `1000 × (0.8 − (L − 1) × 0.007)^(L − 1)` milliseconds per cell. Versus advances a level every ten cleared lines. The previous gentler curve and 40 ms minimum interval are removed. Since versus continues until top-out, Downstack holds the last documented level, **15**, from 140 cleared lines onward; that continuation is a Downstack policy. Sprint remains at starting gravity throughout, consistent with section **12.2**.

The separate **Instant soft drop** toggle reaches the floor in one simulation tick while retaining lock delay. It is an additional option, not the guideline default. At high gravity the default can also cross multiple cells per tick; fractional timing is retained. Finite custom settings cannot slow faster normal gravity.

All **1117 assertions** passed in Godot 4.6.3 on Linux. The 90-check gravity suite covers the complete curve, level boundaries, the versus cap, Sprint, actual falling distances, multiple-cell ticks, default and Instant behavior, release and lock delay. Existing input checks cover continued hold across pieces and slider-zero persistence. Downstack retains its tested anti-burst input behavior for first-cell/re-press cadence. Protocol **8** prevents clients using the old gravity curve from joining the same room.

A multiplier and a fixed rate are different. At 1 cell/second normal gravity, 20× means 20 cells/second; at 2 cells/second it means 40. TETR.IO's SDF values should not be relabeled as fixed cells/second, and 20× should not be confused with instant 20G gravity.

## Downstack's resulting behavior

The default remains 20× current gravity. In the menu review update, slider level 0 selects that default, while levels 1–10 explicitly select fixed minimum rates of 5, 10, 15, 20, 30, 45, 60, 75, 90 or 120 cells/second; faster normal gravity is never slowed. These are Downstack options, not a claim of exact comparison-game or TETR.IO parity. Instant is a separate opt-in toggle. Hard drop remains a separate action that locks immediately.

In 0.4, every release/repress restarted the first-cell bonus. With simulated intermittent controller input, a piece set to 20 cells/second traversed 20 rows in 400 ms without locking, versus 9 with a steady hold. In 0.5 the same intermittent input advances 8 rows; the steady hold still advances 9. A separate cadence timer survives brief releases, so controller chatter cannot multiply the selected rate. Idle and grounded time cannot accumulate a burst. Invalid negative or nonnumeric rates now fall back to the default rather than enabling Instant.

This reproduces and fixes a matching software failure. It does not prove that the user's physical controller produced exactly that input pattern. Physical controller and Windows testing remain necessary.
