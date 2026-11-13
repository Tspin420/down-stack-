class_name FallSession
extends Node

signal lobby_updated
signal started(seed_value)
signal round_finished(winner_id)
signal garbage_arrived(player_id, amount, hole, packet_id)
signal closed(message)

const Board = preload("res://scripts/board.gd")
const PROTOCOL = 4
var online = false
var hosting = false
var running = false
var roster = []
var states = {}
var rules = {"clear_ms":120.0,"entry_ms":100.0,"garbage_ms":1000.0,"lock_ms":500.0,"mode":"versus"}
var screens = 1
var seed_value = 1
var net = ENetMultiplayerPeer.new()
var packet_counter = 0
var attack_rng = RandomNumberGenerator.new()
var next_target = {}
var settle_clock = 0.0
var publish_clock = 0.0
var ready_peers = {}

func _ready():
 multiplayer.peer_connected.connect(_peer_connected)
 multiplayer.peer_disconnected.connect(_peer_disconnected)
 multiplayer.connected_to_server.connect(func(): _hello.rpc_id(1,PROTOCOL))
 multiplayer.connection_failed.connect(func(): close_session("Could not reach host. Check address, UDP port and firewall."))
 multiplayer.server_disconnected.connect(func(): close_session("Host disconnected. The match has ended."))

func local_id() -> int:
 return multiplayer.get_unique_id() if online else 1

func make_local():
 online = false
 hosting = true
 lobby_updated.emit()

func host(port: int) -> Error:
 var result = net.create_server(port,12)
 if result == OK:
  multiplayer.multiplayer_peer = net
  online = true
  hosting = true
  lobby_updated.emit()
 return result

func join(address: String,port: int) -> Error:
 var result = net.create_client(address,port)
 if result == OK:
  multiplayer.multiplayer_peer = net
  online = true
  hosting = false
 return result

func close_session(message: String = ""):
 running = false
 if online:
  net.close()
  multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
 online = false
 hosting = false
 roster.clear()
 states.clear()
 ready_peers.clear()
 screens = 1
 closed.emit(message)

func _peer_connected(_id: int):
 pass # A protocol handshake is required before joining the room.

@rpc("any_peer","call_remote","reliable")
func _hello(version: int):
 if not hosting: return
 var sender = multiplayer.get_remote_sender_id()
 if version != PROTOCOL:
  net.disconnect_peer(sender)
  return
 ready_peers[sender] = true
 _broadcast_lobby()
 if running:
  _start.rpc_id(sender,seed_value)
  for id in states: _state.rpc_id(sender,id,_pack(states[id]))

func _peer_disconnected(id: int):
 if not hosting: return
 ready_peers.erase(id)
 if running:
  for p in roster:
   if p.owner == id and states.has(p.id): states[p.id].alive = false
 else:
  roster = roster.filter(func(p): return p.owner != id)
 _broadcast_lobby()

func change_player(device: int,player_name: String,device_name: String,das: float,arr: float,remove: bool = false,soft_drop: float = -1.0):
 if hosting: _change(local_id(),device,player_name,device_name,das,arr,remove,soft_drop)
 elif online: _request_player.rpc_id(1,device,player_name,device_name,das,arr,remove,soft_drop)

@rpc("any_peer","call_remote","reliable")
func _request_player(device: int,player_name: String,device_name: String,das: float,arr: float,remove: bool,soft_drop: float):
 if hosting and ready_peers.has(multiplayer.get_remote_sender_id()):
  _change(multiplayer.get_remote_sender_id(),device,player_name,device_name,das,arr,remove,soft_drop)

func _change(owner: int,device: int,player_name: String,device_name: String,das: float,arr: float,remove: bool,soft_drop: float):
 if running or device < -2 or device > 31 or not is_finite(das) or not is_finite(arr) or not is_finite(soft_drop): return
 if soft_drop < 0 and soft_drop != -1.0: return
 var id = str(owner)+":"+str(device)
 var index = -1
 for i in roster.size():
  if roster[i].id == id: index = i
 if remove:
  if index >= 0: roster.remove_at(index)
 elif index >= 0 or roster.size() < 4:
  var p = {"id":id,"owner":owner,"device":device,"name":player_name.strip_edges().substr(0,20),"input":device_name.substr(0,40),"das":clampf(das,83.3333,300.0),"arr":clampf(arr,16.6667,100.0),"soft_drop":clampf(soft_drop,-1.0,120.0)}
  if p.name.is_empty(): p.name = "Player "+str(roster.size()+1)
  if index >= 0: roster[index] = p
  else: roster.append(p)
 _broadcast_lobby()

func set_rules(clear_ms: float,garbage_ms: float):
 if not hosting or running: return
 rules.clear_ms = clampf(clear_ms,-1.0,1000.0)
 rules.garbage_ms = clampf(garbage_ms,250.0,3000.0)
 _broadcast_lobby()

func _broadcast_lobby():
 screens = ready_peers.size()+1
 if online: _lobby.rpc(roster,rules,screens)
 else: lobby_updated.emit()

@rpc("authority","call_local","reliable")
func _lobby(players: Array,settings: Dictionary,screen_count: int):
 roster = players
 rules = settings
 screens = screen_count
 lobby_updated.emit()

func begin():
 if not hosting or running or roster.is_empty(): return
 seed_value = randi_range(1,2147483647)
 if online: _start.rpc(seed_value)
 else: _start(seed_value)

