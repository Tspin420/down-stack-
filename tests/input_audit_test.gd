extends SceneTree

const Board = preload("res://scripts/board.gd")
const Settings = preload("res://scripts/input_settings.gd")
const Stream = preload("res://scripts/input_stream.gd")
const Main = preload("res://scripts/main.gd")
const TICK = 1000.0/120.0
var checks = 0
var failures = 0

func check(value: bool, message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func key(code: int, down: bool, echo_event: bool = false):
 var e = InputEventKey.new()
 e.keycode = code
 e.physical_keycode = code
 e.pressed = down
 e.echo = echo_event
 return e

func button(code: int, down: bool, device: int = 2):
 var e = InputEventJoypadButton.new()
 e.device = device
 e.button_index = code
 e.pressed = down
 return e

func axis(value: float, device: int = 2):
 var e = InputEventJoypadMotion.new()
 e.device = device
 e.axis = JOY_AXIS_LEFT_X
 e.axis_value = value
 return e

func deliver(event: InputEvent, stream = null):
 Input.parse_input_event(event)
 Input.flush_buffered_events()
 if stream != null: stream.feed(event)

func consume(stream, board, device: int = -1, dt: float = TICK):
 var frame = stream.take(device)
 return board.step(dt,frame.held,frame.changes)

func fresh_board():
 var b = Board.new(1,{"soft_drop":20.0},{"entry_ms":0.0,"clear_ms":0.0,"mode":"sprint"})
 b.piece = 1
 b.pos = Vector2i(3,Board.VISIBLE_TOP+3)
 return b

func _initialize(): run.call_deferred()

func run():
 var settings = Settings.new()
 var profiles = {-1:Settings.defaults(-1),-2:Settings.defaults(-2),2:Settings.defaults(2),3:Settings.defaults(3)}
 profiles[-1].bindings[3][1] = Settings.key_binding(KEY_T)
 var stream = Stream.new()
 stream.configure(settings,profiles)
 var b = fresh_board()
 deliver(key(KEY_X,true),stream)
 deliver(key(KEY_X,false),stream)
 consume(stream,b)
 deliver(key(KEY_X,true,true),stream)
 consume(stream,b)
 check(b.rotation == 1,"orphan OS repeat cannot become a new press through polling")
 deliver(key(KEY_X,false),stream)
 consume(stream,b)
 check(b.rotation == 1,"a complete rotation tap between physics ticks survives")
 deliver(key(KEY_X,true),stream)
 consume(stream,b)
 deliver(key(KEY_X,false),stream)
 deliver(key(KEY_X,true),stream)
 consume(stream,b)
 check(b.rotation == 3,"release/repress between ticks creates another rotation")
 for i in 12: deliver(key(KEY_X,true,true),stream)
 consume(stream,b)
 check(b.rotation == 3,"OS key auto-repeat never adds rotations")
 deliver(key(KEY_X,false),stream)
 consume(stream,b)
 for order in [[KEY_LEFT,KEY_RIGHT],[KEY_RIGHT,KEY_LEFT]]:
  b = fresh_board()
  deliver(key(order[0],true),stream)
  deliver(key(order[1],true),stream)
  consume(stream,b)
  check(b.direction == (1 if order[1] == KEY_RIGHT else -1),"last delivered direction wins in either order")
  deliver(key(order[1],false),stream)
  consume(stream,b)
  check(b.direction == (-1 if order[0] == KEY_LEFT else 1),"releasing winner falls back to still-held direction")
  deliver(key(order[0],false),stream)
  consume(stream,b)
  check(b.direction == 0,"releasing both directions stops movement")
 b = fresh_board()
 var start_x = b.pos.x
 for i in 2:
  deliver(key(KEY_LEFT,true),stream)
  deliver(key(KEY_LEFT,false),stream)
 consume(stream,b)
 check(b.pos.x == start_x-2 and b.direction == 0,"two short movement taps produce exactly two cells")
 b = fresh_board()
 deliver(key(KEY_X,true),stream)
 deliver(key(KEY_T,true),stream)
 deliver(key(KEY_X,false),stream)
 consume(stream,b)
 check(b.rotation == 1,"overlapping primary/alternate keys do not double an action")
 check(stream.peek(-1) & Board.CW,"alternate key keeps the action held after primary release")
 deliver(key(KEY_T,false),stream)
 deliver(key(KEY_T,true),stream)
 consume(stream,b)
 check(b.rotation == 2,"alternate key re-arms after all aliases release")
 deliver(key(KEY_T,false),stream)
 consume(stream,b)
 b = fresh_board()
 deliver(key(KEY_LEFT,true),stream)
 consume(stream,b)
 deliver(key(KEY_LEFT,false)) # Global state changes, but callback to stream is lost.
 consume(stream,b)
 check(b.direction == 0 and stream.peek(-1) == 0,"polling repairs a missed release callback")
 deliver(key(KEY_RIGHT,true))
 consume(stream,b)
 check(b.direction == 1,"polling recovers a held press when its callback is missed")
 deliver(key(KEY_RIGHT,false),stream)
 consume(stream,b)
 deliver(key(KEY_X,true),stream)
 check(stream.take(-2).held == 0 and stream.take(2).held == 0,"keyboard profile and controller isolation")
 deliver(key(KEY_X,false),stream)
 stream.take(-1)
 b = fresh_board()
 deliver(button(JOY_BUTTON_B,true),stream)
 deliver(button(JOY_BUTTON_B,false),stream)
 consume(stream,b,2)
 check(b.rotation == 1,"a complete controller button tap between ticks survives")
 check(stream.take(3).held == 0 and stream.take(3).changes.is_empty(),"controller events cannot reach another device")
 b = fresh_board()
 deliver(axis(-0.9),stream)
 deliver(axis(0.9),stream)
 consume(stream,b,2)
 check(b.direction == 1,"rapid stick crossover preserves direction order")
 var at = b.pos.x
 for value in [0.51,0.40,0.36,0.50,0.54]: deliver(axis(value),stream)
 consume(stream,b,2)
 check(b.pos.x == at and b.direction == 1,"axis hysteresis does not retrigger initial movement")
 deliver(axis(0),stream)
 consume(stream,b,2)
 check(b.direction == 0,"stick neutral releases movement")
 b = fresh_board()
 deliver(button(JOY_BUTTON_DPAD_LEFT,true),stream)
 deliver(axis(-0.9),stream)
 deliver(button(JOY_BUTTON_DPAD_LEFT,false),stream)
 consume(stream,b,2)
 check(b.pos.x == 2 and b.direction == -1,"D-pad/stick aliases act as one held direction")
 deliver(axis(0),stream)
 consume(stream,b,2)
 b = fresh_board()
 deliver(button(JOY_BUTTON_LEFT_SHOULDER,true),stream)
 deliver(button(JOY_BUTTON_RIGHT_SHOULDER,true),stream)
 consume(stream,b,2)
 var held_kind = b.held
 deliver(button(JOY_BUTTON_DPAD_UP,true),stream)
 deliver(button(JOY_BUTTON_DPAD_UP,false),stream)
 consume(stream,b,2)
 check(b.held == held_kind,"second hold alias cannot hold the following piece while first remains held")
 deliver(button(JOY_BUTTON_LEFT_SHOULDER,false),stream)
 deliver(button(JOY_BUTTON_RIGHT_SHOULDER,false),stream)
 consume(stream,b,2)
 # Several discrete actions in one tick preserve order and simulation time.
 for sequence in [[Board.CW,0,Board.HOLD,0],[Board.HOLD,0,Board.CW,0]]:
  b = fresh_board()
  b.queue[0] = 1
  b.step(TICK,0,sequence)
  check(b.rotation == (0 if sequence[0] == Board.CW else 1),"rotation/hold order is preserved")
  check(is_equal_approx(b.elapsed,TICK),"multiple events advance sprint time exactly once")
 b = fresh_board()
 b.step(TICK,0,[Board.HARD,0,Board.HARD,0])
 check(b.pieces == 2,"two deliberate hard-drop taps lock two pieces with zero entry delay")
 check(b.sounds.count("drop") == 2,"all rapid-action sound cues are retained")
 check(is_equal_approx(b.elapsed,TICK),"two hard drops cannot add simulation time")
 b = fresh_board()
 b.lines = 36
 for y in range(Board.H-4,Board.H):
  for x in 10: b.grid[y][x] = 8 if x != 4 else 0
 b.piece = 6
 b.rotation = 1
 b.pos = Vector2i(2,Board.H-4)
 b.step(TICK,0,[Board.HARD,0,Board.HARD,0])
 check(b.completed and b.lines == 40 and b.pieces == 1 and is_equal_approx(b.elapsed,TICK),"rapid completion counts its last tick and ignores later taps")
 b.step(TICK,0,[Board.HARD,0])
 check(is_equal_approx(b.elapsed,TICK) and b.pieces == 1,"completed sprint stays frozen after queued inputs")
 b = Board.new(1,{}, {"garbage_ms":TICK,"entry_ms":0.0})
 b.receive_garbage(1,4,1)
 b.step(TICK,0,[Board.HARD,0])
 check(b.pending.is_empty() and b.grid[Board.H-1][0] == 8,"garbage deadline reached this tick applies to queued hard drop")
 b = Board.new(1,{}, {"entry_ms":100.0})
 b.step(TICK,0,[Board.HARD,0,Board.HARD,0])
 check(b.pieces == 1,"hard drop during entry is not banked onto the next piece")
 for delta in [0.0,1.0,TICK]:
  b = fresh_board()
  b.piece = 0
  b.delay = delta
  b.queue[0] = 1
  b.step(TICK,Board.CW)
  check(b.rotation == 1,"rotation on exact entry tick applies once at delay %s"%delta)
  check(b.rotation_buffer == 0 and b.buffer_life == 0,"entry consumes its rotation buffer")
 b = fresh_board()
 b.receive_garbage(1,4,1) # Sprint rejects incoming garbage; use versus below.
 b.rules.mode = "versus"
 b.receive_garbage(1,4,1)
 b.piece = 7
 b.pos.y = b.ghost_y()
 b.step(TICK,0,[Board.CW,0,Board.CCW,0])
 check(is_equal_approx(b.pending[0].remaining,1000.0-TICK),"event burst advances garbage warning only once")
 check(is_equal_approx(b.lock_clock,TICK),"event burst advances lock delay only once")
 for rate in [5.0,10.0,15.0,20.0,30.0,45.0,60.0,75.0,90.0,120.0]:
  var steady = fresh_board()
  var noisy = fresh_board()
  steady.handling.soft_drop = rate
  noisy.handling.soft_drop = rate
  steady.pos.y = Board.SPAWN_Y
  noisy.pos.y = Board.SPAWN_Y
  for tick in 12:
   steady.step(TICK,Board.SOFT)
   for tap in 4:
    deliver(key(KEY_DOWN,true),stream)
    deliver(key(KEY_DOWN,false),stream)
   deliver(key(KEY_DOWN,true),stream)
   consume(stream,noisy)
  check(noisy.pos.y == steady.pos.y,"sub-tick chatter retains selected soft-drop cadence at %s"%rate)
  check(noisy.pieces == 0,"sub-tick soft-drop chatter never hard locks at %s"%rate)
  deliver(key(KEY_DOWN,false),stream)
  stream.take(-1)
 for tuning in [{"das":166.6667,"arr":33.3333},{"das":83.3333,"arr":16.6667}]:
  var polled = Board.new(1,tuning)
  var buffered = Board.new(1,tuning)
  polled.pos.x = 7
  buffered.pos.x = 7
  deliver(key(KEY_LEFT,true),stream)
  var same = true
  for tick in 30:
   polled.step(TICK,Board.LEFT)
   consume(stream,buffered)
   same = same and polled.pos.x == buffered.pos.x
  check(same,"event queue preserves each DAS/ARR movement tick at %s ms DAS"%tuning.das)
  deliver(key(KEY_LEFT,false),stream)
  stream.take(-1)
 # Fixed-seed stress: 8,192 transitions, including repeats and aliases.
 var rng = RandomNumberGenerator.new()
 rng.seed = 0x5eed
 var down = {KEY_X:false,KEY_T:false,KEY_Z:false}
 var expected_rotation = 0
 b = fresh_board()
 for batch in 128:
  for event_number in 64:
   var code = [KEY_X,KEY_T,KEY_Z][rng.randi_range(0,2)]
   var pressed = rng.randi_range(0,1) == 1
   var old_cw = down[KEY_X] or down[KEY_T]
   var old_ccw = down[KEY_Z]
   down[code] = pressed
   if (down[KEY_X] or down[KEY_T]) and not old_cw: expected_rotation = posmod(expected_rotation+1,4)
   if down[KEY_Z] and not old_ccw: expected_rotation = posmod(expected_rotation-1,4)
   deliver(key(code,pressed),stream)
  consume(stream,b)
  check(b.rotation == expected_rotation,"stress batch %d retains exact rotation count"%batch)
 check(stream.overflow_count == 0,"normal stress stays below safety backlog limit")
 for code in down: deliver(key(code,false),stream)
 stream.take(-1)
 # Pathological backlog fails neutral, then requires new deliberate input.
 for i in Stream.MAX_CHANGES+20: deliver(key(KEY_X,i%2 == 0),stream)
 var frame = stream.take(-1)
 check(stream.overflow_count == 1 and frame.held == 0,"overflow clears held input safely")
 check(frame.changes == [0],"overflow cannot replay its old rotation backlog")
 deliver(key(KEY_X,false),stream)
 stream.take(-1)
 deliver(key(KEY_X,true),stream)
 deliver(key(KEY_X,false),stream)
 b = fresh_board()
 consume(stream,b)
 check(b.rotation == 1,"input works again after overflow reaches neutral")
 # Real Main event routing, focus and menu lifecycle.
 var app = Main.new()
 root.add_child(app)
 app.set_physics_process(false)
 app.config = ConfigFile.new()
 app.input_settings = Settings.new(app.config)
 app._sprint()
 app._add_player()
 app.room.begin()
 app.countdown = 0
 b = app.models.values()[0]
 b.piece = 1
 deliver(key(KEY_X,true))
 deliver(key(KEY_X,false))
 app._physics_process(TICK/1000.0)
 check(b.rotation == 1,"Main forwards a sub-tick tap to the board")
 deliver(key(KEY_LEFT,true))
 app._physics_process(0.05)
 var elapsed = b.elapsed
 var x = b.pos.x
 app._window_focus_changed(false)
 check(b.direction == 0 and b.das_clock == 0 and b.previous_input == 0,"focus loss immediately clears movement and DAS")
 deliver(key(KEY_SPACE,true))
 app._physics_process(0.5)
 check(b.elapsed == elapsed and b.pos.x == x,"local focus loss pauses timer and board")
 app._window_focus_changed(true)
 app._physics_process(TICK/1000.0)
 check(b.pieces == 0 and b.direction == 0,"held hard drop and movement cannot fire on refocus")
 deliver(key(KEY_LEFT,false))
 deliver(key(KEY_SPACE,false))
 deliver(key(KEY_SPACE,true))
 deliver(key(KEY_SPACE,false))
 app._physics_process(TICK/1000.0)
 check(b.pieces == 1,"fresh hard-drop tap works after focus recovery")
 app.audio_dialog.show()
 elapsed = b.elapsed
 deliver(key(KEY_SPACE,true))
 deliver(key(KEY_R,true))
 app._physics_process(0.5)
 check(b.elapsed == elapsed,"Sound dialog pauses local sprint time")
 app.audio_dialog.hide()
 app._physics_process(TICK/1000.0)
 check(app.models.values()[0] == b and b.pieces == 1,"closing Sound cannot leak held restart or hard drop")
 deliver(key(KEY_SPACE,false))
 deliver(key(KEY_R,false))
 deliver(key(KEY_R,true))
 deliver(key(KEY_R,false))
 app._physics_process(TICK/1000.0)
 check(app.models.values()[0] != b and app.countdown == 3.0,"complete restart tap survives between ticks")
 b = app.models.values()[0]
 b.piece = 1
 deliver(key(KEY_SPACE,true))
 deliver(key(KEY_X,true))
 deliver(key(KEY_C,true))
 deliver(key(KEY_LEFT,true))
 app._physics_process(3.0)
 app._physics_process(TICK/1000.0)
 check(b.pieces == 0 and b.held == 0 and b.rotation == 0,"countdown cannot bank discrete actions at GO")
 check(b.direction == -1,"held movement can carry through countdown")
 for code in [KEY_SPACE,KEY_X,KEY_C,KEY_LEFT]: deliver(key(code,false))
 app._physics_process(TICK/1000.0)
 deliver(key(KEY_X,true))
 deliver(key(KEY_X,false))
 app._physics_process(TICK/1000.0)
 check(b.rotation == 1,"fresh action works after countdown gate")
 # Online policy: local focus/modal cannot pause the live match.
 app.room.online = true
 app.send_clock = -10.0 # Avoid posting to a real network in this fixture.
 app._window_focus_changed(false)
 elapsed = b.elapsed
 app._physics_process(TICK/1000.0)
 check(b.elapsed > elapsed and b.direction == 0,"online simulation continues with neutral input while unfocused")
 app._window_focus_changed(true)
 deliver(key(KEY_SPACE,true,true))
 app._physics_process(TICK/1000.0)
 check(b.pieces == 0,"OS repeat after refocus cannot trigger a hard drop")
 deliver(key(KEY_SPACE,false))
 app.room.online = false
 # Simulate hotplug signal at an assigned controller slot. No physical pad.
 app.local_profiles[2] = Settings.defaults(2)
 app.input_stream.configure(app.input_settings,app.local_profiles)
 deliver(button(JOY_BUTTON_B,true))
 app._controller_connection_changed(2,false)
 check(app.input_stream.peek(2) == 0 and app.disconnected_inputs.has(2),"disconnect clears pending controller input immediately")
 elapsed = b.elapsed
 app._physics_process(0.5)
 check(b.elapsed == elapsed,"local controller loss pauses the round")
 app._controller_connection_changed(2,true)
 check(app.input_stream.peek(2) == 0 and app.disconnected_inputs.has(2),"reused controller ID cannot reclaim a live board automatically")
 check(app.end_button.text == "Back to lobby","local disconnect offers a lobby recovery action")
 deliver(button(JOY_BUTTON_B,false))
 # Closing a room or starting a new one must discard any queued input.
 app.room.close_session()
 check(app.input_stream.devices.is_empty(),"room close discards every pending input")
 app._sprint()
 app._add_player()
 app.room.begin()
 app.countdown = 0
 deliver(key(KEY_SPACE,true))
 app._restart_sprint()
 app.countdown = 0
 app._physics_process(TICK/1000.0)
 check(app.models.values()[0].pieces == 0,"new round cannot inherit a queued or held hard drop")
 deliver(key(KEY_SPACE,false))
 await create_timer(0.12).timeout
 app.room.close_session()
 app.free()
 await create_timer(0.1).timeout
 print("INPUT AUDIT TESTS: %d checks, %d failures; 8192 seeded stress events"%[checks,failures])
 quit(1 if failures else 0)
