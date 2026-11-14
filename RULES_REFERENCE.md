# Garbage rules — Downstack

## Approved rules — 14 November 2026

This section supersedes the old combo table and fixed B2B bonus in the historical
0.8 audit below. The user selected TETR.IO's combo calculation, a custom growing
B2B bonus added afterwards, one-for-one cancellation, combo blocking, and one
aligned garbage shaft per attack, with depth equal to that attack’s sent value.
Surge and an extra counterattack delay were explicitly excluded.

### Attack calculation

The first consecutive clearing placement has combo index `c = 0`; each subsequent
clearing placement increments it. A non-clearing placement resets it to `-1`.
Ordinary single/double/triple/quad base attacks are `0/1/2/4`; full T-spin
single/double/triple are `2/4/6`, and mini single/double are `0/1`.

1. Multiply the base attack by `1 + 0.25*c`.
2. At `c >= 2`, take the larger of that value and `ln(1 + 1.25*c)`.
3. Round down to a whole number of rows.
4. Add the current B2B count, without multiplying it.
5. Keep the existing perfect-clear exception: replace the total with 10.
6. Cancel incoming rows one-for-one, oldest packet first. Send only excess attack.

B2B is `-1` with no chain, `0` after the first qualifying clear, then `1`, `2`,
and so on. A qualifying clear is a quad or line-clearing T-spin, including minis.
Ordinary single/double/triple clears reset B2B; a placement clearing nothing
preserves its exact value. Breaking B2B pays out no stored attack. An ordinary
perfect clear still breaks B2B under the retained falling-block game-style PC behavior; a quad
PC remains a qualifying clear. TETR.IO's all-spin and all-clear B2B extensions
were not selected.

| Example, before cancellation and without a perfect clear | Attack |
| --- | ---: |
| T-spin double, no combo, B2B 3 | 7 |
| T-spin double, no combo, B2B 4 | 8 |
| T-spin double, combo index 4 (×2), B2B 4 | 12 |
| Triple → single → single → quad | 2 + 0 + 1 + 7 |
| Six ordinary doubles → quad → quad | 1 + 1 + 1 + 1 + 2 + 2 + 10 + 12 |

The two finishing quads continue the same combo. The doubles break any previous
B2B, so the first quad establishes a fresh chain and the second adds 1. This
finish was explicitly accepted; no special quad or two-wide combo cap is added.
Single-only combos send `0,0,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3…` per placement.

### Queue and transport

Every clearing placement blocks garbage insertion, including zero-attack singles.
Countering reduces the amount pending but never changes its warning deadline.
When a placement clears nothing, ready rows may rise; unexpired packets still
wait. Timer expiry alone does not interrupt the current piece. There is no
double-cancellation opener phase. Example: ten ready rows, then three attack,
leaves seven blocked rows; the next non-clearing lock admits those seven.

Every attack stays one packet, retains one hole and one selected target, and moves
the target-selection cursor once. The old router limit of 20 and receiver limit
of 40 are removed. The wire sanity bound is 2,147,483,647 rows per packet, not a
gameplay balancing cap. Inserting more than 40 identical rows guarantees overflow;
the engine produces the identical final grid in at most 40 row operations, so an
extreme packet cannot cause billions of simulation iterations.

Protocol 8 retains numeric B2B state and one amount/hole pair per attack while
requiring the updated guideline gravity curve.
Older clients are disconnected before lobby admission; everyone in a room must
use the same updated build. Packet depths, hole columns and B2B counts are also
replicated to spectators through validated board snapshots.

### One shaft per attack

Each individual attack creates a one-cell-wide vertical shaft with depth equal
to its final sent value. The same rule applies to every attack size.

| Attack before any cancellation, with no combo/B2B bonus unless stated | Shaft depth |
| --- | ---: |
| Ordinary single | 0; no garbage packet |
| Double | 1 row |
| Triple | 2 rows |
| falling-block game / quad | 4 rows |
| T-spin double | 4 rows |
| T-spin double at B2B 4 | 8 rows |
| T-spin double at combo index 4 and B2B 4 | 12 rows |

