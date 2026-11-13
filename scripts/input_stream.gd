class_name DownstackInputStream
extends RefCounted

# Keep delivered transitions in order, even when a complete tap fits between
# two physics ticks. Polling repairs state; it must never replace the history.
const Settings = preload("res://scripts/input_settings.gd")
const MAX_CHANGES = 256
var devices = {}
var settings
var overflow_count = 0

func configure(source, profiles: Dictionary):
 settings = source
 devices.clear()
 for device in profiles:
  var entries = []
  for action in Settings.ACTIONS.size():
   for binding in profiles[device].bindings[action]:
    if not binding.is_empty():
     entries.append({"binding":binding.duplicate(true),"bit":1<<action,"down":false,"blocked":false})
  devices[device] = {"entries":entries,"held":0,"changes":[],"enabled":true,"overflow":false}
  reset_device(device)

func _poll(entry: Dictionary, device: int) -> bool:
 var binding = entry.binding
 if binding.kind == "axis":
  return Input.get_joy_axis(device,binding.code)*binding.direction >= (0.35 if entry.down else 0.55)
 return settings.pressed(binding,device)

func reset_device(device: int):
 if not devices.has(device): return
 var state = devices[device]
 state.held = 0
 state.changes.clear()
 state.overflow = false
 for entry in state.entries:
  entry.down = _poll(entry,device)
  entry.blocked = entry.down

func set_enabled(device: int, enabled: bool) -> bool:
 if not devices.has(device) or devices[device].enabled == enabled: return false
 devices[device].enabled = enabled
 reset_device(device)
 return true

func _record(state: Dictionary):
 var mask = 0
 for entry in state.entries:
  if entry.down and not entry.blocked: mask |= entry.bit
 if not state.enabled: return
 if state.overflow: return
 if mask == state.held: return
 if state.changes.size() >= MAX_CHANGES:
  # Discard a pathological backlog rather than replaying stale hard drops.
  overflow_count += 1
  state.changes.clear()
  state.changes.append(0)
  state.held = 0
  state.overflow = true
  for entry in state.entries: entry.blocked = entry.down
  return
 state.held = mask
 state.changes.append(mask)

func _update_entry(entry: Dictionary, down: bool, enabled: bool):
 entry.down = down
 if not down: entry.blocked = false
 elif not enabled: entry.blocked = true

func feed(event: InputEvent):
 for device in devices:
  if device < 0:
   if not event is InputEventKey: continue
  elif event.device != device or not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
   continue
  var state = devices[device]
  for entry in state.entries:
   var b = entry.binding
   if event is InputEventKey:
    var matches = event.keycode == b.code if b.kind == "keycode" else event.physical_keycode == b.code
    # Some navigation-key events carry only their logical keycode.
    if b.kind == "key" and b.code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_HOME,KEY_END,KEY_PAGEUP,KEY_PAGEDOWN,KEY_INSERT,KEY_DELETE]:
     matches = matches or event.keycode == b.code
    if matches:
     if event.echo:
      # After focus loss the OS may resume repeats for a key whose original
      # press was cleared. Such a repeat must not become a new action via poll.
      if not entry.down:
       entry.down = true
       entry.blocked = true
     else: _update_entry(entry,event.pressed,state.enabled)
   elif event is InputEventJoypadButton and b.kind == "button" and event.button_index == b.code:
    _update_entry(entry,event.pressed,state.enabled)
   elif event is InputEventJoypadMotion and b.kind == "axis" and event.axis == b.code:
    _update_entry(entry,event.axis_value*b.direction >= (0.35 if entry.down else 0.55),state.enabled)
  _record(state)

func reconcile(device: int):
 if not devices.has(device): return
 var state = devices[device]
 for entry in state.entries: _update_entry(entry,_poll(entry,device),state.enabled)
 _record(state)

func peek(device: int) -> int:
 reconcile(device)
 return devices[device].held if devices.has(device) and devices[device].enabled else 0

func take(device: int) -> Dictionary:
 reconcile(device)
 if not devices.has(device): return {"held":0,"changes":[]}
 var state = devices[device]
 var result = {"held":state.held,"changes":state.changes.duplicate()}
 state.changes.clear()
 if state.overflow:
  var any_down = false
  for entry in state.entries: any_down = any_down or entry.down
  if not any_down: state.overflow = false
 return result

func discard_actions(device: int, bits: int):
 # Used at GO: movement can carry through the countdown; discrete actions
 # need a fresh press, including when released/repressed between ticks.
 if not devices.has(device): return
 var state = devices[device]
 for entry in state.entries:
  if entry.bit & bits and entry.down: entry.blocked = true
 state.held &= ~bits
 state.changes.clear()
