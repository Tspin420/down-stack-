extends VBoxContainer

const Settings = preload("res://scripts/input_settings.gd")
const HandlingControls = preload("res://scripts/handling_controls.gd")
signal profiles_saved
signal canceled
signal display_mode_requested(fullscreen: bool)
signal shortcut_requested
var display_mode: OptionButton
var shortcut_button: Button
var display_message: Label
var settings
var config: ConfigFile
var picker: OptionButton
var handling
var apply_button: Button
var cancel_button: Button
var hint: Label
var message: Label
var shared: Label
var cancel_capture: Button
var rows = []
var drafts = {}
var draft_devices = {}
var device = -1
var profile_id = ""
var capture_action = -1
var capture_slot = 0
var ready_axes = {}

func _ready():
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 size_flags_vertical = Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",14)
 Input.joy_connection_changed.connect(_connection_changed)
 _label("SETTINGS",self,30)
 _label("Set every action yourself: click Change, then press the key or controller input you want.",self,16)
 var display_row = HBoxContainer.new()
 display_row.add_theme_constant_override("separation",14)
 add_child(display_row)
 _label("DISPLAY",display_row,17)
 display_mode = OptionButton.new()
 display_mode.add_item("Windowed")
 display_mode.add_item("Fullscreen (borderless)")
 display_row.add_child(display_mode)
 display_mode.item_selected.connect(func(index): display_mode_requested.emit(index == 1))
 _label("Saved immediately · F11 also toggles",display_row,14)
 var display_spacer = Control.new()
 display_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 display_row.add_child(display_spacer)
 shortcut_button = _button("Create desktop shortcut",display_row,func(): shortcut_requested.emit())
 shortcut_button.disabled = not preload("res://scripts/desktop_shortcut.gd").available()
 shortcut_button.tooltip_text = "Creates a Windows desktop shortcut with the T icon. Available in the Windows release."
 display_message = _label("Keep the extracted game folder in place after creating its shortcut.",self,13)
 display_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var scroll = ScrollContainer.new()
 scroll.follow_focus = true
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 var columns = HBoxContainer.new()
 columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 columns.add_theme_constant_override("separation",36)
 scroll.add_child(columns)
 var left = VBoxContainer.new()
 left.custom_minimum_size.x = 370
 left.add_theme_constant_override("separation",14)
 columns.add_child(left)
 _label("PLAYER / INPUT DEVICE",left,17)
 picker = OptionButton.new()
 picker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 left.add_child(picker)
 picker.item_selected.connect(func(i): _select_device(int(picker.get_item_metadata(i))))
 _label("HANDLING",left,17)
 handling = HandlingControls.new()
 left.add_child(handling)
 handling.changed.connect(func(values):
  for key in values: _draft()[key] = values[key]
  message.text = "Handling updated. Apply & back to save.")
 var note = _label("Instant soft drop moves to the floor and keeps lock delay. Hard drop locks immediately.\n\nKeyboard 1, Keyboard 2 and each controller have separate saved settings.",left,14)
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var right = VBoxContainer.new()
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 right.add_theme_constant_override("separation",10)
 columns.add_child(right)
 _label("CUSTOM KEY / BUTTON BINDINGS",right,17)
 var instructions = HBoxContainer.new()
 right.add_child(instructions)
 hint = _label("Every row is editable. Click Change or + Bind input.",instructions,14)
 hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 cancel_capture = _button("Cancel capture",instructions,_cancel_capture)
 cancel_capture.hide()
 var grid = GridContainer.new()
 grid.columns = 5
 grid.add_theme_constant_override("h_separation",8)
 grid.add_theme_constant_override("v_separation",7)
 right.add_child(grid)
 for label_value in ["Action","Primary","","Alternate",""]: _label(label_value,grid,14)
 for i in Settings.ACTIONS.size():
  _label(Settings.ACTIONS[i],grid,15).custom_minimum_size.x = 205
  var pair = []
  for slot in 2:
   var button = _button("",grid,_begin_capture.bind(i,slot))
   button.custom_minimum_size = Vector2(190,38)
   button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
   button.add_theme_font_size_override("font_size",14)
   pair.append(button)
   var clear = _button("×",grid,_clear.bind(i,slot))
   clear.tooltip_text = "Clear this binding"
   clear.custom_minimum_size = Vector2(30,38)
  rows.append(pair)
 shared = _label("",right,13)
 shared.custom_minimum_size.y = 36
 shared.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 _label("Esc cancels capture. F11 toggles fullscreen. Controls apply next round.",right,13)
 message = _label("",self,14)
 message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 message.custom_minimum_size.y = 26
 var actions = HBoxContainer.new()
 actions.add_theme_constant_override("separation",10)
 add_child(actions)
 _button("Reset this profile",actions,_reset_profile)
 var spacer = Control.new()
 spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 actions.add_child(spacer)
 cancel_button = _button("Cancel",actions,_cancel)
 apply_button = _button("Apply & back",actions,_apply)

func _button(value: String,parent: Node,callback: Callable) -> Button:
 var button = Button.new()
 button.text = value
 button.focus_mode = Control.FOCUS_ALL
 button.custom_minimum_size.y = 40
 parent.add_child(button)
 button.pressed.connect(callback)
 return button

func set_display_mode(fullscreen: bool):
 display_mode.select(1 if fullscreen else 0)

func _reset_profile():
 _cancel_capture()
 drafts[profile_id] = Settings.defaults(device)
 message.text = "Default bindings and handling restored. Apply & back to save."
 _refresh()

