# Validation — Downstack review updates

## Menu, lobby and launch review — 14 November 2026

Review base: `cef3335d18998966c6dae2c0ee74bcd9d078f874` (`main`).

Launch opens the Play menu directly, applies the saved fullscreen preference
before building controls, and uses Downstack's existing T icon as the engine
loading splash. Local match, Sprint and Network play lead to separate setup
screens. Host/join controls retain direct address/UDP-port networking; pending
connections can be canceled and failed attempts keep their address for retry.

The lobby has four player cards (one in Sprint), local Edit/Remove actions,
per-input handling, host-only Start and Match rules, a scrolling player editor,
and a waiting message for clients. Existing player settings and game rules are
preserved. Settings returns to the screen it was opened from. Keyboard focus,
D-pad navigation and A/B menu actions work independently of gameplay bindings.
Starting a match releases focus and disables header keyboard focus; result
buttons regain it after a round. Menu artwork is static and shares the existing
beveled tile. Neon pink is the primary accent, with blue and green mode badges
and player-card borders on dark violet panels. The existing app icon is retained.
Gameplay, simulation timing and protocol 7 are unchanged.

The gravity/default toggle and Standard/Fast buttons are removed. Reset handling
restores only the selected input’s DAS, ARR and default soft drop; bindings and
other profiles remain intact. Lobby resets save immediately and update the
joined player, while Settings resets remain a cancellable draft. Existing saved
default, finite and Instant soft-drop behavior is retained.

DAS, ARR and soft drop share the same 0–10 track and numeric readout; 0 selects
the existing default on each control. Custom speeds keep their previous values,
with an added 75 cells/second finite step. Reset handling puts all three at 0.
The default remains PPT-inspired; exact PPT soft-drop timing is not newly verified.
Online rooms show a CURRENTLY SPECTATING banner whenever the local computer owns no player slots,
in the lobby, its Settings page and the match. No extra role selector is added.

### Verification

Godot **4.6.3.stable.official.7d41c59c4**, Linux, with isolated preferences.

- All **969 non-menu assertions** passed, including settings persistence,
  fullscreen restoration, input stress, controller disconnection and rendering.
  Six additional settings checks cover Reset handling, persistence, draft
  cancellation and preservation of custom bindings and other profiles.
  The slider follow-up adds 40 checks for default timing, shared slider layout,
  zero/default versus Instant, every saved soft-drop rate through the UI, and 75 cells/second cadence.
- **53 menu assertions** passed: keyboard/D-pad/A/B navigation, page focus,
  Settings return, empty address, cancellation and failure, roster add/edit/remove,
  independent handling, full-lobby behavior, remote slot ownership, host/client
  controls, Sprint setup, Start, hard-drop isolation, results and best-time refresh.
  Ten additional checks cover spectator hosts/clients, adding/removing multiple
  local players, Settings, match entry and clearing the banner on leaving.
  **1022 total assertions, 0 failures.**
- Five-process loopback multiplayer passed: four compatible participants and
  deliberate rejection of a protocol 6 client.
- Actual Compatibility-rendered menu, Network, local lobby, expanded rules,
  Settings and Sprint screens were inspected. Spectator lobby and match captures
  include the automatic banner. Main menu, local lobby and spectator lobby were also
  checked at **960 × 600**, with the default captures at **1280 × 800**.
  Native Enter-to-lobby, mouse Join and Enter-to-match were exercised.
- Windows-preset resource export and a 120-frame Linux headless PCK startup
  passed. New GDScript UIDs are included and `git diff --check` is clean.

`tools/menu_capture.gd` reproduces the screenshots using actual controls; run it
with isolated preferences because it saves sample player setup. These captures
use Mesa software rendering and are **not a frame-pacing benchmark**. Controller
button events were simulated; physical Windows/controller testing and a Windows
executable release remain pending.

## Approved garbage rules update — 14 November 2026

Source update based on `ad71b2c8cfd37f3035edf4ee27959fb9b32fafe2`, including
the approved playfield visuals and garbage rules. This validation covers the
source update; a Windows release has not been validated. The historical visual section
below records that earlier proposal's scope; its statements about unchanged
gameplay and protocol do not describe this subsequent rules update.

### Implemented behavior

- TETR.IO combo multiplier and logarithmic minimum, rounded down, followed by
  the user's growing flat B2B bonus. No B2B surge or multiplication of that bonus.
