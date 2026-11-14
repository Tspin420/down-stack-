class_name FallBoard
extends RefCounted

# Independent fixed-tick board. Rendering and network waits never advance its clocks.
const W = 10
const VISIBLE_ROWS = 20
const BUFFER_ROWS = 20
const VISIBLE_TOP = BUFFER_ROWS
const H = VISIBLE_ROWS + BUFFER_ROWS
const SPAWN_Y = VISIBLE_TOP - 2
const LEFT = 1
const RIGHT = 2
const SOFT = 4
const CW = 8
const CCW = 16
const HARD = 32
const HOLD = 64
const SHAPES = [[], [[1,0],[0,1],[1,1],[2,1]], [[0,0],[0,1],[1,1],[2,1]], [[2,0],[0,1],[1,1],[2,1]], [[1,0],[2,0],[0,1],[1,1]], [[0,0],[1,0],[1,1],[2,1]], [[0,1],[1,1],[2,1],[3,1]], [[1,0],[2,0],[1,1],[2,1]]]
const JL_KICKS = {
 "01":[[0,0],[-1,0],[-1,1],[0,-2],[-1,-2]], "10":[[0,0],[1,0],[1,-1],[0,2],[1,2]],
 "12":[[0,0],[1,0],[1,-1],[0,2],[1,2]], "21":[[0,0],[-1,0],[-1,1],[0,-2],[-1,-2]],
 "23":[[0,0],[1,0],[1,1],[0,-2],[1,-2]], "32":[[0,0],[-1,0],[-1,-1],[0,2],[-1,2]],
 "30":[[0,0],[-1,0],[-1,-1],[0,2],[-1,2]], "03":[[0,0],[1,0],[1,1],[0,-2],[1,-2]]}
const I_KICKS = {
 "01":[[0,0],[-2,0],[1,0],[-2,-1],[1,2]], "10":[[0,0],[2,0],[-1,0],[2,1],[-1,-2]],
 "12":[[0,0],[-1,0],[2,0],[-1,2],[2,-1]], "21":[[0,0],[1,0],[-2,0],[1,-2],[-2,1]],
 "23":[[0,0],[2,0],[-1,0],[2,1],[-1,-2]], "32":[[0,0],[-2,0],[1,0],[-2,-1],[1,2]],
 "30":[[0,0],[1,0],[-2,0],[1,-2],[-2,1]], "03":[[0,0],[-1,0],[2,0],[-1,2],[2,-1]]}
# Wire-format bound, not a gameplay balance cap. Large attacks stay one packet.
const MAX_ATTACK = 2147483647

var grid = []
var queue = []
var rng = RandomNumberGenerator.new()
var piece = 0
var rotation = 0
var pos = Vector2i(3,SPAWN_Y)
var held = 0
var hold_used = false
var alive = true
var completed = false
var sounds = []
var lines = 0
var pieces = 0
var sent = 0
var score = 0
var combo = -1
# -1: no chain; 0: first difficult clear; 1+: displayed B2B and flat bonus.
var b2b = -1
var pending = []
var delay = 0.0
var elapsed = 0.0
var lock_clock = 0.0
var lock_resets = 0
var gravity_clock = 0.0
var soft_clock = 0.0
var previous_input = 0
var direction = 0
var das_clock = 0.0
var repeat_clock = 0.0
var last_rotate = false
var kick_index = 0
var rotation_buffer = 0
var buffer_life = 0.0
var label = ""
var label_life = 0.0
var flash_rows = []
var flash_life = 0.0
var events = []
var handling = {"das":166.6667, "arr":33.3333, "soft_drop":-1.0}
var rules = {"clear_ms":120.0, "entry_ms":100.0, "garbage_ms":1000.0, "lock_ms":500.0, "mode":"versus"}

func _init(seed_value: int = 1, tuning: Dictionary = {}, match_rules: Dictionary = {}):
 handling.merge(tuning, true)
 handling.das = snappedf(float(handling.das),1000.0/120.0)
 var repeat = maxf(1000.0/120.0,float(handling.arr))
 var nearest = snappedf(repeat,1000.0/120.0)
 handling.arr = nearest if absf(nearest-repeat) < 0.02 else repeat
 var soft_rate = float(handling.soft_drop) if (handling.soft_drop is float or handling.soft_drop is int) else -1.0
 # Only an explicit zero selects Instant; invalid negatives must not clamp to it.
 handling.soft_drop = -1.0 if soft_rate < 0.0 or not is_finite(soft_rate) else clampf(soft_rate,0.0,120.0)
 rules.merge(match_rules, true)
 rng.seed = seed_value
 for y in H: grid.append(_empty_row())
 _fill_queue()
 _spawn()

