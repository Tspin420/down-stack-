# Downstack 0.9.1

Download **Downstack_Windows_0.9.1.zip**, extract it into a new folder, and open
**Downstack.exe**. Keep the EXE and PCK together.

## Changes

- Rebuilt from cleaned source and repository history.
- Removed historical product-name references without changing game mechanics.
- Kept all four branch tips' game code, assets, settings and licenses intact.
- Retained protocol 8, 120 Hz gameplay, 20 Hz remote snapshots, uncapped
  rendering and the existing controls, gravity and garbage rules.
- No new online service integration is included in this maintenance release.

## Verification

Publication is gated on the complete regression suite, five-process multiplayer
check, source audit, Windows export, exported-game startup, ZIP integrity,
archive text scan and inspection of files inside the actual resource pack.
The attached validation report records the results.
[Build and test run](https://github.com/Tspin420/down-stack-/actions/runs/43663530758).

These automated checks do not replace physical-controller, WAN or frame-pacing
playtesting. The Windows executable remains unsigned.

## Updating

Saved settings and Sprint records remain in the existing per-user location.
Close the old game, extract this ZIP to a new folder, and recreate the shortcut
from that folder. No settings reset is required.

Repository history has been rewritten. Developers should make a fresh clone;
do not merge an old clone back into the cleaned repository. Existing game
installations do not use Git and are unaffected by the history change.
