extends SceneTree

const Board = preload("res://scripts/board.gd")
const Session = preload("res://scripts/session.gd")
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

func nonclear(board):
 board.events.clear()
 board._spawn(7)
 board.pos.x = 6
 board.pos.y = board.ghost_y()
 board._lock()

func test_two_wide_finish():
 # An actual continuous field: twelve rows of a two-wide well above eight
 # rows of a one-wide well. Six O doubles lead directly into two I quads.
 var b = Board.new()
 for row in b.grid: row.fill(0)
 for y in range(Board.H-20,Board.H):
  b.grid[y].fill(2)
  b.grid[y][4] = 0
  if y < Board.H-8: b.grid[y][5] = 0
 b.grid[Board.H-21][0] = 3 # Keep the final clear from becoming a PC.
 var expected = [1,1,1,1,2,2,10,12]
 for i in expected.size():
  b.events.clear()
  b.piece = 7 if i < 6 else 6
  b.rotation = 0 if i < 6 else 1
  b.pos = Vector2i(3,Board.H-10) if i < 6 else Vector2i(2,Board.H-4)
  b.last_rotate = false
  check(b.fits(b.pos),"two-wide placement %d fits the evolving field"%(i+1))
  b._lock()
  check(outgoing(b) == expected[i],"two-wide placement %d sends %d"%[i+1,expected[i]])
 check(b.alive and b.lines == 20 and b.pieces == 8 and b.sent == 30,"six doubles and two quads complete without resetting the field")
 check(b.combo == 7 and b.b2b == 1,"the finishing quads keep the combo and start a fresh B2B chain")

func test_blocking_and_cancellation():
 var b = Board.new()
 b.receive_garbage(10,6,1000)
 b.pending[0].remaining = -50.0
 for i in 2:
  prepare(b,1)
  b._lock()
  check(outgoing(b) == 0 and b.pending[0].amount == 10,"zero-attack single blocks all ten ready rows")
 prepare(b,1,2)
 b._lock()
 check(outgoing(b) == 0 and b.pending[0].amount == 7,"three-point combo T-spin cancels exactly three; seven remain blocked")
 check(b.pending[0].remaining == -50.0,"countering does not reset or extend the garbage timer")
 nonclear(b)
 check(b.pending.is_empty() and b.combo == -1 and b.alive,"non-clearing placement releases the seven ready rows")
 var aligned = true
 for y in range(Board.H-7,Board.H):
  for x in Board.W:
   aligned = aligned and b.grid[y][x] == (0 if x == 6 else 8)
 check(aligned,"released garbage retains its exact row count and hole")

 b = Board.new()
 b.receive_garbage(3,2,1001)
 b.pending[0].remaining = -10.0
 b.receive_garbage(5,7,1002)
 prepare(b,4)
 b._lock()
 check(outgoing(b) == 0 and b.pending.size() == 1 and b.pending[0].id == 1002 and b.pending[0].amount == 4,"FIFO cancellation spans ready and travelling packets one-for-one, even in the opener")
 check(b.pending[0].remaining == 1000.0,"partly cancelled travelling packet keeps its original deadline")
 nonclear(b)
 check(b.pending.size() == 1 and b.pending[0].amount == 4,"ending a combo cannot insert garbage before its warning expires")

 b = Board.new()
 b.receive_garbage(6,1,1003)
 b.pending[0].remaining = -1.0
 b.b2b = 5
 prepare(b,4)
 b._lock()
 check(b.b2b == 6 and outgoing(b) == 4 and b.pending.is_empty() and b.sent == 4,"ten-point attack cancels six and sends only its four-point excess")

