extends SceneTree

const Session = preload("res://scripts/session.gd")
const Board = preload("res://scripts/board.gd")
var room
var role = "host"
var url = ""
var code = ""
var boards = {}
var registered = false
var queued_start = false
var rounds = 0
var old_seed = 0
var round_time = 0.0
var total_time = 0.0
var publish_time = 0.0
var sent = false
var received = []
var finished = false
var finish_time = 0.0
var saw_boards = false
var failed = false

func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--role="): role = arg.trim_prefix("--role=")
  if arg.begins_with("--url="): url = arg.trim_prefix("--url=")
  if arg.begins_with("--code="): code = arg.trim_prefix("--code=")
 room = Session.new()
 room.name = "Session"
 root.add_child.call_deferred(room)
 _setup.call_deferred()

func _setup():
 room.lobby_updated.connect(_lobby)
 room.started.connect(_start)
 room.round_finished.connect(_finish)
 room.closed.connect(_closed)
 room.garbage_arrived.connect(_garbage)
 if room.open_room(url, role == "host", code) != OK: fail("open room")

func _lobby():
 if role == "host" and not registered:
  print("ROOM_CODE="+room.room_code)
 if role != "watch" and not registered:
  registered = true
  room.change_player(-1, role, "Keyboard", 166.67, 33.33, false, 5.0)
  if role == "player": room.change_player(-2, "second local", "Keyboard 2", 83.34, 16.67, false, 0.0)
 if role == "host" and not room.running and not queued_start and room.roster.size() == 4 and rounds < 2:
  queued_start = true
  room.begin.call_deferred()

func _start(seed_value):
 if rounds > 0 and old_seed == seed_value: fail("rematch seed did not change")
 old_seed = room.seed_value if rounds == 0 else old_seed
 rounds += 1
 queued_start = false
 round_time = 0.0
 sent = false
 saw_boards = false
 boards.clear()
 for player in room.roster:
  if player.owner == room.local_id():
   var board = Board.new(seed_value, {"soft_drop":player.soft_drop}, room.rules)
   board.grid[Board.VISIBLE_TOP-3][0] = 2
   board.grid[Board.H-1][9] = 8
   boards[player.id] = board
 if role == "host": print("ROUND="+str(rounds))

func _garbage(id, amount, hole, number):
 if boards.has(id):
  boards[id].receive_garbage(amount, hole, number)
  if boards[id].pending[-1].remaining != 1000.0: fail("garbage warning changed")
  received.append(amount)
  if amount == 7: fail("old-round attack leaked into rematch")

func _finish(winner):
 if rounds != 2: fail("round ended early")
 var expected = room.roster.filter(func(p): return p.name == "host")[0].id
 if winner != expected: fail("wrong winner")
 finished = true

func _closed(message):
 if role == "remote":
  if rounds != 2: fail("early remote disconnect: "+message)
  return
 if role == "host":
  if not finished: fail("early host disconnect: "+message)
  return
 if not finished or rounds != 2 or not saw_boards: fail("host close before complete match")
 elif "host" not in message.to_lower(): fail("missing host-closed explanation: "+message)
 else:
  print(role+" ROOM PASS: late spectating / rematch / winner / host close")
  quit(0)

func _process(dt):
 if failed: return false
 total_time += dt
 if total_time > 18: fail("timeout"); return false
 if rounds == 0: return false
 round_time += dt
 publish_time += dt
 if room.running and publish_time >= 0.05:
  publish_time = 0
  for id in boards: room.post_state(id, boards[id].snapshot())
 var visible_states = room.states.duplicate()
 for id in boards: visible_states[id] = boards[id].snapshot()
 if visible_states.size() == 4 and visible_states.values().all(func(s): return s.has("grid")):
  for state in visible_states.values():
   if state.grid.size() != Board.H or state.grid[Board.VISIBLE_TOP-3][0] != 2: fail("expanded snapshot lost")
  saw_boards = true
 if rounds == 1:
  if role == "remote" and not sent and round_time > 0.3:
   sent = true
   room.attack(boards.keys()[0], 4)
  if role == "host" and room.running and round_time > 1.0 and room.screens == 4 and saw_boards and 4 in received:
   room.back_to_lobby()
 elif rounds == 2:
  if role == "player" and not sent and round_time > 0.2:
   sent = true
   room.relay.send_packet("attack", [boards.keys()[0], 7, old_seed], 1)
  if role == "remote" and round_time > 0.5:
   if not saw_boards: fail("no remote boards before disconnect")
   else:
    room.close_session()
    print("remote ROOM PASS: two rounds / intentional disconnect")
    quit(0)
  if role == "player" and round_time > 0.8:
   for board in boards.values(): board.alive = false
  if role == "host" and finished:
   finish_time += dt
   if finish_time > 0.5:
    if not saw_boards or 7 in received: fail("rematch verification")
    else:
     room.back_to_lobby()
     if room.roster.size() != 3: fail("disconnected player remained in lobby")
     else:
      room.close_session()
      print("host ROOM PASS: garbage / rematch / stale-round guard / disconnect / winner")
      quit(0)
 return false

func fail(message):
 failed = true
 printerr(role+" FAIL "+message+" rounds="+str(rounds)+" screens="+str(room.screens)+" saw_boards="+str(saw_boards)+" received="+str(received)+" states="+str(room.states.keys()))
 quit(1)
