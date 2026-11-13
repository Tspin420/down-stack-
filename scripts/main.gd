extends Control

const Board = preload("res://scripts/board.gd")
const Session = preload("res://scripts/session.gd")
const BoardView = preload("res://scripts/board_view.gd")
const Handling = preload("res://scripts/handling.gd")
const Sound = preload("res://scripts/audio.gd")
const InputSettings = preload("res://scripts/input_settings.gd")
const SettingsPage = preload("res://scripts/settings_page.gd")
const HandlingControls = preload("res://scripts/handling_controls.gd")
const InputStream = preload("res://scripts/input_stream.gd")
const FullscreenShortcut = preload("res://scripts/fullscreen_shortcut.gd")
const DesktopShortcut = preload("res://scripts/desktop_shortcut.gd")
var fullscreen_shortcut
var fullscreen_button: Button
var fullscreen_enabled = false
var windowed_mode = Window.MODE_WINDOWED
var windowed_size = Vector2i(1280,800)
var windowed_position = Vector2i.ZERO
var input_stream = InputStream.new()
var window_focused = true
var disconnected_inputs = {}
var input_notice = ""
var status_before_input_notice = ""
var input_settings
var settings_page
var settings_button: Button
var lobby_handling
var settings_return_mode = "home"
var settings_return_status = ""
var local_profiles = {}
var restart_held = false
var sound
var session_kind = "versus"
var lobby_title: Label
var player_help: Label
var sprint_help: Label
var rules_help: Label
var audio_dialog: AcceptDialog
var retry_button: Button
var back_button: Button
var room
var page: VBoxContainer
var body: HBoxContainer
var status: Label
var home: VBoxContainer
var lobby: HBoxContainer
var player_list: VBoxContainer
var roster_note: Label
var devices: OptionButton
var name_field: LineEdit
var address_field: LineEdit
var port_field: SpinBox
var das_field: HSlider
var arr_field: HSlider
var garbage_field: SpinBox
var clear_field: OptionButton
var add_button: Button
var start_button: Button
var rule_panel: VBoxContainer
var play_panel: VBoxContainer
var play_top: Label
var end_button: Button
var game_row: HBoxContainer
var result_buttons: HBoxContainer
var models = {}
var views = {}
var countdown = 0.0
var send_clock = 0.0
var mode = "home"
var port = 42970
var last_devices = []
var config = ConfigFile.new()

func _ready():
 _make_theme()
 if config.load("user://preferences.cfg") != OK:
  config.load(OS.get_data_dir().path_join("Godot/app_userdata/Counterfall/preferences.cfg"))
 input_settings = InputSettings.new(config)
 sound = Sound.new()
 add_child(sound)
 room = Session.new()
 room.name = "Session"
 add_child(room)
 room.lobby_updated.connect(_refresh_lobby)
 room.started.connect(_start_game)
 room.round_finished.connect(_round_finished)
 room.garbage_arrived.connect(_garbage)
 room.closed.connect(_closed)
 Input.use_accumulated_input = false
 Input.joy_connection_changed.connect(_controller_connection_changed)
 get_window().focus_exited.connect(func(): _window_focus_changed(false))
 get_window().focus_entered.connect(func(): _window_focus_changed(true))
 _build_ui()
 fullscreen_shortcut = FullscreenShortcut.new()
 fullscreen_shortcut.toggle_requested.connect(_toggle_fullscreen)
 add_child(fullscreen_shortcut)
 fullscreen_shortcut.watch_windows(self)
 var saved_fullscreen = config.get_value("display","fullscreen",false)
 _set_fullscreen(saved_fullscreen if saved_fullscreen is bool else false,false)
 name_field.text = str(config.get_value("player","name","Player"))
 _device_list()
 sound.set_levels(float(config.get_value("audio","sfx",0.65)),float(config.get_value("audio","music",0.22)))
 # Screenshot-only scene demonstration, never used during normal play.
 if "--showcase" in OS.get_cmdline_user_args(): _showcase()

func _style(color: String,border: String = "28384b") -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = Color(color)
 s.border_color = Color(border)
 s.set_border_width_all(1)
 s.set_corner_radius_all(8)
 s.content_margin_left = 14
 s.content_margin_right = 14
 s.content_margin_top = 10
 s.content_margin_bottom = 10
 return s

