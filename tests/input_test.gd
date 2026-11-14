extends SceneTree

const Board = preload("res://scripts/board.gd")
const Settings = preload("res://scripts/input_settings.gd")
const Main = preload("res://scripts/main.gd")
var checks = 0
var failures = 0
const TICK = 1000.0/120.0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func key(code: int,down: bool = true,physical: bool = true) -> InputEventKey:
 var event = InputEventKey.new()
 event.pressed = down
 event.keycode = code
 if physical: event.physical_keycode = code
 return event

func joy_button(id: int,button: int,down: bool = true) -> InputEventJoypadButton:
 var event = InputEventJoypadButton.new()
 event.device = id
 event.button_index = button
 event.pressed = down
 return event

func joy_axis(id: int,axis: int,value: float) -> InputEventJoypadMotion:
 var event = InputEventJoypadMotion.new()
 event.device = id
 event.axis = axis
 event.axis_value = value
 return event

func send(event: InputEvent):
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func _initialize(): run.call_deferred()

func run():
 var prefs = ConfigFile.new()
 var settings = Settings.new(prefs)
 var first = settings.profile(-1)
 var second = settings.profile(-2)
 check(first.soft_drop == -1 and second.soft_drop == -1,"20x gravity is the default for both keyboards")
 check(first.bindings[0][0].code == KEY_LEFT and second.bindings[0][0].code == KEY_A,"keyboard profiles have separate defaults")
 Settings.assign(first,3,0,Settings.key_binding(KEY_Z))
 check(first.bindings[3][0].code == KEY_Z and first.bindings[4][0].code == KEY_X,"duplicate key swaps rotate bindings instead of firing both")
 check(second.bindings[3][0].code == KEY_K,"editing one keyboard does not edit the other")
 first.soft_drop = 5.0
 settings.profiles[settings.profile_key(-1)] = first
 settings.save(prefs)
 prefs.set_value("audio","music",0.31)
 prefs.set_value("sprint","best_ms",60000.0)
 check(prefs.save("user://input-roundtrip.cfg") == OK,"input preferences written")
 var restored = ConfigFile.new()
 check(restored.load("user://input-roundtrip.cfg") == OK,"input preferences reloaded")
 var reloaded = Settings.new(restored)
 check(reloaded.profile(-1).bindings[3][0].code == KEY_Z and reloaded.profile(-1).soft_drop == 5.0,"bindings and soft drop survive save/reload")
 check(restored.get_value("audio","music") == 0.31 and restored.get_value("sprint","best_ms") == 60000.0,"saving controls preserves volume and sprint record")
 var damaged = first.duplicate(true)
 damaged.bindings[0][0] = {"kind":"axis","code":0,"direction":1}
 check(Settings.sanitize(damaged,-1).bindings[0][0].code == KEY_LEFT,"wrong-device binding falls back safely")
 damaged = first.duplicate(true)
 damaged.bindings[0] = [{},{}]
 check(Settings.missing(damaged) == ["Move left"],"missing essential action is detected")
 check(Settings.sanitize(damaged,-1).bindings[0][0].code == KEY_LEFT,"damaged saved profile cannot remove all movement controls")
 check(Settings.from_event(key(KEY_ESCAPE),-1,{}).is_empty() and Settings.from_event(key(KEY_F11),-1,{}).is_empty(),"reserved keys cannot be bound")
 check(Settings.from_event(key(KEY_T),-1,{}).code == KEY_T,"keyboard capture records physical key")
 check(Settings.from_event(key(KEY_LEFT,true,false),-1,{}).kind == "keycode","logical-only navigation event has fallback")
 var echo_event = key(KEY_T)
 echo_event.echo = true
 check(Settings.from_event(echo_event,-1,{}).is_empty(),"key auto-repeat cannot create another capture")
 check(Settings.from_event(joy_button(2,JOY_BUTTON_Y),-1,{}).is_empty(),"keyboard capture ignores controller input")
 check(Settings.from_event(joy_button(2,JOY_BUTTON_Y),1,{}).is_empty(),"controller capture ignores another controller")
 check(Settings.from_event(joy_button(2,JOY_BUTTON_Y),2,{}).code == JOY_BUTTON_Y,"controller face button captures")
 check(Settings.from_event(joy_button(2,JOY_BUTTON_DPAD_RIGHT),2,{}).code == JOY_BUTTON_DPAD_RIGHT,"controller D-pad captures")
 var ready = {}
 check(Settings.from_event(joy_axis(2,JOY_AXIS_TRIGGER_LEFT,0.9),2,ready).is_empty(),"held trigger must return to neutral before capture")
 Settings.from_event(joy_axis(2,JOY_AXIS_TRIGGER_LEFT,0.0),2,ready)
 var trigger = Settings.from_event(joy_axis(2,JOY_AXIS_TRIGGER_LEFT,0.9),2,ready)
 check(trigger == Settings.axis_binding(JOY_AXIS_TRIGGER_LEFT,1),"trigger captures after neutral")
 ready[JOY_AXIS_LEFT_X] = true
 check(Settings.from_event(joy_axis(2,JOY_AXIS_LEFT_X,0.2),2,ready).is_empty(),"stick drift cannot capture a binding")
 check(Settings.from_event(joy_axis(2,JOY_AXIS_LEFT_X,-0.9),2,ready).direction == -1,"stick direction is retained")
 var pad = Settings.defaults(2)
 Settings.assign(pad,5,0,trigger)
 check(pad.bindings[5][0].kind == "axis" and pad.bindings[5][0].code == JOY_AXIS_TRIGGER_LEFT,"hard drop can be reassigned to a trigger")
 check(Settings.sanitize(pad,2) == pad,"controller binding round trip validates")
 settings.profiles[settings.profile_key(2)] = pad
 settings.save(prefs)
 var pad_restore = Settings.new(prefs).profile(2)
 check(pad_restore.bindings[5][0] == trigger,"controller trigger mapping persists in preferences")
 send(key(KEY_Z))
 check(settings.mask(first,-1) & Board.CW and not settings.mask(first,-1) & Board.CCW,"remapped physical key polls the new rotation")
 check(not settings.mask(second,-2) & Board.CW,"same keyboard event does not move the other profile")
 send(key(KEY_Z,false))
 send(key(KEY_LEFT,true,false))
 check(settings.mask(first,-1) & Board.LEFT,"arrow logical-code fallback works")
 send(key(KEY_LEFT,false,false))
 send(joy_button(2,JOY_BUTTON_B))
 check(settings.mask(pad,2) & Board.CW and not settings.mask(pad,3) & Board.CW,"controller polling remains device-specific")
 send(joy_button(2,JOY_BUTTON_B,false))
 send(joy_button(2,JOY_BUTTON_START))
 check(settings.mask(pad,2) & Settings.RESTART,"controller Start produces remappable sprint restart")
 send(joy_button(2,JOY_BUTTON_START,false))
 send(joy_axis(2,JOY_AXIS_TRIGGER_LEFT,0.8))
 check(settings.mask(pad,2) & Board.HARD,"bound trigger generates hard drop")
 send(joy_axis(2,JOY_AXIS_TRIGGER_LEFT,0.45))
 check(settings.mask(pad,2) & Board.HARD,"axis hysteresis prevents threshold chatter")
 send(joy_axis(2,JOY_AXIS_TRIGGER_LEFT,0.2))
 check(not settings.mask(pad,2) & Board.HARD,"trigger releases below lower threshold")
 for rate in [5.0,10.0,20.0,30.0,60.0,120.0]:
  var b = Board.new(1,{"soft_drop":rate})
  b.piece = 7
  b.pos = Vector2i(3,Board.SPAWN_Y)
  b.gravity_clock = 900.0
  b.step(TICK,Board.SOFT)
  check(b.pos.y-Board.SPAWN_Y <= 2,"soft drop does not consume old gravity as a burst at %s"%rate)
  var initial_y = b.pos.y
  for i in 12: b.step(TICK,Board.SOFT)
  check(b.pos.y-initial_y == int(floor(13*TICK*rate/1000.0+0.00001))-int(floor(TICK*rate/1000.0+0.00001)),"fixed soft-drop rate advances the expected distance at %s"%rate)
 var b = Board.new(1,{"soft_drop":10.0})
 b.piece = 7
 b.pos = Vector2i(3,Board.SPAWN_Y)
 b.step(TICK,Board.SOFT)
 var y = b.pos.y
 b.step(TICK,0)
 for i in 30: b.step(TICK,0)
 check(b.pos.y == y,"releasing soft drop returns to ordinary gravity")
 b = Board.new(1,{"soft_drop":0.0})
 b.piece = 7
 b.pos = Vector2i(3,Board.SPAWN_Y)
 var landing = b.ghost_y()
 b.step(TICK,Board.SOFT)
 check(b.pos.y == landing and b.pieces == 0,"instant soft drop reaches floor without immediate lock")
 for i in 58: b.step(TICK,Board.SOFT)
 check(b.pieces == 0,"instant soft drop retains lock delay")
 for i in 3: b.step(TICK,Board.SOFT)
 check(b.pieces == 1,"holding instant soft drop cannot reset lock indefinitely")
 b = Board.new(1,{"soft_drop":5.0})
 b.step(TICK,Board.HARD)
 check(b.pieces == 1,"hard drop still locks immediately at a slow soft-drop setting")
 b = Board.new(1,{"soft_drop":-1.0})
 b.piece = 7
 b.pos = Vector2i(3,Board.SPAWN_Y)
 b.step(TICK,Board.SOFT)
 y = b.pos.y
 for i in 30: b.step(TICK,Board.SOFT)
 check(b.pos.y-y == 5,"guideline preset gives 20 cells/sec at base gravity")
 b = Board.new(1,{"soft_drop":-1.0})
 b.piece = 7
 b.pos = Vector2i(3,Board.SPAWN_Y)
 b.lines = 10 # Normal interval 800 ms; soft interval 40 ms.
 b.step(TICK,Board.SOFT)
 y = b.pos.y
 for i in 24: b.step(TICK,Board.SOFT)
 check(b.pos.y-y == 5,"guideline preset scales with level gravity")
 b = Board.new(1,{"soft_drop":-1.0})
 b.piece = 7
 b.pos = Vector2i(3,Board.SPAWN_Y)
 b.step(TICK,Board.SOFT)
 y = b.pos.y
 for i in 119: b.step(TICK,0)
 check(b.pos.y == y,"default soft-drop release restores the ordinary one-second interval")
 b.step(TICK,0)
 check(b.pos.y == y+1,"ordinary gravity resumes after releasing default soft drop")
 b = Board.new(1,{"soft_drop":-1.0},{"entry_ms":0.0,"clear_ms":0.0,"mode":"sprint"})
 b.piece = 7
 b.pos = Vector2i(3,Board.SPAWN_Y)
 b.pos.y = b.ghost_y()
 for i in 59: b.step(TICK,Board.SOFT)
 check(b.pieces == 0,"default soft drop retains the 500 ms lock delay")
 for i in 2: b.step(TICK,Board.SOFT)
 check(b.pieces == 1,"holding default soft drop does not extend lock delay indefinitely")
 y = b.pos.y
 for i in 12: b.step(TICK,Board.SOFT)
 check(b.pos.y > y and b.pieces == 1,"held default soft drop continues on the next piece without a new press")
 var app = Main.new()
 root.add_child(app)
 app.set_physics_process(false)
 app.config = ConfigFile.new()
 app.input_settings = Settings.new(app.config)
 app.settings_page.settings = app.input_settings
 app.settings_page.config = app.config
 app._sprint()
 app._add_player()
 app._open_settings()
 app.settings_page._begin_capture(3,0)
 app.settings_page._capture_event(key(KEY_T))
 check(app.settings_page._draft().bindings[3][0].code == KEY_T,"settings-page capture updates the pending binding")
 app.settings_page._cancel()
 check(app.input_settings.profile(-1).bindings[3][0].code == KEY_X,"closing without Apply discards draft changes")
 app._open_settings()
 app.settings_page._clear(0,0)
 check(app.settings_page.apply_button.disabled,"Apply disabled when an essential action has no binding")
 app.settings_page._begin_capture(0,0)
 app.settings_page._capture_event(key(KEY_LEFT))
 check(not app.settings_page.apply_button.disabled,"repairing missing action enables Apply")
 app.settings_page._begin_capture(3,0)
 app.settings_page._capture_event(key(KEY_T))
 app.settings_page._begin_capture(3,0)
 app.settings_page._capture_event(key(KEY_R))
 check(app.settings_page._draft().bindings[7][0].code == KEY_T,"assigning R to rotation swaps sprint restart to the old binding")
 app.settings_page._draft().soft_drop = 5.0
 app.settings_page._apply()
 check(app.room.roster[0].soft_drop == 5.0,"Apply updates already-added local player's soft-drop setting")
 app.room.begin()
 var model = app.models.values()[0]
 # The lobby chooses a random bag. O keeps rotation == 0 by design, so use
 # a T for this key-routing assertion instead of a 1-in-7 false failure.
 model.piece = 1
 check(model.handling.soft_drop == 5.0,"selected soft-drop speed reaches the actual board")
 send(key(KEY_R))
 check(app._mask(-1) & Board.CW,"actual gameplay uses saved custom binding")
 app.countdown = 0
 app._physics_process(TICK/1000.0)
 check(app.models.values()[0] == model and model.rotation == 1,"R can rotate without the former global restart shortcut")
 send(key(KEY_R,false))
 send(key(KEY_T))
 app._physics_process(TICK/1000.0)
 check(app.models.values()[0] != model and app.countdown == 3.0,"custom restart binding starts a new sprint")
 app._physics_process(1.0)
 check(app.countdown == 2.0,"holding restart does not restart every frame")
 send(key(KEY_T,false))
 app._physics_process(TICK/1000.0)
 send(key(KEY_T))
 app._physics_process(TICK/1000.0)
 check(app.countdown == 3.0,"releasing and pressing restart works again")
 send(key(KEY_T,false))
 check(app.settings_button.disabled,"remapping is disabled during a round")
 app.room.back_to_lobby()
 check(not app.settings_button.disabled,"remapping becomes available again in lobby")
 await create_timer(0.12).timeout
 app.room.close_session()
 app.free()
 await create_timer(0.1).timeout
 print("INPUT TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
