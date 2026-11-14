extends Control

const EngineBoard = preload("res://scripts/board.gd")
const Handling = preload("res://scripts/handling.gd")
const BLOCK_TEXTURE = preload("res://assets/block_tile.svg")
const COLORS = [Color.TRANSPARENT,Color("b295fa"),Color("6a96ff"),Color("ffae69"),Color("80d9a8"),Color("ff7e9f"),Color("69d9e2"),Color("f4d778"),Color("64758b")]
const CLEAR_SECONDS = 0.11
const GARBAGE_SOON_MS = 250.0
const GARBAGE_METER_ROWS = 20
const GARBAGE_CURVE_POWER = 1.5
const GARBAGE_COLORS = [Color("e9c66b"),Color("f49b54"),Color("f46c7d")]
const EMPTY_ROWS: Array = []
# Shape construction and styles are shared read-only resources, never rebuilt in _draw.
static var _shape_cells = _make_shape_cells()
static var _preview_bounds = _make_preview_bounds()
static var _panels = [_make_panel(false),_make_panel(true)]
static var _preview_panel = _make_preview_panel()
static var _garbage_levels = _make_garbage_levels()
var data: Dictionary = {}:
 set(value):
  # Remote snapshots can be assigned repeatedly between 20 Hz network updates.
  if is_same(data,value): return
  _observe_clear(value)
  _observe_garbage(value)
  data = value
  queue_redraw()
var player: Dictionary = {}:
 set(value):
  player = value
  queue_redraw()
var own = false:
 set(value):
  own = value
  queue_redraw()
var font = ThemeDB.fallback_font
var _clear_spans: Array[Vector2i] = []
var _clear_left = 0.0
var _clear_lines = -1
var _clear_pieces = -1
var _cell = 0.0
var _origin = Vector2.ZERO
var _preview_cell = 0.0
var _hold_rect = Rect2()
var _next_rect = Rect2()
var _preview_step = 0.0
var _incoming = 0
var _soonest = 0.0
var _visible_garbage = 0
# At most the visible 20 rows are drawn, even with the maximum network queue.
var _garbage_rows = _make_garbage_rows()

static func _make_shape_cells() -> Array:
 var form = EngineBoard.new()
 var shapes = []
 for kind in 8:
  var rotations = []
  for rotation in 4: rotations.append(form.cells(kind,rotation))
  shapes.append(rotations)
 return shapes

static func _make_preview_bounds() -> Array[Rect2]:
 var bounds: Array[Rect2] = [Rect2()]
 for kind in range(1,8):
  var low = Vector2(4,4)
  var high = Vector2.ZERO
  for cell in _shape_cells[kind][0]:
   low = low.min(Vector2(cell))
   high = high.max(Vector2(cell)+Vector2.ONE)
  bounds.append(Rect2(low,high-low))
 return bounds

static func _make_garbage_rows() -> PackedByteArray:
 var rows = PackedByteArray()
 rows.resize(GARBAGE_METER_ROWS)
 return rows

static func _make_garbage_levels() -> PackedFloat32Array:
 # An accelerating amount scale, shared by all views. Precompute the curve
 # once so snapshots and animation redraws never evaluate powers or allocate it.
 var levels = PackedFloat32Array()
 levels.resize(GARBAGE_METER_ROWS+1)
 for row in range(GARBAGE_METER_ROWS+1):
  levels[row] = pow(float(row)/GARBAGE_METER_ROWS,GARBAGE_CURVE_POWER)
 return levels

static func _make_preview_panel() -> StyleBoxFlat:
 var panel = StyleBoxFlat.new()
 panel.bg_color = Color("0c1522")
 panel.border_color = Color("293b50")
 panel.set_border_width_all(1)
 panel.set_corner_radius_all(6)
 return panel

static func _make_panel(local: bool) -> StyleBoxFlat:
 var panel = StyleBoxFlat.new()
 panel.bg_color = Color("101b2a")
 panel.border_color = Color("4b777b") if local else Color("344359")
 panel.set_border_width_all(1)
 panel.set_corner_radius_all(12)
 return panel

func _ready():
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 _update_layout()
 set_process(_clear_left > 0.0)

func _notification(what: int):
 if what == NOTIFICATION_RESIZED:
  _update_layout()