func _make_theme():
 var t = Theme.new()
 t.default_font_size = 16
 t.set_color("font_color","Label",Color("dbe5f2"))
 for type in ["Button","OptionButton"]:
  t.set_stylebox("normal",type,_style("19283a"))
  t.set_stylebox("hover",type,_style("284252","6ed5bd"))
  t.set_stylebox("pressed",type,_style("284f51","6ed5bd"))
  t.set_stylebox("disabled",type,_style("101a28"))
  t.set_color("font_color",type,Color("e2edf6"))
 t.set_stylebox("normal","LineEdit",_style("0b1420"))
 t.set_stylebox("focus","LineEdit",_style("0b1420","6ed5bd"))
 t.set_color("font_color","LineEdit",Color("edf5ff"))
 t.set_color("font_color","SpinBox",Color.WHITE)
 theme = t

func _label(text_value: String,parent: Node,point_size: int = 16,color: String = "dbe5f2") -> Label:
 var l = Label.new()
 l.text = text_value
 l.add_theme_font_size_override("font_size",point_size)
 l.add_theme_color_override("font_color",Color(color))
 parent.add_child(l)
 return l

func _button(text_value: String,parent: Node,callback: Callable) -> Button:
 var b = Button.new()
 b.text = text_value
 b.custom_minimum_size.y = 44
 b.focus_mode = Control.FOCUS_NONE
 parent.add_child(b)
 b.pressed.connect(callback)
 b.pressed.connect(func(): sound.play("menu"))
 return b

func _space(parent: Node,height: float):
 var c = Control.new()
 c.custom_minimum_size.y = height
 parent.add_child(c)

func _spin(parent: Node,label_value: String,low: float,high: float,value: float) -> SpinBox:
 var row = HBoxContainer.new()
 parent.add_child(row)
 var l = _label(label_value,row,14)
 l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var spin = SpinBox.new()
 spin.min_value = low
 spin.max_value = high
 spin.step = 0.01
 spin.value = value
 spin.suffix = " ms"
 spin.custom_minimum_size.x = 175
 spin.get_line_edit().focus_mode = Control.FOCUS_CLICK
 row.add_child(spin)
 return spin

