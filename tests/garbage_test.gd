extends SceneTree

const Board = preload("res://scripts/board.gd")
var checks = 0
var failures = 0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

# Build a final lock position with the requested full rows. Recognition uses
# the real three-corner test; these fixtures do not claim an exhaustive SRS test.
func prepare(board, cleared: int, spin: int = 0, perfect: bool = false):
 for row in board.grid: row.fill(0)
 board.events.clear()
 board.piece = 6 if spin == 0 else 1
 board.rotation = 1
 board.pos = Vector2i(2,Board.H-4) if spin == 0 else Vector2i(3,Board.H-3)
 board.last_rotate = spin > 0
 board.kick_index = 0
 for y in range(Board.H-cleared,Board.H): board.grid[y].fill(8)
 if spin > 0:
  board.grid[Board.H-3][3] = 8
  if spin == 2: board.grid[Board.H-3][5] = 8
 for c in board.cells(): board.grid[board.pos.y+c.y][board.pos.x+c.x] = 0
 if not perfect: board.grid[Board.H-5][0] = 8
 check(board.fits(board.pos),"fixture fits without overlapping fixed blocks")
 if spin > 0: check(board._spin_type() == spin,"fixture has expected full/mini spin recognition")

func outgoing(board) -> int:
 return int(board.events[0].attack) if not board.events.is_empty() else 0

func _initialize():
 # Expected game-facing outcomes, before incoming-garbage cancellation.
 for example in [[1,0,0],[2,0,1],[3,0,2],[4,0,4],[1,2,2],[2,2,4],[3,2,6],[1,1,0],[2,1,1]]:
  var b = Board.new()
  prepare(b,example[0],example[1])
  b._lock()
  check(b.lines == example[0] and outgoing(b) == example[2],"base attack for clear %s"%[example])
  if example[1] > 0 or example[0] == 4:
   b = Board.new()
   b.b2b = true
   prepare(b,example[0],example[1])
   b._lock()
   check(outgoing(b) == example[2]+1,"back-to-back adds one for difficult clear")
 var b = Board.new()
 # A chain of singles isolates combo attack. First clear is not combo 1.
 var expected = [0,0,1,1,2,2,3,3,4,4,4,5,5,5,5]
 for index in expected.size():
  prepare(b,1)
  b._lock()
  check(outgoing(b) == expected[index] and b.combo == index,"combo chain clear %d"%(index+1))
 for row in b.grid: row.fill(0)
 b.piece = 7
 b.rotation = 0
 b.pos = Vector2i(3,Board.H-2)
 b.b2b = true
 b._lock()
 check(b.combo == -1 and b.b2b,"non-clear ends combo but preserves back-to-back")
 prepare(b,2)
 b._lock()
 check(not b.b2b and outgoing(b) == 1,"ordinary clear breaks back-to-back and starts fresh combo")
 for boosted in [false,true]:
  b = Board.new()
  b.b2b = boosted
  b.combo = 10 if boosted else -1
  prepare(b,4,0,true)
  b._lock()
  check(outgoing(b) == 10 and b.label == "PERFECT CLEAR","perfect clear is ten total, even with B2B/combo")
 b = Board.new()
 prepare(b,4,0,true)
 b.receive_garbage(4,3,100)
 b._lock()
 check(outgoing(b) == 6 and b.pending.is_empty(),"perfect clear cancels four and sends remaining six")
 b = Board.new()
 prepare(b,2)
 b.receive_garbage(3,3,101)
 b._lock()
 check(outgoing(b) == 0 and b.pending[0].amount == 2,"double subtracts one from incoming garbage")
 print("GARBAGE TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
