# Hidden buffer and top-out — Downstack 0.7

The board stores **10 columns × 40 rows**: 20 visible rows and 20 invisible rows above the skyline. Spawn remains immediately above the visible board, with the same entry step into view. Pieces do not spawn at the very top of the 40-row storage area.

## Reproduced 0.6 failure

The old board stored only two hidden rows but allowed active pieces to extend into negative, unstored rows. A vertical I-piece with three cells above the skyline and one visible could fit and rotate into place. Locking it then discarded its highest cell and immediately marked the player dead.

The regression fixture starts a horizontal I at its normal post-entry height, places three blocking cells one row beneath it, and forces the fifth clockwise SRS kick. That kick lifts the I by two rows. In 0.7 all four resulting cells are stored, and this partly visible lock survives. A following piece can spawn normally when its cells are clear.

## Boundaries

- Moving or rotating wholly or partly above the visible skyline is allowed while the piece is active.
- A lock with at least one visible cell does not lose solely because its other cells are hidden.
- A lock with every cell above the skyline still loses. This check occurs at lock, before row elimination, as in the previous build.
- A newly spawned piece overlapping stored cells still loses.
- Garbage may push blocks into the hidden buffer. Overflow loses only when a stored block is pushed past the actual top of the full 20-row buffer.
- Hidden cells remain solid for movement/rotation and can return to view when rows below them clear.
- The visible floor, spawn location relative to the skyline, handling and lock delay are unchanged. The renderer displays only the 20 visible rows and clips hidden active/ghost cells.

## Reference and limits

The [March 2009 Tetris Design Guideline reproduction](https://studylib.net/doc/27262492/2009-tetris-design-guideline), glossary and section 10, specifies an additional 20-row buffer, permits movement above the skyline and partial-above locks, and distinguishes fully hidden locks, blocked spawns and overflow. This is a historical document hosted by a third party, not verification of today's private licensing rules or exact Puyo Puyo Tetris behavior.

TETR.IO's current buffer dimension was not independently confirmed from its own accessible documentation during this update. Do not describe this release as a verified recreation of its complete top-out system.

## Tests and networking

The new `tests/buffer_test.gd` contains **89 checks** for spawn heights, all eight I quarter-turn transitions at five heights, forced upward kick, partial/whole hidden locks, blocked spawns, hidden collisions, line compaction, garbage push/overflow, real ceiling/floor bounds, ghost, hard drop, hold, snapshot round trips and rejection of old 22-row states. All **640 checks** pass across the full suite.

The four-process multiplayer test now verifies specific hidden and floor cells at both the host and the remote spectator before disconnect. The test launcher also treats explicit failure messages as failures.

**All players and spectators must use version 0.7 / protocol 4.** The 40-row snapshots are intentionally incompatible with older builds. This does not change saved key bindings, handling, audio preferences or sprint personal bests.

Physical Windows/controller behavior and exhaustive commercial-game rotation/top-out parity remain unverified. This update fixes the reproduced buffer defect and the scenarios covered by the included tests.
