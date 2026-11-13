extends SceneTree

const Board = preload("res://scripts/board.gd")
const Session = preload("res://scripts/session.gd")
var checks = 0
var failures = 0

func check(condition: bool,message: String):
 checks += 1
 if not condition:
  failures += 1
  printerr("FAIL: "+message)

func _initialize():
 var a = Board.new(183)
 var b = Board.new(183)
 var sequence = [a.piece]+a.queue
 var first = sequence.slice(0,7)
 first.sort()
 check(first == [1,2,3,4,5,6,7],"first bag contains every tetromino once")
 check(a.piece == b.piece and a.queue == b.queue,"same seed, same piece sequence")
 for kind in range(1,8):
  var spawn_board = Board.new()
  spawn_board._spawn(kind)
  var visible = false
  for c in spawn_board.cells():
   if spawn_board.pos.y+c.y >= Board.VISIBLE_TOP: visible = true
  check(visible,"every spawned piece has a visible entry row")
 var original = a.piece
 a.step(8.333333,Board.HOLD)
 var second = a.piece
 a.step(8.333333,0)
 a.step(8.333333,Board.HOLD)
 check(a.held == original and a.piece == second,"hold limited to once per piece")
 a = Board.new()
 a.piece = 1
 a.rotation = 1
 a.pos = Vector2i(-1,Board.VISIBLE_TOP+3)
 check(a.fits(a.pos),"wall kick starts from a valid position")
 check(a.rotate(-1) and a.pos.x == 0,"T wall kick moves right at left wall")
 a.piece = 6
 a.rotation = 1
 a.pos = Vector2i(-2,Board.VISIBLE_TOP+3)
 check(a.fits(a.pos) and a.rotate(1) and a.pos.x == 0,"I-piece uses its separate kick table")
 for config in [{"das":166.67,"arr":33.33},{"das":83.33,"arr":16.67}]:
  a = Board.new(3,config)
  a.pos.x = 5
  a.step(1000.0/120,Board.LEFT)
  check(a.pos.x == 4,"initial movement is immediate")
  var ticks = 20 if config.das > 100 else 10
  for i in ticks-1: a.step(1000.0/120,Board.LEFT)
  check(a.pos.x == 4,"no repeat before configured DAS")
  a.step(1000.0/120,Board.LEFT)
  check(a.pos.x == 3,"DAS fires on selected fixed tick")
  var arr_ticks = 4 if config.arr > 20 else 2
  for i in arr_ticks: a.step(1000.0/120,Board.LEFT)
  check(a.pos.x == 2,"ARR repeats at configured interval")
 a = Board.new(1,{}, {"garbage_ms":1000.0})
 a.receive_garbage(4,4,1)
 a.receive_garbage(4,4,1)
 check(a.pending.size() == 1,"duplicate packet cannot double-apply garbage")
 for i in 119: a.step(1000.0/120,0)
 check(a.pending[0].remaining > 0,"garbage remains pending before full warning interval")
 a._raise_garbage()
 check(a.pending.size() == 1,"immature garbage cannot rise")
 a.step(1000.0/120,0)
 a.step(1000.0/120,0)
 check(a.pending.size() == 1,"timer expiry alone does not interrupt active piece")
 a._raise_garbage()
 check(a.pending.is_empty() and a.grid[Board.H-1][4] == 0 and a.grid[Board.H-1][0] == 8,"eligible garbage enters with specified hole")
 a = Board.new()
 for y in range(Board.H-4,Board.H):
  for x in 10: a.grid[y][x] = 8 if x != 4 else 0
 a.grid[Board.H-5][0] = 2
 a.piece = 6
 a.rotation = 1
 a.pos = Vector2i(2,Board.H-4)
 a.receive_garbage(4,5,19)
 a._lock()
 check(a.lines == 4 and a.pending.is_empty(),"quad cancels four pending garbage lines")
 check(a.events.is_empty(),"canceled attack is not also sent")
 check(a.grid[Board.H-1][0] == 2,"cleared rows compact correctly")
 a = Board.new()
 for y in range(Board.H-4,Board.H):
  for x in 10: a.grid[y][x] = 8 if x != 4 else 0
 a.piece = 6
 a.rotation = 1
 a.pos = Vector2i(2,Board.H-4)
 a._lock()
 check(a.events[0].attack == 10 and a.label == "PERFECT CLEAR","perfect clear attack uses explicit rules")
 a = Board.new()
 a.piece = 1
 a.pos = Vector2i(3,Board.H-4)
 a.rotation = 0
 a.last_rotate = true
 a.grid[Board.H-4][3] = 8
 a.grid[Board.H-4][5] = 8
 a.grid[Board.H-2][3] = 8
 check(a._spin_type() == 2,"three-corner full T-spin recognition")
 a.grid[Board.H-4][5] = 0
 a.grid[Board.H-2][5] = 8
 check(a._spin_type() == 1,"front-corner test distinguishes mini")
 a.kick_index = 4
 check(a._spin_type() == 2,"fifth kick upgrades mini")
 a = Board.new()
 a.piece = 0
 a.delay = 33.3333
 a.step(1000.0/120,Board.CW)
 for i in 3: a.step(1000.0/120,0)
 check(a.rotation == 1,"short early rotation buffer survives clear delay")
 a = Board.new(3,{}, {"entry_ms":0.0,"clear_ms":0.0})
 a.step(1000.0/120,Board.HARD)
 var placed = a.pieces
 for i in 10: a.step(1000.0/120,Board.HARD)
 check(a.pieces == placed,"held hard drop cannot drop following pieces")
 a = Board.new()
 a.piece = 7
 a.pos = Vector2i(3,Board.H-2)
 a.lock_clock = 200
 check(a.rotate(1) and a.lock_clock == 0 and a.lock_resets == 1,"O rotation resets lock without shifting the piece")
 a.lock_resets = 0
 for i in 16:
  a.lock_clock = 200
  a.move(1 if i%2 == 0 else -1)
 check(a.lock_resets == 15 and a.lock_clock == 200,"floor movement cannot reset lock forever")
 var room = Session.new()
 room.hosting = true
 root.add_child(room)
 room.change_player(-1,"One","Keyboard",166.67,33.33)
 room.change_player(-2,"Two","Keyboard 2",83.33,16.67)
 room.change_player(0,"Three","Pad 1",100,20)
 room.change_player(1,"Four","Pad 2",100,20)
 room.change_player(2,"Five","Pad 3",100,20)
 check(room.roster.size() == 4,"active player limit applies across devices")
 check(room._owns(1,"1:-1") and not room._owns(2,"1:-1"),"board ownership prevents cross-peer submissions")
 check(room._valid_state(a.snapshot()),"valid board can cross network boundary")
 var broken = a.snapshot()
 broken.grid = [[999]]
 check(not room._valid_state(broken),"malformed board snapshot rejected")
 room.free()
 print("CORE TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