func test_large_attacks_and_wire_state():
 var room = Session.new()
 root.add_child(room)
 room.make_local()
 room.change_player(-1,"Attacker","Keyboard",166.67,33.33)
 room.change_player(-2,"Receiver","Keyboard 2",166.67,33.33)
 room.change_player(0,"Other","Pad",166.67,33.33)
 room.begin()
 var packets = []
 room.garbage_arrived.connect(func(id,amount,hole,packet): packets.append({"target":id,"amount":amount,"hole":hole,"id":packet}))
 var sender = Board.new()
 sender.b2b = 50
 prepare(sender,4)
 sender._lock()
 check(outgoing(sender) == 55 and sender.b2b == 51,"long B2B chain produces an attack above the former board and router limits")
 room.attack("1:-1",outgoing(sender))
 room.attack("1:-1",24)
 check(packets.size() == 2 and packets[0].amount == 55 and packets[1].amount == 24,"large attacks reach the local routing signal without truncation or splitting")
 check(packets[0].target == "1:-2" and packets[1].target == "1:0" and packets[0].id != packets[1].id,"target rotation advances once per attack and packet ids remain distinct")
 var receiver = Board.new()
 var packet = packets[0]
 receiver.receive_garbage(packet.amount,packet.hole,packet.id)
 receiver.receive_garbage(packet.amount,packet.hole,packet.id)
 check(receiver.pending.size() == 1 and receiver.pending[0].amount == 55,"receiver keeps the full large packet and ignores a duplicate")
 var decoded = room._unpack(room._pack(receiver.snapshot()))
 check(room._valid_state(decoded) and decoded.pending[0].amount == 55,"large pending packet survives serialization and snapshot validation")
 decoded = room._unpack(room._pack(sender.snapshot()))
 check(room._valid_state(decoded) and decoded.b2b == 51,"numeric B2B counter survives serialization")
 decoded.b2b = true
 check(not room._valid_state(decoded),"old boolean B2B snapshot is rejected")
 decoded.b2b = -2
 check(not room._valid_state(decoded),"invalid B2B counter is rejected")
 var count_before = packets.size()
 for amount in [0,-1,Board.MAX_ATTACK+1]: room.attack("1:-1",amount)
 room._route_attack(99,"1:-1",55)
 check(packets.size() == count_before,"invalid amounts and unowned attacks are rejected")
 room.free()

 check(receiver._cancel(40) == 0 and receiver.pending[0].amount == 15,"partial cancellation preserves the remainder of a large attack")
 check(receiver._cancel(18) == 3 and receiver.pending.is_empty(),"overcancelling a large packet returns only unused attack")
 receiver.receive_garbage(Board.MAX_ATTACK,3,2000)
 receiver.pending[0].remaining = 0.0
 receiver._raise_garbage()
 check(not receiver.alive and receiver.grid.size() == Board.H and receiver.pending.is_empty(),"extreme packet overflows safely with work bounded by board height")
 var filled = true
 for row in receiver.grid:
  for x in Board.W: filled = filled and row[x] == (0 if x == 3 else 8)
 check(filled,"bounded overflow produces the same final grid as inserting every identical row")

func shaft_matches(board, depth: int, hole: int) -> bool:
 for y in Board.H:
  for x in Board.W:
   var expected = 8 if y >= Board.H-depth and x != hole else 0
   if board.grid[y][x] != expected: return false
 return true

func test_attack_shafts():
 var room = Session.new()
 root.add_child(room)
 room.make_local()
 room.change_player(-1,"Attacker","Keyboard",166.67,33.33)
 room.change_player(-2,"Receiver","Keyboard 2",166.67,33.33)
 room.begin()
 room.attack_rng.seed = 71203
 var packets = []
 room.garbage_arrived.connect(func(id,amount,hole,packet): packets.append({"target":id,"amount":amount,"hole":hole,"id":packet}))
 # Actual locks -> attacks -> routing -> receiver rows. Bonuses deepen the
 # same shaft; sender cancellation reduces its depth before transmission.
 var examples = [[2,0,-1,-1,1,0],[3,0,-1,-1,2,0],[4,0,-1,-1,4,0],[2,2,-1,3,8,0],[2,2,3,3,12,0],[3,0,-1,-1,1,1]]
 for example in examples:
  var sender = Board.new()
  sender.combo = example[2]
  sender.b2b = example[3]
  if example[5] > 0: sender.receive_garbage(example[5],3,100)
  prepare(sender,example[0],example[1])
  sender._lock()
  check(outgoing(sender) == example[4],"source clear generates the expected shaft depth")
  var previous = packets.size()
  room.attack("1:-1",outgoing(sender))
  check(packets.size() == previous+1,"each clear sends exactly one attack packet")
  var packet = packets[-1]
  check(packet.target == "1:-2" and packet.id == packets.size() and packet.amount == example[4],"packet preserves its target, identity and exact attack value")
  var receiver = Board.new()
  receiver.receive_garbage(packet.amount,packet.hole,packet.id)
  receiver.pending[0].remaining = 0.0
  receiver._raise_garbage()
  check(receiver.alive and receiver.pending.is_empty() and shaft_matches(receiver,example[4],packet.hole),"receiver gets one aligned shaft exactly as deep as the attack")
 for amount in [7,8,24]:
  room.attack("1:-1",amount)
  var packet = packets[-1]
  var receiver = Board.new()
  receiver.receive_garbage(packet.amount,packet.hole,packet.id)
  receiver.pending[0].remaining = 0.0
  receiver._raise_garbage()
  check(shaft_matches(receiver,amount,packet.hole),"same one-shaft rule applies on both sides of the removed cutoff")

 var b = Board.new()
 b.receive_garbage(1,2,3000)
 b.receive_garbage(2,7,3001)
 for packet in b.pending: packet.remaining = -5.0
 var decoded = room._unpack(room._pack(b.snapshot()))
 check(room._valid_state(decoded) and decoded.pending == b.pending,"separate one-deep and two-deep shafts survive spectator serialization")
 b._raise_garbage()
 var exact = true
 for row in 3:
  for x in Board.W: exact = exact and b.grid[Board.H-3+row][x] == (0 if x == [2,7,7][row] else 8)
 check(exact and b.pending.is_empty(),"separate attacks keep their own columns when rising together")

 b = Board.new()
 b.receive_garbage(1,2,3002)
 b.receive_garbage(2,7,3003)
 for packet in b.pending: packet.remaining = -5.0
 check(b._cancel(2) == 0 and b.pending.size() == 1 and b.pending[0].id == 3003,"FIFO cancellation removes the first shaft and one row of the second")
 check(b.pending[0].amount == 1 and b.pending[0].hole == 7 and b.pending[0].remaining == -5.0,"partial cancellation preserves the remaining column and warning deadline")
 b._raise_garbage()
 check(shaft_matches(b,1,7),"cancelled triple leaves the correct one-deep shaft")
 b = Board.new()
 b.receive_garbage(8,6,3004)
 b._cancel(5)
 b.pending[0].remaining = 0.0
 b._raise_garbage()
 check(shaft_matches(b,3,6),"cancelling five from an eight-row attack leaves a three-deep shaft")

 decoded.pending[0].row_holes = [2]
 check(not room._valid_state(decoded),"old per-row pattern snapshots are rejected")
 var crowded = Board.new()
 for i in 128: crowded.receive_garbage(1+i%12,i%10,5000+i)
 decoded = room._unpack(room._pack(crowded.snapshot()))
 check(room._valid_state(decoded) and decoded.pending == crowded.pending,"maximum 128-packet shaft queue fits the wire-size limits")
 room.free()