func _build_ui():
 var margin = MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,42)
 for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,26)
 add_child(margin)
 page = VBoxContainer.new()
 page.add_theme_constant_override("separation",10)
 margin.add_child(page)
 var header = HBoxContainer.new()
 page.add_child(header)
 var icon = TextureRect.new()
 icon.texture = preload("res://assets/icon.png")
 icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.custom_minimum_size = Vector2(46,46)
 header.add_child(icon)
 var brand = _label("DOWNSTACK",header,29,"e6f5ed")
 brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _label("PLAY TOGETHER  /  HOST YOUR OWN",header,12,"78d9c3")
 settings_button = _button("Settings",header,_open_settings)
 fullscreen_button = _button("Fullscreen",header,_toggle_fullscreen)
 fullscreen_button.tooltip_text = "Toggle fullscreen (F11). Your choice is saved."
 _button("Sound",header,func(): audio_dialog.popup_centered(Vector2i(500,240)))
 _build_audio_dialog()
 status = _label("Versus, practice and the race to 40 · v0.8",page,14,"8294ae")
 _space(page,12)
 body = HBoxContainer.new()
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 page.add_child(body)
 home = VBoxContainer.new()
 home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 home.add_theme_constant_override("separation",16)
 body.add_child(home)
 _space(home,75)
 _label("Your room.\nYour rhythm.",home,64,"ecf7f4")
 _label("Fast handling. Deliberate counterplay.\nOne screen or across the internet.",home,22,"95aac5")
 _space(home,22)
 var actions = HBoxContainer.new()
 home.add_child(actions)
 _button("Local match",actions,_local)
 _button("40-line sprint",actions,_sprint)
 _button("Host lobby",actions,_host)
 _space(home,16)
 var join_row = HBoxContainer.new()
 home.add_child(join_row)
 address_field = LineEdit.new()
 address_field.placeholder_text = "Host IP address"
 address_field.custom_minimum_size.x = 320
 join_row.add_child(address_field)
 port_field = SpinBox.new()
 port_field.min_value = 1024
 port_field.max_value = 65535
 port_field.value = 42970
 port_field.custom_minimum_size.x = 130
 join_row.add_child(port_field)
 _button("Join lobby",join_row,_join)
 _label("Host on UDP 42970 · Direct internet connections may need port forwarding.\nNo account or subscription. Everyone joins as a spectator until they add a player.",home,13,"8294ae")
 lobby = HBoxContainer.new()
 lobby.add_theme_constant_override("separation",38)
 lobby.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_child(lobby)
 lobby.hide()
 var left = VBoxContainer.new()
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 left.add_theme_constant_override("separation",15)
 lobby.add_child(left)
 lobby_title = _label("THE LOBBY",left,30,"edf8f4")
 roster_note = _label("",left,15,"78d9c3")
 player_list = VBoxContainer.new()
 player_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
 player_list.add_theme_constant_override("separation",14)
 left.add_child(player_list)
 var row = HBoxContainer.new()
 left.add_child(row)
 start_button = _button("Start match",row,func(): room.begin())
 _button("Leave lobby",row,func(): room.close_session())
 var settings_scroll = ScrollContainer.new()
 settings_scroll.custom_minimum_size.x = 458
 settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 lobby.add_child(settings_scroll)
 var right = VBoxContainer.new()
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 right.add_theme_constant_override("separation",13)
 settings_scroll.add_child(right)
 _label("ADD A LOCAL PLAYER",right,17,"edf8f4")
 name_field = LineEdit.new()
 name_field.placeholder_text = "Player name"
 name_field.text = "Player"
 right.add_child(name_field)
 devices = OptionButton.new()
 devices.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 right.add_child(devices)
 devices.item_selected.connect(func(_i): _load_lobby_handling())
 _button("Rebind each key / button",right,_open_settings)
 lobby_handling = HandlingControls.new()
 right.add_child(lobby_handling)
 das_field = lobby_handling.das
 arr_field = lobby_handling.arr
 lobby_handling.changed.connect(_lobby_handling_changed)
 var presets = HBoxContainer.new()
 right.add_child(presets)
 _button("Baseline · 5",presets,func(): das_field.value=5;arr_field.value=5)
 _button("Fastest · 10",presets,func(): das_field.value=10;arr_field.value=10)
 add_button = _button("Add / update player",right,_add_player)
 player_help = _label("Each keyboard layout or controller owns one board.\nLeave your slots empty to host and watch.",right,13,"8294ae")
 _space(right,7)
 rule_panel = VBoxContainer.new()
 rule_panel.add_theme_constant_override("separation",10)
 right.add_child(rule_panel)
 _label("MATCH RULES · HOST",rule_panel,17,"edf8f4")
 garbage_field = _spin(rule_panel,"Garbage warning",250,3000,1000)
 _label("Line-clear delay",rule_panel,14)
 clear_field = OptionButton.new()
 clear_field.add_item("Quick · 120 ms",120)
 clear_field.add_item("Instant · 0 ms",0)
 clear_field.add_item("Classic · varies with clear size",9999)
 clear_field.add_item("Custom pace · 250 ms",250)
 rule_panel.add_child(clear_field)
 sprint_help = _label("40 lines. Your fastest time.\nNo garbage. Instant clear and entry.\nRestart button retries. Personal best saves locally.",right,15,"78d9c3")
 sprint_help.hide()
 garbage_field.value_changed.connect(func(_v): _apply_rules())
 clear_field.item_selected.connect(func(_i): _apply_rules())
 rules_help = _label("",right,13,"8294ae")
 play_panel = VBoxContainer.new()
 play_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 play_panel.add_theme_constant_override("separation",14)
 body.add_child(play_panel)
 play_panel.hide()
 var match_header = HBoxContainer.new()
 play_panel.add_child(match_header)
 play_top = _label("",match_header,21,"dff5ec")
 play_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 end_button = _button("End round",match_header,func(): _restart_sprint() if session_kind == "sprint" and disconnected_inputs.is_empty() else room.back_to_lobby())
 _button("Leave room",match_header,func(): room.close_session())
 game_row = HBoxContainer.new()
 game_row.alignment = BoxContainer.ALIGNMENT_CENTER
 game_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
 game_row.add_theme_constant_override("separation",22)
 play_panel.add_child(game_row)
 result_buttons = HBoxContainer.new()
 play_panel.add_child(result_buttons)
 retry_button = _button("Retry sprint",result_buttons,_restart_sprint)
 back_button = _button("Back to lobby",result_buttons,func(): room.back_to_lobby())
 _button("Leave",result_buttons,func(): room.close_session())
 result_buttons.hide()
 settings_page = SettingsPage.new()
 settings_page.settings = input_settings
 settings_page.config = config
 settings_page.profiles_saved.connect(_settings_saved)
 settings_page.canceled.connect(_return_from_settings)
 settings_page.display_mode_requested.connect(func(enabled): _set_fullscreen(enabled))
 settings_page.shortcut_requested.connect(_create_desktop_shortcut)
 body.add_child(settings_page)
 settings_page.hide()
 var footer = _label("Settings: bind each key, button, trigger or stick  ·  Soft drop: slider below ARR  ·  F11 fullscreen",page,12,"8294ae")
 footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_audio_dialog():
 audio_dialog = AcceptDialog.new()
 audio_dialog.title = "Downstack · Sound"
 add_child(audio_dialog)
 audio_dialog.visibility_changed.connect(_sync_input_guard)
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation",16)
 audio_dialog.add_child(column)
 for option in [["Sound effects","sfx",0.65],["Music","music",0.22]]:
  var row = HBoxContainer.new()
  column.add_child(row)
  var label_value = _label(option[0],row,16)
  label_value.custom_minimum_size.x = 130
  var slider = HSlider.new()
  slider.max_value = 100
  slider.step = 1
  slider.value = float(config.get_value("audio",option[1],option[2]))*100
  slider.custom_minimum_size.x = 230
  slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(slider)
  var amount = _label("%d%%"%int(slider.value),row,16,"78d9c3")
  amount.custom_minimum_size.x = 48
  slider.value_changed.connect(func(v):
   amount.text = "%d%%"%int(v)
   config.set_value("audio",option[1],v/100.0)
   config.save("user://preferences.cfg")
   sound.set_levels(float(config.get_value("audio","sfx",0.65)),float(config.get_value("audio","music",0.22))))
 _label("Set either slider to 0 to mute it.",column,14,"8294ae")

