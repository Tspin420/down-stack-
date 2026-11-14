extends SceneTree

# Deterministic renderer fixtures, not an FPS benchmark. Run through capture_visuals.py.
const Board = preload("res://scripts/board.gd")
const View = preload("res://scripts/board_view.gd")
var output = ""
var baseline_script = ""
var baseline_label = "repository baseline"

func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
  if arg.begins_with("--baseline="): baseline_script = arg.trim_prefix("--baseline=")
  if arg.begins_with("--baseline-label="): baseline_label = arg.trim_prefix("--baseline-label=")
 run.call_deferred()

func label_at(text: String,at: Vector2,point_size: int = 20) -> Label:
 var label = Label.new()
 label.text = text
 label.position = at
 label.add_theme_font_size_override("font_size",point_size)
 root.add_child(label)
 return label

func fixture() -> Dictionary:
 var board = Board.new(183)
 var rows = [
  [0,0,0,0,0,0,0,4,4,0],
  [2,0,0,0,0,0,4,4,3,0],
  [2,2,2,1,0,0,0,3,3,0],
  [7,7,1,1,1,6,6,6,6,0],
  [7,7,5,5,3,3,3,4,4,0],
  [5,5,2,2,2,1,1,1,4,0],
  [8,8,8,8,8,8,8,8,8,0],
  [8,8,8,8,8,8,8,8,8,0]]
 for i in rows.size(): board.grid[Board.H-rows.size()+i] = rows[i]
 board.piece = 1
 board.rotation = 1
 board.pos = Vector2i(3,Board.VISIBLE_TOP+4)
 board.held = 6
 board.queue = [2,3,7,4,5,6,1]
 board.lines = 24
 board.pieces = 61
 board.sent = 12
 board.receive_garbage(4,9,1)
 board.pending[0].remaining = 650.0
 return board.snapshot()

func add_board(script,at: Vector2,dimensions: Vector2,state: Dictionary,local: bool = true):
 var view = script.new()
 view.position = at
 view.size = dimensions
 view.player = {"name":"Player 1" if local else "Player 2","das":166.6667 if local else 83.3333,"arr":33.3333 if local else 16.6667,"soft_drop":-1.0 if local else 0.0}
 view.own = local
 view.data = state
 root.add_child(view)
 view.set_process(false)
 return view

func save_frame(filename: String):
 # The legacy view only invalidated from _process, which this fixture freezes.
 for child in root.get_children():
  if child is CanvasItem: child.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var result = root.get_texture().get_image().save_png(output.path_join(filename))
 if result != OK:
  printerr("Capture failed: "+error_string(result))
  quit(1)
 print("CAPTURE "+filename)