func _initialize():
 # Expected game-facing outcomes, before incoming-garbage cancellation.
 for example in [[1,0,0],[2,0,1],[3,0,2],[4,0,4],[1,2,2],[2,2,4],[3,2,6],[1,1,0],[2,1,1]]:
  var b = Board.new()
  prepare(b,example[0],example[1])
  b._lock()
  check(b.lines == example[0] and outgoing(b) == example[2],"base attack for clear %s"%[example])
  if example[1] > 0 or example[0] == 4:
   b = Board.new()
   b.b2b = 0
   prepare(b,example[0],example[1])
   b._lock()
   check(outgoing(b) == example[2]+1,"back-to-back adds one for difficult clear")
 var b = Board.new()
 # A chain of singles isolates combo attack. First clear is not combo 1.
 var expected = [0,0,1,1,1,1,2,2,2,2,2,2,2,2,2,2,3]
 for index in expected.size():
  prepare(b,1)
  b._lock()
  check(outgoing(b) == expected[index] and b.combo == index,"combo chain clear %d"%(index+1))
 for row in b.grid: row.fill(0)
 b.piece = 7
 b.rotation = 0
 b.pos = Vector2i(3,Board.H-2)
 b.b2b = 4
 b._lock()
 check(b.combo == -1 and b.b2b == 4,"non-clear ends combo but preserves the exact back-to-back count")
 prepare(b,2)
 b._lock()
 check(b.b2b == -1 and outgoing(b) == 1,"ordinary clear breaks back-to-back without a surge and starts fresh combo")
 for boosted in [false,true]:
  b = Board.new()
  b.b2b = 10 if boosted else -1
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
 # Independently specified examples catch combo indexing, floor rounding, and
 # applying the growing B2B bonus in the wrong order.
 for example in [[2,0,2,-1,1],[3,0,1,-1,3],[2,2,-1,2,7],[2,2,-1,3,8],[2,2,3,3,12],[1,1,3,3,5],[4,0,19,-1,24]]:
  b = Board.new()
  b.combo = example[2]
  b.b2b = example[3]
  prepare(b,example[0],example[1])
  b._lock()
  check(outgoing(b) == example[4],"combo and flat B2B example %s"%[example])
 b = Board.new()
 for i in 7:
  prepare(b,2,2)
  b._lock()
  check(outgoing(b) == 4+i and b.b2b == i,"separate T-spin double %d grows the flat B2B reward"%(i+1))
  nonclear(b)
  check(b.b2b == i and b.combo == -1,"building between difficult clears keeps B2B but ends combo")
 b = Board.new()
 var sequence = [[3,2],[1,0],[1,1],[4,7]]
 for example in sequence:
  prepare(b,example[0])
  b._lock()
  check(outgoing(b) == example[1],"documented triple-single-single-quad combo")
 test_two_wide_finish()
 test_blocking_and_cancellation()
 test_large_attacks_and_wire_state()
 test_attack_shafts()
 print("GARBAGE TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
