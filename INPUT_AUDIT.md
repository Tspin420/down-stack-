# Input reliability audit — Downstack 0.6

Audited 12 November 2026. Compared the delivered 0.5 source with this update using Godot 4.6.3. Tests inject keyboard/controller events, exercise the actual gameplay event handler, and step the same board code used by the game. These are software tests, not a physical-controller certification.

## Reproduced failures and repairs

| Scenario | Observed in 0.5 | Behavior in 0.6 |
| --- | --- | --- |
| Complete rotation tap between 120 Hz ticks | Zero rotations | One rotation |
| Release/repress between ticks | One observed rotation after three total taps in the reproduction | Three rotations |
| Left followed by right before one tick | Left won | Right wins; reversing the sequence makes left win |
| Rotation pressed on the tick entry finishes | Two rotations from one press | One rotation; the entry buffer is consumed |
| Hold hard drop while Sound is open, then close it | A piece immediately locked on closing | Held input stays blocked until release and a fresh press |
| Deliver input after the window's focus-exit signal | Movement continued and local sprint time advanced | Local simulation pauses and input is cleared |

The focus reproduction explicitly emits the window signal. The desktop automation could not transfer real window focus reliably, so focus loss/recovery is verified by signal injection, not an actual Alt-Tab test. It is not evidence of how every Windows driver handles lost key-up events.

## Recovery rules

- Record per-device mask transitions as events arrive, without render-frame input accumulation. A complete tap no longer has to overlap a simulation tick. Movement, rotation, hold and hard drop retain their delivered ordering.
- Reconcile with current keyboard/controller state each tick. A missed release callback clears the held action if the engine knows it is released; a still-held press missed by the callback can likewise be recovered. Polling cannot infer the order of entirely missing transitions.
- Primary and alternate bindings are ORed. Switching between two held aliases does not add another rotation or hold. Analog activation uses 55% and release uses 35% to prevent threshold chatter.
- Event processing adds no extra elapsed, gravity, lock or garbage-warning time. Brief soft-drop releases/represses still cannot exceed the selected finite rate. DAS/ARR retain their previous movement ticks.
- Focus changes and Sound clear queued actions, direction charge and entry rotation buffers. Controls held when input resumes are blocked until release. OS auto-repeat cannot rearm a cleared action.
- Local play pauses on focus loss, Sound or controller disconnection, including during the countdown. Online matches continue with suspended controls neutral. Other connected local players in an online match remain usable after one controller disconnects.
- A disconnected controller remains blocked for that round. Reusing a runtime ID, even with the same reported controller model, is not enough to resume control. Host: use Back to lobby, reassign the device and start again. Client: leave/rejoin and add the intended controller. This prioritizes correct board ownership over automatic reconnection.
- At GO, discrete countdown actions need a fresh press. Held movement and soft drop may continue. Starting/restarting/leaving a round clears all queued inputs.
- A pathological queue exceeding 256 transitions for one device before consumption is discarded and neutralized. It rearms only after a consumption tick observes every bound control released. It cannot replay a large stale sequence of hard drops.

## Verification

The new suite has **214 checks**, including **8,192 deterministic generated events** in 128 batches, alias overlap, repeats, release/repress, direction ordering, stick crossover, cross-device isolation, polling recovery, all nine finite soft-drop rates, baseline/fast DAS/ARR, entry timing, action ordering, multiple hard drops, timer integrity, queue overflow, focus/menu guards, countdown, restart, room lifecycle and simulated hotplug.

All **551 automated checks** pass, including the prior 337 checks. The four-process loopback test also passes. Linux UI inspection checks very short native key taps and pause/resume. Full build/export details are in VALIDATION.md.

To reproduce the new suite from the source project:

```text
godot --headless --path . --script tests/input_audit_test.gd
```

Use an isolated user-data directory; this test starts games and writes test preferences. The generated event sequence is seeded with `0x5eed`. Synthetic controller device IDs 2 and 3 do not require physical controllers.

## Limits

No Windows machine or physical controller was available. Keyboard rollover, USB polling, cable faults, actual controller firmware/disconnection behavior, OS scheduling, and device-driver event loss remain unverified. A press/release pair that neither the OS nor Godot reports is unknowable to the game. The 8,192-event stress case is deterministic and bounded; it does not establish that every timing sequence or long-duration session is bug-free. WAN latency/packet loss tests are outside this input audit.

Engine references: [Input](https://docs.godotengine.org/en/stable/classes/class_input.html) and [Window focus signals](https://docs.godotengine.org/en/stable/classes/class_window.html). The observed failures above come from Downstack reproductions, not from a claim that Godot itself loses delivered events.
