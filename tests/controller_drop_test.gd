extends SceneTree

const Board = preload("res://scripts/board.gd")
const Settings = preload("res://scripts/input_settings.gd")
const TICK = 1000.0/120.0
var checks = 0
var failures = 0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func axis(value: float):
 var event = InputEventJoypadMotion.new()
 event.device = 2
 event.axis = JOY_AXIS_LEFT_Y
 event.axis_value = value
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func button(down: bool):
 var event = InputEventJoypadButton.new()
 event.device = 2
 event.button_index = JOY_BUTTON_DPAD_DOWN
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func board(rate: float):
 var result = Board.new(1,{"soft_drop":rate})
 result.piece = 7
 result.pos = Vector2i(3,Board.SPAWN_Y)
 return result

func _initialize(): run.call_deferred()

func run():
 var settings = Settings.new()
 var profile = Settings.defaults(2)
 for source in ["stick","D-pad"]:
  var steady = board(20)
  var intermittent = board(20)
  for tick in 48:
   steady.step(TICK,Board.SOFT)
   if source == "stick": axis(0.2 if tick%2 else 0.9)
   else: button(tick%2 == 0)
   intermittent.step(TICK,settings.mask(profile,2))
  check(steady.pos.y-Board.SPAWN_Y == 9,"steady 20 cells/sec reference in 400 ms")
  check(intermittent.pos.y <= steady.pos.y,"%s release/repress cannot exceed held soft-drop cadence"%source)
  check(intermittent.pos.y < intermittent.ghost_y() and intermittent.pieces == 0,"%s intermittent input does not drop to floor or lock"%source)
  axis(0)
  button(false)
  settings.mask(profile,2)
 for rate in [5.0,10.0,15.0,20.0,30.0,45.0,60.0,90.0,120.0]:
  var b = board(rate)
  for tick in 12: b.step(TICK,Board.SOFT)
  var expected = 1+int(floor(12*TICK*rate/1000.0+0.00001))
  check(b.pos.y-Board.SPAWN_Y == expected,"held cadence retains fractional timing at %s cells/sec"%rate)
  check(b.handling.soft_drop == rate,"finite rate never changes to Instant")
  var noisy = board(rate)
  for tick in 12: noisy.step(TICK,Board.SOFT if tick%2 == 0 else 0)
  check(noisy.pos.y-Board.SPAWN_Y <= expected,"rapid press/release cannot accelerate %s cells/sec"%rate)
 var shallow = board(20)
 var full = board(20)
 for tick in 24:
  axis(0.6)
  shallow.step(TICK,settings.mask(profile,2))
  axis(1.0)
  full.step(TICK,settings.mask(profile,2))
 check(shallow.pos.y == full.pos.y,"stick pressure does not change soft-drop speed")
 var both = board(20)
 var single = board(20)
 for tick in 24:
  axis(1.0)
  button(true)
  both.step(TICK,settings.mask(profile,2))
  single.step(TICK,Board.SOFT)
 check(both.pos.y == single.pos.y,"D-pad and stick together cannot double soft-drop speed")
 axis(0)
 button(false)
 var b = board(20)
 for tick in 6: b.step(TICK,Board.SOFT)
 var start_y = b.pos.y
 for tick in 30: b.step(TICK,0)
 check(b.pos.y == start_y,"release returns to ordinary gravity without stored-time burst")
 b._spawn(7)
 start_y = b.pos.y
 b.step(TICK,Board.SOFT)
 check(b.pos.y-start_y <= 2,"new piece cannot inherit catch-up soft-drop time")
 b = board(20)
 b.pos.y = b.ghost_y()
 for tick in 59: b.step(TICK,Board.SOFT if tick%2 else 0)
 check(b.pieces == 0,"finite soft drop retains lock delay")
 for tick in 3: b.step(TICK,Board.SOFT if tick%2 else 0)
 check(b.pieces == 1,"noisy input at floor cannot keep resetting lock delay")
 b = board(0)
 var floor_y = b.ghost_y()
 b.step(TICK,Board.SOFT)
 check(b.pos.y == floor_y and b.pieces == 0,"explicit Instant still reaches floor without locking")
 check(b.move(-1),"Instant soft drop still permits movement before lock")
 b = board(20)
 b.step(TICK,Board.HARD)
 check(b.pieces == 1,"hard drop remains a distinct immediate lock")
 for invalid in [-2.0,-0.1,INF,NAN,"invalid",null]:
  b = Board.new(1,{"soft_drop":invalid})
  check(b.handling.soft_drop == -1,"invalid rate cannot silently enable Instant")
 print("CONTROLLER DROP TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
