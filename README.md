# Downstack 0.9.0

A playable falling-block game with adjustable handling, delayed garbage, local multiplayer, player-hosted rooms, and a 40-line sprint. This is the next version of Counterfall, renamed Downstack. Original project code, synthesized audio, and a new T-piece icon; no a comparison game files are needed.

[Download the latest Windows release](https://github.com/Tspin420/down-stack-/releases/latest). Choose the **Downstack_Windows_0.9.0.zip** asset; GitHub’s source-code ZIP is for development.

## Start on Windows

1. Extract the entire ZIP into a normal folder.
2. Keep **Downstack.exe and Downstack.pck together**, then open Downstack.exe. No installer, administrator rights, account, or separate Godot installation is required.
3. Launch opens the Play menu. Choose **Local match**, **40-line sprint**, or **Network play**. In the lobby, enter your name, choose a keyboard layout or connected controller, set your handling, then select **Join as player** (or **Use this player** for Sprint).
4. Select **Start practice** for one player or **Start match** for local versus. Add each player on a different input. Use **Edit** or **Remove** on a player card, and **Match rules** beside Start to adjust host settings.

Menus use neon pink accents with blue and green borders on the mode badges and player cards. The existing app icon is retained. DAS, ARR and soft drop share matching 0–10 sliders: **0 restores the default** for each control, while 1–10 retain the custom speed range.

Navigate menus with arrow keys or the controller D-pad; Enter / the south face button (A / Cross) selects, and Esc / the east face button (B / Circle) goes back. The saved fullscreen choice is restored during startup. The T icon appears while resources load; there is no extra press-to-start screen.

**Desktop shortcut:** open Settings and click **Create desktop shortcut**, or double-click **Create Desktop Shortcut.cmd** in the extracted game folder. This creates Downstack.lnk on your Windows desktop with the embedded T icon. It uses your actual Desktop location, including a redirected/OneDrive Desktop. Extract the entire ZIP first and keep the game folder in place afterward; the shortcut points there. Run the button/helper again after moving or updating the game. An existing Downstack game shortcut is updated. A different application’s shortcut with the same name is preserved and reported as a conflict. Downstack.ico is also included for manual icon customization.

**Fullscreen:** click **Fullscreen** in the header, press **F11**, or choose **Settings > Display > Fullscreen (borderless)**. The setting saves immediately and is restored at the next launch. F11 and the header button return to windowed mode; the previous window size/position or maximized state is restored within the current screen. The interface expands to fit the display without stretching the blocks. Sound and dropdown dialogs stay inside the game. F11 also works during binding capture and does not become a gameplay binding.

If shortcut creation is restricted by your Windows configuration, right-click Downstack.exe, choose Show more options if needed, then Send to > Desktop (create shortcut). Neither method moves the EXE or PCK.

**Publisher warning:** This is still an unsigned development build. Renaming it and adding an icon do not create a verified publisher or guarantee that Windows SmartScreen stops warning. No certificate, security-setting change, or antivirus exception is installed. Trusted release signing needs a real signing identity and certificate; even newly signed applications can receive reputation warnings. The Windows executable has been exported and inspected, but not run on Windows hardware here. See VALIDATION.md.

## New in 0.9

- **VSync off, no render FPS cap, fixed 120 Hz gameplay.** Rendering speed does not change movement, gravity or lock timing. Remote boards receive snapshots at 20 Hz. Driver or operating-system settings may still impose synchronization or a cap; tearing can be visible with VSync disabled.
- Neon menus, dedicated host/join setup, player cards, keyboard/controller navigation, and an automatic spectator banner. The existing T icon appears while loading.
- Matching 0–10 handling sliders, zero/default presets, per-input Reset handling and a separate Instant soft-drop option.
- Historical guideline gravity for levels 1–15, fixed starting gravity in Sprint, and 20× gravity for default soft drop. See SOFT_DROP_REFERENCE.md for the documented source and versus continuation policy.
- Larger Hold/Next previews, adjusted board position, beveled blocks, continuous line-clear effects and the nonlinear garbage meter.
- TETR.IO-style combos plus the custom growing flat B2B bonus; one shaft per attack, one-for-one cancellation, combo blocking and intact large attacks. See RULES_REFERENCE.md.
- **Protocol 8: all players and spectators must update.** Older clients are rejected before joining.

See [RELEASE_NOTES.md](RELEASE_NOTES.md) for this update, [CHANGELOG.md](CHANGELOG.md) for earlier releases and [VALIDATION.md](VALIDATION.md) for checks and remaining hardware tests.

## Updating an existing installation

Close Downstack and extract the new ZIP into a new folder. Keep all packaged files together. Controls, volume, fullscreen preference and Sprint records are stored separately in `%APPDATA%\Godot\app_userdata\Downstack` and survive changing the game folder. Run the desktop-shortcut helper again from the new folder if you used a shortcut. Everyone in an online room needs the same current build.

## Handling

DAS is the wait before a held direction starts repeating. ARR is the interval between repeated horizontal moves. These change movement, not gravity.

| Level | DAS, ms | ARR, ms |
| --- | ---: | ---: |
| 0 — default | 166.67 | 33.33 |
| 1 | 300.00 | 100.00 |
| 2 | 266.67 | 83.33 |
| 3 | 233.33 | 66.67 |
| 4 | 200.00 | 50.00 |
| 5 — baseline | 166.67 | 33.33 |
| 6 | 150.00 | 30.00 |
| 7 | 133.33 | 26.67 |
| 8 | 116.67 | 23.33 |
| 9 | 100.00 | 20.00 |
| 10 — fastest | 83.33 | 16.67 |

Zero is a default preset, separate from the custom 1–10 range; custom level 5 has the same timing. Existing saved levels retain their physical speeds. Level 10 gives twice the repeat rate and half the initial repeat wait of the default. The baseline is the previous prototype's a comparison game-inspired approximation, not a newly measured frame-perfect comparison-game timing claim. The simulation runs at 120 Hz. DAS falls on fixed ticks; intermediate ARR values retain their fractional remainder so adjacent slider levels have distinct average repeat rates.

Handling applies per input profile. Select the keyboard or controller before changing values. Lobby sliders save immediately and update that device’s existing local player slot; use Join as player to add a slot or Update player to change its name. **Reset handling** puts all three sliders at 0, restoring default DAS/ARR and soft drop for the selected input without changing its bindings, name or other profiles. In the lobby it saves immediately; on Settings it updates the draft until Apply & back. The last player name is also saved. The app attempts to import the old Counterfall preferences when no Downstack preferences file exists. Saving new controls or sound settings does not overwrite them with legacy settings.

## 40-line sprint

Choose 40-line sprint, add one player, and start. The clock begins after the three-second countdown and freezes on the piece that reaches or exceeds 40 cleared lines. There is no incoming or outgoing garbage. Both clear and entry delay are zero, with fixed 1-row/second gravity and the normal 500 ms lock delay. Your assigned restart input (R by default on keyboard, Start / Options on gamepad) or the on-screen Restart button starts a fresh bag seed and countdown. A top-out does not replace your best completed time. Best time is stored locally in the game's preferences.

## Local and online rooms

Up to four active players may share one room, with any mix of local and remote players. A computer may own two keyboard players plus gamepad players within that four-player total. Menus use the mouse; keyboard rollover depends on your keyboard.

**LAN:** Open **Network play → Create lobby**. Other computers open **Network play**, enter the host's LAN address and matching UDP port, then select **Join lobby**. A pending connection can be canceled; failed connections keep the address for retry. Add players on each computer. The host starts the round.

**Internet:** Direct connections use the host's reachable address. The host's network must route the selected UDP port (default 42970) to that computer. Firewall permission and router port forwarding may be needed. There is no automatic NAT traversal or relay; carrier-grade NAT may prevent direct hosting.

**Host as viewer:** Leave your player slots empty. Remote players join and add themselves; you can start/end rounds and watch without playing. Remote spectators likewise join without adding a player. A **CURRENTLY SPECTATING** banner appears at the top whenever you have no player slot in an online room, including while watching a match. Adding a local player hides it; removing your last local player restores it. No extra spectator button is needed. The room accepts twelve remote computer connections plus the host, with four active players total.

The host can end a round to return everyone to the lobby. Leaving as host closes the room; there is no host migration. A disconnected player's boards forfeit. Late joiners can watch, then add players in the next lobby. All participants must use this updated protocol 8 build. Earlier clients are rejected before entering the lobby so different gravity curves cannot share a match.

## Remapping and soft drop

Open **Settings** in the header, or **Change bindings** in a lobby. Select the input profile on the left. Handling sliders appear below it in this order: DAS, ARR, soft drop. Individual action bindings are on the right. Click **Change** or **+ Bind input** beside any action, then press the desired key, controller button, D-pad direction, trigger, or stick direction. For an analog input, start at neutral, then press/move it deliberately. Keyboard bindings are individual physical keys, not modifier chords.

Reusing an input swaps its previous binding into the edited slot, preventing one input from silently firing two actions. The × buttons clear bindings. Every gameplay action must retain at least one binding before Apply & back is enabled; restart is optional. Apply & back saves all profiles edited on the page and returns to the previous screen. Cancel discards pending controls/handling edits across all profiles; Display changes are saved immediately and remain in effect. Reset this profile restores its default controls, level-0 DAS/ARR, and level-0 (20× gravity) soft drop; Apply & back commits the reset. Esc cancels capture; outside capture it cancels the page. F11 remains reserved for fullscreen. Shared keys across the two keyboard profiles are flagged because they affect both players if both join.

Settings are local and persist across launches. Keyboard profiles are separate. Controller profiles use the controller's reported model/GUID, with connection order separating identical controllers. A different connection order for identical pads may change which saved profile they use. Controller hotplug updates the selector and cancels any capture. A disconnected controller is blocked for the rest of that round, even if the same runtime ID reconnects. Return to the lobby and explicitly select/add the intended controller before restarting.

Normal gravity uses the public March 2009 guideline's curve: `1000 × (0.8 − (L − 1) × 0.007)^(L − 1)` milliseconds per cell. Versus advances one level per ten cleared lines, then holds level 15 for long matches. Sprint stays at level 1. Default soft drop at slider **0** is **20× this gravity**, with normal lock delay retained; the separate **Instant soft drop** toggle reaches the floor immediately. The reference is the historical guideline, not verified comparison-game timing or the latest private specification. See SOFT_DROP_REFERENCE.md for details and tests.

Soft-drop level 0 selects the existing 20× gravity default. Levels 1–10 select fixed minimum descent speeds: 5, 10, 15, 20, 30, 45, 60, 75, 90 or 120 cells/second. The added 75 cells/second step fills the tenth finite position without changing any saved rate. These rates never slow a faster normal gravity. All three sliders use the same track, thumb, dimensions and numeric readout; the soft-drop readout tooltip identifies its actual rate. The separate Instant soft drop toggle moves the active piece to the floor in one simulation tick and retains the normal lock delay. Holding it does not reset that delay forever. Hard drop still lands and locks immediately at every soft-drop setting. Finite soft drop responds immediately when its cadence permits, then repeats at the selected interval. Brief releases/re-presses cannot exceed that rate. Releasing it returns to normal gravity without a stored-time burst.

Changes apply to the next round. Remapping is disabled during a round and automatically closes if the online host starts a match. Already-added local slots receive new soft-drop settings when you save Settings or adjust a lobby slider; no remove/re-add step is needed. Existing sprint personal bests remain stored; different handling settings can affect comparisons.

## Default controls

| Action | Keyboard 1 | Keyboard 2 | Standard gamepad |
| --- | --- | --- | --- |
| Move | Left / Right | A / D | D-pad left / right |
| Soft drop | Down | S | D-pad down |
| Rotate clockwise | X | K | East face button: B / Circle |
| Rotate counterclockwise | Z | J | South face button: A / Cross |
| Hard drop | Space | W | D-pad up |
| Hold | C | Q | Either shoulder button |
| Restart sprint | R | R | Start / Options |
| Fullscreen | F11 | F11 | Keyboard F11 |

The left stick supports horizontal movement and soft drop: activation at 55%, release below 35%. Stick up does not hard drop. Physical controllers have not been tested here. Opening Sound or switching away pauses local games and clears input; online matches continue with those controls suspended. Release held controls before pressing them again after resuming. A complete press/release that never reaches either the engine event stream or its device state cannot be reconstructed.

## Rules

10×20 visible field plus a 10×20 hidden buffer above it; seven-piece bags; five-piece preview; hold once per piece; ghost; SRS quarter-turns with separate I-piece kicks. Lock delay is 500 ms with up to fifteen grounded movement/rotation resets. A short early rotation input buffer accepts rotations just before entry; this is separate from the hidden spatial buffer above the board. No 180-degree rotation. Merely moving or rotating above the visible skyline is allowed. Locking partly above it survives if at least one cell is visible. Locking entirely above it, colliding at spawn, or pushing stored cells beyond the top of the full buffer still ends play.

All players share the seeded piece sequence. Practice is endless until top-out; versus is last player standing. There are no bots.

Versus defaults to 120 ms line-clear delay plus 100 ms entry delay. Host options include instant clear, 250 ms clear, and a slower classic profile (approximately 583 ms for single, 667 ms for double/triple, 750 ms for quad). Instant clear in versus still retains entry delay. These timings are custom approximations.

Incoming garbage gets a full receiver-side warning, default 1000 ms, adjustable 250–3000 ms. Outgoing strength first cancels the oldest queued garbage. Expired garbage rises only on a non-clearing lock, never during an active piece. Line clearing continues to block it. Network travel time is additional to that warning. Every attack produces one aligned, one-cell-wide shaft whose depth equals its final sent value. A base double sends a one-deep shaft, a triple two, and a quad four. Combo and B2B bonuses deepen that same shaft. Each packet chooses its hole column independently; cancellation shortens its shaft without changing the column. Three/four-player attacks rotate through surviving opponents.

Normal single/double/triple/quad: 0/1/2/4. Full T-spin single/double/triple: 2/4/6. Mini single/double: 0/1. Combos use TETR.IO's multiplier calculation, rounded down, with its logarithmic minimum for singles. Then add the current B2B count as a flat bonus on qualifying quads and T-spin clears. The first qualifying clear establishes the chain at 0; subsequent ones add 1, 2, 3, and so on. Ordinary single/double/triple clears break B2B; non-clearing placements preserve B2B but end the combo. No surge or extra counterattack delay. Perfect clears retain the existing 10-total override before cancellation. Read RULES_REFERENCE.md for the formula, examples, sources and remaining design choices.

Multiplayer protocol 8 requires the updated gravity curve and retains the numeric B2B counter and one aligned shaft per attack. All participants must use this updated build; older clients are rejected before lobby admission. Each attack keeps one target, one hole column and one packet identity, including attacks above 20 or 40 rows.

## Limits

This is an independently developed falling-block puzzle game in development. No matchmaking, friend list, invite codes, automatic port setup, relay, ranked ladder, host migration, replay system, bots, or competitive anti-cheat. Each computer simulates its own boards; the host coordinates routing/results. Input never waits for a remote player, and remote views update at 20 Hz. Real Windows performance, controller behavior, WAN conditions, and exhaustive rotation/top-out edge cases still need playtesting.

## Source and builds

The source folder contains the editable Godot project. Open project.godot with Godot 4.6.3 Standard (no .NET). F5 runs the game. Rebuilding requires matching official export templates. From the source folder:

```text
godot --headless --path . --export-release "Windows Desktop" ../build/Downstack.exe
godot --headless --path . --script tests/core_test.gd
godot --headless --path . --script tests/gravity_test.gd
godot --headless --path . --script tests/garbage_test.gd
godot --headless --path . --script tests/update_test.gd
godot --headless --path . --script tests/input_test.gd
godot --headless --path . --script tests/settings_test.gd
godot --headless --path . --script tests/controller_drop_test.gd
godot --headless --path . --script tests/input_audit_test.gd
godot --headless --path . --script tests/buffer_test.gd
godot --headless --path . --script tests/desktop_test.gd
godot --headless --path . --script tests/visual_test.gd
godot --headless --path . --script tests/menu_test.gd
python tests/run_network_tests.py
```

Create the sibling build folder before exporting. The update/input/settings/input-audit/desktop/menu tests write test preferences and personal bests; use isolated user-data directories when running them. Python 3 is needed only for the five-process loopback test launcher and the optional audio regeneration script, tools/make_audio.py. The launcher tests four compatible participants and rejection of an old-protocol client. The release shortcut helper can be regenerated with `python tools/make_shortcut_helper.py "../build/Create Desktop Shortcut.cmd"`. Set GODOT_BIN if the engine is not named godot on PATH.

To reproduce the actual menu screenshots with a desktop display and isolated preferences:

```text
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://tools/menu_capture.gd -- --output=/absolute/path/to/captures
```

This fixture writes sample player preferences. Use an isolated user-data directory (for example, `XDG_DATA_HOME` on Linux); it is a visual fixture, not a performance benchmark.

For the repeatable test/package commands and automated Windows release workflow, see [GITHUB_SETUP.md](GITHUB_SETUP.md). Windows builds belong in Releases.

Project code is supplied under MIT. Godot engine/third-party notices are in licenses. The icon was generated for Downstack; audio was synthesized for this project, with its generation source included.
