# Downstack 0.8.0

A playable falling-block game with adjustable handling, delayed garbage, local multiplayer, player-hosted rooms, and a 40-line sprint. This is the next version of Counterfall, renamed Downstack. Original project code, synthesized audio, and a new T-piece icon; no Tetris Ultimate files are needed.

## Start on Windows

1. Extract the entire ZIP into a normal folder.
2. Keep **Downstack.exe and Downstack.pck together**, then open Downstack.exe. No installer, administrator rights, account, or separate Godot installation is required.
3. Launch opens the Play menu. Choose **Local match**, **40-line sprint**, or **Network play**. In the lobby, enter your name, choose a keyboard layout or connected controller, set your handling, then select **Join as player** (or **Use this player** for Sprint).
4. Select **Start practice** for one player or **Start match** for local versus. Add each player on a different input. Use **Edit** or **Remove** on a player card, and **Match rules** beside Start to adjust host settings.

Menus use neon pink accents with blue and green borders on the mode badges and player cards. The existing app icon is retained.

Navigate menus with arrow keys or the controller D-pad; Enter / the south face button (A / Cross) selects, and Esc / the east face button (B / Circle) goes back. The saved fullscreen choice is restored during startup. The T icon appears while resources load; there is no extra press-to-start screen.

**Desktop shortcut:** open Settings and click **Create desktop shortcut**, or double-click **Create Desktop Shortcut.cmd** in the extracted game folder. This creates Downstack.lnk on your Windows desktop with the embedded T icon. It uses your actual Desktop location, including a redirected/OneDrive Desktop. Extract the entire ZIP first and keep the game folder in place afterward; the shortcut points there. Run the button/helper again after moving or updating the game. An existing Downstack game shortcut is updated. A different application’s shortcut with the same name is preserved and reported as a conflict. Downstack.ico is also included for manual icon customization.

**Fullscreen:** click **Fullscreen** in the header, press **F11**, or choose **Settings > Display > Fullscreen (borderless)**. The setting saves immediately and is restored at the next launch. F11 and the header button return to windowed mode; the previous window size/position or maximized state is restored within the current screen. The interface expands to fit the display without stretching the blocks. Sound and dropdown dialogs stay inside the game. F11 also works during binding capture and does not become a gameplay binding.

If shortcut creation is restricted by your Windows configuration, right-click Downstack.exe, choose Show more options if needed, then Send to > Desktop (create shortcut). Neither method moves the EXE or PCK.

**Publisher warning:** This is still an unsigned development build. Renaming it and adding an icon do not create a verified publisher or guarantee that Windows SmartScreen stops warning. No certificate, security-setting change, or antivirus exception is installed. Trusted release signing needs a real signing identity and certificate; even newly signed applications can receive reputation warnings. The Windows executable has been exported and inspected, but not run on Windows hardware here. See VALIDATION.md.

## New in 0.8

- Visible fullscreen button, immediate saved Display setting, reliable reserved F11 handling before key-binding capture, and remembered startup mode.
- Fullscreen expands the layout to the screen; switching back restores the prior window bounds or maximized state. Embedded dialogs remain visible in fullscreen.
- Windows desktop-shortcut button plus a double-click helper, both using the same included script. The shortcut targets the extracted EXE, uses its folder as the working directory, and shows the T icon. No administrator rights or execution-policy change.
- **665 automated checks passed**, plus the four-process network test. Fullscreen transitions and Settings/Sound interaction were visually checked on Linux. Windows shortcut creation and Windows-specific display behavior still need target-PC testing.
- Protocol remains 4, compatible with 0.7.

## Included from 0.7

- **20 hidden buffer rows above the 20 visible rows.** I-pieces can rotate and kick above the skyline, and all their hidden cells remain stored and collision checked.
- Fixed a reproduced premature top-out: an I-piece with three cells above the skyline and one visible could fit, but locking it killed the player and discarded the upper cell. That legal partial-above lock now survives. Fully hidden locks, blocked spawns and true buffer overflow still end the game.
- Updated rendering, garbage movement, clearing and multiplayer snapshots for the full 40-row field. Spawn height relative to the visible board, floor, handling and lock delay are retained.
- **Online compatibility changed:** all players and spectators need version **0.7 / protocol 4**. Older 22-row snapshots are incompatible.
- All **640 checks**, including 89 new buffer checks, passed, plus four-process hidden-row replication. See BUFFER_NOTES.md.
- Added source ignore rules and GITHUB_SETUP.md. The `source` folder is ready to use as a GitHub repository root; no hosted repository has been created.