func _update_layout():
 # Recompute only on resize. Large panels use 18 px previews (formerly 10);
 # the four-player layout uses 12 px previews with reserved space for the meter.
 _preview_cell = floorf(clampf(12.0+(size.x-320.0)*6.0/170.0,12.0,18.0))
 var side_width = _preview_cell*4+6
 _origin = Vector2(12+side_width+22,88)
 _cell = maxf(1.0,minf((size.x-_origin.x-12-side_width-12)/10.0,(size.y-180)/20.0))
 _preview_step = _preview_cell*2+14
 _hold_rect = Rect2(Vector2(12,_origin.y),Vector2(side_width,26+_preview_step))
 _next_rect = Rect2(Vector2(_origin.x+_cell*10+12,_origin.y),Vector2(side_width,26+_preview_step*5))

func _observe_garbage(value: Dictionary):
 _incoming = 0
 _soonest = INF
 _visible_garbage = 0
 # Sprint never accepts garbage. The meter is only a view of existing packets;
 # it does not run a second countdown or change cancellation/arrival timing.
 if value.get("goal",0) == 40: return
 for packet in value.get("pending",EMPTY_ROWS):
  var amount = maxi(0,int(packet.amount))
  if amount == 0: continue
  var remaining = float(packet.remaining)
  _incoming += amount
  _soonest = minf(_soonest,remaining)
  var urgency = 2 if remaining <= 0 else (1 if remaining <= GARBAGE_SOON_MS else 0)
  var end = mini(GARBAGE_METER_ROWS,_visible_garbage+amount)
  while _visible_garbage < end:
   _garbage_rows[_visible_garbage] = urgency
   _visible_garbage += 1

static func _make_clear_spans(rows: Array) -> Array[Vector2i]:
 # Merge adjacent visible rows once per event, never across an uncleared row.
 var ordered = PackedInt32Array(rows)
 ordered.sort()
 var spans: Array[Vector2i] = []
 for row in ordered:
  if row < EngineBoard.VISIBLE_TOP or row >= EngineBoard.H: continue
  if spans.is_empty() or row > spans[-1].y+1:
   spans.append(Vector2i(row,row))
  else:
   spans[-1] = Vector2i(spans[-1].x,row)
 return spans

func _observe_clear(value: Dictionary):
 var lines = int(value.get("lines",0))
 var pieces = int(value.get("pieces",0))
 # New rounds may reuse a view. Empty/waiting data must not retain old effects.
 if value.is_empty() or lines < int(data.get("lines",0)) or pieces < int(data.get("pieces",0)):
  _clear_lines = -1
  _clear_pieces = -1
  _clear_left = 0.0
  _clear_spans.clear()
  set_process(false)
 var rows: Array = value.get("flash",EMPTY_ROWS)
 if rows.is_empty() or (lines == _clear_lines and pieces == _clear_pieces): return
 _clear_lines = lines
 _clear_pieces = pieces
 _clear_spans = _make_clear_spans(rows)
 _clear_left = 0.0 if _clear_spans.is_empty() else CLEAR_SECONDS
 set_process(_clear_left > 0.0)

func _process(dt: float):
 # Presentation time only: never delays compaction, spawning, input or simulation.
 _clear_left = maxf(0.0,_clear_left-dt)
 queue_redraw()
 if _clear_left == 0.0:
  _clear_spans.clear()
  set_process(false)

func txt(at: Vector2, message: String, point_size: int = 14,color: Color = Color("aab7ca")):
 draw_string(font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,color)

func block(at: Vector2,cell: float,kind: int,ghost: bool = false):
 var rect = Rect2(at+Vector2(1,1),Vector2(cell-2,cell-2))
 if ghost:
  draw_rect(rect,Color(COLORS[kind],0.055))
  draw_rect(rect,Color(COLORS[kind],0.60),false,1.0)
 else:
  draw_texture_rect(BLOCK_TEXTURE,rect,false,COLORS[kind])

func miniature(kind: int,slot: Rect2,cell: float):
 if kind <= 0 or kind >= _preview_bounds.size(): return
 # Center occupied cells, not the padded SRS box (especially I and O).
 var bounds: Rect2 = _preview_bounds[kind]
 var at = slot.get_center()-bounds.size*cell/2-bounds.position*cell
 for c in _shape_cells[kind][0]: block(at+Vector2(c)*cell,cell,kind)

