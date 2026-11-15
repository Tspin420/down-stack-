# Downstack 0.9.0 — 14 November 2026

VSync is explicitly disabled and rendering has no FPS cap. Gameplay remains on
the independent 120 Hz physics loop; remote snapshots remain 20 Hz. Added a
versioned Windows ZIP builder, source-commit metadata, SHA-256 checksum and a
Windows release workflow that runs regression tests and exported-game startup
before publishing.

Launch now opens a focused Play menu with Local match, 40-line sprint and
Network play. The T icon replaces the engine splash; saved fullscreen is applied
before the menu is built, with no extra press-to-start step. Host/join fields
move to a dedicated Network page with cancellable connections. The lobby uses
four player cards, Edit/Remove actions, a separate player setup panel, and
Start/Match rules controls. Keyboard and controller focus work through menus,
settings and results; gameplay releases focus to protect hard-drop inputs.

Menus now use neon pink, blue and green borders on a dark violet palette.
Removed the gravity toggle and Standard/Fast presets; Reset handling restores
only the selected input’s DAS, ARR and soft drop. Online rooms automatically
show CURRENTLY SPECTATING when no local player slot is present, including in
the match view. No additional role-selection button is needed.

DAS, ARR and soft drop now share identical 0–10 sliders and numeric readouts.
Zero selects the existing default on every control; Reset handling returns all
three to zero. Custom 1–10 DAS/ARR speeds and saved soft-drop rates are retained;
a 75 cells/second choice fills the tenth finite soft-drop position. Instant stays
an explicit toggle and turning it off restores the selected slider position.
Normal gravity now follows the documented level 1–15 curve,
replacing the gentler custom curve and 40 ms minimum interval. Versus advances
every ten lines and holds at level 15 for continuing matches. Sprint stays at
starting gravity. Default soft drop at zero runs at 20× that gravity. The separate
Instant option reaches the floor immediately and retains lock delay. Ninety new
gravity checks cover the curve, fast ticks, level boundaries, Sprint, release,
default and Instant lock delay, and the versus cap.
Exact timing parity with other games remains unverified.

Enlarged and centered Hold/Next previews, shifted the playfield right, and added
the nonlinear incoming-garbage meter with separate amount and urgency cues.
Blocks use a shared beveled tile, and adjacent cleared rows form one continuous
fading band. Renderer caches avoid repeated style and piece-cell construction.

Combos use the documented multiplier and logarithmic minimum, followed by a growing
flat B2B bonus. Each attack retains one shaft with depth equal to the sent value;
combo/B2B bonuses deepen that same shaft. One-for-one cancellation and blocking
on every clearing placement remain, with no surge or extra counterattack delay.
Large attacks now reach their intended receiver intact instead of being dropped
by the former 20-row router and 40-row receiver cutoffs. Perfect clears remain
10 total before cancellation.

Multiplayer protocol 8 requires the updated gravity curve and retains numeric
B2B state and the expanded attack range. All players and spectators need the
updated build. All 1117 automated checks and
the five-process multiplayer test passed on Linux/Godot 4.6.3, including old-client
rejection. Resource export and startup passed; physical Windows/controller playtesting and frame-pacing
validation remain pending. The Windows release workflow separately runs the
regression suites and an exported-executable headless startup before publication. See RULES_REFERENCE.md and VALIDATION.md.

# Downstack 0.8.0

Added a visible Fullscreen/Windowed button and an immediately saved Display selection in Settings. F11 is handled before gameplay and key capture, including popup windows; echoes and releases do not retoggle. Startup restores the display preference. Fullscreen uses borderless mode with an expanding layout, and returning to windowed mode restores the previous bounds or maximized state. Sound and popup dialogs are embedded so they stay with the game.

Added Windows Create desktop shortcut in Settings and a generated double-click Create Desktop Shortcut.cmd helper. Both use the same PowerShell source with the target passed as data, the actual per-user Desktop directory, the EXE’s embedded icon, and the extracted game’s working directory. Existing Downstack links update; other same-name application links are preserved. No administrator access or security-policy changes. Shortcut errors are displayed instead of claiming success.

665 automated checks and four-process networking pass. New coverage includes reserved-key routing, Settings capture, dialog forwarding, repeats, persistence/relaunch, unrelated settings, gameplay isolation, script inclusion, and path quoting. Fixed a nondeterministic test fixture: the custom-R rotation assertion could randomly spawn an O, whose rotation index stays zero by design; it now uses a T. Native Linux fullscreen transitions and Settings/Sound layout were checked. Windows COM shortcut execution remains untested here. Network protocol remains 4, compatible with 0.7. The Windows build remains unsigned.

# Downstack 0.7.0

Expanded the stored field from 22 rows to 40: 20 visible rows plus a 20-row hidden buffer. Reproduced and fixed a partial-above I-piece lock that fitted and rotated legally but lost its upper cell and incorrectly topped out. Hidden cells now participate in collision, clearing and garbage movement. Fully hidden locks, blocked spawns and genuine overflow retain their game-over behavior; spawn height relative to the skyline and the visible floor are unchanged.

Rendering and snapshots use the shared field dimensions. Multiplayer protocol is now 4; every player and spectator must update to 0.7. All 640 checks pass, including 89 new buffer cases. Four-process networking verifies hidden and floor cells at host and spectator. The network test harness now catches explicit failure messages and validates snapshots before the host disconnects.

