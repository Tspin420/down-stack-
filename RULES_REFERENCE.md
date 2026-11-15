# Garbage reference audit — Downstack

## Attack amounts before cancellation

| Clear | Garbage lines |
| --- | ---: |
| Single | 0 |
| Double | 1 |
| Triple | 2 |
| Quad (four-line clear) | 4 |
| Full T-spin single | 2 |
| Full T-spin double | 4 |
| Full T-spin triple | 6 |
| Mini T-spin single | 0 |
| Mini T-spin double | 1 |
| No line clear | 0 |

Back-to-back adds one on the second and later qualifying difficult clear (four-line clear or line-clearing T-spin). Ordinary single/double/triple breaks back-to-back; a placement that clears nothing preserves it. Combo is separate and can add to an ordinary or difficult clear.

| Consecutive line-clearing placement | Combo/REN count | Bonus on this placement |
| --- | ---: | ---: |
| 1st | 0 | 0 |
| 2nd | 1 | 0 |
| 3rd–4th | 2–3 | 1 |
| 5th–6th | 4–5 | 2 |
| 7th–8th | 6–7 | 3 |
| 9th–11th | 8–10 | 4 |
| 12th onward | 11+ | 5 |

A non-clearing placement ends the combo. The first clear is index zero; omitting that first entry is a common source of an off-by-one combo table.

A **perfect clear sets the attack to 10 total** before incoming cancellation. It does not add 10 to the ordinary clear or stack the normal combo bonus on top. The gameplay walkthrough explicitly describes the ten-line total; Cold Clear likewise overwrites the calculated attack with 10 after back-to-back/combo computation. Downstack follows that behavior.

For example: a plain quad with no combo sends 4; a back-to-back quad with no combo sends 5; a perfect clear with 4 queued incoming lines cancels those 4 and sends 6. A double into 3 queued lines cancels 1 and sends nothing.

## Changes resulting from this audit

No attack amounts needed changing: the current code already matches the table above. Added tests/garbage_test.gd to exercise actual board locks, full/mini classification, every base clear amount, back-to-back bonuses/breaks, a long single-clear combo, perfect-clear override, and incoming cancellation. These are regression tests for our implementation, not evidence that we measured comparison-game itself.

## Deliberate Downstack differences

The receiver-side 1000 ms warning (adjustable), unlimited blocking while clearing, one aligned hole per packet, and round-robin targeting in 3–4-player rooms are Downstack policies. They have not been verified as exact comparison-game behavior. The normal/quick/classic delays, handling baseline, score display, and top-out handling also should not be described as exact comparison-game parity. This audit verifies the documented attack table; it does not certify the entire garbage system or all guideline edge cases.

## Soft-drop reference added in 0.3

The publicly available reproduction of the March 2009 historical design reference, sections 5.5 and 7.1, describes soft drop at 20 times current gravity while retaining lock delay:  . This is a historical document hosted by a third party; the current private licensing specification was not verified.

Downstack now defaults to that 20× gravity behavior. Fixed cells/second rates and Instant remain user-selectable alternatives. Normal gravity and other timing rules still use the custom values documented above.

## Updated soft-drop comparison in 0.5

See SOFT_DROP_REFERENCE.md for the cross-reference against TETR.IO and official quad documentation, the distinction between multipliers and fixed rates, and the reproduced controller timing failure fixed in 0.5. Exact comparison-game and a comparison game soft-drop timings are not claimed.

## Hidden buffer update in 0.7

The board now stores 20 hidden rows above its 20 visible rows. BUFFER_NOTES.md documents the historical guideline reference, repaired partial-above I-piece lock, top-out boundaries and protocol 4 migration.