- One-for-one FIFO cancellation and blocking on every clearing placement,
  including zero-attack singles. A non-clearing lock admits ready garbage.
  Cancellation never resets or extends a packet's warning time.
- Numeric B2B state: first qualifying clear establishes the chain at 0; later
  qualifying clears add 1, 2, 3, and so on. Ordinary clears break the chain;
  non-clearing placements preserve it and end the combo.
- Every attack retains one packet, hole column and target. Its shaft depth equals
  its final sent value, including combo and B2B contributions. Separate attacks
  choose independent columns. Cancellation reduces the depth without changing
  the column or deadline. No size threshold or within-attack hole changes apply.
- Removed the old 20-row router and 40-row receiver cutoffs; board insertion work
  is bounded by the 40-row playfield even for an extreme overflow packet.
- Protocol 7 validates and replicates the numeric counter and one amount/hole
  pair per packet. Earlier clients are rejected before entering the lobby.

The exact formula, indexing, examples and research references are documented in
`RULES_REFERENCE.md`. Perfect clears still override attack to 10, warning time
remains 1000 ms by default, and all ready packets may rise on a non-clear.

### Verification performed on this update

Godot **4.6.3.stable.official.7d41c59c4**, Linux. Preference-writing tests used
isolated temporary user-data directories.

| Check | Result |
| --- | --- |
| Core / garbage / feature tests | 41 / 230 / 65 checks passed |
| Input / settings / controller-drop tests | 67 / 38 / 48 checks passed |
| Input audit / hidden buffer / desktop tests | 214 / 89 / 25 checks passed |
| Existing visual, preview and nonlinear-meter regressions | 106 checks passed |
| Total automated assertions | **923 passed, 0 failures** |
| Five-process loopback integration | Four compatible participants passed; old-protocol client rejected |
| Windows-preset PCK export | Passed |
| Exported PCK loaded in Linux Godot, headless, 120 frames | Passed; no errors |

The garbage tests include a continuous, legal two-wide field with six doubles
followed by two quads: attacks `1,1,1,1,2,2,10,12`, without resetting the field.
They verify the agreed T-spin examples (B2B 3 = 7, B2B 4 = 8, and combo index 4
with B2B 4 = 12), single-only combo rounding, chain preservation/breaking,
zero-attack blocking, exact partial cancellation, unchanged deadlines, FIFO
cancellation across ready and travelling packets, and extreme-packet overflow.
Additional checks follow actual doubles, triples, quads and boosted T-spin
clears through routing and into receiver grids, verifying exact 1-, 2-, 4-, 8-
and 12-deep aligned shafts. They cover sender cancellation, separate shafts
rising together, FIFO partial cancellation without moving the hole, old per-row
pattern rejection, and a maximum 128-packet queue within the wire-size limits.
The feature tests also exercise the application's actual garbage signal handler
with short and long shafts and an unrelated remote-board target.

The network integration sends actual board-generated 1-, 2-, 4-, 24- and 55-row
attacks through a spectator host to two boards owned by one remote player.
Each arrives intact as one packet at its intended board. The host and another
spectator observe both queues, their exact amounts and hole columns, the full
hidden buffer and numeric B2B counts. A fifth process deliberately uses protocol 6
and is disconnected before lobby admission. This is a loopback test, not an
Internet latency or relay test.

No Windows executable was run. The PCK export and Linux smoke test establish
resource/script packaging and startup, not Windows driver behavior or frame
pacing. Human two-wide/four-wide balance testing remains necessary.

## Historical playfield visual proposal — 14 November 2026

Review base: `ad71b2c8cfd37f3035edf4ee27959fb9b32fafe2` (`main`).
Originally prepared on `visual/playfield-prototype` and subsequently approved
for inclusion in this source update. The following records the renderer's scope.

### Exact scope

- `scripts/board_view.gd`: use one preloaded, tinted tile for settled blocks,
  active pieces, hold and next previews; retain the existing piece palette and
  occupied cells. Increase ghost outline contrast and add a faint interior.
  Add an inset frame, quieter grid and short ownership-colored corner accents.
- Enlarge and center the hold and five-piece Up Next previews in inset panels,
  centering occupied cells rather than each piece's padded rotation box.
  Shift the playfield right to reserve a separate garbage-meter lane. At panel
  widths 490 / 410 / 320 px, preview cells are 18 / 15 / 12 px (formerly 10),
  and the well starts at x = 112 / 100 / 88 px (formerly 68). At 490 × 730,
  the board's 27.5 px cell size is retained. Narrow layouts trade some board
  width for larger previews; their 20-row board and all five next pieces fit.
