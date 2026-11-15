# Downstack 0.9.2

Download **Downstack_Windows_0.9.2.zip**, extract it into a new folder, and open
**Downstack.exe**. Keep the EXE and PCK together.

## Changes

- Upgraded the bundled engine from Godot 4.6.3 to **Godot 4.7.2 stable**.
- Updated the checksum-pinned build editor and matching Windows export templates.
- Updated bundled Godot and third-party notices from the official 4.7.2 source.
- Packaging checks that the exported runtime and editor versions match.
- Retained game code and assets, protocol 8, 120 Hz gameplay, 20 Hz remote
  snapshots, uncapped rendering, VSync off, and existing controls and rules.

## Verification

Publication requires all twelve regression suites, the five-process loopback
multiplayer test, the source wording audit, Windows x64 export, exported-runtime
version verification, exported-game headless startup and ZIP integrity checks.
The [Windows release workflow](https://github.com/Tspin420/down-stack-/actions/workflows/release.yml)
records the results. BUILD_INFO.json inside the ZIP records the engine version
and source commit used to build it.

Physical-controller behavior, graphics, WAN play and frame pacing still need
playtesting on your PC. This engine update is not a measured performance claim.
The Windows executable remains unsigned.

## Updating

Close the old game and extract this ZIP to a new folder. Saved settings and
Sprint records remain in the existing per-user location; no reset or separate
Godot installation is needed. Recreate your desktop shortcut from the new folder.
Use the same Downstack build for everyone in a multiplayer room.
