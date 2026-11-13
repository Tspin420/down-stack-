extends Control

const EngineBoard = preload("res://scripts/board.gd")
const Handling = preload("res://scripts/handling.gd")
const COLORS = [Color.TRANSPARENT,Color("b295fa"),Color("6a96ff"),Color("ffae69"),Color("80d9a8"),Color("ff7e9f"),Color("69d9e2"),Color("f4d778"),Color("64758b")]
var data = {}
var player = {}
var own = false
var form = EngineBoard.new()
var font = ThemeDB.fallback_font

func _process(_dt): queue_redraw()

func txt(at: Vector2, message: String, point_size: int = 14,color: Color = Color("aab7ca")):
 draw_string(font,at,message,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,color)

func block(at: Vector2,cell: float,kind: int,ghost: bool = false):
 var rect = Rect2(at+Vector2(1,1),Vector2(cell-2,cell-2))
 if ghost:
  draw_rect(rect,Color(COLORS[kind],0.35),false,1.5)
 else:
  draw_rect(rect,COLORS[kind])
  draw_rect(Rect2(rect.position,Vector2(rect.size.x,2)),Color(1,1,1,0.28))
  draw_rect(Rect2(rect.position+Vector2(0,rect.size.y-3),Vector2(rect.size.x,3)),Color(0,0,0,0.16))

func miniature(kind: int,at: Vector2,cell: float = 10):
 for c in form.cells(kind,0): block(at+Vector2(c)*cell,cell,kind)

func _draw():
 if player.is_empty(): return
 var box = StyleBoxFlat.new()
 box.bg_color = Color("101b2a")
 box.border_color = Color("345a60") if own else Color("263448")
 box.set_border_width_all(1)
 box.set_corner_radius_all(12)
 draw_style_box(box,Rect2(Vector2.ZERO,size))
 var cell = minf((size.x-138)/10.0,(size.y-180)/20.0)
 var origin = Vector2(68,88)
 var width = cell*10
 var height = cell*20
 txt(Vector2(18,29),str(player.get("name","Player")),20,Color("f0f5fb"))
 txt(Vector2(18,51),"YOUR BOARD" if own else "SPECTATING",10,Color("78d9c3") if own else Color("90a1bb"))
 var soft = float(player.get("soft_drop",-1.0))
 txt(Vector2(18,70),"DAS %d  ·  ARR %d  ·  SOFT %s"%[Handling.level_for_ms("das",player.get("das",167)),Handling.level_for_ms("arr",player.get("arr",33)),"20×" if soft < 0 else ("Instant" if soft == 0 else "%d/s"%int(soft))],11)
 draw_rect(Rect2(origin,Vector2(width,height)),Color("080e17"))
 for y in 21: draw_line(origin+Vector2(0,y*cell),origin+Vector2(width,y*cell),Color("182231"),1)
 for x in 11: draw_line(origin+Vector2(x*cell,0),origin+Vector2(x*cell,height),Color("182231"),1)
 if not data.has("grid"):
  txt(origin+Vector2(25,height/2),"Waiting for board…",15)
  return
 for y in range(EngineBoard.VISIBLE_TOP,EngineBoard.H):
  for x in 10:
   var v = int(data.grid[y][x])
   if v: block(origin+Vector2(x,y-EngineBoard.VISIBLE_TOP)*cell,cell,v)
 var kind = int(data.get("piece",0))
 if kind:
  for c in form.cells(kind,int(data.get("rotation",0))):
   var x = int(data.x)+c.x
   var ghost = int(data.get("ghost",data.y))+c.y-EngineBoard.VISIBLE_TOP
   var y = int(data.y)+c.y-EngineBoard.VISIBLE_TOP
   if ghost >= 0 and ghost < 20: block(origin+Vector2(x,ghost)*cell,cell,kind,true)
   if y >= 0 and y < 20: block(origin+Vector2(x,y)*cell,cell,kind)
 for row in data.get("flash",[]):
  if row >= EngineBoard.VISIBLE_TOP and row < EngineBoard.H: draw_rect(Rect2(origin+Vector2(0,(row-EngineBoard.VISIBLE_TOP)*cell),Vector2(width,cell)),Color(0.7,1,0.94,0.24))
 var sidebar = origin.x+width+11
 txt(Vector2(14,origin.y+8),"HOLD",10)
 miniature(int(data.get("held",0)),Vector2(12,origin.y+20),10)
 txt(Vector2(sidebar,origin.y+8),"NEXT",10)
 var index = 0
 for n in data.get("next",[]):
  miniature(int(n),Vector2(sidebar,origin.y+20+index*44),10)
  index += 1
 var bottom = origin.y+height
 var incoming = 0
 var soonest = 99999.0
 var bar_y = bottom
 for p in data.get("pending",[]):
  incoming += int(p.amount)
  soonest = minf(soonest,float(p.remaining))
  var segment = minf(float(p.amount)*cell,bar_y-origin.y)
  if segment > 0:
   draw_rect(Rect2(Vector2(origin.x-9,bar_y-segment),Vector2(5,segment-2)),Color("f4b66b") if p.remaining <= 0 else Color("6ad8c0"))
   bar_y -= segment
 var sprint = data.get("goal",0) == 40
 txt(Vector2(18,bottom+25),("%d / 40 LINES" if sprint else "%d LINES")%data.get("lines",0),12,Color("eef3fa"))
 txt(Vector2(155,bottom+25),("%d PIECES"%data.get("pieces",0)) if sprint else ("%d SENT"%data.get("sent",0)),12,Color("eef3fa"))
 if sprint:
  txt(Vector2(18,bottom+49),Handling.time_text(data.get("elapsed",0.0)),22,Color("78d9c3"))
 elif incoming:
  txt(Vector2(18,bottom+47),"INCOMING %d  ·  %s"%[incoming,"READY" if soonest <= 0 else "%.2fs"%(soonest/1000.0)],12,Color("f4b66b") if soonest <= 0 else Color("78d9c3"))
 else: txt(Vector2(18,bottom+47),"GARBAGE QUEUE CLEAR",10,Color("72859d"))
 if not str(data.get("label","")).is_empty(): txt(Vector2(18,bottom+68),data.label,13,Color("e7cd89"))
 if data.get("completed",false):
  draw_rect(Rect2(origin,Vector2(width,height)),Color(0.02,0.035,0.06,0.65))
  txt(origin+Vector2(12,height/2),"40 CLEARED",22,Color("78d9c3"))
 elif not data.get("alive",true):
  draw_rect(Rect2(origin,Vector2(width,height)),Color(0.02,0.035,0.06,0.8))
  txt(origin+Vector2(20,height/2),"TOPPED OUT",21,Color("ff9dba"))