- Replace the thin garbage strip with a framed, bottom-up meter: one segment
  per queued row, yellow while delayed, orange in the final 250 ms, red when
  ready. This 250 ms threshold only controls the presentation color. The
  existing packet countdown, cancellation and arrival rules are untouched.
  The meter draws at most 20 segments; overflow is labeled beside it and the
  footer retains the full total. Sprint hides the meter. Waiting and round
  transitions clear its state. Frozen remote snapshots do not invent countdowns.
- Use an accelerating nonlinear amount scale: `height = (min(rows,20)/20)^1.5`.
  Four rows fill about 9%, eight 25%, twelve 46%, sixteen 72%, and twenty 100%.
  Each incoming row still owns one segment, but those segments grow in height
  toward the top. Exact row counts and packet timing colors remain independent
  of this scale. One-row warnings stay visible at every supported layout size.
- `assets/block_tile.svg` and its import settings: original 64 × 64 grayscale
  artwork with a raised face, four bevels, clipped corners and restrained edge
  highlights. Godot imports this once; no SVG rasterization occurs in `_draw`.
  No commercial artwork is included or traced.
- Replace the static row flash with a 110 ms fading, continuous filled band and
  bright top/bottom edges. Adjacent cleared rows merge into one full-height band:
  a quad stays four rows tall throughout its fade, with no internal stripes.
  Nonadjacent clear groups stay separate. Presentation time is local
  to each view. Repeated snapshots of the same clear do not restart the effect;
  consecutive clears, round resets, waiting states and frozen terminal snapshots
  are handled. Network schema and clear/entry timing are unchanged.
- Cache panel styles and every piece rotation once per script. Invalidate on
  new snapshot, player/ownership changes, normal Control resize, or clear
  animation. Stop `_process` after the effect ends. Reassignment of the same
  remote snapshot object does not invalidate the drawing. Callers should replace
  snapshots rather than mutate `view.data` in place, as the existing main loop does.
- `tests/visual_test.gd`: presentation and redraw regression coverage.
- `tools/capture_visuals.py` and `tools/visual_capture.gd`: reproducible actual
  Godot before/after captures, including the original renderer loaded from the
  exact baseline commit. Fixtures freeze time deliberately; they are not an FPS
  benchmark. Generated `.uid` files accompany the new GDScript files.

No changes to `board.gd`, `main.gd`, input/handling/settings scripts,
`session.gd`, `project.godot`, audio, or export presets. Gameplay, independent
per-player handling, 120 Hz simulation, GL Compatibility and multiplayer
protocol remain as before.

### Verification performed on this proposal

Godot **4.6.3.stable.official.7d41c59c4**, Linux.

| Check | Result |
| --- | --- |
| Existing core / garbage / feature tests | 41 / 81 / 62 checks passed |
| Existing input / settings / controller-drop tests | 67 / 38 / 48 checks passed |
| Existing input audit / hidden buffer / desktop tests | 214 / 89 / 25 checks passed |
| New presentation regressions | 65 checks passed |
| Additional layout / preview / garbage-meter regressions | 33 checks passed |
| Additional nonlinear meter regressions | 8 checks passed |
| Total automated assertions | **771 passed, 0 failures** |
| Four-process loopback integration | Host, two-local-board player, remote player and spectator all passed |
| Resource import / script parsing | Passed |
| Windows-preset PCK export | Passed; includes imported tile texture |
| Exported PCK loaded in Linux Godot, headless, 120 frames | Passed; no errors |
| Before/after, garbage, clear-phase and three/four-player captures | Passed in real Compatibility rendering |
| Patch whitespace and application to the baseline | Checked during review packaging |

The original 665 checks and network integration were also run successfully on
the untouched baseline before implementation. Tests that write preferences used
isolated temporary user-data directories.

The original 65 presentation checks cover all 28 piece/rotation combinations, draw invalidation
and idle caching, 480 input/presentation ticks compared with a separate seeded
simulation across round resets, snapshot immutability, wire-schema validity,
duplicate/new/frozen clear events, long frame deltas, independent views,
waiting/round reset behavior, and draw paths at all three existing panel widths
with hidden cells, ghost, hold/next, garbage, completion and top-out. Band coverage
also verifies single/double/triple/quad merging, uncleared gaps, unsorted/duplicate
rows without snapshot mutation, empty clears, and clipping at the hidden buffer
and field boundaries.