func run():
 if DisplayServer.get_name() == "headless":
  printerr("Visual capture needs a real display/Compatibility renderer; headless has no pixels.")
  quit(1)
  return
 if output.is_empty() or baseline_script.is_empty():
  printerr("Supply --output and --baseline (or use tools/capture_visuals.py).")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_size = Vector2i.ZERO
 root.size = Vector2i(1280,900)
 root.title = "Downstack — original / visual prototype"
 var baseline = load(baseline_script)
 if baseline == null:
  quit(1)
  return
 label_at("DOWNSTACK / PLAYFIELD STUDY",Vector2(56,20),24)
 label_at("BEFORE · "+baseline_label,Vector2(98,64),17)
 label_at("UPDATED · nonlinear garbage meter",Vector2(692,64),17)
 var state = fixture()
 var before = add_board(baseline,Vector2(84,103),Vector2(490,730),state)
 var after = add_board(View,Vector2(686,103),Vector2(490,730),state)
 var caption = label_at("Identical board state · Godot 4.6.3 / GL Compatibility · deterministic capture, not a frame-rate measurement",Vector2(56,855),15)
 await save_frame("before-after.png")
 state = fixture()
 state.pending = [{"amount":4,"remaining":0.0,"hole":2,"id":1},{"amount":3,"remaining":200.0,"hole":5,"id":2},{"amount":2,"remaining":800.0,"hole":0,"id":3}]
 before.data = state
 after.data = state
 caption.text = "Nonlinear amount scale · red: ready · orange: under 250 ms · yellow: delayed · exact row count below"
 await save_frame("garbage-queue.png")
 state = fixture()
 state.pending = [{"amount":24,"remaining":0.0,"hole":2,"id":1}]
 before.data = state
 after.data = state
 caption.text = "Large queues fill the meter to 20 rows · +4 marks overflow · the footer reports all 24 incoming rows"
 await save_frame("garbage-overflow.png")
 # Use a real post-clear snapshot: compaction and entry timing remain in the engine.
 var clear = Board.new(183)
 for y in range(Board.H-4,Board.H):
  for x in 10: clear.grid[y][x] = 8 if x != 4 else 0
 clear.grid[Board.H-5][0] = 2
 clear.piece = 6
 clear.rotation = 1
 clear.pos = Vector2i(2,Board.H-4)
 clear._lock()
 state = clear.snapshot()
 before.data = state
 after.data = state
 after.set_process(false)
 caption.text = "Actual post-quad snapshot · t = 0 ms · row-local effect; gameplay compacts and spawns on its existing schedule"
 await save_frame("clear-start.png")
 after._process(0.055)
 after.set_process(false)
 caption.text = "Same post-quad snapshot · t = 55 ms · one continuous four-row band fades with no internal stripes"
 await save_frame("clear-middle.png")
 clear.step(120.0,0)
 before.data = clear.snapshot()
 after._process(0.065)
 after.set_process(false)
 caption.text = "t = 120 ms · effect is finished, including if a remote or completed sprint snapshot stops updating"
 await save_frame("clear-end.png")
 for child in root.get_children():
  root.remove_child(child)
  child.queue_free()
 root.size = Vector2i(1364,900)
 label_at("DOWNSTACK / FOUR-BOARD READABILITY",Vector2(20,22),24)
 for i in 4:
  state = fixture()
  state.piece = i+1
  state.rotation = i
  state.y = Board.VISIBLE_TOP+3+i
  state.ghost = Board.H-12
  state.completed = i == 2
  state.alive = i != 3
  state.goal = 40 if i == 2 else 0
  state.lines = 40 if i == 2 else state.lines
  var view = add_board(View,Vector2(20+i*332,83),Vector2(320,730),state,i < 2)
  view.player = view.player.duplicate()
  view.player.name = "Player %d"%(i+1)
 label_at("320 px panels · local / remote ownership · hold / next · garbage warning · sprint completion / top-out",Vector2(20,850),16)
 await save_frame("four-boards.png")
 for child in root.get_children():
  root.remove_child(child)
  child.queue_free()
 root.size = Vector2i(1364,700)
 label_at("DOWNSTACK / THREE PLAYERS · SHORT PANELS",Vector2(20,22),24)
 for i in 3:
  state = fixture()
  state.held = i+1
  state.pending = [] if i == 0 else [{"amount":6+i,"remaining":180.0 if i == 1 else 0.0,"hole":2,"id":1}]
  var view = add_board(View,Vector2(40+i*432,83),Vector2(410,530),state,i == 0)
  view.player = view.player.duplicate()
  view.player.name = "Player %d"%(i+1)
 label_at("410 × 530 px panels · centered hold / five-piece preview · empty, imminent and ready garbage",Vector2(40,650),16)
 await save_frame("three-boards.png")
 for child in root.get_children():
  root.remove_child(child)
  child.queue_free()
 root.size = Vector2i(1100,760)
 label_at("DOWNSTACK / NONLINEAR GARBAGE METER",Vector2(32,22),24)
 label_at("Small queues stay low. Each additional row makes a larger jump toward the top.",Vector2(32,60),17)
 # Clip actual BoardView meters into equal-height samples. These are rendered
 # by the game code, not independently plotted approximations of its curve.
 var samples = [1,4,8,12,16,20]
 for i in samples.size():
  var amount = samples[i]
  var x = 50+i*172
  label_at("%d ROW%s"%[amount,"" if amount == 1 else "S"],Vector2(x,110),19)
  var fraction = View._garbage_levels[amount]
  label_at("%.0f%% FULL"%(fraction*100),Vector2(x,140),14)
  var clip = Control.new()
  clip.position = Vector2(x+26,183)
  clip.size = Vector2(18,514)
  clip.clip_contents = true
  root.add_child(clip)
  var view = View.new()
  view.size = Vector2(490,690)
  view.player = {"name":"Meter scale"}
  state = Board.new().snapshot()
  state.pending = [{"amount":amount,"remaining":0.0,"hole":0,"id":1}]
  view.data = state
  clip.add_child(view)
  view.position = -view._origin+Vector2(22,2)
  view.set_process(false)
 label_at("All samples are ready (red) to isolate amount. Color still shows timing; the footer retains the exact row count.",Vector2(32,719),15)
 await save_frame("meter-scale.png")
 print("VISUAL CAPTURE PASS")
 quit()
