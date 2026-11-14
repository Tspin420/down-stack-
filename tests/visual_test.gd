extends SceneTree

const Board = preload("res://scripts/board.gd")
const View = preload("res://scripts/board_view.gd")
const Session = preload("res://scripts/session.gd")
var checks = 0
var failures = 0
var draws = 0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func _initialize(): run.call_deferred()

func run():
 var view = View.new()
 view.player = {"name":"Visual regression","das":166.6667,"arr":33.3333,"soft_drop":-1.0}
 view.size = Vector2(490,730)
 view.draw.connect(func(): draws += 1)
 root.add_child(view)
 view.set_process(false) # Explicit presentation steps make tests deterministic.
 var board = Board.new(183)
 var reference = Board.new(183)
 var session = Session.new()
 check(not view.is_processing(),"idle view has no per-frame callback")
 view.data = board.snapshot()
 await process_frame
 await process_frame
 var drawn = draws
 await process_frame
 await process_frame
 check(draws == drawn,"unchanged board retains cached drawing")
 view.data = board.snapshot()
 await process_frame
 await process_frame
 check(draws > drawn,"new board snapshot invalidates drawing")
 drawn = draws
 view.data = view.data
 await process_frame
 await process_frame
 check(draws == drawn,"same remote dictionary does not redraw between network updates")
 view.own = true
 view.player = view.player.duplicate()
 view.size.x = 410
 await process_frame
 await process_frame
 check(draws > drawn,"ownership, player metadata and resizing refresh the view")
 check(View.BLOCK_TEXTURE.get_width() == 64 and View.BLOCK_TEXTURE.get_height() == 64,"original tile imports at its small intended size")
 for kind in range(1,8):
  for rotation in 4:
   check(View._shape_cells[kind][rotation] == board.cells(kind,rotation),"cached geometry matches engine for every piece and rotation")
 # Comparing two seeded simulations catches accidental writes to snapshots or models.
 var unchanged = true
 for tick in 480:
  if not board.alive:
   board = Board.new(183+tick)
   reference = Board.new(183+tick)
  var mask = [0,Board.LEFT,Board.CW,0,Board.HOLD,0,Board.RIGHT,Board.HARD][tick%8]
  board.step(1000.0/120.0,mask)
  reference.step(1000.0/120.0,mask)
  var state = board.snapshot()
  var untouched = state.duplicate(true)
  view.data = state
  view._process(1.0/120.0)
  unchanged = unchanged and state == untouched and board.snapshot() == reference.snapshot()
 check(unchanged,"480 presentation/input ticks across round resets preserve snapshots and seeded simulation")
 check(session._valid_state(view.data),"unchanged snapshot schema remains network-valid")
 var state = Board.new().snapshot()
 state.lines = 4
 state.pieces = 10
 state.flash = [36,37,38,39]
 var untouched = state.duplicate(true)
 view.data = state
 check(view._clear_spans == [Vector2i(36,39)] and view.is_processing(),"quad starts one continuous four-row presentation band")
 view._process(0.04)
 var remaining = view._clear_left
 view.data = state
 check(view._clear_left == remaining,"reassigning the same remote snapshot does not restart clear")
 view.data = state.duplicate(true)
 check(view._clear_left == remaining,"equivalent fresh snapshot does not restart clear")
 view._process(1.0)
 check(view._clear_left == 0.0 and view._clear_spans.is_empty() and not view.is_processing(),"large frame delta expires and disables effect processing")
 view.data = state.duplicate(true)
 check(view._clear_left == 0.0,"frozen sprint or spectator snapshot cannot leave a persistent flash")
 check(state == untouched,"clear timing does not mutate incoming flash rows")
 state = state.duplicate(true)
 state.lines += 4
 state.pieces += 1
 view.data = state
 check(view._clear_left == View.CLEAR_SECONDS,"consecutive clear of identical rows is a new event")
 view.data = {}
 check(view._clear_spans.is_empty() and not view.is_processing(),"waiting state removes stale effects")
 view.data = state
 view.data = Board.new().snapshot()
 check(view._clear_left == 0.0,"round counter reset clears old animation")
 var other = View.new()
 other.player = {"name":"Other player","das":83.3333,"arr":16.6667,"soft_drop":0.0}
 other.data = Board.new().snapshot()
 root.add_child(other)
 view.data = state
 check(other._clear_left == 0.0 and not other.is_processing(),"one player's effect does not affect another board")
 check(view.player.das != other.player.das and view.player.soft_drop != other.player.soft_drop,"independent handling metadata is retained")
 for count in range(1,5):
  var rows = []
  for row in range(Board.H-count,Board.H): rows.append(row)
  check(View._make_clear_spans(rows) == [Vector2i(Board.H-count,Board.H-1)],"one band covers every adjacent row in a single, double, triple or quad")
 check(View._make_clear_spans([34,36,37,39]) == [Vector2i(34,34),Vector2i(36,37),Vector2i(39,39)],"separate clears leave uncleared rows unpainted")
 var unsorted = [39,38,38,19]
 check(View._make_clear_spans(unsorted) == [Vector2i(38,39)] and unsorted == [39,38,38,19],"unsorted duplicate rows merge without mutating a network snapshot")
 check(View._make_clear_spans([19,20,21]) == [Vector2i(20,21)],"band clips at the visible top without painting the hidden buffer")
 check(View._make_clear_spans([]).is_empty(),"empty clear creates no bands")
 check(View._make_clear_spans([0,19,40,99]).is_empty(),"hidden and out-of-field rows create no visible bands")
 # Geometry checks supplement the captures: all preview shapes must fit, with
 # the I/O's occupied cells centered and no overlap with the reserved meter.
 for width in [320,410,490]:
  for panel_height in [480,650,730]:
   view.size = Vector2(width,panel_height)
   var well = Rect2(view._origin,Vector2(view._cell*10,view._cell*20))
   var meter = Rect2(view._origin-Vector2(20,2),Vector2(14,view._cell*20+4))
   var bounds = Rect2(Vector2.ZERO,view.size)
   var fits = bounds.encloses(well.grow(5)) and bounds.encloses(view._hold_rect) and bounds.encloses(view._next_rect)
   fits = fits and not well.grow(5).intersects(meter) and not view._hold_rect.intersects(meter)
   fits = fits and not well.grow(5).intersects(view._next_rect)
   check(fits,"previews, frame and meter fit without overlap at each supported width and short/tall height")
  check(view._preview_cell > 10 and view._origin.x > 68,"previews grow and the well shifts right in every player layout")
 view.size = Vector2(490,730)
 check(view._preview_cell == 18 and view._cell >= 27,"large panel enlarges previews 80 percent while retaining board cell size")
 for kind in range(1,8):
  var slot = Rect2(Vector2.ZERO,Vector2(view._hold_rect.size.x,view._preview_step))
  var occupied: Rect2 = View._preview_bounds[kind]
  var at = slot.get_center()-occupied.size*view._preview_cell/2-occupied.position*view._preview_cell
  var actual = Rect2(at+Vector2(View._shape_cells[kind][0][0])*view._preview_cell,Vector2.ONE*view._preview_cell)
  for cell in View._shape_cells[kind][0]:
   actual = actual.merge(Rect2(at+Vector2(cell)*view._preview_cell,Vector2.ONE*view._preview_cell))
  check(slot.encloses(actual) and actual.get_center().is_equal_approx(slot.get_center()),"each piece preview fits and centers its occupied cells")
 # Use real engine packets to exercise receiving, countdown, cancellation and
 # arrival rather than maintaining an independent presentation timer.
 var garbage_board = Board.new(91)
 garbage_board.receive_garbage(4,2,1)
 garbage_board.receive_garbage(3,6,2)
 view.data = garbage_board.snapshot()
 check(view._incoming == 7 and view._visible_garbage == 7 and view._garbage_rows[0] == 0,"received packets stack bottom-up at one segment per line")
 garbage_board.step(800,0)
 view.data = garbage_board.snapshot()
 check(view._garbage_rows[0] == 1 and view._garbage_rows[6] == 1,"engine countdown changes the meter to the imminent color")
 garbage_board.receive_garbage(2,0,3)
 view.data = garbage_board.snapshot()
 check(view._garbage_rows[6] == 1 and view._garbage_rows[7] == 0,"later packets retain their own urgency above earlier packets")
 check(garbage_board._cancel(5) == 0,"existing attack cancellation consumes pending rows")
 view.data = garbage_board.snapshot()
 check(view._incoming == 4 and view._visible_garbage == 4 and view._garbage_rows[1] == 1 and view._garbage_rows[2] == 0,"partial cancellation rebuilds the displayed queue with the right boundaries")
 garbage_board.step(250,0)
 view.data = garbage_board.snapshot()
 check(view._incoming == 4 and view._garbage_rows[0] == 2 and view._garbage_rows[2] == 0,"ready packets turn red without prematurely disappearing")
 garbage_board._raise_garbage()
 view.data = garbage_board.snapshot()
 check(view._incoming == 2 and view._visible_garbage == 2 and view._garbage_rows[0] == 0,"arrived rows leave the meter while delayed rows remain")
 garbage_board._cancel(2)
 view.data = garbage_board.snapshot()
 check(view._incoming == 0 and view._visible_garbage == 0,"fully countered garbage leaves an empty meter")
 for i in 128: garbage_board.receive_garbage(40,i%10,100+i)
 var crowded = garbage_board.snapshot()
 var crowded_copy = crowded.duplicate(true)
 view.data = crowded
 check(view._incoming == 5120 and view._visible_garbage == 20 and view._garbage_rows.size() == 20,"128-packet queue keeps the exact total with bounded 20-row rendering")
 view._process(5)
 check(view._incoming == 5120 and view._garbage_rows[0] == 0 and crowded == crowded_copy,"frozen remote snapshots never invent arrival times or mutate packets")
 other.data = Board.new().snapshot()
 check(other._incoming == 0 and view._incoming == 5120,"each player's meter follows only that player's queue")
 view.data = Board.new(91,{}, {"mode":"sprint"}).snapshot()
 check(view._incoming == 0 and view._visible_garbage == 0,"sprint clears previous versus meter state")
 view.data = crowded
 view.data = {}
 check(view._incoming == 0 and view._visible_garbage == 0,"waiting state removes queued-garbage presentation")
 # Amount is nonlinear; urgency remains independent and the meter never loses
 # a one-line warning or draws outside its track at supported panel sizes.
 var levels = View._garbage_levels
 check(levels.size() == 21 and levels[0] == 0.0 and levels[20] == 1.0,"curve has an empty origin and exactly full 20-row endpoint")
 var increasing = true
 var accelerating = true
 for i in range(1,levels.size()):
  increasing = increasing and levels[i] > levels[i-1] and levels[i] <= 1.0
  if i > 1: accelerating = accelerating and levels[i]-levels[i-1] > levels[i-1]-levels[i-2]
 check(increasing,"every additional row increases height without exceeding the track")
 check(accelerating,"each successive incoming row creates a larger height increase")
 for width in [320,410,490]:
  view.size = Vector2(width,480)
  check(levels[1]*view._cell*20 >= 3.0,"a single incoming row remains visible at the shortest tested layout")
 var warning = Board.new().snapshot()
 warning.pending = [{"amount":12,"remaining":800.0,"hole":1,"id":1}]
 view.data = warning
 var fill = levels[view._visible_garbage]
 warning = warning.duplicate(true)
 warning.pending[0].remaining = 0.0
 view.data = warning
 check(levels[view._visible_garbage] == fill and view._garbage_rows[0] == 2,"time changes urgency color without changing the nonlinear amount height")
 warning = warning.duplicate(true)
 warning.pending[0].amount = 4
 view.data = warning
 check(view._incoming == 4 and levels[view._visible_garbage] < fill,"canceling queued rows immediately reduces nonlinear height and exact count")
 # Exercise real draw notifications with hidden cells, ghost, previews, garbage,
 # completion and death at every current layout width. Pixel QA uses visual_capture.gd.
 for width in [320,410,490]:
  for status in ["live","completed","dead"]:
   state = Board.new().snapshot()
   state.grid[0][0] = 8
   state.grid[Board.VISIBLE_TOP][0] = 2
   state.grid[Board.H-1][9] = 8
   state.piece = 6
   state.rotation = 1
   state.y = Board.VISIBLE_TOP-2
   state.held = 1
   state.pending = [{"amount":4,"remaining":0.0,"hole":4,"id":1}]
   state.completed = status == "completed"
   state.alive = status != "dead"
   state.goal = 40 if state.completed else 0
   var saved = state.duplicate(true)
   view.data = state
   view.size = Vector2(width,730)
   view.set_process(false)
   await process_frame
   await process_frame
   check(view.data == saved,"draw path preserves hidden cells, ghost, queue and terminal states")
 other.free()
 view.free()
 session.free()
 print("VISUAL TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
