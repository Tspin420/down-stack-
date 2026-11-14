extends SceneTree

# Capture actual menu controls using the Compatibility renderer, not mockups.
var output = ""
var app

func _initialize():
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
 run.call_deferred()

func frame(filename: String):
 # Let nested containers and deferred focus settle before saving pixels.
 for i in 4: await process_frame
 await RenderingServer.frame_post_draw
 var result = root.get_texture().get_image().save_png(output.path_join(filename))
 if result != OK:
  printerr("Capture failed: "+error_string(result))
  quit(1)
 print("CAPTURE "+filename)

func run():
 if DisplayServer.get_name() == "headless" or output.is_empty():
  printerr("Needs a real display and --output=<directory>.")
  quit(1)
  return
 DirAccess.make_dir_recursive_absolute(output)
 root.size = Vector2i(1280,800)
 app = preload("res://main.tscn").instantiate()
 root.add_child(app)
 app.set_physics_process(false)
 app._set_fullscreen(false,false)
 app.sound.set_levels(0,0)
 app.config.set_value("sprint","best_ms",0.0)
 app._menu_state()
 await frame("Downstack_Main_Menu.png")
 app._network()
 await frame("Downstack_Network_Menu.png")
 app._local()
 app.name_field.text = "Jacob"
 app._add_player()
 app.devices.select(1)
 app.devices.item_selected.emit(1)
 app.name_field.text = "Player 2"
 app.das_field.value = 7
 app._add_player()
 app._edit_player(app.room.roster[0])
 app.start_button.grab_focus()
 await frame("Downstack_Local_Lobby.png")
 app._toggle_rules()
 app.rules_toggle.grab_focus()
 await frame("lobby_rules.png")
 app._open_settings()
 await frame("settings.png")
 app._return_from_settings()
 app.room.close_session()
 app._sprint()
 app._add_player()
 await frame("sprint_setup.png")
 app.room.close_session()
 root.size = Vector2i(960,600)
 await frame("main_960x600.png")
 app._local()
 app._add_player()
 await frame("lobby_960x600.png")
 app.room.close_session()
 root.size = Vector2i(1280,800)
 await frame("final_menu.png")
 app.free()
 app = null
 await create_timer(0.12).timeout
 print("MENU CAPTURE PASS")
 quit()