func _cancel():
 close_page()
 canceled.emit()

func close_page():
 _cancel_capture()
 drafts.clear()
 draft_devices.clear()
 hide()

func _input(event: InputEvent):
 if not is_visible_in_tree(): return
 if capture_action >= 0:
  _capture_event(event)
 elif event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  _cancel()

func _label(value: String,parent: Node,font_size: int) -> Label:
 var item = Label.new()
 item.text = value
 item.add_theme_font_size_override("font_size",font_size)
 parent.add_child(item)
 return item

func _populate(preferred: int):
 picker.clear()
 picker.add_item("Keyboard 1")
 picker.set_item_metadata(0,-1)
 picker.add_item("Keyboard 2")
 picker.set_item_metadata(1,-2)
 for id in Input.get_connected_joypads():
  picker.add_item("Controller %d · %s"%[id+1,Input.get_joy_name(id)])
  picker.set_item_metadata(picker.item_count-1,id)
 var selected = 0
 for i in picker.item_count:
  if int(picker.get_item_metadata(i)) == preferred: selected = i
 picker.select(selected)
 _select_device(int(picker.get_item_metadata(selected)))

func open_for(preferred: int = -1):
 drafts.clear()
 draft_devices.clear()
 capture_action = -1
 message.text = "Choose a player or controller, edit its individual bindings, then Apply & back."
 _populate(preferred)
 show()

func _select_device(value: int):
 _cancel_capture()
 device = value
 var key = settings.profile_key(device)
 profile_id = key
 if not drafts.has(key): drafts[key] = settings.profile(device)
 draft_devices[key] = device
 _refresh()

func _draft() -> Dictionary:
 return drafts[profile_id]

func _refresh():
 if drafts.is_empty() or not drafts.has(profile_id): return
 var current = _draft()
 handling.set_values(current)
 for action in Settings.ACTIONS.size():
  for slot in 2:
   var binding = current.bindings[action][slot]
   rows[action][slot].text = "Press input…" if action == capture_action and slot == capture_slot else ("+ Bind input" if binding.is_empty() else "Change · "+Settings.binding_text(binding))
   rows[action][slot].tooltip_text = Settings.ACTIONS[action]+": "+Settings.binding_text(binding)+". Click to assign any key, button, trigger or stick direction."
 var invalid = []
 for value in drafts.values(): invalid.append_array(Settings.missing(value))
 apply_button.disabled = not invalid.is_empty() or capture_action >= 0
 if not invalid.is_empty(): message.text = "Assign at least one binding for: "+", ".join(invalid)
 var conflicts = []
 if device < 0:
  var other = -2 if device == -1 else -1
  var other_profile = drafts.get(settings.profile_key(other),settings.profile(other))
  for action in Settings.REQUIRED:
   for binding in current.bindings[action]:
    if binding.is_empty(): continue
    for other_action in Settings.REQUIRED:
     for other_binding in other_profile.bindings[other_action]:
      if Settings.token(binding) == Settings.token(other_binding) and not Settings.binding_text(binding) in conflicts:
       conflicts.append(Settings.binding_text(binding))
 shared.text = "Shared with the other keyboard profile: "+", ".join(conflicts)+". Both players respond if both join." if not conflicts.is_empty() else ("Same-model controllers use connection order for separate saved profiles." if device >= 0 else "Connect a controller to configure its buttons, D-pad, triggers and sticks.")

func _begin_capture(action: int,slot: int):
 capture_action = action
 capture_slot = slot
 ready_axes.clear()
 if device >= 0:
  for axis in JOY_AXIS_MAX:
   if absf(Input.get_joy_axis(device,axis)) < 0.35: ready_axes[axis] = true
 hint.text = "Press input for "+Settings.ACTIONS[action]+". Esc cancels."
 cancel_capture.show()
 _refresh()

func _cancel_capture():
 capture_action = -1
 if is_instance_valid(hint): hint.text = "Every row is editable. Click Change or + Bind input."
 if is_instance_valid(cancel_capture): cancel_capture.hide()
 if not drafts.is_empty(): _refresh()

func _capture_event(event: InputEvent):
 if capture_action < 0: return
 if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
  _cancel_capture()
  get_viewport().set_input_as_handled()
  return
 if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
  get_viewport().set_input_as_handled()
 var binding = Settings.from_event(event,device,ready_axes)
 if binding.is_empty():
  if event is InputEventKey and event.pressed and event.keycode == KEY_F11: message.text = "F11 is reserved for fullscreen. Choose another input."
  return
 message.text = Settings.assign(_draft(),capture_action,capture_slot,binding)
 _cancel_capture()

func _clear(action: int,slot: int):
 _cancel_capture()
 _draft().bindings[action][slot] = {}
 message.text = "Binding cleared. Apply & back to save."
 _refresh()

func _apply():
 if capture_action >= 0: return
 var updates = {}
 for key in drafts:
  if not Settings.missing(drafts[key]).is_empty(): return
  updates[key] = Settings.sanitize(drafts[key],draft_devices[key])
 var error = settings.commit(config,updates)
 if error != OK:
  message.text = "Could not save preferences: "+error_string(error)
  return
 close_page()
 profiles_saved.emit()

func _connection_changed(_id: int,_connected: bool):
 if is_visible_in_tree():
  # Cancel capture before replacing a disconnected device selector.
  capture_action = -1
  _populate(device)
  message.text = "Controller list updated. Review the selected input profile."
