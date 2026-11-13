extends SceneTree

const Session = preload("res://scripts/session.gd")
const Board = preload("res://scripts/board.gd")
var room
var role = "host"
var port = 43971
var elapsed = 0.0
var began = false
var sent = false
var received = false
var reported = false
var failed = false
var model
var local_boards = {}

func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
  if arg.begins_with("--port="): port = int(arg.trim_prefix("--port="))
 room = Session.new()
 room.name = "Session"
 root.add_child.call_deferred(room)
 _setup.call_deferred()

func _setup():
 room.lobby_updated.connect(_lobby)
 room.started.connect(_start)
 room.garbage_arrived.connect(_garbage)
 if role == "host":
  room.net.set_bind_ip("127.0.0.1")
  if room.host(port) != OK: fail("host start")
 else:
  if room.join("127.0.0.1",port) != OK: fail("client start")

func _lobby():
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
   local_boards[p.id] = board
 print(role+" MATCH STARTED players="+str(room.roster.size())+" owned="+str(local_boards.size()))

func _garbage(id,amount,hole,packet):
 if local_boards.has(id):
  var b = local_boards[id]
  b.receive_garbage(amount,hole,packet)
  if b.pending.size() != 1 or b.pending[0].remaining != 1000.0: fail("garbage warning interval not preserved")
  received = true

func _process(dt):
 if failed: return false
 elapsed += dt
 if elapsed > 10:
  fail("timeout")
  return false
 if not began: return false
 for id in local_boards: room.post_state(id,local_boards[id].snapshot())
 if role == "remote" and not sent:
  sent = true
  room.attack(local_boards.keys()[0],4)
 if role == "host" and not reported and room.states.size() == 3 and elapsed > 2:
  for p in room.roster:
   if p.owner == 1: fail("spectator host consumed player slot")
  if room.states.values().all(func(s): return s.has("grid")):
   if not buffers_present():
    fail("hidden buffer or visible floor lost during replication")
    return false
   reported = true
   print("HOST PASS: 3 active boards across 2 player processes; spectator host + remote spectator")
 if role == "watch" and not reported and elapsed > 2 and buffers_present():
  reported = true
  print("WATCH PASS: all three expanded boards received before host disconnect")
 if elapsed > 4:
  if role == "player" and not received: fail("garbage was not delivered to receiver")
  if role == "watch" and not reported: fail("spectator missing expanded boards")
  if role == "host" and not reported: fail("host did not collect states")
  if failed: return false
  print(role+" NETWORK PASS")
  room.close_session()
  quit(0)
 return false

func buffers_present() -> bool:
 if room.states.size() != 3: return false
 for state in room.states.values():
  if not state.has("grid") or state.grid.size() != Board.H: return false
  if state.grid[Board.VISIBLE_TOP-3][0] != 2 or state.grid[Board.H-1][9] != 8: return false
 return true

func fail(message):
 failed = true
 printerr(role+" FAIL "+message)
 quit(1)
