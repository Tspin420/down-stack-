extends SceneTree

const Board = preload("res://scripts/board.gd")
const TICK = 1000.0/120.0
# Independent numeric fixtures from the March 2009 section 7 formula.
const INTERVALS = [1000.0,793.0,617.796,472.729139,355.196928256,
 262.003549978,189.677245333,134.734730816,93.882248904,64.151584960,
 42.976258297,28.217677801,18.153328544,11.439342347,7.058616221]
var checks = 0
var failures = 0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func board(level: int, rate: float = -1.0, mode: String = "versus"):
 var b = Board.new(1,{"soft_drop":rate},{"mode":mode})
 b.lines = (level-1)*10
 b.piece = 7
 # Include the hidden buffer so fast drop rates can be measured before landing.
 b.pos = Vector2i(3,0)
 return b

func _initialize(): run.call_deferred()

func run():
 for level in range(1,16):
  var expected = float(INTERVALS[level-1])
  var b = board(level)
  check(absf(b.gravity_interval_ms()-expected) < 0.00001,"level %d matches the documented gravity curve"%level)
  for i in 12: b.step(TICK,0)
  check(b.pos.y == floori(100.0/expected+0.00001),"level %d falls the correct number of cells in 100 ms"%level)
  var soft = board(level)
  soft.step(TICK,Board.SOFT)
  check(soft.pos.y == 1+floori(TICK*20.0/expected+0.00001),"level %d default soft drop scales with the new gravity"%level)

 var b = board(1)
 b.lines = 9
 check(b.gravity_interval_ms() == 1000.0,"nine lines retain level 1")
 b.lines = 10
 check(is_equal_approx(b.gravity_interval_ms(),793.0),"the tenth line enters level 2")
 b.lines = 139
 check(absf(b.gravity_interval_ms()-11.439342347) < 0.00001,"139 lines remain at level 14")
 b.lines = 140
 check(absf(b.gravity_interval_ms()-7.058616221) < 0.00001,"140 lines enter level 15")
 for count in [150,1000,2147483647]:
  b.lines = count
  check(absf(b.gravity_interval_ms()-7.058616221) < 0.00001,"long versus matches hold level 15 without an invalid interval")
 b = board(0)
 check(b.gravity_interval_ms() == 1000.0,"negative fixture line counts safely use starting gravity")

 for count in [0,10,20,39]:
  b = board(1,-1.0,"sprint")
  b.lines = count
  check(b.gravity_interval_ms() == 1000.0,"Sprint does not level up")
  for i in 119: b.step(TICK,0)
  check(b.pos.y == 0,"Sprint waits a full second per ordinary cell")
  b.step(TICK,0)
  check(b.pos.y == 1,"Sprint falls one cell at one second")
  b = board(1,-1.0,"sprint")
  b.lines = count
  b.step(TICK,Board.SOFT)
  var start = b.pos.y
  for i in 30: b.step(TICK,Board.SOFT)
  check(b.pos.y-start == 5,"Sprint default soft drop stays at 20 cells/sec")

 b = board(15)
 for i in 6: b.step(TICK,0)
 check(b.pos.y == 7,"level 15 retains fractional time and can cross several cells per tick")
 check(b.pieces == 0,"fast natural gravity does not hard-lock a falling piece")
 var normal = board(15)
 var fixed = board(15,5.0)
 for i in 12:
  normal.step(TICK,0)
  fixed.step(TICK,Board.SOFT)
 check(fixed.pos.y >= normal.pos.y,"a finite custom soft drop cannot slow faster normal gravity")

 for level in [1,15]:
  b = board(level)
  b.step(TICK,Board.SOFT)
  var released_at = b.pos.y
  var normal_only = board(level)
  for i in 6:
   b.step(TICK,0)
   normal_only.step(TICK,0)
  check(b.pos.y-released_at == normal_only.pos.y,"release restores normal gravity with no banked burst at level %d"%level)
  for rate in [-1.0,0.0]:
   b = board(level,rate)
   b.pos.y = b.ghost_y()
   for i in 59: b.step(TICK,Board.SOFT)
   check(b.pieces == 0,"default and Instant retain lock delay at level %d"%level)
   for i in 2: b.step(TICK,Board.SOFT)
   check(b.pieces == 1,"holding default or Instant cannot keep a landed piece unlocked")
   b = board(level,rate)
   b.step(TICK,Board.HARD)
   check(b.pieces == 1,"hard drop locks immediately with either soft-drop option")
  b = board(level,0.0)
  var floor_y = b.ghost_y()
  b.step(TICK,Board.SOFT)
  check(b.pos.y == floor_y and b.pieces == 0,"Instant reaches the floor in one tick at level %d"%level)
  check(b.move(-1),"Instant permits movement after landing")

 print("GRAVITY TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