func _device_list():
 if not is_instance_valid(devices): return
 var selected = devices.get_selected_id() if devices.item_count else -1
 devices.clear()
 devices.add_item("Keyboard 1",101)
 devices.set_item_metadata(0,-1)
 devices.add_item("Keyboard 2",102)
 devices.set_item_metadata(1,-2)
 for d in Input.get_connected_joypads():
  devices.add_item("Controller %d · %s"%[d+1,Input.get_joy_name(d)],d)
  devices.set_item_metadata(devices.item_count-1,d)
 for i in devices.item_count:
  if devices.get_item_id(i) == selected: devices.select(i)
 _load_lobby_handling()

func _open_settings():
 if mode in ["game","settings"]: return
 var device = int(devices.get_item_metadata(devices.selected)) if devices.selected >= 0 else -1
 settings_return_mode = mode
 settings_return_status = status.text
 mode = "settings"
 home.hide()
 lobby.hide()
 play_panel.hide()
 settings_button.disabled = true
 status.text = "Set up your controls · Saved separately for each input profile"
 settings_page.open_for(device)

func _return_from_settings():
 settings_page.close_page()
 mode = settings_return_mode
 settings_button.disabled = false
 home.visible = mode in ["home","connecting"]
 lobby.visible = mode == "lobby"
 status.text = settings_return_status
 if mode == "lobby": _refresh_lobby()
 _load_lobby_handling()

func _load_lobby_handling():
 if not is_instance_valid(lobby_handling) or devices.selected < 0: return
 lobby_handling.set_values(input_settings.profile(int(devices.get_item_metadata(devices.selected))))

func _lobby_handling_changed(values: Dictionary):
 if devices.selected < 0: return
 var device = int(devices.get_item_metadata(devices.selected))
 var profile = input_settings.profile(device)
 for key in values: profile[key] = values[key]
 var updates = {input_settings.profile_key(device):profile}
 var error = input_settings.commit(config,updates)
 if error != OK:
  _load_lobby_handling()
  status.text = "Could not save handling: "+error_string(error)
  return
 _sync_player_profiles()

func _sync_player_profiles():
 if mode != "lobby": return
 for p in room.roster.duplicate():
  if p.owner == room.local_id():
   var profile = input_settings.profile(p.device)
   room.change_player(p.device,p.name,p.input,Handling.das_ms(profile.das_level),Handling.arr_ms(profile.arr_level),false,profile.soft_drop)

func _settings_saved():
 _return_from_settings()
 _sync_player_profiles()
 status.text = "Bindings and handling saved for your next round."