The 33 additional checks cover layout containment and meter/frame separation
at 320 / 410 / 490 px widths and 480 / 650 / 730 px heights, larger previews,
the retained large-panel board size, occupied-cell centering for all seven
pieces, and actual engine packet receive/countdown/partial cancellation/arrival.
They also cover complete cancellation, independent boards, sprint/waiting reset,
frozen snapshot immutability, and a maximum 128-packet, 5,120-row network queue
with an exact total and a bounded 20-slot display buffer.

Eight nonlinear-meter checks cover empty/full endpoints, strictly increasing
height, accelerating row increments, one-row visibility at all three panel
widths, independent urgency color changes, and height/count reduction after
queue cancellation. All 106 visual checks and the existing 665 checks passed
again after this revision, as did the four-process multiplayer test.

Visual inspection: identical-state comparisons against both the repository
baseline and the previous visual proposal at 490 px panel width; mixed urgency
and 24-row overflow queues; actual post-quad states at 0, 55 and 120 ms; four
320 px panels including completion and top-out; three short 410 × 530 px panels;
equal-height meter samples with 1 / 4 / 8 / 12 / 16 / 20 incoming rows.
Bevels, centered previews, ghost, meter and board boundaries remained readable.
Captures use **Mesa llvmpipe software OpenGL 4.5**; the driver reported
that changing V-Sync mode is unsupported. These images verify appearance only.

### Performance interpretation and remaining Windows work

Source-level changes remove per-redraw StyleBox construction and calls that
allocate piece-cell arrays. A solid block now submits one textured rectangle
instead of three rectangles. The shared tile has a nominal 16 KiB RGBA8 pixel
payload before driver overhead. A clear submits three primitives per contiguous
visible group. A small sorted row copy and merged spans are built once per clear,
never per animation frame. Preview bounds and panel styles are shared; layout
geometry updates only on resize. The meter uses one reusable 20-byte state
buffer per view, refreshed from received snapshots, and draws at most 20
segments regardless of total garbage. Its 21 normalized height boundaries are
precomputed once and shared; snapshots and redraws do not evaluate the power
curve or allocate a replacement array. There are no particles, tweens,
custom shaders, blur, bloom, dynamic lights or offscreen render targets in the
game renderer.

This is **not a zero-allocation renderer or a measured speedup**. Existing text
formatting, snapshot construction/deep copies, network serialization and the
rest of the game remain. The frame adds a small fixed number of primitives;
the ghost adds a translucent fill. Actual GPU draw calls depend on Godot batching.

No Windows executable was run and no Windows presented-frame timing was
measured. The PCK smoke test ran in the Linux editor executable; it does not
establish Windows launch, driver compatibility, input latency or frame pacing.
The 120 Hz simulation setting is unchanged and is not an FPS measurement.

Before calling the prototype stutter-free, compare baseline and proposal on
the same Windows PC, resolution, refresh rate and V-Sync settings. Record
presented-frame times during ordinary movement and repeated single/quad clears,
with one and four boards. Include first-use and warmed-up runs. Compare p95,
p99, maximum frame time and over-budget frames around clears, keeping the raw
timing traces. Visual approval can precede that hardware validation.

### Reproduce

