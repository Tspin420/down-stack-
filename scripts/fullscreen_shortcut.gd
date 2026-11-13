extends Node

signal toggle_requested

# Added after the UI so the reserved key is handled before binding capture.
# Popup Windows have their own input path, so register those separately.
func watch_windows(node: Node):
 for child in node.get_children(true):
  if child is Window:
   child.window_input.connect(func(event): handle_event(event,child))
  watch_windows(child)

func _input(event: InputEvent):
 handle_event(event,get_viewport())

func handle_event(event: InputEvent, viewport: Viewport):
 if not event is InputEventKey: return
 if event.keycode != KEY_F11 and event.physical_keycode != KEY_F11: return
 viewport.set_input_as_handled()
 if event.pressed and not event.echo: toggle_requested.emit()