func _local():
 if mode == "connecting": room.close_session()
 session_kind = "versus"
 room.rules.mode = "versus"
 room.rules.entry_ms = 100.0
 mode = "lobby"
 room.make_local()
 _apply_rules()
 status.text = "Local room · All players on this computer"

func _sprint():
 if mode == "connecting": room.close_session()
 session_kind = "sprint"
 room.rules.mode = "sprint"
 room.rules.clear_ms = 0.0
 room.rules.entry_ms = 0.0
 mode = "lobby"
 room.make_local()
 status.text = "40-line sprint · Countdown, then clear 40 as fast as you can"

func _host():
 if mode == "connecting": room.close_session()
 session_kind = "versus"
 room.rules.mode = "versus"
 room.rules.entry_ms = 100.0
 port = int(port_field.value)
 var err = room.host(port)
 if err != OK:
  status.text = "Could not host on port %d (%s)."%[port,error_string(err)]
  return
 mode = "lobby"
 _apply_rules()
 _refresh_lobby()
 var addresses = []
 for a in IP.get_local_addresses():
  if ":" not in a and a != "127.0.0.1": addresses.append(a)
 status.text = "Hosting · UDP %d · LAN %s"%[port,", ".join(addresses)]

func _join():
 if mode == "connecting": room.close_session()
 session_kind = "versus"
 if address_field.text.strip_edges().is_empty():
  status.text = "Enter the host’s address first."
  return
 var err = room.join(address_field.text.strip_edges(),int(port_field.value))
 if err != OK: status.text = "Connection could not start: "+error_string(err)
 else:
  mode = "connecting"
  status.text = "Connecting to host…"

func _apply_rules():
 if not room.hosting or mode != "lobby" or session_kind == "sprint": return
 var clear_ms = clear_field.get_selected_id()
 if clear_ms == 9999: clear_ms = -1
 room.set_rules(clear_ms,garbage_field.value)

func _add_player():
 if devices.selected < 0: return
 var device = int(devices.get_item_metadata(devices.selected))
 var profile = input_settings.profile(device)
 profile.merge(lobby_handling.values(),true)
 var error = input_settings.commit(config,{input_settings.profile_key(device):profile})
 if error != OK:
  status.text = "Could not save player settings: "+error_string(error)
  return
 if session_kind == "sprint":
  for old in room.roster.duplicate():
   if old.device != device: room.change_player(old.device,"","",old.das,old.arr,true)
 room.change_player(device,name_field.text,devices.get_item_text(devices.selected),Handling.das_ms(int(das_field.value)),Handling.arr_ms(int(arr_field.value)),false,input_settings.profile(device).soft_drop)
 config.set_value("handling","das_level",int(das_field.value))
 config.set_value("handling","arr_level",int(arr_field.value))
 config.set_value("player","name",name_field.text)
 config.save("user://preferences.cfg")