The combo contribution and B2B bonus deepen the same shaft from that placement.
Consecutive combo clears still send separate attacks; their values are not merged
into one combined shaft. For example, the two finishing quads in the accepted
six-doubles/two-quads sequence create separate 10- and 12-deep shafts.

Each packet chooses one uniformly random column independently. All its rows use
that column. Different packets can choose different columns, creating short,
changing shafts from multiple small attacks and long straight shafts from large
attacks. Adjacent packets can happen to choose the same column; their identities,
warning deadlines and cancellation accounting remain separate.

Sender-side cancellation reduces the attack before transmission. Receiver-side
cancellation shortens an existing shaft without moving its column or deadline.
An eight-row attack reduced by five leaves a three-deep shaft. Several ready
packets rising on the same lock retain their individual hole columns and order.
There is no size cutoff and no random hole change within an attack.

### Retained settings

The 1000 ms receiver-side warning remains adjustable to 250–3000 ms. The existing
all-ready-rows rise policy remains; TETR.IO's eight-row cap was researched but not
selected. Perfect clears remain 10 total. These are explicit boundaries of this update,
not a claim that all discussed ideas are implemented or that either game is copied
exactly. Blocking was already present in Downstack and now has focused regression
coverage for the newly agreed behavior.

### Evidence for the reference calculations

- OSK's original design explanation: a combo multiplier rewards strong finishing
  clears while weakening single-only chains:
  https://blog.osk.sh/post.php?p=5df9463f716867.05060790
- Independent attack calculator with an attributed OSK logarithmic-single formula:
  https://github.com/skysomorphic/tetrio-attack-calculator
- Triangle, an independent TETR.IO client, corroborates multiplier, logarithmic
  minimum, rounding and current Tetra League settings at reviewed commit
  `aa0698ab8b4299b85c5f87e9b54793e1b7d9d380`:
  https://github.com/halp1/triangle/blob/aa0698ab8b4299b85c5f87e9b54793e1b7d9d380/src/engine/utils/damageCalc/index.ts
  https://github.com/halp1/triangle/blob/aa0698ab8b4299b85c5f87e9b54793e1b7d9d380/src/engine/garbage/index.ts
  https://github.com/halp1/triangle/blob/aa0698ab8b4299b85c5f87e9b54793e1b7d9d380/src/classes/room/presets.ts
- Official TETR.IO patch notes distinguish combo blocking, travel/cancellation,
  B2B charging, opener defense and the garbage-clearing bonus. The latter three
  extra attack mechanics are not part of this custom Downstack selection:
  https://tetr.io/about/patchnotes/
- Firsthand falling-block game hole-pattern experiment, including grouped reception of separate
  attacks, used while comparing the reference games:
  https://p8g.hatenablog.com/entry/2018/08/14/070957
- Player-authored falling-block game cancellation/placement explanation:
  https://note.com/dottiz712/n/nce2de5ed2fb8

The tests verify Downstack's implementation of the selected formula and queue
rules. They do not measure the current commercial falling-block game executable, establish an
exact falling-block game travel delay, or replace human balance testing of two- and four-wide play.

## Historical falling-block game reference audit — version 0.8

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

Downstack adopted that 20× gravity behavior in 0.3. Fixed cells/second rates and Instant remain user-selectable alternatives. The current gravity update also adopts the documented level 1–15 curve, with one level per ten cleared lines and a level-15 cap for continuing versus matches. Sprint stays at level 1. Other timing rules retain the custom values documented above; see SOFT_DROP_REFERENCE.md for the current gravity and soft-drop details.

## Updated soft-drop comparison in 0.5

See SOFT_DROP_REFERENCE.md for the cross-reference against TETR.IO and official falling-block game documentation, the distinction between multipliers and fixed rates, and the reproduced controller timing failure fixed in 0.5. Exact falling-block game and falling-block game Effect soft-drop timings are not claimed.

## Hidden buffer update in 0.7

The board now stores 20 hidden rows above its 20 visible rows. BUFFER_NOTES.md documents the historical guideline reference, repaired partial-above I-piece lock, top-out boundaries and protocol 4 migration.
