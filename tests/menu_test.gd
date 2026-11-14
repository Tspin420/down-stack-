extends SceneTree

const Main = preload("res://scripts/main.gd")
var checks = 0
var failures = 0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func key(code: int,down: bool = true):
 var event = InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func pad(button: int,down: bool = true):
 var event = InputEventJoypadButton.new()
 event.button_index = button
 event.pressed = down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func settle():
 await process_frame
 await process_frame

func _initialize(): run.call_deferred()

func run():
 var app = Main.new()
 root.add_child(app)
 app.set_physics_process(false)
 await settle()
 check(app.mode == "home" and app.home.visible,"launch goes straight to Play")
 check(not app.lobby.visible and not app.network_page.visible and not app.play_panel.visible,"launch hides setup and network fields")
 check(root.gui_get_focus_owner() == app.menu_local,"launch focuses Local match")
 check(not app.menu_back.visible,"main menu has no dead-end Back button")
 key(KEY_DOWN)
 key(KEY_DOWN,false)
 check(root.gui_get_focus_owner() == app.menu_sprint,"arrow moves to Sprint")
 pad(JOY_BUTTON_DPAD_DOWN)
 pad(JOY_BUTTON_DPAD_DOWN,false)
 check(root.gui_get_focus_owner() == app.menu_network,"D-pad moves to Network play")
 pad(JOY_BUTTON_A)
 pad(JOY_BUTTON_A,false)
 await settle()
 check(app.mode == "network" and app.network_page.visible and not app.home.visible,"controller accept opens Network page")
 check(root.gui_get_focus_owner() == app.host_button,"Network page receives focus")
 app.address_field.text = "127.0.0.1"
 app._open_settings()
 check(not app.network_page.visible and app.settings_page.visible,"Settings replaces the Network page")
 pad(JOY_BUTTON_B)
 pad(JOY_BUTTON_B,false)
 await settle()
 check(app.mode == "network" and app.network_page.visible and app.address_field.text == "127.0.0.1","controller back returns from Settings without losing host address")
 app.address_field.text = " "
 app._join()
 check(app.mode == "network" and app.status.text.contains("address"),"empty address stays on Network page with useful feedback")
 app.address_field.text = "127.0.0.1"
 app.port_field.value = 49876
 app._join()
 await settle()
 check(app.mode == "connecting" and app.cancel_connect_button.visible,"connection exposes Cancel")
 check(app.host_button.disabled and app.join_button.disabled and not app.address_field.editable and not app.port_field.editable,"pending connection prevents conflicting host/join actions")
 check(root.gui_get_focus_owner() == app.cancel_connect_button,"connection gives focus to Cancel")
 pad(JOY_BUTTON_B)
 pad(JOY_BUTTON_B,false)
 await settle()
 check(app.mode == "network" and not app.room.online and not app.host_button.disabled and app.address_field.editable,"Back cancels the peer and restores connection controls")
 app._join()
 app.room.close_session("Could not reach host.")
 await settle()
 check(app.mode == "network" and app.status.text == "Could not reach host." and app.address_field.text == "127.0.0.1","failed connection keeps address and error on Network page")
 key(KEY_ESCAPE)
 key(KEY_ESCAPE,false)
 await settle()
 check(app.mode == "home" and root.gui_get_focus_owner() == app.menu_local,"Escape returns to Play with focus")
 key(KEY_ENTER)
 key(KEY_ENTER,false)
 await settle()
 check(app.mode == "lobby" and app.player_list.get_child_count() == 4 and app.player_list.columns == 2,"Enter opens a four-slot local lobby")
 check(app.start_button.visible and app.start_button.disabled,"empty local lobby cannot start")
 check(not app.rule_panel.visible and app.rules_toggle.visible,"host rules are initially collapsed")
 app.rules_toggle.pressed.emit()
 check(app.rule_panel.visible and app.rules_help.visible,"host can expand match rules")
 app.garbage_field.value = 1500
 check(app.room.rules.garbage_ms == 1500 and app.rule_panel.visible,"rules change propagates without collapsing editor")
 app.rules_toggle.pressed.emit()
 app.name_field.text = "First"
 app.add_button.pressed.emit()
 await settle()
 check(app.room.roster.size() == 1 and app.room.roster[0].name == "First","Join adds the selected input")
 check(app.start_button.text == "Start practice" and not app.start_button.disabled,"one-player lobby offers practice")
 check(app.add_button.text == "Update player" and root.gui_get_focus_owner() == app.start_button,"joined input offers Update and focuses Start")
 app._edit_player(app.room.roster[0])
 check(root.gui_get_focus_owner() == app.name_field and app.name_field.text == "First","Edit selects that player's name and input")
 app.name_field.text = "Renamed"
 app._add_player()
 check(app.room.roster.size() == 1 and app.room.roster[0].name == "Renamed","Update edits the existing slot")
 app.devices.select(1)
 app.devices.item_selected.emit(1)
 app.name_field.text = "Second"
 app.das_field.value = 7
 app._add_player()
 check(app.room.roster.size() == 2 and app.start_button.text == "Start match","second input produces a versus match")
 check(app.input_settings.profile(-1).das_level == 5 and app.input_settings.profile(-2).das_level == 7,"lobby handling remains independent per input")
 app._edit_player(app.room.roster[0])
 check(app.devices.selected == 0 and app.name_field.text == "Renamed" and app.das_field.value == 5,"Edit restores the correct player's handling")
 app._remove_player(app.room.roster[1])
 check(app.room.roster.size() == 1 and app.start_button.text == "Start practice","Remove updates roster and start mode")
 app.room._change(42,-1,"Remote","Keyboard 1",166.6667,33.3333,false,-1.0)
 app.room._change(43,-1,"Remote 2","Keyboard 1",166.6667,33.3333,false,-1.0)
 app.room._change(44,-1,"Remote 3","Keyboard 1",166.6667,33.3333,false,-1.0)
 app.devices.select(1)
 app.devices.item_selected.emit(1)
 check(app.add_button.disabled and app.add_button.text == "Lobby is full","full lobby blocks a fifth input")
 app._edit_player(app.room.roster[0])
 check(not app.add_button.disabled and app.add_button.text == "Update player","full lobby still permits editing an existing input")
 var remote_column = app.player_list.get_child(1).get_child(0)
 check(remote_column.get_children().all(func(c): return not c is HBoxContainer),"remote slot has no local Edit or Remove action")
 app.room.hosting = false
 app._refresh_lobby()
 check(not app.start_button.visible and not app.rules_toggle.visible and not app.rule_panel.visible,"client cannot change host rules or start")
 check(app.waiting_label.text.contains("Waiting for the host"),"client sees who starts the match")
 app.room.hosting = true
 app.room.close_session()
 await settle()
 check(app.mode == "home" and not app.lobby.visible,"leaving lobby returns to main menu")
 app._sprint()
 app._add_player()
 check(app.player_list.columns == 1 and app.player_list.get_child_count() == 1 and not app.rules_toggle.visible,"Sprint offers one player and hides versus rules")
 await settle()
 key(KEY_ENTER)
 key(KEY_ENTER,false)
 await settle()
 check(app.mode == "game" and app.play_panel.visible and not app.home.visible and not app.lobby.visible and not app.network_page.visible,"Start enters the board and hides every menu")
 check(root.gui_get_focus_owner() == null and app.fullscreen_button.focus_mode == Control.FOCUS_NONE and app.sound_button.focus_mode == Control.FOCUS_NONE,"gameplay releases focus and protects header buttons from hard drop")
 var board = app.models.values()[0]
 app.countdown = 0
 key(KEY_SPACE)
 key(KEY_SPACE,false)
 app._physics_process(1.0/120.0)
 check(board.pieces == 1 and app.mode == "game" and not app.audio_dialog.visible,"Space hard-drops without activating menu controls")
 app.config.set_value("sprint","best_ms",12345.0)
 app._finish_sprint(board)
 await settle()
 check(root.gui_get_focus_owner() == app.retry_button,"Sprint result offers a focused Retry")
 app.room.close_session()
 check(app.menu_best.text == app.Handling.time_text(12345.0),"returning home refreshes the personal best")
 app._set_fullscreen(false)
 await create_timer(0.12).timeout
 app.free()
 await create_timer(0.1).timeout
 print("MENU TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
