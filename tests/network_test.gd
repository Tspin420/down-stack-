extends SceneTree

const Session = preload("res://scripts/session.gd")
const Board = preload("res://scripts/board.gd")

class LegacySession:
 extends "res://scripts/session.gd"
 func _ready():
  multiplayer.connected_to_server.connect(func(): _hello.rpc_id(1,7))

var room
var role = "host"
var port = 43971
var elapsed = 0.0
var began = false
var sent = false
var received = {}
var received_packets = {}
var observed_holes = {}
var reported = false
var failed = false
var model
var local_boards = {}

func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
  if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
 room = LegacySession.new() if role == "legacy" else Session.new()
 room.name = "Session"
 root.add_child.call_deferred(room)
 _setup.call_deferred()

func _setup():
 room.lobby_updated.connect(_lobby)
 room.started.connect(_start)
 room.garbage_arrived.connect(_garbage)
 if role == "legacy": room.multiplayer.server_disconnected.connect(_legacy_rejected)
 if role == "host":
  room.net.set_bind_ip("127.0.0.1")
  if room.host(port) != OK: fail("host start")
 else:
  if room.join("127.0.0.1",port) != OK: fail("client start")

func _lobby():
 if role == "legacy":
  fail("protocol 7 client was admitted to a protocol 8 lobby")
  return
 if role == "player" and not room.roster.any(func(p): return p.owner == room.local_id()):
  room.change_player(-1,"Local one","Keyboard",166.67,33.33,false,5.0)
  room.change_player(-2,"Local two","Keyboard 2",83.33,16.67,false,0.0)
 elif role == "remote" and not room.roster.any(func(p): return p.owner == room.local_id()):
  room.change_player(-1,"Remote","Keyboard",100,20,false,-1.0)
 if role == "host" and room.roster.size() == 3 and room.screens == 4 and not began:
  began = true
  room.begin.call_deferred()

func _start(seed_value):
 began = true
 for p in room.roster:
  var expected = {"Local one":5.0,"Local two":0.0,"Remote":-1.0}
  if not p.has("soft_drop") or p.soft_drop != expected[p.name]: fail("per-player soft drop lost in roster replication")
  if p.owner == room.local_id():
   var board = Board.new(seed_value,{"soft_drop":p.soft_drop},room.rules)
   board.grid[Board.VISIBLE_TOP-3][0] = 2
   board.grid[Board.H-1][9] = 8
   board.b2b = 6 if role == "remote" else 0
   local_boards[p.id] = board
 print(role+" MATCH STARTED players="+str(room.roster.size())+" owned="+str(local_boards.size()))

func _garbage(id,amount,hole,packet):
 observed_holes[packet] = hole
 if local_boards.has(id):
  var b = local_boards[id]
  var index = b.pending.size()
  var expected = [24,1,4] if id.ends_with(":-1") else [55,2]
  if index >= expected.size():
   fail("attack was split or duplicated")
   return
  b.receive_garbage(amount,hole,packet)
  if b.pending.size() != index+1 or b.pending[-1].remaining != 1000.0: fail("garbage warning interval not preserved")
  if amount != expected[index] or b.pending[-1].amount != expected[index]: fail("attack was truncated or routed to the wrong board")
  if b.pending[-1].hole != hole: fail("shaft column changed during delivery")
  if hole < 0 or hole >= Board.W or received_packets.has(packet): fail("invalid hole or repeated packet identity")
  received[id] = index+1
  received_packets[packet] = true

func _legacy_rejected():
 if elapsed >= 2.0:
  fail("old-client disconnect was not prompt protocol rejection")
  return
 print("legacy NETWORK PASS: protocol 7 rejected before lobby admission")
 quit(0)

func make_attack(cleared: int, previous_b2b: int = -1) -> int:
 var b = Board.new()
 for y in range(Board.H-cleared,Board.H):
  b.grid[y].fill(8)
  b.grid[y][4] = 0
 b.grid[Board.H-5][0] = 2
 b.piece = 6
 b.rotation = 1
 b.pos = Vector2i(2,Board.H-4)
 b.b2b = previous_b2b
 b._lock()
 return int(b.events[0].attack)

func _process(dt):
 if failed: return false
 elapsed += dt
 if elapsed > 10:
  fail("timeout")
  return false
 if role == "legacy":
  if elapsed >= 2.0: fail("protocol 7 client was not rejected")
  return false
 if not began: return false
 for id in local_boards: room.post_state(id,local_boards[id].snapshot())
 if role == "remote" and not sent:
  sent = true
  var attacks = [make_attack(4,19),make_attack(4,50),make_attack(2),make_attack(3),make_attack(4)]
  if attacks != [24,55,1,2,4]: fail("source boards generated incorrect shaft depths")
  for amount in attacks: room.attack(local_boards.keys()[0],amount)
 if role == "host" and not reported and room.states.size() == 3 and elapsed > 2:
  for p in room.roster:
   if p.owner == 1: fail("spectator host consumed player slot")
  if room.states.values().all(func(s): return s.has("grid")):
   if not buffers_present():
    fail("hidden buffer or visible floor lost during replication")
    return false
   reported = true
   print("HOST PASS: three boards, B2B and intact 1/2/4/24/55-row shafts")
 if role == "watch" and not reported and elapsed > 2 and buffers_present():
  reported = true
  print("WATCH PASS: expanded boards, B2B and exact 1/2/4/24/55-row shaft amounts and columns replicated")
 if elapsed > 4:
  if role == "player" and (received.size() != 2 or received.values().reduce(func(a,n): return a+n,0) != 5): fail("all five attacks did not reach their intended local boards")
  if role == "watch" and not reported: fail("spectator missing expanded boards")
  if role == "host" and not reported: fail("host did not collect states")
  if failed: return false
  print(role+" NETWORK PASS")
  room.close_session()
  quit(0)
 return false

func buffers_present() -> bool:
 if room.states.size() != 3: return false
 for p in room.roster:
  var state = room.states[p.id]
  if not state.has("grid") or state.grid.size() != Board.H: return false
  if state.grid[Board.VISIBLE_TOP-3][0] != 2 or state.grid[Board.H-1][9] != 8: return false
  if not state.has("b2b") or state.b2b != (6 if p.name == "Remote" else 0): return false
  if p.name != "Remote":
   var expected = [24,1,4] if p.name == "Local one" else [55,2]
   if not state.has("pending") or state.pending.size() != expected.size(): return false
   for i in expected.size():
    var packet = state.pending[i]
    if packet.amount != expected[i] or not observed_holes.has(packet.id): return false
    if packet.hole != observed_holes[packet.id] or packet.has("row_holes"): return false
 return true

func fail(message):
 failed = true
 printerr(role+" FAIL "+message)
 quit(1)