@rpc("authority","call_local","reliable")
func _start(value: int):
 seed_value = value
 running = true
 states.clear()
 next_target.clear()
 packet_counter = 0
 settle_clock = 0
 attack_rng.seed = seed_value+93
 for p in roster: states[p.id] = {"alive":true}
 started.emit(value)

func back_to_lobby():
 if not hosting: return
 if online: _return_to_lobby.rpc()
 else: _return_to_lobby()

@rpc("authority","call_local","reliable")
func _return_to_lobby():
 running = false
 if hosting:
  roster = roster.filter(func(p): return p.owner == 1 or ready_peers.has(p.owner))
 lobby_updated.emit()
 if hosting: _broadcast_lobby()

func post_state(id: String,data: Dictionary):
 if not running: return
 if hosting:
  if _owns(local_id(),id): states[id] = data
 elif online: _submit_state.rpc_id(1,id,_pack(data))

func _pack(data: Dictionary) -> PackedByteArray:
 return var_to_bytes(data).compress(FileAccess.COMPRESSION_DEFLATE)

func _unpack(payload: PackedByteArray) -> Dictionary:
 if payload.size() > 8192: return {}
 var decoded = payload.decompress_dynamic(65536,FileAccess.COMPRESSION_DEFLATE)
 if decoded.is_empty(): return {}
 var result = bytes_to_var(decoded)
 return result if result is Dictionary else {}

func _owns(owner: int,id: String) -> bool:
 for p in roster:
  if p.id == id: return p.owner == owner
 return false

func _valid_state(data: Dictionary) -> bool:
 if not data.has_all(["grid","piece","rotation","x","y","held","next","alive","lines","pieces","sent","score","pending","ghost","label","elapsed","flash","combo","b2b"]): return false
 if not data.grid is Array or data.grid.size() != Board.H: return false
 for row in data.grid:
  if not row is Array or row.size() != Board.W: return false
  for value in row:
   if not value is int or value < 0 or value > 8: return false
 for key in ["piece","rotation","x","y","held","lines","pieces","sent","score","ghost","combo"]:
  if not data[key] is int: return false
 if data.piece < 0 or data.piece > 7 or data.held < 0 or data.held > 7 or data.rotation < 0 or data.rotation > 3: return false
 if not data.next is Array or data.next.size() > 5: return false
 for n in data.next:
  if not n is int or n < 1 or n > 7: return false
 if not data.pending is Array or data.pending.size() > 128: return false
 for p in data.pending:
  if not p is Dictionary or not p.has_all(["amount","remaining","hole","id"]): return false
  if not p.amount is int or p.amount < 0 or p.amount > 40: return false
  if not (p.remaining is float or p.remaining is int): return false
 if not data.label is String or data.label.length() > 40: return false
 if not data.flash is Array or data.flash.size() > 4: return false
 for v in data.flash:
  if not v is int or v < 0 or v >= Board.H: return false
 return data.alive is bool

@rpc("any_peer","call_remote","unreliable_ordered",1)
func _submit_state(id: String,payload: PackedByteArray):
 var data = _unpack(payload)
 if hosting and running and _owns(multiplayer.get_remote_sender_id(),id) and _valid_state(data):
  states[id] = data

@rpc("authority","call_remote","unreliable_ordered",1)
func _state(id: String,payload: PackedByteArray):
 var data = _unpack(payload)
 if running and _valid_state(data): states[id] = data

func attack(id: String,amount: int):
 if hosting: _route_attack(local_id(),id,amount)
 elif online: _attack.rpc_id(1,id,amount)

@rpc("any_peer","call_remote","reliable")
func _attack(id: String,amount: int):
 if hosting: _route_attack(multiplayer.get_remote_sender_id(),id,amount)

func _route_attack(owner: int,id: String,amount: int):
 if not running or not _owns(owner,id) or amount < 1 or amount > 20: return
 var targets = []
 for p in roster:
  if p.id != id and states.get(p.id,{}).get("alive",false): targets.append(p.id)
 if targets.is_empty(): return
 var cursor = int(next_target.get(id,0))%targets.size()
 var target = targets[cursor]
 next_target[id] = cursor+1
 packet_counter += 1
 var hole = attack_rng.randi_range(0,9)
 if online: _garbage.rpc(target,amount,hole,packet_counter)
 else: _garbage(target,amount,hole,packet_counter)

@rpc("authority","call_local","reliable")
func _garbage(id: String,amount: int,hole: int,number: int):
 garbage_arrived.emit(id,amount,hole,number)

@rpc("authority","call_local","reliable")
func _finish(winner_id: String):
 running = false
 round_finished.emit(winner_id)

func _process(dt: float):
 if not hosting or not running: return
 publish_clock += dt
 if publish_clock >= 0.05:
  publish_clock = 0
  if online:
   for id in states: _state.rpc(id,_pack(states[id]))
 var alive_ids = []
 for p in roster:
  if states.get(p.id,{}).get("alive",true): alive_ids.append(p.id)
 if alive_ids.size() == 0 or (roster.size() > 1 and alive_ids.size() <= 1):
  settle_clock += dt
  if settle_clock >= 0.2:
   var winner = str(alive_ids[0]) if alive_ids.size() == 1 else ""
   if online: _finish.rpc(winner)
   else: _finish(winner)
 else: settle_clock = 0
