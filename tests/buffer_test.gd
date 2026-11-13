extends SceneTree

const Board = preload("res://scripts/board.gd")
const Session = preload("res://scripts/session.gd")
const TICK = 1000.0/120.0
var checks = 0
var failures = 0

func check(value: bool, message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func min_y(board) -> int:
 var top = Board.H
 for c in board.cells(): top = mini(top,board.pos.y+c.y)
 return top

func _initialize():
 var b = Board.new()
 check(b.grid.size() == 40 and Board.VISIBLE_ROWS == 20 and Board.BUFFER_ROWS == 20,"20 visible rows plus 20 stored hidden rows")
 check(b.grid.all(func(row): return row.size() == 10),"buffer has the same ten columns as the visible board")
 for kind in range(1,8):
  b = Board.new()
  b._spawn(kind)
  check(b.pos == Vector2i(3,Board.VISIBLE_TOP-1) and b.fits(b.pos),"piece %d retains its spawn height relative to the skyline"%kind)
  var visible = false
  for c in b.cells(): visible = visible or b.pos.y+c.y >= Board.VISIBLE_TOP
  check(visible,"piece %d still enters the visible field immediately"%kind)
 # Every I rotation transition, including fully hidden positions.
 for above in [1,3,4,10,18]:
  for rotation in 4:
   for turn in [-1,1]:
    b = Board.new()
    b.piece = 6
    b.rotation = rotation
    b.pos = Vector2i(3,Board.VISIBLE_TOP-above)
    var before = b.pos
    check(b.rotate(turn) and b.rotation == posmod(rotation+turn,4) and b.pos == before and b.alive,"I rotation %d/%d at %d rows above skyline has no false ceiling"%[rotation,turn,above])
 # Real high-stack I kick: first four SRS candidates collide. The fifth lifts
 # the I two rows, leaving three cells above the skyline and one visible.
 b = Board.new()
 b._spawn(6)
 for x in [3,5,6]: b.grid[Board.VISIBLE_TOP+1][x] = 8
 check(b.fits(b.pos),"high-stack I fixture starts in a legal horizontal position")
 check(b.rotate(1) and b.kick_index == 4 and b.pos == Vector2i(4,Board.VISIBLE_TOP-3),"I uses its fifth SRS kick into the hidden buffer")
 check(not b.fits(b.pos+Vector2i(0,1)) and min_y(b) == Board.VISIBLE_TOP-3,"kicked I is grounded with three cells above skyline")
 b.queue[0] = 7
 b._lock()
 check(b.alive and b.pieces == 1,"partly visible I lock is not a top-out")
 var retained = true
 for y in range(Board.VISIBLE_TOP-3,Board.VISIBLE_TOP+1): retained = retained and b.grid[y][6] == 6
 check(retained,"all four I cells survive the lock, including the upper three")
 b.step(100.0,0)
 check(b.alive and b.piece == 7,"next piece spawns normally after partly hidden I lock")
 # The old two-row store could lose the top cell of this legal placement.
 for above in [1,2,3]:
  b = Board.new()
  b.piece = 6
  b.rotation = 1
  b.pos = Vector2i(0,Board.VISIBLE_TOP-above)
  b.grid[Board.VISIBLE_TOP-above+4][2] = 8
  b._lock()
  check(b.alive,"I lock with %d hidden cells remains alive"%above)
  check(b.grid[Board.VISIBLE_TOP-above][2] == 6,"upper I cell is retained with %d hidden cells"%above)
 b = Board.new()
 b.piece = 6
 b.rotation = 1
 b.pos = Vector2i(0,Board.VISIBLE_TOP-4)
 check(b.fits(b.pos) and b.alive,"fully hidden active piece can still be manipulated")
 b._lock()
 check(not b.alive,"locking all four cells above skyline still locks out")
 b = Board.new()
 b.grid[Board.SPAWN_Y][4] = 8
 b._spawn(7)
 check(not b.alive,"occupied spawn cells still block out")
 # Hidden cells participate in collisions and fall back into view on clears.
 b = Board.new()
 b.piece = 6
 b.rotation = 1
 b.pos = Vector2i(0,Board.VISIBLE_TOP-3)
 b.grid[Board.VISIBLE_TOP-3][2] = 8
 check(not b.fits(b.pos),"hidden buffer cells are solid, not discarded or ignored")
 b = Board.new()
 b.grid[Board.VISIBLE_TOP-1][0] = 2
 for x in 8: b.grid[Board.H-1][x] = 8
 b.piece = 7
 b.pos = Vector2i(7,Board.H-2)
 b._lock()
 check(b.lines == 1 and b.grid[Board.VISIBLE_TOP][0] == 2,"line clear pulls a hidden cell into visible top row")
 check(b.grid.size() == Board.H,"row compaction retains full buffer height")
 # Garbage can push blocks into the buffer; only its real top is overflow.
 b = Board.new()
 b.grid[Board.VISIBLE_TOP+2][0] = 3
 b.receive_garbage(5,9,1)
 b.pending[0].remaining = 0
 b._raise_garbage()
 check(b.alive and b.grid[Board.VISIBLE_TOP-3][0] == 3,"five garbage rows preserve cells beyond the old two-row buffer")
 check(b.grid[Board.H-1][0] == 8 and b.grid[Board.H-1][9] == 0,"garbage holes and bottom rows remain correct")
 b = Board.new()
 b.grid[1][0] = 4
 b.receive_garbage(1,9,2)
 b.pending[0].remaining = 0
 b._raise_garbage()
 check(b.alive and b.grid[0][0] == 4,"cell at the top stored row is still in bounds")
 b.receive_garbage(1,9,3)
 b.pending[0].remaining = 0
 b._raise_garbage()
 check(not b.alive and b.grid.size() == Board.H,"pushing a cell beyond the full buffer still tops out")
 b = Board.new()
 b.piece = 6
 b.rotation = 1
 check(b.fits(Vector2i(0,0)) and not b.fits(Vector2i(0,-1)),"true buffer ceiling is finite and collision checked")
 check(b.fits(Vector2i(0,Board.H-4)) and not b.fits(Vector2i(0,Board.H-3)),"visible floor does not move relative to the bottom")
 b = Board.new()
 b.piece = 6
 b.rotation = 1
 b.pos = Vector2i(3,Board.VISIBLE_TOP-3)
 check(b.ghost_y() == Board.H-4,"ghost falls from hidden area to the same visible floor")
 b.step(TICK,Board.HARD)
 check(b.alive and b.pieces == 1 and b.grid[Board.H-1][5] == 6,"hard drop from buffer lands and locks at the floor")
 b = Board.new()
 b._spawn(6)
 b.step(TICK,Board.HOLD)
 check(b.alive and b.held == 6 and b.pos.y == Board.VISIBLE_TOP-1,"hold respawns at the skyline, not the buffer ceiling")
 # All 40 rows, including invisible cells, cross the network boundary.
 var session = Session.new()
 b = Board.new()
 b.grid[2][1] = 3
 b.grid[Board.VISIBLE_TOP-1][7] = 5
 b.grid[Board.H-1][9] = 8
 var state = b.snapshot()
 check(session._valid_state(state),"expanded snapshot validates")
 var packed = session._pack(state)
 var decoded = session._unpack(packed)
 check(packed.size() < 8192 and session._valid_state(decoded),"40-row snapshot fits the existing packet budget")
 check(decoded.grid == state.grid,"network round trip retains hidden and visible cells exactly")
 var legacy = state.duplicate(true)
 legacy.grid = legacy.grid.slice(18)
 check(not session._valid_state(legacy),"old 22-row snapshots are rejected")
 state.flash = [Board.H-1]
 check(session._valid_state(state),"visible floor flash row validates after expansion")
 state.flash = [Board.H]
 check(not session._valid_state(state),"out-of-bounds flash row is rejected")
 session.free()
 print("BUFFER TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
