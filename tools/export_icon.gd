extends SceneTree

# PNG-backed Windows ICO, generated from the same app icon used by the game.
func _initialize():
 var args = OS.get_cmdline_user_args()
 if args.size() != 1:
  printerr("Expected one destination ICO path")
  quit(1)
  return
 var source = preload("res://assets/icon.png").get_image()
 if source == null:
  quit(1)
  return
 var sizes = [16, 24, 32, 48, 64, 128, 256]
 var images = []
 for size in sizes:
  var scaled = source.duplicate()
  scaled.resize(size, size, Image.INTERPOLATE_LANCZOS)
  images.append(scaled.save_png_to_buffer())
 var output = FileAccess.open(args[0], FileAccess.WRITE)
 if output == null:
  quit(1)
  return
 output.store_16(0)
 output.store_16(1)
 output.store_16(sizes.size())
 var offset = 6 + sizes.size() * 16
 for i in sizes.size():
  output.store_8(sizes[i] % 256)
  output.store_8(sizes[i] % 256)
  output.store_8(0)
  output.store_8(0)
  output.store_16(1)
  output.store_16(32)
  output.store_32(images[i].size())
  output.store_32(offset)
  offset += images[i].size()
 for data in images:
  output.store_buffer(data)
 output.close()
 quit()