From the project directory with Godot 4.6.3 on PATH:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/visual_test.gd
python3 tests/run_network_tests.py
python3 tools/capture_visuals.py --output build/visual-review
godot --headless --path . --export-pack "Windows Desktop" build/Downstack-visual.pck
godot --headless --main-pack build/Downstack-visual.pck --quit-after 120
```

The capture command requires a desktop display and the baseline commit in
local git history; `--headless` cannot produce pixels. It automatically removes
its temporary baseline script. `GODOT_BIN` selects a different engine path for
the Python tools. Run the nine older GDScript suites listed below as well; use
isolated user-data directories for tests that write preferences.

To compare an earlier local renderer instead of the repository baseline, add
`--baseline-file /path/to/previous_board_view.gd` to the capture command.

Visual convention reference: Nintendo's [Tetris 99 tips](https://www.nintendo.com/en-gb/News/2019/March/Boost-your-block-dropping-abilities-with-our-TETRIS-99-tips--1526705.html)
describe a left-side incoming meter with one block per garbage row. The artwork
here is original, and Downstack's existing timing/cancellation rules are used;
this is not an attempt to reproduce Tetris 99's complete attack system.

---

Built and checked 12 November 2026 with Godot 4.6.3 Standard and the matching official export templates. The template archive's SHA-512 matched the checksum published with the official release.

## Passed

- **665 automated checks, zero failures:** 41 core checks, 81 attack/garbage checks, 62 earlier-feature checks, 67 input/soft-drop checks, 38 settings-page checks, 48 controller-drop checks, 214 rapid-input/loss checks, 89 buffer checks, and 25 desktop/display checks. Core coverage includes seeded bags, entry, hold restrictions, selected SRS wall kicks, DAS/ARR boundaries, warning/cancellation, row compaction, spin recognition, rotation buffering, hard-drop release, lock reset limits, player ownership and snapshot validation. Garbage coverage includes all base clear amounts, back-to-back, long combos, perfect-clear totals, and cancellation. Feature coverage includes all ten handling levels, sprint success/overshoot/failure/timer freeze, no sprint garbage, countdown exclusion, personal best, retry, audio loading and playback state, and separate volume controls.
- **Input/soft-drop coverage:** independent keyboard profiles, saved key and trigger bindings, safe defaults for invalid profiles, reserved keys, duplicate swaps, neutral-axis capture, device isolation, analog hysteresis, fixed rates, 20× gravity scaling, press/release clock transitions, Instant lock delay, hard-drop independence, Settings Apply/Cancel validation, player-slot updates, and remapped sprint restart without held-button retriggers. Controller events were synthesized in a headless engine; no physical controller was available.
- **Four-process loopback network integration:** spectator host, two boards owned by one player process, another remote board, and a separate spectator. All four passed roster, board-state, attack-routing, warning checks, full 40-row replication including specific hidden/floor cells at the host and remote spectator before disconnection, and replication of different per-player soft-drop settings (5 cells/sec, Instant, and 20× gravity). This is four processes on one machine, not four physical computers or a WAN test.
- **Settings/navigation coverage:** dedicated page from home/lobby; one primary and alternate input per action; actual input-event capture; soft-drop slider placement; fixed, Instant and default modes; independent profiles; pending edits across device switches; save/reload; Cancel and Reset behavior; preservation of prior bindings, handling, audio and sprint records; existing player-slot updates; roster updates while editing; automatic dismissal on host start/room close; no capture while hidden.
- **Controller-drop regression:** reproduced 0.4 with intermittent simulated stick input at 20 cells/second: 20 rows in 400 ms without locking, versus 9 with a steady hold. The repaired build moves 8 with the intermittent input and still 9 with a steady hold. Tests cover stick/D-pad release/repress, all nine finite rates and fractional timing, analog pressure, simultaneous alternate inputs, release/new-piece transitions, finite and instant lock delay, separate hard drop, and invalid-rate fallback.
- **Input reliability audit:** reproduced dropped sub-tick taps, merged release/repress, wrong opposite-direction priority, double rotation at entry, and held hard drop leaking from Sound in 0.5. Added 214 checks covering ordered events, alias aggregation, 8,192 deterministic stress events, polling repair, OS repeat, analog hysteresis, all finite soft-drop rates, unchanged DAS/ARR movement ticks, timer integrity, bounded queue overflow, focus/menu/countdown/restart guards, and simulated controller disconnect/reused-ID protection. Focus and hotplug tests use injected events/signals; they are not physical-device tests. See INPUT_AUDIT.md.
- **Hidden-buffer coverage:** all seven spawn heights, 40 I-piece quarter-turn cases across five above-board heights, a forced fifth SRS kick with three hidden cells, partial/full hidden locks, spawn collision, hidden-cell collision and reappearance after clearing, garbage push/true overflow, finite top/floor bounds, ghost/hard drop/hold, full snapshot compression and old-layout rejection. The 0.6 reproduction fitted the I but killed the player on a partial-above lock; the new build retains its cells and allows the next piece to spawn. See BUFFER_NOTES.md.
- **Native Linux UI inspection:** fullscreen filled the 1364×1024 test desktop after restoring its saved preference, without letterboxing or stretching the layout. F11 during active key capture returned to the prior 1280×800 position/size while keeping capture active; F11 returned to fullscreen. Settings controls were readable in both sizes (the smaller window scrolls the binding list). The embedded Sound dialog remained visible and F11 switched to windowed mode from that dialog. The test desktop required its standard window manager to be running before fullscreen could resize; this is an environment detail, not a claimed Windows bug. The earlier four-board buffer-layout inspection remains documented in BUFFER_NOTES.md.
- **Desktop/display regression coverage:** 25 new checks verify header and Settings synchronization, immediate persistence without losing sound/records, reload, F11 ordering before binding capture/text fields, echo/release filtering, Sound/dropdown forwarding, gameplay isolation, raw shortcut-resource availability, path escaping and editor/platform gating. The existing input test’s random O-piece false failure was replaced with a deterministic T fixture.
- **Windows shortcut review:** one PowerShell source is packaged for the in-game button and used to generate the CMD helper. Paths are passed as data, with apostrophes escaped for the direct command and an environment value for the CMD helper. The script resolves DesktopDirectory, checks EXE/PCK, preserves a different application’s same-name link, writes target/working directory/icon, and reads back target/working directory before reporting success. No execution-policy bypass, elevation, or antivirus exceptions. This is source/package validation; Windows Script Host COM was not executed on Linux.
- **Audio assets:** all 18 effects plus one music loop are valid non-silent mono 44.1 kHz/16-bit PCM, with no clipped samples. Godot loads the streams and starts effect playback; separate volume settings are tested. The Linux desktop has no audio device, so audible playback was not assessed. Headless processes intentionally skip music autoplay.
- **Windows x64 release export:** completed with no script errors or export warnings. PE32+ x86-64 format, Downstack product name, version 0.8.0.0, six embedded icon sizes, and a separate valid PCK were inspected. Both EXE and PCK are required. There is no Authenticode signature.
- **Linux exported-resource smoke test:** matching Linux release loaded the exported project headlessly and exited cleanly after 120 frames with no errors or warnings. This validates resource loading, not Windows execution.
- **Distribution:** complete editable source, repository ignore rules/setup notes, original audio-generation script, icon, licenses, documentation and hashes included. ZIP CRC and file hashes checked during packaging.

## Not verified

Actual Windows launch, Windows desktop-shortcut creation/launch, Windows fullscreen/multimonitor/high-DPI behavior, Windows audio output, GPU/display scaling, antivirus/reputation behavior, or frame pacing. No claim that the unknown-publisher warning is fixed. No target-PC measurement of line-clear stutter.

Physical controllers, keyboard rollover, real OS focus transfer, physical hotplug behavior, WAN/router/NAT behavior, variable latency/loss, malicious clients, long-duration play, exhaustive SRS/top-out edge cases, and exact commercial-game timing are not tested here.

The garbage reference audit compares documented values and community code. It is not an official SEGA specification or a direct measurement of the commercial game. See RULES_REFERENCE.md and SOFT_DROP_REFERENCE.md.

## Architecture and reproduction

Protocol 4 carries the full 40-row board, including the 20-row hidden buffer. Every participant must use protocol 4 (0.7 or 0.8); protocol 3 builds are incompatible. Gameplay uses a 120 Hz local simulation with ordered per-device input transitions and polling reconciliation; remote board snapshots update at 20 Hz. Discrete events do not add simulation time. Local simulation pauses on focus loss, Sound or assigned-controller disconnection; online simulation continues with suspended controls neutral. Reliable messages carry lobby changes, attacks and transitions. Each participant owns its own board simulation; the host coordinates routing and results. This is a private-match prototype, not a competitive anti-cheat system. Garbage's full warning starts on receipt; network travel is additional.

Run tests/core_test.gd, tests/garbage_test.gd, tests/update_test.gd, tests/input_test.gd, tests/settings_test.gd, tests/controller_drop_test.gd, tests/input_audit_test.gd tests/buffer_test.gd and tests/desktop_test.gd with Godot's --headless --script options. Use an isolated user-data directory for the update/input/settings/input-audit/desktop tests, which write test preferences and a personal best. tests/run_network_tests.py starts and cleans up four Godot processes on loopback UDP 43971. Set GODOT_BIN if needed. See README.md for full commands.

BUILD_MANIFEST.json records included files' SHA-256 hashes and build inputs. SHA256SUMS.txt covers the distributed files including that manifest. Neither a checksum nor an icon establishes a trusted Windows publisher.
