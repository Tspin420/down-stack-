class_name DownstackInputSettings
extends RefCounted

const ACTIONS = ["Move left","Move right","Soft drop","Rotate clockwise","Rotate counterclockwise","Hard drop","Hold","Restart sprint"]
const REQUIRED = 7
const RESTART = 128
const SOFT_RATES = [-1.0,5.0,10.0,15.0,20.0,30.0,45.0,60.0,90.0,120.0,0.0]
const Handling = preload("res://scripts/handling.gd")
const PAD_NAMES = ["South · A / Cross","East · B / Circle","West · X / Square","North · Y / Triangle","Back / Select","Guide","Start / Options","Left stick click","Right stick click","LB / L1","RB / R1","D-pad Up","D-pad Down","D-pad Left","D-pad Right"]
var profiles = {}
var axis_latches = {}
var device_profiles = {}
var legacy_handling = {"das_level":5,"arr_level":5}

func _init(config: ConfigFile = null):
 if config:
  for kind in ["das","arr"]:
   var fallback = Handling.level_for_ms(kind,float(config.get_value("handling",kind,166.6667 if kind == "das" else 33.3333)))
   legacy_handling[kind+"_level"] = clampi(int(config.get_value("handling",kind+"_level",fallback)),1,10)
 if config and config.has_section("input_profiles"):
  for key in config.get_section_keys("input_profiles"):
   var value = config.get_value("input_profiles",key)
   if value is Dictionary:
    profiles[key] = value.duplicate(true)
    for kind in legacy_handling:
     if not profiles[key].has(kind): profiles[key][kind] = legacy_handling[kind]

static func key_binding(code: int) -> Dictionary:
 return {"kind":"key","code":code}

static func button_binding(code: int) -> Dictionary:
 return {"kind":"button","code":code}

static func axis_binding(axis: int,direction: int) -> Dictionary:
 return {"kind":"axis","code":axis,"direction":direction}

static func defaults(device: int) -> Dictionary:
 var bindings = []
 if device < 0:
  var keys = [KEY_LEFT,KEY_RIGHT,KEY_DOWN,KEY_X,KEY_Z,KEY_SPACE,KEY_C,KEY_R] if device == -1 else [KEY_A,KEY_D,KEY_S,KEY_K,KEY_J,KEY_W,KEY_Q,KEY_R]
  for code in keys: bindings.append([key_binding(code),{}])
 else:
  for code in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_B,JOY_BUTTON_A,JOY_BUTTON_DPAD_UP,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_START]:
   bindings.append([button_binding(code),{}])
  bindings[0][1] = axis_binding(JOY_AXIS_LEFT_X,-1)
  bindings[1][1] = axis_binding(JOY_AXIS_LEFT_X,1)
  bindings[2][1] = axis_binding(JOY_AXIS_LEFT_Y,1)
  bindings[6][1] = button_binding(JOY_BUTTON_RIGHT_SHOULDER)
 return {"bindings":bindings,"soft_drop":-1.0,"das_level":5,"arr_level":5}

static func reserved(code: int) -> bool:
 return code == KEY_ESCAPE or code == KEY_F11

static func valid_binding(value,device: int) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true
 if not value.get("code") is int: return false
 var code = int(value.code)
 match value.get("kind",""):
  "key", "keycode": return device < 0 and code > 0 and code < (1<<24) and not reserved(code)
  "button": return device >= 0 and code >= 0 and code < JOY_BUTTON_MAX
  "axis": return device >= 0 and code >= 0 and code < JOY_AXIS_MAX and value.get("direction",0) in [-1,1]
 return false

static func token(value: Dictionary) -> String:
 if value.is_empty(): return ""
 # Physical and logical fallbacks for navigation keys denote the same control.
 var kind = str(value.get("kind",""))
 if kind == "keycode": kind = "key"
 return "%s:%d:%d"%[kind,value.get("code",0),value.get("direction",0)]

static func sanitize(value,device: int) -> Dictionary:
 var clean = defaults(device)
 if not value is Dictionary: return clean
 for kind in ["das_level","arr_level"]:
  var level = value.get(kind,5)
  if (level is int or level is float) and is_finite(float(level)):
   clean[kind] = clampi(int(level),1,10)
 var rate = value.get("soft_drop",-1.0)
 if (rate is float or rate is int) and is_finite(float(rate)) and float(rate) in SOFT_RATES:
  clean.soft_drop = float(rate)
 var raw = value.get("bindings")
 if not raw is Array or raw.size() != ACTIONS.size(): return clean
 var candidate = []
 var seen = {}
 for action in raw:
  if not action is Array or action.size() != 2: return clean
  var pair = []
  for binding in action:
   if not valid_binding(binding,device): return clean
   var id = token(binding)
   if not id.is_empty() and seen.has(id): return clean
   if not id.is_empty(): seen[id] = true
   pair.append(binding.duplicate(true))
  candidate.append(pair)
 for i in REQUIRED:
  if candidate[i][0].is_empty() and candidate[i][1].is_empty(): return clean
 clean.bindings = candidate
 return clean

func profile_key(device: int) -> String:
 if device < 0: return "keyboard_1" if device == -1 else "keyboard_2"
 var connected = Input.get_connected_joypads()
 if not device in connected: return device_profiles.get(device,"pad_offline_"+str(device))
 var guid = Input.get_joy_guid(device)
 var name_value = Input.get_joy_name(device)
 var ordinal = 0
 for other in connected:
  if other < device and Input.get_joy_guid(other) == guid and Input.get_joy_name(other) == name_value: ordinal += 1
 # Reconnecting one controller at a new runtime ID retains its profile.
 # Identical controllers are distinguished by their connection order.
 var key = "pad_"+(guid+"|"+name_value).sha256_text().substr(0,20)+"_"+str(ordinal)
 device_profiles[device] = key
 return key