func _draw_previews():
 draw_style_box(_preview_panel,_hold_rect)
 draw_style_box(_preview_panel,_next_rect)
 draw_string(font,_hold_rect.position+Vector2(0,18),"HOLD",HORIZONTAL_ALIGNMENT_CENTER,_hold_rect.size.x,11,Color("b5c5da"))
 draw_string(font,_next_rect.position+Vector2(0,18),"UP NEXT",HORIZONTAL_ALIGNMENT_CENTER,_next_rect.size.x,11,Color("b5c5da"))
 var slot_size = Vector2(_hold_rect.size.x,_preview_step)
 miniature(int(data.get("held",0)),Rect2(_hold_rect.position+Vector2(0,26),slot_size),_preview_cell)
 var next: Array = data.get("next",EMPTY_ROWS)
 for i in mini(5,next.size()):
  miniature(int(next[i]),Rect2(_next_rect.position+Vector2(0,26+i*_preview_step),slot_size),_preview_cell)

func _draw_garbage():
 if data.get("goal",0) == 40: return
 var track = Rect2(_origin-Vector2(18,0),Vector2(10,_cell*20))
 draw_rect(track.grow(2),Color("293b50"))
 draw_rect(track,Color("080e17"))
 for i in _visible_garbage:
  var bottom = track.end.y-_garbage_levels[i]*track.size.y
  var top = track.end.y-_garbage_levels[i+1]*track.size.y
  var at = Vector2(track.position.x,top)
  var inset = minf(1.0,(bottom-top)*0.25)
  var color: Color = GARBAGE_COLORS[_garbage_rows[i]]
  # Unequal segment heights express the amount curve. Each segment still
  # belongs to one incoming row and retains that packet's timing color.
  draw_rect(Rect2(at+Vector2(1,inset),Vector2(8,bottom-top-inset*2)),color)
  draw_line(at+Vector2(1,inset),at+Vector2(9,inset),color.lightened(0.22),1)
 # Saturate at the field height; the footer always reports the full amount.
 if _incoming > GARBAGE_METER_ROWS:
  draw_line(track.position-Vector2(1,3),track.position+Vector2(11,-3),GARBAGE_COLORS[2],2)
  txt(_hold_rect.position+Vector2(3,_hold_rect.size.y+20),"+%d"%(_incoming-GARBAGE_METER_ROWS),12,GARBAGE_COLORS[2])
  txt(_hold_rect.position+Vector2(3,_hold_rect.size.y+34),"MORE",9,Color("aab7ca"))

func _draw_well(origin: Vector2,width: float,height: float,cell: float):
 var well = Rect2(origin,Vector2(width,height))
 draw_rect(well.grow(5),Color("213244"))
 draw_rect(well.grow(4),Color("49616f"),false,1.0)
 draw_rect(well.grow(2),Color("050a11"))
 draw_rect(well,Color("080e17"))
 for y in 21: draw_line(origin+Vector2(0,y*cell),origin+Vector2(width,y*cell),Color("15202e"),1)
 for x in 11: draw_line(origin+Vector2(x*cell,0),origin+Vector2(x*cell,height),Color("15202e"),1)
 var accent = Color("7cbab7") if own else Color("60758e")
 # Short corner accents keep the boundary readable without a luminous full frame.
 for x in 2:
  for y in 2:
   var corner = origin+Vector2(x*width,y*height)
   draw_line(corner,corner+Vector2(14 if x == 0 else -14,0),accent,2)
   draw_line(corner,corner+Vector2(0,14 if y == 0 else -14),accent,2)

func _draw_clear(origin: Vector2,width: float,cell: float):
 if _clear_left <= 0.0: return
 var fade = clampf(_clear_left/CLEAR_SECONDS,0.0,1.0)
 for span in _clear_spans:
  var top = origin+Vector2(0,(span.x-EngineBoard.VISIBLE_TOP)*cell)
  var height = (span.y-span.x+1)*cell
  # One continuous full-height fill: a quad is four rows tall throughout its fade.
  draw_rect(Rect2(top,Vector2(width,height)),Color(0.57,0.94,0.89,0.22*fade))
  var edge = Color(0.83,1.0,0.97,0.65*fade)
  draw_line(top+Vector2(0,0.75),top+Vector2(width,0.75),edge,1.5)
  draw_line(top+Vector2(0,height-0.75),top+Vector2(width,height-0.75),edge,1.5)

