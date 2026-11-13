# Soft-drop comparison — Downstack 0.5

Checked 12 November 2026. This audit distinguishes published behavior, numerical settings, and parameters that still need direct measurement. It does not claim that every modern falling-block game game has identical timing.

| Reference | Verified behavior or speed | Evidence and limits |
| --- | --- | --- |
| March 2009 falling-block game Design Guideline, sections 5.5 and 7.1 | 20 times the current normal gravity; release restores ordinary fall speed; landing retains lock delay; holding continues across pieces. | Historical primary document reproduced on a third-party host. It is not proof of the current private specification or every released game's implementation. |
| TETR.IO | Finite SDF settings from 5× through 40×, plus explicit infinity for an immediate, non-locking soft/sonic drop. | Live public control markup starts at 5; official patch notes document 40×; the team's FAQ describes infinity. The FAQ explicitly cautions that SDF is not always a simple multiplication of current gravity: it works at zero gravity too. Exact low-gravity fallback math was not established. |
| reference falling-block game series | SEGA's public manual distinguishes soft drop and hard drop. | The consulted public manual does not establish an exact numerical soft-drop rate. No direct executable measurement was performed. |
| falling-block game Effect: Connected | Its official-site guide defines SDR as the falling speed while holding soft drop. | That guide publishes numerical DAS/ARR defaults but not an SDR number. Exact soft-drop timing was not independently measured. |

A multiplier and a fixed rate are different. At 1 cell/second normal gravity, 20× means 20 cells/second; at 2 cells/second it means 40. TETR.IO's SDF values should not be relabeled as fixed cells/second, and 20× should not be confused with instant 20G gravity.

## Downstack's resulting behavior

The default remains 20× current gravity. The slider explicitly selects fixed minimum rates of 5, 10, 15, 20, 30, 45, 60, 90 or 120 cells/second; faster normal gravity is never slowed. These are Downstack options, not a claim of exact falling-block game or TETR.IO parity. Instant is a separate opt-in toggle. Hard drop remains a separate action that locks immediately.

In 0.4, every release/repress restarted the first-cell bonus. With simulated intermittent controller input, a piece set to 20 cells/second traversed 20 rows in 400 ms without locking, versus 9 with a steady hold. In 0.5 the same intermittent input advances 8 rows; the steady hold still advances 9. A separate cadence timer survives brief releases, so controller chatter cannot multiply the selected rate. Idle and grounded time cannot accumulate a burst. Invalid negative or nonnumeric rates now fall back to the default rather than enabling Instant.

This reproduces and fixes a matching software failure. It does not prove that the user's physical controller produced exactly that input pattern. Physical controller and Windows testing remain necessary.

## Sources

- Historical guideline reproduction: [historical source link removed]
- TETR.IO live configuration: https://tetr.io/
- Team-maintained mechanics FAQ, Soft Drop Factor and Sonic Drop: https://github.com/tetrio/faq/blob/main/mechanics.html
- Official TETR.IO patch notes, Alpha 4.0.0 (22 June 2020): https://tetr.io/about/patchnotes/
- Public JSON behind those patch notes: https://tetr.io/about/patchnotes/notes.json
- SEGA reference falling-block game 2S manual: [historical source link removed]
- falling-block game Effect: Connected official-site guide: [historical source link removed]
