# Garbage rules — Downstack

## Approved rules — 14 November 2026

These rules supersede the version 0.8 combo table and fixed B2B bonus.
The selected rules use a combo multiplier, a custom growing B2B bonus added
afterwards, one-for-one cancellation, combo blocking, and one aligned garbage
shaft per attack, with depth equal to that attack’s sent value.
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
perfect clear still breaks B2B under the retained perfect-clear behavior; a
quad perfect clear remains a qualifying clear. All-spin and all-clear B2B
extensions are not part of the selected rules.

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
requiring the updated level-based gravity curve.
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
| Quad (four-line clear) | 4 rows |
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
all-ready-rows rise policy remains; no eight-row rise cap is applied. Perfect clears remain 10 total. These are explicit boundaries of this update,
not a claim that all discussed ideas are implemented or that either game is copied
exactly. Blocking was already present in Downstack and now has focused regression
coverage for the newly agreed behavior.