func _empty_row() -> Array:
 var row = []
 row.resize(W)
 row.fill(0)
 return row

func _fill_queue():
 while queue.size() < 8:
  var bag = [1,2,3,4,5,6,7]
  for i in range(6,0,-1):
   var j = rng.randi_range(0,i)
   var tmp = bag[i]
   bag[i] = bag[j]
   bag[j] = tmp
  queue.append_array(bag)

func cells(kind: int = -1, rot: int = -1) -> Array:
 if kind == -1: kind = piece
 if rot == -1: rot = rotation
 var result = []
 if kind < 1 or kind > 7: return result
 for cell in SHAPES[kind]:
  var v = Vector2i(cell[0],cell[1])
  if kind != 7:
   for r in rot:
    v = Vector2i((3 if kind == 6 else 2)-v.y,v.x)
  result.append(v)
 return result

func fits(at: Vector2i, rot: int = -1) -> bool:
 for c in cells(piece,rot):
  var p = at+c
  if p.x < 0 or p.x >= W or p.y < 0 or p.y >= H: return false
  if grid[p.y][p.x] != 0: return false
 return true

func _spawn(kind: int = 0):
 if not alive: return
 piece = kind if kind else int(queue.pop_front())
 _fill_queue()
 pos = Vector2i(3,SPAWN_Y)
 rotation = 0
 lock_clock = 0
 gravity_clock = 0
 soft_clock = 0
 lock_resets = 0
 last_rotate = false
 if not fits(pos):
  alive = false
 elif fits(pos+Vector2i(0,1)):
  pos.y += 1 # Entry step makes the bottom spawn row visible immediately.

func _reset_lock(was_grounded: bool):
 if was_grounded and lock_resets < 15:
  lock_clock = 0
  lock_resets += 1

func move(dx: int) -> bool:
 var grounded = not fits(pos+Vector2i(0,1))
 if fits(pos+Vector2i(dx,0)):
  pos.x += dx
  sounds.append("move")
  last_rotate = false
  _reset_lock(grounded)
  return true
 return false

func rotate(turn: int) -> bool:
 if piece == 7:
  _reset_lock(not fits(pos+Vector2i(0,1)))
  sounds.append("rotate")
  return true # O rotates around its center without changing occupied cells.
 var next = posmod(rotation+turn,4)
 var key = str(rotation)+str(next)
 var kicks = (I_KICKS if piece == 6 else JL_KICKS)[key]
 var grounded = not fits(pos+Vector2i(0,1))
 for i in kicks.size():
  var at = pos+Vector2i(kicks[i][0],-kicks[i][1])
  if fits(at,next):
   pos = at
   rotation = next
   last_rotate = true
   kick_index = i
   sounds.append("rotate")
   _reset_lock(grounded)
   return true
 return false

func ghost_y() -> int:
 var p = pos
 while fits(p+Vector2i(0,1)): p.y += 1
 return p.y

func receive_garbage(amount: int, hole: int, packet_id: int):
 if rules.mode == "sprint" or completed: return
 if amount <= 0 or amount > MAX_ATTACK: return
 for p in pending:
  if p.id == packet_id: return
 # Every attack creates one shaft whose depth is the number of rows sent.
 pending.append({"amount":amount, "hole":clampi(hole,0,9), "remaining":float(rules.garbage_ms), "id":packet_id})

func _cancel(attack: int) -> int:
 while attack > 0 and not pending.is_empty():
  var n = mini(attack,int(pending[0].amount))
  attack -= n
  pending[0].amount -= n
  if pending[0].amount == 0: pending.pop_front()
 return attack

func _raise_garbage():
 var rose = false
 while not pending.is_empty() and pending[0].remaining <= 0:
  rose = true
  var packet = pending.pop_front()
  # More than H identical rows guarantees overflow and leaves the same final
  # grid as H rows. Bound work by board height, not the incoming attack size.
  if int(packet.amount) > H: alive = false
  for n in mini(int(packet.amount),H):
   var removed = grid.pop_front()
   for value in removed:
    if value != 0: alive = false
   var row = _empty_row()
   row.fill(8)
   row[int(packet.hole)] = 0
   grid.append(row)
 if rose: sounds.append("garbage")