func profile(device: int) -> Dictionary:
 var raw = profiles.get(profile_key(device),{}).duplicate(true)
 for kind in legacy_handling:
  if not raw.has(kind): raw[kind] = legacy_handling[kind]
 return sanitize(raw,device)

func commit(config: ConfigFile,updates: Dictionary) -> Error:
 # Keep the live profiles and shared preferences intact if writing fails.
 var candidate = ConfigFile.new()
 candidate.parse(config.encode_to_text())
 for key in profiles: candidate.set_value("input_profiles",key,profiles[key].duplicate(true))
 for key in updates: candidate.set_value("input_profiles",key,updates[key].duplicate(true))
 var error = candidate.save("user://preferences.cfg")
 if error != OK: return error
 for key in updates: profiles[key] = updates[key].duplicate(true)
 config.clear()
 config.parse(candidate.encode_to_text())
 axis_latches.clear()
 return OK

func save(config: ConfigFile):
 for key in profiles: config.set_value("input_profiles",key,profiles[key].duplicate(true))

static func binding_text(value: Dictionary) -> String:
 if value.is_empty(): return "Unassigned"
 var code = int(value.code)
 match value.kind:
  "key", "keycode": return OS.get_keycode_string(code)
  "button": return PAD_NAMES[code] if code < PAD_NAMES.size() else "Button %d"%(code+1)
  "axis":
   if code == JOY_AXIS_TRIGGER_LEFT: return "LT / L2"
   if code == JOY_AXIS_TRIGGER_RIGHT: return "RT / R2"
   if code in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y]:
    var stick = "Left stick " if code <= JOY_AXIS_LEFT_Y else "Right stick "
    var direction = ("Left" if value.direction < 0 else "Right") if code in [JOY_AXIS_LEFT_X,JOY_AXIS_RIGHT_X] else ("Up" if value.direction < 0 else "Down")
    return stick+direction
   return "Axis %d %s"%[code,"−" if value.direction < 0 else "+"]
 return "Unassigned"

static func soft_text(rate: float) -> String:
 return "20× gravity · Default" if rate < 0 else ("Instant" if rate == 0 else "%d cells/sec"%int(rate))

static func from_event(event: InputEvent,device: int,ready_axes: Dictionary) -> Dictionary:
 if device < 0 and event is InputEventKey and event.pressed and not event.echo:
  var code = int(event.physical_keycode) if event.physical_keycode else int(event.keycode)
  if code > 0 and not reserved(code): return {"kind":"key" if event.physical_keycode else "keycode","code":code}
 elif device >= 0 and event.device == device:
  if event is InputEventJoypadButton and event.pressed: return button_binding(event.button_index)
  if event is InputEventJoypadMotion:
   if absf(event.axis_value) < 0.35: ready_axes[event.axis] = true
   elif ready_axes.get(event.axis,false) and absf(event.axis_value) >= 0.65:
    return axis_binding(event.axis,1 if event.axis_value > 0 else -1)
 return {}

static func assign(profile_value: Dictionary,action: int,slot: int,binding: Dictionary) -> String:
 var old = profile_value.bindings[action][slot].duplicate(true)
 var id = token(binding)
 var result = "Assigned "+binding_text(binding)+" to "+ACTIONS[action]+"."
 for i in ACTIONS.size():
  for j in 2:
   if i == action and j == slot: continue
   if not id.is_empty() and token(profile_value.bindings[i][j]) == id:
    profile_value.bindings[i][j] = old
    result = "Swapped bindings for "+ACTIONS[action]+" and "+ACTIONS[i]+"."
 profile_value.bindings[action][slot] = binding.duplicate(true)
 return result

static func missing(profile_value: Dictionary) -> Array:
 var result = []
 for i in REQUIRED:
  if profile_value.bindings[i][0].is_empty() and profile_value.bindings[i][1].is_empty(): result.append(ACTIONS[i])
 return result

func pressed(binding: Dictionary,device: int) -> bool:
 if binding.is_empty(): return false
 var code = int(binding.code)
 match binding.kind:
  "key":
   var navigation = code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_HOME,KEY_END,KEY_PAGEUP,KEY_PAGEDOWN,KEY_INSERT,KEY_DELETE]
   return Input.is_physical_key_pressed(code) or (navigation and Input.is_key_pressed(code))
  "keycode": return Input.is_key_pressed(code)
  "button": return Input.is_joy_button_pressed(device,code)
  "axis":
   var id = str(device)+":"+token(binding)
   var strength = Input.get_joy_axis(device,code)*int(binding.direction)
   var active = strength >= (0.35 if axis_latches.get(id,false) else 0.55)
   axis_latches[id] = active
   return active
 return false

func mask(profile_value: Dictionary,device: int) -> int:
 var result = 0
 for action in ACTIONS.size():
  # Evaluate both slots so analog hysteresis stays current even if the other
  # slot is held (for example D-pad plus stick).
  var first = pressed(profile_value.bindings[action][0],device)
  var second = pressed(profile_value.bindings[action][1],device)
  if first or second: result |= 1<<action
 return result
