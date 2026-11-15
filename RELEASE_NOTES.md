# Downstack 0.9.0

Download **Downstack_Windows_0.9.0.zip** from this release, extract the entire
folder, and open **Downstack.exe**. Keep the EXE and PCK together. An installer,
account, administrator rights, or a separate Godot installation is not required.

## Changes

- VSync is disabled and rendering has no FPS cap. Gameplay still updates at
  **120 Hz**, independently of rendering; remote board snapshots remain 20 Hz.
- New neon pink, blue and green menus, a dedicated Network page, player cards,
  controller/keyboard menu navigation, and an automatic **CURRENTLY SPECTATING**
  banner. The existing T icon appears during loading.
- Matching 0–10 DAS, ARR and soft-drop sliders. **0 selects the default**;
  Reset handling affects only the selected input profile. Instant soft drop
  remains a separate option and retains lock delay.
- Normal gravity follows the documented level 1–15 curve.
  Versus advances every ten lines and stays at level 15; Sprint keeps starting
  gravity. Default soft drop is 20× current gravity.
- Larger Hold/Next previews, adjusted board position, beveled blocks, continuous
  line-clear effects, and a nonlinear incoming-garbage meter.
- Multiplier-based combo calculation followed by the custom growing flat B2B bonus.
  Each attack creates one shaft as deep as its final sent value. One-for-one
  FIFO cancellation and garbage blocking on clearing placements apply.
  Large attacks are no longer cut off at 20 or 40 rows. No surge or added
  counterattack delay.

## Updating

Close the old game and extract 0.9.0 into a new folder. Saved controls, volume,
fullscreen choice and Sprint records remain in the same per-user data location.
If you use a desktop shortcut, run **Create Desktop Shortcut.cmd** from the new
folder, or use the in-game Settings button, to point it at the new executable.

**Everyone in a room must update.** This release uses network protocol 8 and
rejects older clients before lobby admission.

## Build and verification

Built with Godot 4.6.3 Standard for Windows x64. The ZIP contains the game,
shortcut helper, icon, rules/reference documents, licenses, and `BUILD_INFO.json`
with its source commit. A SHA-256 checksum is attached beside the ZIP.

The release workflow runs all twelve regression suites and the five-process
multiplayer check, then exports and smoke-tests the actual Windows executable
before publishing. Linux validation passed 1117 assertions. See `VALIDATION.md`
and the linked repository Actions run for the platform-specific results.

The build is unsigned. Physical Windows/controller playtesting, WAN play and
frame pacing still need testing; automated headless startup is not a gameplay
or performance benchmark. With VSync off, visible tearing depends on the PC
and display. Exact timing parity with other games is not claimed.
