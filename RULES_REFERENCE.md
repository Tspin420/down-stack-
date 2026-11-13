# Garbage reference audit — Downstack

Checked 12 November 2026. Target: **the original reference falling-block game, falling-block game-versus-falling-block game**. Do not substitute its falling-block game-versus-falling-block game gauge values or assume every licensed falling-block game game has one universal attack table.

## What was verified, and its limits

SEGA's public lesson page describes line clears, hold, perfect clears, T-spins, and back-to-back, but does not publish a numeric attack table. No developer-published numeric specification was found in this audit. The values below are corroborated by player-authored gameplay documentation and, where noted, an independently implemented open-source bot. They are not a claim of access to SEGA's source code, formal guideline certification, or independent frame-by-frame testing of the commercial game.

- Official explanation, without numeric attack amounts: [historical source link removed]
- FOUR's original falling-block game guide, using the **Garbage (vs. falling-block game)** column, not Gauge: [historical source link removed]
- First-person falling-block game walkthrough with a separate falling-block game-vs-falling-block game comparison, including the perfect-clear total: https://forums.somethingawful.com/showthread.php?threadid=3868890&userid=221322
- Cold Clear, an independent community bot, not official game code: https://github.com/MinusKelvin/cold-clear
  - Reviewed commit: 279edd7c3177ff8077f6a930193397814b281f27
  - Base and combo table: [historical source link removed]
  - Back-to-back, combo application, and perfect-clear override: [historical source link removed]

The core ordinary/full-T-spin table is consistent across the gameplay sources. The full long-combo curve and mini-double entry are also present in Cold Clear's source; that corroboration is weaker than an official specification or direct measurement of the game. The mini recognition rules themselves have not been exhaustively compared against falling-block game.

## Attack amounts before cancellation

| Clear | Garbage lines |
| --- | ---: |
| Single | 0 |
| Double | 1 |
| Triple | 2 |
| Four-line clear / falling-block game | 4 |
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

For example: a plain falling-block game with no combo sends 4; a back-to-back falling-block game with no combo sends 5; a perfect clear with 4 queued incoming lines cancels those 4 and sends 6. A double into 3 queued lines cancels 1 and sends nothing.

## Changes resulting from this audit

No attack amounts needed changing: the current code already matches the table above. Added tests/garbage_test.gd to exercise actual board locks, full/mini classification, every base clear amount, back-to-back bonuses/breaks, a long single-clear combo, perfect-clear override, and incoming cancellation. These are regression tests for our implementation, not evidence that we measured falling-block game itself.

## Deliberate Downstack differences

The receiver-side 1000 ms warning (adjustable), unlimited blocking while clearing, one aligned hole per packet, and round-robin targeting in 3–4-player rooms are Downstack policies. They have not been verified as exact falling-block game behavior. The normal/quick/classic delays, handling baseline, score display, and top-out handling also should not be described as exact falling-block game parity. This audit verifies the documented attack table; it does not certify the entire garbage system or all guideline edge cases.


## Soft-drop reference added in 0.3

The publicly available reproduction of the March 2009 falling-block game Design Guideline, sections 5.5 and 7.1, describes soft drop at 20 times current gravity while retaining lock delay: [historical source link removed] . This is a historical document hosted by a third party; the current private licensing specification was not verified.

Downstack now defaults to that 20× gravity behavior. Fixed cells/second rates and Instant remain user-selectable alternatives. Normal gravity and other timing rules still use the custom values documented above.

## Updated soft-drop comparison in 0.5

See SOFT_DROP_REFERENCE.md for the cross-reference against TETR.IO and official falling-block game documentation, the distinction between multipliers and fixed rates, and the reproduced controller timing failure fixed in 0.5. Exact falling-block game and falling-block game Effect soft-drop timings are not claimed.

## Hidden buffer update in 0.7

The board now stores 20 hidden rows above its 20 visible rows. BUFFER_NOTES.md documents the historical guideline reference, repaired partial-above I-piece lock, top-out boundaries and protocol 4 migration.
