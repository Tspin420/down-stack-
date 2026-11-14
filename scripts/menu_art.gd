extends Control

# Static menu artwork built from the same shared tile as the playfield.
const TILE = preload("res://assets/block_tile.svg")

func _ready():
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw():
 var cell = minf(size.x/6.0,size.y/6.0)
 var origin = (size-Vector2(cell*6,cell*6))/2
 for i in 7:
  var offset = float(i)*cell
  draw_line(origin+Vector2(offset,0),origin+Vector2(offset,cell*6),Color("222b48"),1.0,true)
  draw_line(origin+Vector2(0,offset),origin+Vector2(cell*6,offset),Color("222b48"),1.0,true)
 var start = origin+Vector2(cell*1.5,cell*1.3)
 for point in [Vector2(0,0),Vector2(1,0),Vector2(2,0),Vector2(1,1)]:
  var rect = Rect2(start+point*cell,Vector2.ONE*(cell-3))
  draw_rect(Rect2(rect.position+Vector2(0,8),rect.size),Color(0,0,0,0.28))
  draw_texture_rect(TILE,rect,false,Color("ff4fbd"))
 for point in [Vector2(0,0),Vector2(1,0),Vector2(2,0),Vector2(1,1)]:
  var rect = Rect2(origin+Vector2(cell*1.5,cell*3.6)+point*cell,Vector2.ONE*(cell-3))
  draw_rect(rect,Color("44ceff"),false,2,true)
 draw_line(origin+Vector2(cell*0.7,cell*5.8),origin+Vector2(cell*5.3,cell*5.8),Color("75ffb6"),2,true)