Added source ignore rules, GITHUB_SETUP.md and BUFFER_NOTES.md. Source is prepared for a repository; GitHub authentication/creation was not performed. Windows build remains unsigned and has not been run on Windows hardware here.

# Downstack 0.6.0

Fixed reproduced input loss: a complete tap between physics ticks was missed; a release/repress could merge into one press; opposite directions pressed in the same tick favored left instead of the last input. A bounded per-device event queue now retains delivered transition order, with current-state polling as a fallback. Primary/alternate bindings aggregate into one action. Timers advance once per simulation tick regardless of event count; DAS/ARR and finite soft-drop cadence are retained.

Fixed double rotation on the piece-entry boundary and held hard-drop leakage when closing Sound. Focus/menu transitions flush pending actions and require held controls to release before reuse, including orphan OS repeat events. Local play pauses on focus loss, Sound and controller disconnection; online play continues with affected controls neutral. Reconnecting a controller cannot silently reclaim a live board; reassign it in the lobby. Countdown and new-round transitions discard stale discrete actions.

All 551 automated checks passed, including 214 new audit checks and an 8,192-event deterministic stress run, plus four-process loopback multiplayer. INPUT_AUDIT.md records reproduced failures and remaining hardware limits. Network protocol remains 3. Windows/controller hardware execution is not verified; the Windows build remains unsigned.

# Downstack 0.5.0

Fixed a reproduced controller soft-drop bug. Brief release/repress events previously restarted the immediate-step bonus, so a finite soft-drop setting could race to the floor without locking. A separate cadence timer now survives brief releases, while idle/grounded time cannot accumulate a burst. The steady fall rate is retained. Invalid negative/nonnumeric rates no longer select Instant.

Moved Instant soft drop to an explicit toggle; the slider directly below ARR now ends at a finite 120 cells/second. Existing saved choices are preserved. Individual bindings now visibly say Change or + Bind input, and the lobby links directly to Rebind each key / button.

Added SOFT_DROP_REFERENCE.md, cross-checking historical rules references, public settings, manuals and gameplay guides. The research citations are retained in docs/RESEARCH_SOURCES.md. Keeps the distinction between 20× gravity, fixed cells/second and explicit Instant. Exact commercial-game numeric timing is not claimed where it could not be verified.

All 337 automated checks passed, including 48 new controller-drop checks and 38 settings checks, plus four-process loopback multiplayer. Controller input was simulated; actual Windows/controller hardware is not available here. Network protocol remains 3. The Windows build is unsigned.

# Downstack 0.4.0

Replaced the controls popup with a dedicated Settings page reachable from home and lobby. Every gameplay action and sprint restart has independent primary and alternate binding buttons. Apply & back saves all edited profiles; Cancel discards them. The page stays open during roster updates and closes cleanly when the host starts or closes the room.

Added a soft-drop slider immediately below ARR, on both Settings and the lobby. Fixed-speed steps are 5/10/15/20/30/45/60/90/120 cells per second, followed by Instant. A separate 20× gravity default toggle retains the previous gravity-scaled option. Soft-drop physics are unchanged.

DAS/ARR now save per input profile alongside soft drop and bindings, with migration from the previous global handling values. Lobby changes update existing local slots immediately for the next round. Preference writes leave live profiles unchanged if saving fails. Existing volume preferences and sprint records are retained.

Added 35 settings/navigation/migration checks; all 286 automated checks and the four-process network test passed. Network protocol remains 3, shared with 0.3. The Windows build remains unsigned.

# Downstack 0.3.0

Added per-input-profile remapping with primary/alternate bindings for keyboard keys, controller buttons, D-pad, triggers and stick directions. Added capture cancellation, neutral-axis gating, duplicate-binding swaps, missing-essential-action validation, shared-key warnings, saved profiles and reset. Controller polling uses hysteresis to avoid repeated presses around the analog threshold. Restart sprint is now an ordinary remappable action rather than a hardcoded R shortcut.

Added default 20× gravity soft drop, fixed 5–120 cells/second choices, and Instant. Fixed accumulated normal-gravity time causing a multi-row burst when soft drop is pressed. Instant soft drop keeps lock delay; hard drop still locks immediately. Settings apply per player in local and network matches. Lobby settings scroll to remain accessible at the default window size.

Preserves sound settings and sprint records when loading/saving input profiles. Network protocol is now 3; all peers need version 0.3. Added 67 input/soft-drop checks and extended four-process networking checks for distinct per-player rates. The Windows build remains unsigned.

# Downstack 0.2.0

Renamed Counterfall to Downstack. Added a T-piece app/Windows icon and product version metadata; Windows now loads Downstack.pck alongside Downstack.exe.

Moved hold to the left. Added 18 synthesized sound effects, ambient music, and independent saved volume controls. Added single-player 40-line sprint, countdown, timer, personal best, completion/top-out result, and retry.

Replaced raw DAS/ARR UI with independent 1–10 sliders. Level 5 retains the prior baseline; level 10 halves its wait and repeat interval. Fractional ARR accumulation preserves distinct intermediate speed levels. Migrates prior handling preferences where available.

Documented historical attack-table references, distinctions from custom garbage behavior, and verification limits. Attack amounts remain unchanged. Added 81 garbage and 62 feature checks alongside the existing 41 core checks and four-process network integration. Network protocol incremented to 2; all players need this version.

The Windows release remains unsigned. Trusted-publisher status is not established by these packaging changes.
