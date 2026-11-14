extends Node

signal connected(peer_id, code)
signal peer_joined(peer_id)
signal peer_left(peer_id)
signal packet(sender, kind, args)
signal failed(message)

var socket = WebSocketPeer.new()
var active = false
var welcomed = false
var request_sent = false
var endpoint = ""
var request = {}
var elapsed = 0.0
var retry_at = 0.0
var ping_clock = 0.0
var peer_id = 0

static func normalize_code(value: String) -> String:
 return value.strip_edges().to_upper().replace("-", "").replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")

static func valid_code(value: String) -> bool:
 var code = normalize_code(value)
 if code.length() != 8: return false
 for character in code:
  if character not in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789": return false
 return true

static func valid_url(value: String) -> bool:
 # Internet rooms always verify TLS. Plain WebSockets are for loopback tests only.
 if "@" in value or " " in value or "#" in value or "?" in value: return false
 if value.begins_with("wss://"):
  return value.trim_prefix("wss://").get_slice("/", 0).length() > 0 and value.ends_with("/rooms")
 return (value.begins_with("ws://127.0.0.1:") or value.begins_with("ws://localhost:")) and value.ends_with("/rooms")

static func configured_url() -> String:
 var override = OS.get_environment("DOWNSTACK_RELAY_URL").strip_edges()
 if not override.is_empty(): return override
 var cfg = ConfigFile.new()
 var external = OS.get_executable_path().get_base_dir().path_join("online.cfg")
 if not OS.has_feature("editor") and cfg.load(external) == OK:
  return str(cfg.get_value("online", "relay_url", "")).strip_edges()
 if cfg.load("res://online.cfg") == OK:
  return str(cfg.get_value("online", "relay_url", "")).strip_edges()
 return ""

func open(url: String, create: bool, code: String, protocol: int) -> Error:
 if active: return ERR_ALREADY_IN_USE
 if not valid_url(url): return ERR_INVALID_PARAMETER
 if not create and not valid_code(code): return ERR_INVALID_PARAMETER
 endpoint = url
 request = {"op":"create" if create else "join", "code":normalize_code(code), "wire":1, "protocol":protocol}
 active = true
 elapsed = 0.0
 retry_at = 0.0
 ping_clock = 0.0
 welcomed = false
 request_sent = false
 peer_id = 0
 _connect_socket()
 return OK

func _connect_socket():
 socket = WebSocketPeer.new()
 socket.inbound_buffer_size = 1048576
 socket.outbound_buffer_size = 1048576
 socket.max_queued_packets = 512
 request_sent = false
 socket.connect_to_url(endpoint)

func shutdown():
 active = false
 welcomed = false
 socket.close()

func _fail(message: String):
 if not active: return
 shutdown()
 failed.emit(message)

func send_packet(kind: String, args: Array, target: int = 0, skip: int = 0) -> bool:
 if not active or not welcomed: return false
 # Do not accumulate obsolete views behind a slow TCP connection.
 if kind == "state" and socket.get_current_outbound_buffered_amount() > 262144: return true
 var payload = var_to_bytes(args)
 if payload.size() > 65536:
  _fail("A room update was too large. Please rejoin.")
  return false
 if socket.send_text(JSON.stringify({"op":"send", "to":target, "skip":skip, "kind":kind, "payload":Marshalls.raw_to_base64(payload)})) != OK:
  _fail("Connection interrupted. Please rejoin the room.")
  return false
 return true

func _process(dt: float):
 if not active: return
 elapsed += dt
 socket.poll()
 var state = socket.get_ready_state()
 if state == WebSocketPeer.STATE_OPEN or socket.get_available_packet_count() > 0:
  if not request_sent and state == WebSocketPeer.STATE_OPEN:
   socket.send_text(JSON.stringify(request))
   request_sent = true
  while active and socket.get_available_packet_count() > 0:
   var raw = socket.get_packet()
   if raw.size() > 100000: continue
   var msg = JSON.parse_string(raw.get_string_from_utf8())
   if not msg is Dictionary: continue
   match msg.get("op", ""):
    "welcome":
     if welcomed: continue
     var id = int(msg.get("peer", 0))
     var code = str(msg.get("code", ""))
     if id < 1 or not valid_code(code) or (request.op == "create" and id != 1) or (request.op == "join" and id == 1):
      _fail("Invalid room response. Please try again.")
      return
     welcomed = true
     peer_id = id
     connected.emit(id, normalize_code(code))
    "peer_joined":
     if welcomed and peer_id == 1: peer_joined.emit(int(msg.get("peer", 0)))
    "peer_left":
     if welcomed and peer_id == 1: peer_left.emit(int(msg.get("peer", 0)))
    "packet":
     if not welcomed or not msg.get("payload", "") is String: continue
     var encoded = msg.payload
     if encoded.length() > 90000: continue
     var payload = Marshalls.base64_to_raw(encoded)
     if payload.size() > 65536: continue
     var args = bytes_to_var(payload) # Objects are never allowed.
     if args is Array: packet.emit(int(msg.get("from", 0)), str(msg.get("kind", "")), args)
    "error":
     _fail(str(msg.get("message", "Unable to join the room.")).substr(0, 200))
     return
  if not active: return
  ping_clock += dt
  if ping_clock >= 15.0 and state == WebSocketPeer.STATE_OPEN:
   ping_clock = 0.0
   socket.send_text('{"op":"ping"}')
 elif state == WebSocketPeer.STATE_CLOSED:
  var reason = socket.get_close_reason()
  if not reason.is_empty() and socket.get_close_code() in [1000, 1008, 1013]:
   _fail(reason.substr(0, 200))
   return
  if welcomed:
   _fail("Room connection lost. Return to the menu and rejoin.")
   return
  if elapsed >= retry_at:
   retry_at = elapsed + 2.0
   _connect_socket()
 if not welcomed and elapsed >= 90.0:
  _fail("Could not reach online rooms. Check your internet connection and try again.")