func _refresh_lobby():
 if mode == "home" and not room.hosting: return
 if room.running: return
 if mode == "settings": settings_return_mode = "lobby"
 else: mode = "lobby"
 settings_button.disabled = mode == "settings"
 settings_button.tooltip_text = ""
 home.hide()
 play_panel.hide()
 lobby.visible = mode == "lobby"
 var mine = room.roster.filter(func(p): return p.owner == room.local_id()).size()
 var sprint = session_kind == "sprint"
 lobby_title.text = "40-LINE SPRINT" if sprint else "THE LOBBY"
 player_help.text = "Select your input device and handling, then add a player.\nOne player. Restart using your assigned button." if sprint else "Each keyboard layout or controller owns one board.\nLeave your slots empty to host and watch."
 roster_note.text = "%d / 4 players · %d connected screen%s · You: %s"%[room.roster.size(),room.screens,"s" if room.screens!=1 else "","spectator" if mine == 0 else str(mine)+" player(s)"]
 if sprint:
  var best = float(config.get_value("sprint","best_ms",0.0))
  roster_note.text = "PERSONAL BEST  ·  "+(Handling.time_text(best) if best > 0 else "Set your first time")
 for c in player_list.get_children():
  player_list.remove_child(c)
  c.queue_free()
 for i in (1 if sprint else 4):
  var panel = PanelContainer.new()
  panel.add_theme_stylebox_override("panel",_style("101c2c"))
  panel.custom_minimum_size.y = 91
  player_list.add_child(panel)
  var row = HBoxContainer.new()
  panel.add_child(row)
  var column = VBoxContainer.new()
  column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(column)
  if i < room.roster.size():
   var p = room.roster[i]
   _label("%02d   %s"%[i+1,p.name],column,21,"e1f2ed")
   _label("%s · %s · DAS %d / ARR %d"%["LOCAL" if p.owner == room.local_id() else "REMOTE",p.input,Handling.level_for_ms("das",p.das),Handling.level_for_ms("arr",p.arr)],column,12,"91a5bd")
   _label("Soft drop: "+InputSettings.soft_text(p.get("soft_drop",-1.0)),column,12,"78d9c3")
   if p.owner == room.local_id():
    _button("Remove",row,func(): room.change_player(p.device,"","",p.das,p.arr,true))
  else:
   _label("%02d   Open slot"%[i+1],column,21,"657c98")
   _label("A local or remote player can join",column,12,"657c98")
 start_button.visible = room.hosting
 start_button.disabled = room.roster.is_empty()
 start_button.text = "Start practice" if room.roster.size() == 1 else "Start match"
 if sprint: start_button.text = "Start 40-line sprint"
 rule_panel.visible = room.hosting and not sprint
 sprint_help.visible = sprint
 rules_help.text = "SRS · 7-bag · hold · ghost · five-piece preview" if sprint else "SRS · 7-bag · hold · T-spins · combos · back-to-back\nGarbage rises on a non-clearing lock after its warning.\nWith 3–4 players, attacks rotate between opponents."
 if not room.hosting and mode != "settings":
  status.text = "Connected · Garbage warning %.0f ms · Clear delay %s"%[room.rules.garbage_ms,"classic" if room.rules.clear_ms < 0 else "%.0f ms"%room.rules.clear_ms]

func _start_game(seed_value: int):
 mode = "game"
 settings_page.close_page()
 settings_button.disabled = true
 settings_button.tooltip_text = "Return to the lobby to change settings."
 status.text = "40-line sprint · Restart with your assigned button" if session_kind == "sprint" else "Local input · Player-hosted match"
 home.hide()
 lobby.hide()
 play_panel.show()
 result_buttons.hide()
 retry_button.visible = session_kind == "sprint"
 end_button.visible = room.hosting
 end_button.text = "Restart" if session_kind == "sprint" else "End round"
 models.clear()
 views.clear()
 local_profiles.clear()
 disconnected_inputs.clear()
 input_notice = ""
 input_settings.axis_latches.clear()
 for c in game_row.get_children():
  game_row.remove_child(c)
  c.queue_free()
 for p in room.roster:
  var model = Board.new(seed_value,{"das":p.das,"arr":p.arr,"soft_drop":p.get("soft_drop",-1.0)},room.rules)
  if p.owner == room.local_id():
   models[p.id] = model
   local_profiles[p.device] = input_settings.profile(p.device)
   if p.device >= 0 and not p.device in Input.get_connected_joypads(): disconnected_inputs[p.device] = true
  var view = BoardView.new()
  view.player = p
  view.own = p.owner == room.local_id()
  view.data = model.snapshot()
  view.custom_minimum_size.x = 320 if room.roster.size() == 4 else (410 if room.roster.size() == 3 else 490)
  view.size_flags_vertical = Control.SIZE_EXPAND_FILL
  game_row.add_child(view)
  views[p.id] = view
 countdown = 3.0
 input_stream.configure(input_settings,local_profiles)
 _sync_input_guard()
 restart_held = false
 for device in local_profiles:
  if input_settings.mask(local_profiles[device],device) & InputSettings.RESTART: restart_held = true
 sound.play("tick")
 send_clock = 0
 var focus = get_viewport().gui_get_focus_owner()
 if focus: focus.release_focus()

func _round_finished(winner_id: String):
 end_button.hide()
 var winner = "DRAW" if room.roster.size() > 1 else "PRACTICE COMPLETE"
 for p in room.roster:
  if p.id == winner_id: winner = p.name.to_upper()+" WINS"
 play_top.text = winner
 sound.play("win" if not winner_id.is_empty() else "lose")
 result_buttons.show()
 retry_button.hide()
 back_button.visible = room.hosting

func _restart_sprint():
 if session_kind != "sprint" or room.roster.is_empty(): return
 room.running = false
 room.begin()