## Included from 0.6

- Captures rapid key/controller transitions in order: short taps, double taps and opposite-direction changes survive between simulation ticks. Overlapping primary/alternate controls still count as one held action.
- Polling repairs a missed press/release callback when the current device state is available. Focus loss, Sound settings and controller loss clear pending input, movement charge and early rotation buffers. Held inputs need release before reuse after suspension.
- Local games pause on focus loss, while Sound is open, or if an assigned controller disconnects. Online games continue; suspended local controls remain neutral. A disconnected controller must be reassigned in the lobby; its runtime ID cannot silently reclaim a live board after reconnecting. Use **Back to lobby** as host, or leave and rejoin as a client.
- Fixed one rotation being applied twice on the exact piece-entry tick. Discrete actions pressed during the countdown do not fire at GO; held movement/soft drop can carry through. OS key repeat cannot become a fresh action after refocusing.
- Added **214 input reliability checks**, including an 8,192-event deterministic stress sequence. All **551 checks** and the four-process network test passed. See INPUT_AUDIT.md for reproduced failures, recovery behavior and hardware limits.

## Included from 0.5

- Fixed a reproduced controller soft-drop timing bug: brief releases/re-presses can no longer grant repeated bonus steps and make a finite speed appear instant.
- **Instant soft drop is now a separate toggle.** The slider below ARR stays finite, from 5 to 120 cells/second. Existing saved Instant choices remain explicitly enabled; the default stays 20× gravity.
- Each action now has clearly labeled **Change** and **+ Bind input** buttons. Open Settings, choose the keyboard player or controller, click the action, press your desired input, then Apply & back. All eight actions can be bound individually.
- Invalid soft-drop values no longer fall through to Instant.
- Added a source comparison of official Tetris documentation and TETR.IO: see SOFT_DROP_REFERENCE.md. Their multiplier settings are not interchangeable with fixed cells/second.

## Included from 0.4

- Dedicated **Settings** page, available from the main menu and lobby, with click-to-bind primary and alternate inputs for every action.
- **Soft-drop slider directly below ARR**, both on Settings and in the lobby. Slide through fixed speeds from 5 to 120 cells/second. Instant has its own toggle. **Reset handling** restores the selected input’s default DAS, ARR and soft drop. The former gravity toggle and Standard/Fast presets are removed; moving the soft-drop slider selects a fixed speed.
- Separate saved DAS, ARR, soft drop and bindings for each input profile. Existing 0.3 controls and soft-drop choices are retained, with old global DAS/ARR values used until a profile has its own saved handling.
- Apply & back saves all edited profiles; Cancel discards pending Settings edits. Lobby slider changes save immediately and update existing local player slots for the next round.
- Settings stays open when the online roster changes. A host-started round closes it and uses the last saved settings.

## Included from 0.3

- Remappable controls for Keyboard 1, Keyboard 2, and connected controllers. Each action has a primary and alternate input; buttons, D-pad, stick directions and analog triggers are supported.
- Independent saved soft-drop choices per input profile: **20× gravity (default)**, fixed 5/10/15/20/30/45/60/90/120 cells per second, or Instant.
- Fixed the accumulated-gravity burst: pressing soft drop no longer spends time already accumulated at normal gravity to drop many cells at once.
- Restart sprint can also be remapped, so assigning R to another action no longer triggers the old global restart shortcut.
- Existing player slots pick up saved soft-drop changes in the lobby. Each player's selected speed is carried through online room setup. Versions 0.3–0.6 used network protocol 3. Version 0.7 upgrades to protocol 4 for the expanded field; all participants must update.

## Included from 0.2