func _draw():
 if player.is_empty(): return
 draw_style_box(_panels[1 if own else 0],Rect2(Vector2.ZERO,size))
 var cell = _cell
 var origin = _origin
 var width = cell*10
 var height = cell*20
 txt(Vector2(18,29),str(player.get("name","Player")),20,Color("f0f5fb"))
 txt(Vector2(18,51),"YOUR BOARD" if own else "SPECTATING",10,Color("78d9c3") if own else Color("90a1bb"))
 var soft = float(player.get("soft_drop",-1.0))
 txt(Vector2(18,70),"DAS %d  ·  ARR %d  ·  SOFT %s"%[Handling.level_for_ms("das",player.get("das",167)),Handling.level_for_ms("arr",player.get("arr",33)),"20×" if soft < 0 else ("Instant" if soft == 0 else "%d/s"%int(soft))],11)
 _draw_well(origin,width,height,cell)
 _draw_previews()
 _draw_garbage()
 if not data.has("grid"):
  draw_string(font,origin+Vector2(0,height/2),"Waiting for board…",HORIZONTAL_ALIGNMENT_CENTER,width,14,Color("aab7ca"))
  return
 for y in range(EngineBoard.VISIBLE_TOP,EngineBoard.H):
  for x in 10:
   var v = int(data.grid[y][x])
   if v: block(origin+Vector2(x,y-EngineBoard.VISIBLE_TOP)*cell,cell,v)
 var kind = int(data.get("piece",0))
 if kind:
  for c in _shape_cells[kind][int(data.get("rotation",0))]:
   var x = int(data.x)+c.x
   var ghost = int(data.get("ghost",data.y))+c.y-EngineBoard.VISIBLE_TOP
   var y = int(data.y)+c.y-EngineBoard.VISIBLE_TOP
   if ghost >= 0 and ghost < 20: block(origin+Vector2(x,ghost)*cell,cell,kind,true)
   if y >= 0 and y < 20: block(origin+Vector2(x,y)*cell,cell,kind)
 _draw_clear(origin,width,cell)
 var bottom = origin.y+height
 var sprint = data.get("goal",0) == 40
 txt(Vector2(18,bottom+25),("%d / 40 LINES" if sprint else "%d LINES")%data.get("lines",0),12,Color("eef3fa"))
 txt(Vector2(155,bottom+25),("%d PIECES"%data.get("pieces",0)) if sprint else ("%d SENT"%data.get("sent",0)),12,Color("eef3fa"))
 if sprint:
  txt(Vector2(18,bottom+49),Handling.time_text(data.get("elapsed",0.0)),22,Color("78d9c3"))
 elif _incoming:
  var urgency = 2 if _soonest <= 0 else (1 if _soonest <= GARBAGE_SOON_MS else 0)
  txt(Vector2(18,bottom+47),"INCOMING %d  ·  %s"%[_incoming,"READY" if _soonest <= 0 else "%.2fs"%(_soonest/1000.0)],12,GARBAGE_COLORS[urgency])
 else: txt(Vector2(18,bottom+47),"GARBAGE QUEUE CLEAR",10,Color("72859d"))
 if not str(data.get("label","")).is_empty(): txt(Vector2(18,bottom+68),data.label,13,Color("e7cd89"))
 if data.get("completed",false):
  draw_rect(Rect2(origin,Vector2(width,height)),Color(0.02,0.035,0.06,0.65))
  draw_string(font,origin+Vector2(0,height/2),"40 CLEARED",HORIZONTAL_ALIGNMENT_CENTER,width,mini(22,floori(width/7)),Color("78d9c3"))
 elif not data.get("alive",true):
  draw_rect(Rect2(origin,Vector2(width,height)),Color(0.02,0.035,0.06,0.8))
  draw_string(font,origin+Vector2(0,height/2),"TOPPED OUT",HORIZONTAL_ALIGNMENT_CENTER,width,mini(21,floori(width/7)),Color("ff9dba"))