func _finish_sprint(board):
 room.running = false
 var time_value = Handling.time_text(board.elapsed)
 var best = float(config.get_value("sprint","best_ms",0.0))
 var record = board.completed and (best <= 0 or board.elapsed < best)
 if record:
  config.set_value("sprint","best_ms",board.elapsed)
  config.set_value("sprint","best_pieces",board.pieces)
  config.save("user://preferences.cfg")
 play_top.text = ("NEW BEST" if record else "40 LINES CLEARED")+"  ·  "+time_value if board.completed else "TOPPED OUT  ·  %d / 40  ·  %s"%[board.lines,time_value]
 status.text = "SPRINT RESULT  ·  %d pieces  ·  %.2f pieces/sec  ·  Retry with your restart button"%[board.pieces,board.pieces/maxf(board.elapsed/1000.0,0.001)]
 sound.play("win" if board.completed else "lose")
 result_buttons.show()
 retry_button.show()
 back_button.show()

func _closed(message: String):
 settings_page.close_page()
 mode = "home"
 settings_button.disabled = false
 settings_button.tooltip_text = ""
 home.show()
 lobby.hide()
 play_panel.hide()
 models.clear()
 views.clear()
 local_profiles.clear()
 input_stream.devices.clear()
 disconnected_inputs.clear()
 input_notice = ""
 status.text = message if not message.is_empty() else "Versus, practice and the race to 40 · v0.8"

func _garbage(id: String,amount: int,hole: int,packet_id: int):
 if models.has(id):
  models[id].receive_garbage(amount,hole,packet_id)
  sound.play("warning")

func _mask(device: int) -> int:
 _sync_input_guard()
 return input_stream.peek(device)

func _input(event: InputEvent):
 if mode != "game": return
 _sync_input_guard()
 input_stream.feed(event)

func _window_focus_changed(focused: bool):
 window_focused = focused
 _sync_input_guard()

func _controller_connection_changed(device: int, connected: bool):
 if mode == "game" and local_profiles.has(device) and not connected:
  # Runtime IDs may be reused by a different pad. Reassignment belongs in the
  # lobby; reconnecting must never give a new device a live board implicitly.
  disconnected_inputs[device] = true
  _sync_input_guard()
 _device_list()

func _sync_input_guard():
 if mode != "game" or not is_instance_valid(audio_dialog) or not is_instance_valid(settings_page): return
 var blocked = not window_focused or audio_dialog.visible or settings_page.visible
 var pause_local = not room.online and (blocked or not disconnected_inputs.is_empty())
 for device in local_profiles:
  var enabled = not blocked and not pause_local and not disconnected_inputs.has(device)
  if input_stream.set_enabled(device,enabled):
   for p in room.roster:
    if p.device == device and models.has(p.id): models[p.id].reset_input()
 var notice = ""
 if not disconnected_inputs.is_empty():
  notice = "Controller disconnected · Return to lobby to reassign it." if room.hosting else "Controller disconnected · Leave and rejoin to reassign it."
  if room.hosting: end_button.text = "Back to lobby"
 elif blocked:
  notice = "Paused · Return to the game and release held controls." if not room.online else "Input suspended · Online match continues."
 if notice != input_notice:
  if input_notice.is_empty(): status_before_input_notice = status.text
  status.text = notice if not notice.is_empty() else status_before_input_notice
  input_notice = notice

func _local_input_paused() -> bool:
 return not room.online and (not window_focused or audio_dialog.visible or settings_page.visible or not disconnected_inputs.is_empty())

func _toggle_fullscreen():
 _set_fullscreen(not fullscreen_enabled)

func _set_fullscreen(enabled: bool, persist: bool = true):
 var window = get_window()
 # Headless validation has no display; still exercise UI and persistence.
 if DisplayServer.get_name() != "headless":
  var already_fullscreen = window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
  if enabled and not already_fullscreen:
   windowed_mode = Window.MODE_MAXIMIZED if window.mode == Window.MODE_MAXIMIZED else Window.MODE_WINDOWED
   windowed_size = window.size
   windowed_position = window.position
   window.mode = Window.MODE_FULLSCREEN
  elif not enabled and already_fullscreen:
   window.mode = Window.MODE_WINDOWED
   if windowed_mode == Window.MODE_MAXIMIZED:
    window.mode = Window.MODE_MAXIMIZED
   else:
    var screen = DisplayServer.screen_get_usable_rect(window.current_screen)
    window.size = windowed_size.min(screen.size)
    window.position = Vector2i(clampi(windowed_position.x,screen.position.x,maxi(screen.position.x,screen.end.x-window.size.x)),clampi(windowed_position.y,screen.position.y,maxi(screen.position.y,screen.end.y-window.size.y)))
 fullscreen_enabled = enabled
 fullscreen_button.text = "Windowed" if enabled else "Fullscreen"
 settings_page.set_display_mode(enabled)
 if persist:
  config.set_value("display","fullscreen",enabled)
  var error = config.save("user://preferences.cfg")
  if error != OK: status.text = "Display changed, but could not save preferences: "+error_string(error)

