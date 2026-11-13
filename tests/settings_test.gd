extends SceneTree

const Main = preload("res://scripts/main.gd")
const Settings = preload("res://scripts/input_settings.gd")
const Handling = preload("res://scripts/handling.gd")
var checks = 0
var failures = 0

func check(value: bool,message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func send_key(code: int,down: bool = true):
 var event = InputEventKey.new()
 event.pressed = down
 event.keycode = code
 event.physical_keycode = code
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func _initialize(): run.call_deferred()

func run():
 var legacy = ConfigFile.new()
 legacy.set_value("handling","das_level",8)
 legacy.set_value("handling","arr_level",9)
 var old_profile = Settings.defaults(-1)
 old_profile.erase("das_level")
 old_profile.erase("arr_level")
 old_profile.bindings[3][0] = Settings.key_binding(KEY_T)
 old_profile.soft_drop = 10.0
 legacy.set_value("input_profiles","keyboard_1",old_profile)
 var upgraded = Settings.new(legacy)
 check(upgraded.profile(-1).das_level == 8 and upgraded.profile(-1).arr_level == 9,"old global handling survives migration")
 check(upgraded.profile(-1).bindings[3][0].code == KEY_T and upgraded.profile(-1).soft_drop == 10.0,"old bindings and soft drop survive migration")
 var app = Main.new()
 root.add_child(app)
 app.set_physics_process(false)
 app.config = ConfigFile.new()
 app.config.set_value("audio","music",0.23)
 app.config.set_value("sprint","best_ms",43210.0)
 app.input_settings = Settings.new(app.config)
 var page = app.settings_page
 page.settings = app.input_settings
 page.config = app.config
 app._load_lobby_handling()
 app._open_settings()
 check(app.mode == "settings" and page.visible and not app.home.visible and not app.lobby.visible,"Settings is a dedicated page from home")
 check(page.rows.size() == 8 and page.rows[0].size() == 2,"every action has primary and alternate inputs")
 check(page.rows[0][0].text.begins_with("Change") and page.rows[0][1].text == "+ Bind input","individual bindings visibly invite editing")
 var handling = page.handling
 check(handling.soft.get_parent().get_index() == handling.arr.get_parent().get_index()+1,"soft drop is immediately below ARR on Settings")
 check(app.lobby_handling.soft.get_parent().get_index() == app.arr_field.get_parent().get_index()+1,"soft drop is immediately below ARR in the lobby")
 check(handling.gravity_default.button_pressed and handling.soft_value.text == "20×","default gravity mode is labeled")
 page.rows[3][0].pressed.emit()
 check(page.capture_action == 3 and page.apply_button.disabled,"binding click starts capture and disables Apply")
 send_key(KEY_T)
 send_key(KEY_T,false)
 check(page._draft().bindings[3][0].code == KEY_T and page.capture_action == -1,"page receives keyboard events for individual remapping")
 handling.soft.value = 2
 check(page._draft().soft_drop == 10 and not handling.gravity_default.button_pressed,"moving slider chooses fixed soft drop")
 page.handling.das.value = 10
 page._select_device(-2)
 check(page._draft().bindings[3][0].code == KEY_K and page._draft().soft_drop == -1,"second profile is independent")
 page.handling.instant_soft.button_pressed = true
 check(page._draft().soft_drop == 0 and page.handling.soft_value.text == "Instant","explicit toggle selects Instant")
 check(not page.handling.soft.editable,"Instant mode clearly disables the finite-speed slider")
 page.handling.instant_soft.button_pressed = false
 page.handling.soft.value = page.handling.soft.max_value
 check(page._draft().soft_drop == 120 and not page.handling.instant_soft.button_pressed,"maximum slider value stays finite and cannot enable Instant")
 page.handling.instant_soft.button_pressed = true
 page._select_device(-1)
 check(page._draft().bindings[3][0].code == KEY_T and page.handling.soft.value == 2,"switching profiles retains pending edits")
 page.cancel_button.pressed.emit()
 check(app.mode == "home" and app.home.visible and not page.visible,"Cancel returns to home")
 check(app.input_settings.profile(-1).bindings[3][0].code == KEY_X and app.input_settings.profile(-2).soft_drop == -1,"Cancel discards edits for all profiles")
 app._sprint()
 app._add_player()
 check(app.input_settings.profiles.has("keyboard_1") and app.input_settings.profiles.keyboard_1.das_level == 5,"adding a player saves even unmodified profile handling")
 app._open_settings()
 page._begin_capture(3,1)
 send_key(KEY_ESCAPE)
 send_key(KEY_ESCAPE,false)
 check(page.visible and page.capture_action == -1,"Escape cancels capture while keeping Settings open")
 page.handling.das.value = 10
 page.handling.arr.value = 8
 page.handling.soft.value = 1
 page._begin_capture(3,1)
 send_key(KEY_T)
 send_key(KEY_T,false)
 app._refresh_lobby()
 check(app.mode == "settings" and not app.lobby.visible and page._draft().bindings[3][1].code == KEY_T,"roster update does not dismiss Settings or lose edits")
 page.apply_button.pressed.emit()
 check(app.mode == "lobby" and app.lobby.visible and not page.visible,"Apply returns to lobby")
 check(app.room.roster[0].soft_drop == 5 and is_equal_approx(app.room.roster[0].das,Handling.das_ms(10)),"Apply updates existing player handling")
 check(app.das_field.value == 10 and app.arr_field.value == 8 and app.lobby_handling.soft.value == 1,"lobby sliders reflect saved Settings values")
 var saved = ConfigFile.new()
 check(saved.load("user://preferences.cfg") == OK,"Settings writes preferences")
 var reloaded = Settings.new(saved).profile(-1)
 check(reloaded.bindings[3][1].code == KEY_T and reloaded.das_level == 10 and reloaded.arr_level == 8 and reloaded.soft_drop == 5,"relaunch restores bindings and all three handling values")
 check(saved.get_value("audio","music") == 0.23 and saved.get_value("sprint","best_ms") == 43210.0,"saving Settings retains sound and sprint record")
 app.lobby_handling.instant_soft.button_pressed = true
 check(app.room.roster[0].soft_drop == 0 and app.input_settings.profile(-1).soft_drop == 0,"lobby Instant toggle saves and updates existing player")
 app.devices.select(1)
 app.devices.item_selected.emit(1)
 check(app.lobby_handling.soft_value.text == "20×" and app.das_field.value == 5,"lobby device selection restores that profile's handling")
 app.lobby_handling.soft.value = 3
 check(app.input_settings.profile(-2).soft_drop == 15 and app.input_settings.profile(-1).soft_drop == 0,"lobby changes stay isolated by profile")
 app.devices.select(0)
 app.devices.item_selected.emit(0)
 app.lobby_handling.gravity_default.button_pressed = true
 check(app.room.roster[0].soft_drop == -1 and app.input_settings.profile(-1).soft_drop == -1,"default toggle restores 20x gravity")
 app._open_settings()
 page._reset_profile()
 check(page._draft().das_level == 5 and page._draft().arr_level == 5 and page._draft().soft_drop == -1 and page._draft().bindings[3][1].is_empty(),"Reset restores controls and handling in the draft")
 page._cancel()
 check(app.input_settings.profile(-1).das_level == 10 and app.input_settings.profile(-1).bindings[3][1].code == KEY_T,"Cancel also discards a pending reset")
 app._open_settings()
 page.handling.soft.value = 1
 page._begin_capture(5,0)
 app.room.begin()
 check(app.mode == "game" and not page.visible and page.capture_action == -1,"host-started round dismisses Settings and capture")
 check(app.models.values()[0].handling.soft_drop == -1,"host-started round uses saved settings, not pending edits")
 check(is_equal_approx(app.models.values()[0].handling.das,Handling.das_ms(10)),"saved per-profile DAS reaches the board")
 app.room.back_to_lobby()
 app._open_settings()
 app.room.close_session()
 check(app.mode == "home" and not page.visible and app.home.visible,"room closure while editing returns cleanly home")
 send_key(KEY_T)
 send_key(KEY_T,false)
 check(page.drafts.is_empty(),"hidden Settings does not capture input")
 await create_timer(0.12).timeout
 app.free()
 await create_timer(0.1).timeout
 print("SETTINGS TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