- Hold preview on the left; next queue on the right.
- 18 sound effects and an original ambient music loop. The Sound button provides separate effects/music levels; set either to 0 to mute. Volume saves locally.
- 40-line sprint with countdown, elapsed time, locally saved personal best, result screen, and R to retry.
- Independent DAS and ARR sliders from 1 to 10. Higher numbers are faster; 5 is the previous build's baseline and 10 halves both baseline delays.
- Downstack name, T-piece app icon, Windows version information, and separate project-data file.
- Garbage-rule source audit and 81 regression checks. The attack amounts already matched the documented reference values, so those amounts are unchanged.

## Handling

DAS is the wait before a held direction starts repeating. ARR is the interval between repeated horizontal moves. These change movement, not gravity.

| Level | DAS, ms | ARR, ms |
| --- | ---: | ---: |
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

Level 10 gives twice the repeat rate and half the initial repeat wait of level 5. The baseline is the previous prototype's Puyo Puyo Tetris-inspired approximation, not a newly measured frame-perfect PPT timing claim. The simulation runs at 120 Hz. DAS falls on fixed ticks; intermediate ARR values retain their fractional remainder so adjacent slider levels have distinct average repeat rates.

Handling applies per input profile. Select the keyboard or controller before changing values. Lobby sliders save immediately and update that device’s existing local player slot; use Join as player to add a slot or Update player to change its name. **Reset handling** restores level-5 DAS/ARR and default soft drop for the selected input without changing its bindings, name or other profiles. In the lobby it saves immediately; on Settings it updates the draft until Apply & back. The last player name is also saved. The app attempts to import the old Counterfall preferences when no Downstack preferences file exists. Saving new controls or sound settings does not overwrite them with legacy settings.

## 40-line sprint

Choose 40-line sprint, add one player, and start. The clock begins after the three-second countdown and freezes on the piece that reaches or exceeds 40 cleared lines. There is no incoming or outgoing garbage. Both clear and entry delay are zero, with fixed 1-row/second gravity and the normal 500 ms lock delay. Your assigned restart input (R by default on keyboard, Start / Options on gamepad) or the on-screen Restart button starts a fresh bag seed and countdown. A top-out does not replace your best completed time. Best time is stored locally in the game's preferences.

## Local and online rooms

Up to four active players may share one room, with any mix of local and remote players. A computer may own two keyboard players plus gamepad players within that four-player total. Menus use the mouse; keyboard rollover depends on your keyboard.

**LAN:** Open **Network play → Create lobby**. Other computers open **Network play**, enter the host's LAN address and matching UDP port, then select **Join lobby**. A pending connection can be canceled; failed connections keep the address for retry. Add players on each computer. The host starts the round.

**Internet:** Direct connections use the host's reachable address. The host's network must route the selected UDP port (default 42970) to that computer. Firewall permission and router port forwarding may be needed. There is no automatic NAT traversal or relay; carrier-grade NAT may prevent direct hosting.

**Host as viewer:** Leave your player slots empty. Remote players join and add themselves; you can start/end rounds and watch without playing. Remote spectators likewise join without adding a player. A **CURRENTLY SPECTATING** banner appears at the top whenever you have no player slot in an online room, including while watching a match. Adding a local player hides it; removing your last local player restores it. No extra spectator button is needed. The room accepts twelve remote computer connections plus the host, with four active players total.

The host can end a round to return everyone to the lobby. Leaving as host closes the room; there is no host migration. A disconnected player's boards forfeit. Late joiners can watch, then add players in the next lobby. All participants must use this updated protocol 7 build. Earlier clients are rejected before entering the lobby.

## Remapping and soft drop

Open **Settings** in the header, or **Change bindings** in a lobby. Select the input profile on the left. Handling sliders appear below it in this order: DAS, ARR, soft drop. Individual action bindings are on the right. Click **Change** or **+ Bind input** beside any action, then press the desired key, controller button, D-pad direction, trigger, or stick direction. For an analog input, start at neutral, then press/move it deliberately. Keyboard bindings are individual physical keys, not modifier chords.