func _create_desktop_shortcut():
 var result = DesktopShortcut.create()
 settings_page.display_message.text = result.message

func _physics_process(dt: float):
 if mode != "game": return
 _sync_input_guard()
 var frames = {}
 for device in local_profiles: frames[device] = input_stream.take(device)
 if _local_input_paused(): return
 var restart_down = false
 var restart_pressed = false
 if session_kind == "sprint":
  for device in local_profiles:
   # Preserve complete restart taps too, including release/repress in one tick.
   var prior = restart_held
   for mask in frames[device].changes:
    if mask & InputSettings.RESTART and not prior: restart_pressed = true
    prior = bool(mask & InputSettings.RESTART)
   if frames[device].held & InputSettings.RESTART: restart_down = true
  restart_pressed = restart_pressed or (restart_down and not restart_held)
 restart_held = restart_down
 if restart_pressed:
  _restart_sprint()
  return
 if countdown > 0:
  var old_beat = ceili(countdown)
  countdown -= dt
  if countdown > 0 and ceili(countdown) < old_beat: sound.play("tick")
  play_top.text = ("HOSTING AS SPECTATOR" if models.is_empty() and room.hosting else ("SPECTATING" if models.is_empty() else "GET READY"))+"  ·  "+str(maxi(1,ceili(countdown)))
  if countdown <= 0:
   for device in local_profiles:
    input_stream.discard_actions(device,Board.CW | Board.CCW | Board.HARD | Board.HOLD | InputSettings.RESTART)
   sound.play("go")
   play_top.text = ("HOSTING AS SPECTATOR" if models.is_empty() and room.hosting else ("SPECTATING" if models.is_empty() else "MATCH LIVE"))+"  ·  GARBAGE WARNING %.0f ms"%room.rules.garbage_ms
  return
 if room.running:
  for p in room.roster:
   if not models.has(p.id): continue
   var frame = frames[p.device]
   var events = models[p.id].step(dt*1000,frame.held,frame.changes)
   for cue in models[p.id].sounds: sound.play(cue)
   views[p.id].data = models[p.id].snapshot()
   for e in events: room.attack(p.id,e.attack)
   if session_kind == "sprint":
    var board = models[p.id]
    play_top.text = "SPRINT  ·  %d / 40  ·  %s"%[mini(board.lines,40),Handling.time_text(board.elapsed)]
    if board.completed or not board.alive:
     _finish_sprint(board)
     return
  send_clock += dt
  if send_clock >= 0.05:
   send_clock = 0
   for id in models: room.post_state(id,models[id].snapshot())
 for id in views:
  if not models.has(id) and room.states.get(id,{}).has("grid"): views[id].data = room.states[id]

func _showcase():
 _local()
 room.change_player(-1,"Jacob","Keyboard 1",83.3333,16.6667)
 room.change_player(-2,"Guest","Keyboard 2",166.6667,33.3333)
 room.change_player(0,"Rival","Controller 1",100.0,20.0)
 room.change_player(1,"Rival 2","Controller 2",150.0,25.0)
 room.begin()
 countdown = 0
 room.running = false
 var n = 0
 for id in models:
  var board = models[id]
  for y in range(Board.H-6+n%2,Board.H):
   for x in 10:
    if x != 4 and x != 5: board.grid[y][x] = (x+y+n)%7+1
  board.pos.y = Board.VISIBLE_TOP+3+n
  board.lines = 20+n*8
  board.sent = 12+n*3
  if n == 1: board.receive_garbage(4,5,1)
  views[id].data = board.snapshot()
  n += 1
 play_top.text = "MATCH VIEW  ·  4 PLAYERS  ·  GARBAGE WARNING 1000 ms"