static func combo_attack(base_attack: int, combo_index: int) -> int:
 # TETR.IO multiplier table: first clear is index 0. The logarithmic minimum
 # lets ordinary singles send during a combo even though their base is zero.
 var attack = float(base_attack)*(1.0+0.25*maxi(0,combo_index))
 if combo_index > 1: attack = maxf(attack,log(1.0+1.25*combo_index))
 return floori(attack)

func _corner(x: int,y: int) -> bool:
 return x < 0 or x >= W or y < 0 or y >= H or grid[y][x] != 0

func _spin_type() -> int:
 if piece != 1 or not last_rotate: return 0
 var p = pos+Vector2i(1,1)
 var corners = [_corner(p.x-1,p.y-1),_corner(p.x+1,p.y-1),_corner(p.x+1,p.y+1),_corner(p.x-1,p.y+1)]
 var count = 0
 for c in corners:
  if c: count += 1
 if count < 3: return 0
 return 2 if (corners[rotation] and corners[(rotation+1)%4]) or kick_index == 4 else 1

func _lock():
 var spin = _spin_type()
 var all_hidden = true
 for c in cells():
  var p = pos+c
  if p.y >= VISIBLE_TOP: all_hidden = false
  if p.y < 0: alive = false
  elif p.y < H: grid[p.y][p.x] = piece
 if all_hidden: alive = false
 pieces += 1
 flash_rows.clear()
 for y in H:
  if not grid[y].has(0): flash_rows.append(y)
 var cleared = flash_rows.size()
 for i in range(flash_rows.size()-1,-1,-1): grid.remove_at(flash_rows[i])
 for i in cleared: grid.push_front(_empty_row())
 var attack = 0
 if cleared > 0:
  lines += cleared
  combo += 1
  var difficult = cleared == 4 or spin > 0
  attack = [0,0,1,2,4][cleared]
  score += [0,100,300,500,800][cleared]
  if spin == 2:
   attack = [0,2,4,6][mini(cleared,3)]
   score += 400*cleared
  elif spin == 1:
   attack = [0,0,1][mini(cleared,2)]
  b2b = b2b+1 if difficult else -1
  # Downstack B2B is a growing flat bonus AFTER the combo calculation. It is
  # never multiplied, stored for a surge, or paid out when the chain breaks.
  attack = combo_attack(attack,combo)+maxi(0,b2b)
  var perfect = true
  for row in grid:
   for v in row:
    if v != 0: perfect = false
  if perfect: attack = 10
  sounds.append("perfect" if perfect else ("tspin" if spin else "clear"+str(cleared)))
  label = "PERFECT CLEAR" if perfect else ("T-SPIN " if spin == 2 else ("MINI " if spin == 1 else ""))+["","SINGLE","DOUBLE","TRIPLE","QUAD"][cleared]
  label_life = 1000
  flash_life = 110
  attack = _cancel(attack)
  if rules.mode == "sprint": attack = 0
  if attack > 0:
   sent += attack
   events.append({"attack":attack})
 else:
  sounds.append("lock")
  combo = -1
  _raise_garbage()
 hold_used = false
 piece = 0
 if rules.mode == "sprint" and lines >= 40 and alive:
  completed = true
  delay = 0
  return
 var clear_delay = float(rules.clear_ms)
 if clear_delay < 0:
  clear_delay = [0,583.3333,666.6667,666.6667,750.0][cleared]
 delay = float(rules.entry_ms)+(clear_delay if cleared > 0 else 0.0)
 if delay <= 0: _spawn()

func reset_input():
 previous_input = 0
 direction = 0
 das_clock = 0
 repeat_clock = 0
 rotation_buffer = 0
 buffer_life = 0

func step(dt_ms: float, mask: int, changes: Array = []) -> Array:
 events.clear()
 sounds.clear()
 if not alive or completed: return []
 # Tick clocks once, before any action can finish the sprint or lock a piece.
 # In particular, a garbage deadline on this tick applies to that lock.
 elapsed += dt_ms
 flash_life = maxf(0,flash_life-dt_ms)
 label_life = maxf(0,label_life-dt_ms)
 buffer_life -= dt_ms
 for packet in pending: packet.remaining -= dt_ms
 soft_clock -= dt_ms
 var changed_direction = false
 for transition in changes:
  var before = direction
  _advance(0.0,int(transition))
  changed_direction = changed_direction or before != direction
 # Transitions cost no extra gravity, warning, lock, or sprint time.
 _advance(dt_ms,mask,changed_direction)
 # Only actual idle ticks discard overdue time. A zero-time release/repress
 # must preserve the fractional remainder of rates such as 90 cells/second.
 if not mask & SOFT: soft_clock = maxf(0.0,soft_clock)
 return events.duplicate(true)