Reusing an input swaps its previous binding into the edited slot, preventing one input from silently firing two actions. The × buttons clear bindings. Every gameplay action must retain at least one binding before Apply & back is enabled; restart is optional. Apply & back saves all profiles edited on the page and returns to the previous screen. Cancel discards pending controls/handling edits across all profiles; Display changes are saved immediately and remain in effect. Reset this profile restores its default controls, level-5 DAS/ARR, and 20× gravity soft drop; Apply & back commits the reset. Esc cancels capture; outside capture it cancels the page. F11 remains reserved for fullscreen. Shared keys across the two keyboard profiles are flagged because they affect both players if both join.

Settings are local and persist across launches. Keyboard profiles are separate. Controller profiles use the controller's reported model/GUID, with connection order separating identical controllers. A different connection order for identical pads may change which saved profile they use. Controller hotplug updates the selector and cancels any capture. A disconnected controller is blocked for the rest of that round, even if the same runtime ID reconnects. Return to the lobby and explicitly select/add the intended controller before restarting.

The default **20× gravity** setting divides the current normal fall interval by 20. At the sprint's 1 row/second gravity this gives 20 cells/second; in versus it increases with gravity. This follows the historical 2009 guideline reference described in RULES_REFERENCE.md, not a claim of current official certification.

The soft-drop slider gives a predictable minimum descent speed: 5, 10, 15, 20, 30, 45, 60, 90 or 120 cells/second. They never slow a faster normal gravity. The separate Instant soft drop toggle moves the active piece to the floor in one simulation tick and retains the normal lock delay. Holding it does not reset that delay forever. Hard drop still lands and locks immediately at every soft-drop setting. Finite soft drop responds immediately when its cadence permits, then repeats at the selected interval. Brief releases/re-presses cannot exceed that rate. Releasing it returns to normal gravity without a stored-time burst.

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

Incoming garbage gets a full receiver-side warning, default 1000 ms, adjustable 250–3000 ms. Outgoing strength first cancels the oldest queued garbage. Expired garbage rises only on a non-clearing lock, never during an active piece. Line clearing continues to block it. Network travel time is additional to that warning. Every attack produces one aligned, one-cell-wide shaft whose depth equals its final sent value. A base double sends a one-deep shaft, a triple two, and a Tetris four. Combo and B2B bonuses deepen that same shaft. Each packet chooses its hole column independently; cancellation shortens its shaft without changing the column. Three/four-player attacks rotate through surviving opponents.

Normal single/double/triple/quad: 0/1/2/4. Full T-spin single/double/triple: 2/4/6. Mini single/double: 0/1. Combos use TETR.IO's multiplier calculation, rounded down, with its logarithmic minimum for singles. Then add the current B2B count as a flat bonus on qualifying quads and T-spin clears. The first qualifying clear establishes the chain at 0; subsequent ones add 1, 2, 3, and so on. Ordinary single/double/triple clears break B2B; non-clearing placements preserve B2B but end the combo. No surge or extra counterattack delay. Perfect clears retain the existing 10-total override before cancellation. Read RULES_REFERENCE.md for the formula, examples, sources and remaining design choices.

Multiplayer protocol 7 carries the numeric B2B counter and one aligned shaft per attack. All participants must use this updated build; older clients are rejected before lobby admission. Each attack keeps one target, one hole column and one packet identity, including attacks above 20 or 40 rows.

## Limits

This is a guideline-style independent prototype, not an officially certified Tetris game or an exact commercial-game recreation. No matchmaking, friend list, invite codes, automatic port setup, relay, ranked ladder, host migration, replay system, bots, or competitive anti-cheat. Each computer simulates its own boards; the host coordinates routing/results. Input never waits for a remote player, and remote views update at 20 Hz. Real Windows performance, controller behavior, WAN conditions, and exhaustive rotation/top-out edge cases still need playtesting.

## Source and builds

The source folder contains the editable Godot project. Open project.godot with Godot 4.6.3 Standard (no .NET). F5 runs the game. Rebuilding requires matching official export templates. From the source folder:

```text
godot --headless --path . --export-release "Windows Desktop" ../build/Downstack.exe
godot --headless --path . --script tests/core_test.gd
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

For repository setup, use the source folder as the project root and follow GITHUB_SETUP.md. Windows builds belong in Releases.

Project code is supplied under MIT. Godot engine/third-party notices are in licenses. The icon was generated for Downstack; audio was synthesized for this project, with its generation source included.
