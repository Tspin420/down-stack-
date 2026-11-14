extends SceneTree
const Board = preload("res://scripts/board.gd")
const Session = preload("res://scripts/session.gd")

func _initialize():
 var rng = RandomNumberGenerator.new()
 rng.seed = 1225
 var session = Session.new()
 for height in [0, 8, 16]:
  var total = 0
  for sample in 100:
   var board = Board.new(sample+1, {}, {})
   for y in range(Board.H-height, Board.H):
    var hole = rng.randi_range(0, 9)
    for x in Board.W: board.grid[y][x] = 0 if x == hole else rng.randi_range(1, 8)
   var args = ["2:-1", session._pack(board.snapshot()), 123456]
   var payload = Marshalls.raw_to_base64(var_to_bytes(args))
   total += JSON.stringify({"op":"packet", "from":1, "kind":"state", "payload":payload}).to_utf8_buffer().size()
  var average = total/100.0
  # Two PCs, one board each: 20 submit + 20 opponent-view deliveries per second.
  # Four PCs, one board each: 60 submit + 180 opponent-view deliveries per second.
  print(JSON.stringify({"filled_rows":height, "average_packet_bytes":average, "two_player_MB_per_hour":average*40*3600/1000000.0, "four_player_MB_per_hour":average*240*3600/1000000.0}))
 session.free()
 quit()
