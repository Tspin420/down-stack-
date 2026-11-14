extends SceneTree

const Board = preload("res://scripts/board.gd")
const Handling = preload("res://scripts/handling.gd")
const Main = preload("res://scripts/main.gd")
var checks = 0
var failures = 0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func _initialize():
 run.call_deferred()

func quad(board):
 for y in range(Board.H-4,Board.H):
  for x in 10: board.grid[y][x] = 8 if x != 4 else 0
 board.piece = 6
 board.rotation = 1
 board.pos = Vector2i(2,Board.H-4)

func run():
 for level in range(0,11):
  var canonical = 0 if level == 5 else level
  check(Handling.level_for_ms("das",Handling.das_ms(level)) == canonical,"DAS round trip identifies the baseline as default")
  check(Handling.level_for_ms("arr",Handling.arr_ms(level)) == canonical,"ARR round trip identifies the baseline as default")
  if level > 1:
   check(Handling.das_ms(level) < Handling.das_ms(level-1),"higher DAS level is faster")
   check(Handling.arr_ms(level) < Handling.arr_ms(level-1),"higher ARR level is faster")
 check(is_equal_approx(Handling.das_ms(0),166.666667),"DAS zero restores the existing baseline")
 check(is_equal_approx(Handling.arr_ms(0),33.333333),"ARR zero restores the existing baseline")
 check(is_equal_approx(Handling.das_ms(10)*2,Handling.das_ms(0)),"DAS 10 halves baseline delay")
 check(is_equal_approx(Handling.arr_ms(10)*2,Handling.arr_ms(0)),"ARR 10 halves baseline interval")
 check(Handling.time_text(62345.0) == "01:02.345","sprint time formatting")
 var b = Board.new(1,{}, {"mode":"sprint","clear_ms":0.0,"entry_ms":0.0})
 b.lines = 36
 quad(b)
 b.receive_garbage(4,4,1)
 check(b.pending.is_empty(),"sprint cannot receive garbage")
 b.step(1000.0/120.0,Board.HARD)
 check(b.completed and b.lines == 40 and b.alive,"40th line ends sprint successfully")
 check(b.events.is_empty() and b.sent == 0,"sprint sends no versus attack")
 check(b.piece == 0,"no extra piece spawns after sprint completion")
 var finish_time = b.elapsed
 var piece_count = b.pieces
 for i in 120: b.step(1000.0/120.0,Board.HARD)
 check(b.elapsed == finish_time and b.pieces == piece_count,"sprint timer and input freeze at finish")
 b = Board.new(1,{}, {"mode":"sprint","clear_ms":0.0,"entry_ms":0.0})
 b.lines = 39
 quad(b)
 b.step(1000.0/120.0,Board.HARD)
 check(b.completed and b.lines == 43,"overshooting 40 still finishes")
 b = Board.new(1,{}, {"mode":"sprint"})
 b.alive = false
 b.step(1000.0/120.0,0)
 check(not b.completed and b.elapsed == 0,"top-out is not a sprint completion")
 b = Board.new()
 b.step(1000.0/120.0,Board.LEFT)
 check("move" in b.sounds,"successful movement creates sound cue")
 b.step(1000.0/120.0,Board.HOLD)
 check("hold" in b.sounds,"hold creates sound cue")
 b.step(1000.0/120.0,Board.HARD)
 check("drop" in b.sounds,"hard drop creates sound cue")
 b.step(1000.0/120.0,0)
 check(b.sounds.is_empty(),"cues do not replay in following ticks")
 var app = Main.new()
 root.add_child(app)
 app.set_physics_process(false)
 app.config = ConfigFile.new()
 var receiver = Board.new()
 app.models["pattern-check"] = receiver
 app.room.garbage_arrived.emit("pattern-check",2,2,3999)
 check(receiver.pending.size() == 1 and receiver.pending[0].amount == 2 and receiver.pending[0].hole == 2,"actual application signal forwards a two-deep shaft to its local board")
 app.room.garbage_arrived.emit("remote-board",3,4,4000)
 check(app.models.size() == 1 and receiver.pending.size() == 1,"application ignores garbage intended for another player's board")
 receiver._cancel(2)
 app.room.garbage_arrived.emit("pattern-check",8,6,4001)
 check(receiver.pending.size() == 1 and receiver.pending[0].amount == 8 and receiver.pending[0].hole == 6,"actual application signal forwards an eight-deep shaft")
 app.models.clear()
 app._sprint()
 app._add_player()
 app.room.begin()
 check(app.models.size() == 1 and app.countdown == 3.0,"sprint starts one board after countdown")
 b = app.models.values()[0]
 app._physics_process(1.0)
 check(b.elapsed == 0,"countdown excluded from sprint clock")
 app.countdown = 0
 b.lines = 36
 quad(b)
 b.step(1000.0/120.0,Board.HARD)
 app._finish_sprint(b)
 check(not app.room.running and app.retry_button.visible,"sprint result exposes retry and stops round")
 check(float(app.config.get_value("sprint","best_ms",0)) == b.elapsed,"completed run persists personal best")
 var saved = b.elapsed
 app._restart_sprint()
 b = app.models.values()[0]
 check(b.lines == 0 and b.elapsed == 0 and app.countdown == 3.0,"retry resets field and timer")
 b.alive = false
 b.elapsed = saved/2
 app._finish_sprint(b)
 check(float(app.config.get_value("sprint","best_ms",0)) == saved,"failed run cannot replace personal best")
 check(app.sound.voices.size() == 18,"all 18 sound effects loaded")
 app.sound.set_levels(0.4,0.2)
 check(is_equal_approx(db_to_linear(app.sound.voices.move.volume_db),0.4),"effect volume applied")
 check(is_equal_approx(db_to_linear(app.sound.music.volume_db),0.2),"music volume applied independently")
 app.sound.play("clear4")
 check(app.sound.voices.clear4.playing,"clear effect playback starts")
 # Let the asynchronous audio mixer consume playback/stop commands in a
 # headless run, which otherwise exits before its first real-time buffer.
 await create_timer(0.1).timeout
 app.room.close_session()
 app.free()
 await create_timer(0.1).timeout
 print("UPDATE TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