func _advance(dt_ms: float, mask: int, skip_das: bool = false):
 if not alive or completed: return
 var edges = mask & ~previous_input
 # Keep the cadence through short releases. Controller chatter must not grant
 # another immediate cell on every rising edge. Idle time never banks drops.
 # A rate change must not spend previously accumulated gravity time as a burst.
 if bool(mask & SOFT) != bool(previous_input & SOFT): gravity_clock = 0.0
 previous_input = mask
 var want_dir = -1 if mask & LEFT else (1 if mask & RIGHT else 0)
 # Last pressed direction wins when both are held.
 if mask & LEFT and mask & RIGHT:
  want_dir = -1 if edges & LEFT else (1 if edges & RIGHT else direction)
 var dir_changed = want_dir != direction
 if dir_changed:
  direction = want_dir
  das_clock = 0
  repeat_clock = 0
 elif direction != 0 and not skip_das:
  das_clock += dt_ms
 if piece == 0:
  if edges & CW or edges & CCW:
   rotation_buffer = 1 if edges & CW else -1
   buffer_life = 50.0
  delay -= dt_ms
  if delay > 0: return
  _spawn()
  if buffer_life > 0:
   rotate(rotation_buffer)
   edges &= ~(CW | CCW) # This edge was consumed by the entry rotation.
  rotation_buffer = 0
  buffer_life = 0
 if not alive: return
 if edges & HOLD and not hold_used:
  var old = held
  held = piece
  _spawn(old)
  hold_used = true
  sounds.append("hold")
 if not alive: return
 if edges & CW: rotate(1)
 elif edges & CCW: rotate(-1)
 if direction != 0:
  if dir_changed: move(direction)
  elif dt_ms > 0 and das_clock+0.0001 >= float(handling.das):
   if repeat_clock <= 0.0001:
    move(direction)
    repeat_clock += float(handling.arr)
   repeat_clock -= dt_ms
 if edges & HARD:
  sounds.append("drop")
  var target_y = ghost_y()
  score += (target_y-pos.y)*2
  if target_y != pos.y: last_rotate = false
  pos.y = target_y
  _lock()
  return
 var gravity = maxf(40.0,1000.0*pow(0.8,floori(lines/10.0)))
 if rules.mode == "sprint": gravity = 1000.0
 var instant_soft = bool(mask & SOFT) and float(handling.soft_drop) == 0.0
 if instant_soft:
  var distance = ghost_y()-pos.y
  if distance > 0:
   pos.y += distance
   lock_clock = 0
   score += distance
  gravity_clock = 0.0
  soft_clock = 0.0
 elif mask & SOFT:
  var interval = gravity/20.0 if float(handling.soft_drop) < 0 else minf(gravity,1000.0/maxf(1.0,float(handling.soft_drop)))
  gravity_clock = 0.0
  while soft_clock <= 0.0001:
   soft_clock += interval
   if fits(pos+Vector2i(0,1)):
    pos.y += 1
    lock_clock = 0
    score += 1
   else:
    # Do not store catch-up time while grounded or inside an entry delay.
    soft_clock = interval
    break
 else:
  gravity_clock += dt_ms
  while gravity_clock+0.0001 >= gravity:
   gravity_clock -= gravity
   if fits(pos+Vector2i(0,1)):
    pos.y += 1
    lock_clock = 0
   else:
    gravity_clock = 0.0
    break
 if not fits(pos+Vector2i(0,1)):
  lock_clock += dt_ms
  if lock_clock >= float(rules.lock_ms): _lock()
 return

func snapshot() -> Dictionary:
 return {"grid":grid.duplicate(true),"piece":piece,"rotation":rotation,"x":pos.x,"y":pos.y,"held":held,"next":queue.slice(0,5),"alive":alive,"completed":completed,"goal":40 if rules.mode == "sprint" else 0,"lines":lines,"pieces":pieces,"sent":sent,"score":score,"combo":combo,"b2b":b2b,"pending":pending.duplicate(true),"label":label if label_life > 0 else "","ghost":ghost_y() if piece else 0,"elapsed":elapsed,"flash":flash_rows.duplicate() if flash_life > 0 else []}
