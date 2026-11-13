extends SceneTree

const Main = preload("res://scripts/main.gd")
const DesktopLink = preload("res://scripts/desktop_shortcut.gd")
var checks = 0
var failures = 0

func check(value: bool, message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func key(code: int, down: bool = true, echo_key: bool = false):
 var event = InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = down
 event.echo = echo_key
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func _initialize(): run.call_deferred()

func run():
 var app = Main.new()
 root.add_child(app)
 app.set_physics_process(false)
 app.config.set_value("audio","music",0.17)
 app.config.set_value("sprint","best_ms",45678)
 app._set_fullscreen(false)
 check(not app.fullscreen_enabled and app.fullscreen_button.text == "Fullscreen","visible button offers fullscreen")
 app.fullscreen_button.pressed.emit()
 check(app.fullscreen_enabled and app.settings_page.display_mode.selected == 1,"header button switches display and Settings together")
 var disk = ConfigFile.new()
 check(disk.load("user://preferences.cfg") == OK and disk.get_value("display","fullscreen",false),"fullscreen choice persists to disk")
 check(disk.get_value("audio","music") == 0.17 and disk.get_value("sprint","best_ms") == 45678,"display saves preserve sound and records")
 key(KEY_F11)
 check(not app.fullscreen_enabled,"F11 exits fullscreen")
 for i in 5: key(KEY_F11,true,true)
 check(not app.fullscreen_enabled,"OS key repeat cannot repeatedly toggle fullscreen")
 key(KEY_F11,false)
 check(not app.fullscreen_enabled,"release does not toggle fullscreen")
 app._open_settings()
 var page = app.settings_page
 page._begin_capture(3,0)
 var before = page._draft().duplicate(true)
 key(KEY_F11)
 key(KEY_F11,false)
 check(app.fullscreen_enabled,"F11 works while a binding is being captured")
 check(page.capture_action == 3 and page._draft() == before,"fullscreen shortcut does not assign a key or cancel capture")
 key(KEY_T)
 key(KEY_T,false)
 check(page.capture_action == -1 and page._draft().bindings[3][0].code == KEY_T,"normal binding capture still works after fullscreen")
 page.display_mode.item_selected.emit(0)
 check(not app.fullscreen_enabled and app.fullscreen_button.text == "Fullscreen","Settings dropdown switches immediately")
 page.display_mode.item_selected.emit(1)
 page._cancel()
 check(app.fullscreen_enabled and app.config.get_value("display","fullscreen"),"Cancel controls retains explicitly immediate display setting")
 app.address_field.grab_focus()
 key(KEY_F11)
 key(KEY_F11,false)
 check(not app.fullscreen_enabled,"focused text field cannot swallow F11")
 var event = InputEventKey.new()
 event.keycode = KEY_F11
 event.pressed = true
 app.audio_dialog.window_input.emit(event)
 check(app.fullscreen_enabled,"Sound window forwards the reserved fullscreen key")
 event.echo = true
 app.audio_dialog.window_input.emit(event)
 check(app.fullscreen_enabled,"Sound window ignores OS repeats")
 event.echo = false
 page.display_mode.get_popup().window_input.emit(event)
 check(not app.fullscreen_enabled,"open dropdown forwards the fullscreen key")
 app._sprint()
 app._add_player()
 app.room.begin()
 app.countdown = 0
 var board = app.models.values()[0]
 var pieces = board.pieces
 key(KEY_F11)
 key(KEY_F11,false)
 var input = app.input_stream.take(-1)
 check(app.fullscreen_enabled and input.held == 0 and input.changes.is_empty(),"fullscreen does not become a gameplay input")
 check(board.pieces == pieces,"switching display does not drop or lock a piece")
 check(FileAccess.file_exists(DesktopLink.SCRIPT_PATH) and FileAccess.get_file_as_string(DesktopLink.SCRIPT_PATH).length() > 500,"shortcut script is available as a game resource")
 var tricky = "C:\\Games\\O'Brien & Sons ! 100% $tools [test]\\Downstack.exe"
 var command = DesktopLink.command_for(tricky)
 check(command.begins_with("$env:DOWNSTACK_SHORTCUT_TARGET='C:\\Games\\O''Brien & Sons ! 100% $tools [test]\\Downstack.exe';\n"),"spaces, apostrophes and shell characters stay inside a literal path")
 check(DesktopLink.powershell_literal("C:\\ゲーム\\Downstack.exe") == "'C:\\ゲーム\\Downstack.exe'","Unicode paths remain unchanged")
 check(not DesktopLink.available() and page.shortcut_button.disabled,"development editor cannot create a shortcut to the Godot editor")
 check(not DesktopLink.create().ok,"unavailable shortcut operation reports failure instead of success")
 await create_timer(0.12).timeout
 app.free()
 await create_timer(0.1).timeout
 app = Main.new()
 root.add_child(app)
 app.set_physics_process(false)
 check(app.fullscreen_enabled and app.settings_page.display_mode.selected == 1,"new launch restores fullscreen and both controls")
 check(app.config.get_value("audio","music") == 0.17,"startup preserves unrelated settings")
 app._set_fullscreen(false)
 await create_timer(0.12).timeout
 app.free()
 await create_timer(0.1).timeout
 print("DESKTOP TESTS: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
