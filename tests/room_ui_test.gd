extends SceneTree
const Main = preload("res://scripts/main.gd")
const Relay = preload("res://scripts/room_relay.gd")
var checks = 0
var failures = 0
var url = ""

func check(value: bool, message: String):
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)

func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--url="): url = arg.trim_prefix("--url=")
 run.call_deferred()

func wait_for(predicate: Callable):
 for i in 400:
  if predicate.call(): return
  await create_timer(0.01).timeout

func run():
 check(Relay.normalize_code(" abcd-efgh\r\n") == "ABCDEFGH", "pasted codes normalize")
 check(Relay.valid_code("abcd-efgh"), "lowercase formatted code accepted")
 for invalid in ["", "ABC", "ABCD-0000", "ABCD-IIII", "ABCDEFGHJK"]:
  check(not Relay.valid_code(invalid), "invalid code rejected: "+invalid)
 check(Relay.valid_url("wss://rooms.example.com/rooms"), "secure production service allowed")
 check(Relay.valid_url(url), "loopback testing allowed")
 for invalid in ["", "http://example.com/rooms", "ws://example.com/rooms", "wss:///rooms", "wss://user:pass@example.com/rooms", "wss://example.com/rooms?token=abc"]:
  check(not Relay.valid_url(invalid), "unsafe or malformed endpoint rejected")
 OS.set_environment("DOWNSTACK_RELAY_URL", "")
 var app = Main.new()
 root.add_child(app)
 check(app.online_create_button.disabled and app.online_join_button.disabled, "unconfigured build never pretends rooms are live")
 check("aren't available" in app.online_help.text, "unconfigured state explained")
 app.free()
 OS.set_environment("DOWNSTACK_RELAY_URL", url)
 app = Main.new()
 root.add_child(app)
 check(not app.online_create_button.disabled, "configured build offers online rooms")
 app.code_field.text = "bad"
 app._online_room(false)
 check(app.mode == "home" and "eight-character" in app.status.text, "invalid join stays on menu")
 app.clear_field.select(2)
 app.garbage_field.value = 1300
 app._online_room(true)
 check(app.mode == "connecting" and app.online_cancel_button.visible, "connection can be cancelled")
 await wait_for(func(): return app.mode == "lobby")
 check(app.mode == "lobby" and app.room.hosting and not app.room.room_code.is_empty(), "create opens a real coded lobby")
 check(app.code_box.visible and app.room.room_code in app.code_label.text, "room code displayed")
 check(not app.online_cancel_button.visible, "connection controls reset after success")
 check(app.room.rules.garbage_ms == 1300, "host rules carried into online room")
 app.name_field.text = "Room UI test"
 app._add_player()
 check(app.room.roster.size() == 1 and app.room.roster[0].owner == 1, "host can add own player")
 var first_code = app.room.room_code
 app.room.close_session()
 check(app.mode == "home" and not app.code_box.visible and app.room.room_code.is_empty(), "leave clears code and returns home")
 app.code_field.text = "ZZZZ-ZZZZ"
 app._online_room(false)
 await wait_for(func(): return app.mode == "home")
 check(app.mode == "home" and "Room not found" in app.status.text, "missing room error arrives without hanging or retrying")
 app._online_room(true)
 app.room.close_session()
 await create_timer(0.1).timeout
 check(app.mode == "home" and not app.room.online, "cancel stops pending connection")
 app._online_room(true)
 await wait_for(func(): return app.mode == "lobby")
 check(app.mode == "lobby" and app.room.room_code != first_code, "new room after cancel gets a fresh code")
 app.room.close_session()
 app.free()
 await create_timer(0.05).timeout
 print("ROOM UI TESTS: %d checks, %d failures"%[checks, failures])
 quit(1 if failures else 0)
