extends VBoxContainer

const Settings = preload("res://scripts/input_settings.gd")
const FIXED_RATES = [5.0,10.0,15.0,20.0,30.0,45.0,60.0,90.0,120.0]
signal changed(values: Dictionary)
var das: HSlider
var arr: HSlider
var soft: HSlider
var soft_value: Label
var instant_soft: CheckButton
var reset_button: Button
var default_soft = true

func _ready():
 add_theme_constant_override("separation",10)
 das = _slider("DAS speed",5)
 arr = _slider("ARR speed",5)
 soft = _slider("Soft drop",4)
 soft_value = soft.get_parent().get_child(2)
 soft.max_value = FIXED_RATES.size()
 soft.tick_count = FIXED_RATES.size()
 soft.ticks_on_borders = true
 soft.tooltip_text = "5, 10, 15, 20, 30, 45, 60, 90 or 120 cells/sec. Instant is a separate option."
 instant_soft = CheckButton.new()
 instant_soft.text = "Instant soft drop"
 instant_soft.focus_mode = Control.FOCUS_ALL
 instant_soft.tooltip_text = "Explicitly enable a non-locking drop to the floor. Hard drop is a separate action."
 add_child(instant_soft)
 var help = Label.new()
 help.text = "DAS / ARR: 1 = slow · 5 = baseline · 10 = 2×\nSoft drop: drag for 5–120 cells/sec"
 help.add_theme_font_size_override("font_size",12)
 help.add_theme_color_override("font_color",Color("9b93b5"))
 add_child(help)
 reset_button = Button.new()
 reset_button.text = "Reset handling"
 reset_button.custom_minimum_size.y = 44
 reset_button.tooltip_text = "Restore default DAS, ARR and soft drop for this input. Key bindings stay as they are."
 add_child(reset_button)
 reset_button.pressed.connect(func():
  set_values(Settings.defaults(-1))
  changed.emit(values()))
 das.value_changed.connect(func(_v): changed.emit(values()))
 arr.value_changed.connect(func(_v): changed.emit(values()))
 soft.value_changed.connect(func(_v):
  default_soft = false
  instant_soft.set_pressed_no_signal(false)
  _soft_label()
  changed.emit(values()))
 instant_soft.toggled.connect(func(on):
  if on: default_soft = false
  _soft_label()
  changed.emit(values()))
 set_values(Settings.defaults(-1))

func _slider(title: String,initial: int) -> HSlider:
 var row = HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 add_child(row)
 var label = Label.new()
 label.text = title
 label.add_theme_font_size_override("font_size",14)
 label.custom_minimum_size.x = 90
 row.add_child(label)
 var slider = HSlider.new()
 slider.min_value = 1
 slider.max_value = 10
 slider.step = 1
 slider.value = initial
 slider.custom_minimum_size = Vector2(170,34)
 slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 slider.focus_mode = Control.FOCUS_ALL
 row.add_child(slider)
 var number = Label.new()
 number.text = "%d / 10"%initial
 number.custom_minimum_size.x = 62
 number.add_theme_font_size_override("font_size",14)
 number.add_theme_color_override("font_color",Color("44ceff"))
 row.add_child(number)
 if title != "Soft drop": slider.value_changed.connect(func(v): number.text = "%d / 10"%int(v))
 return slider

func set_values(profile: Dictionary):
 das.set_value_no_signal(profile.get("das_level",5))
 arr.set_value_no_signal(profile.get("arr_level",5))
 das.get_parent().get_child(2).text = "%d / 10"%int(das.value)
 arr.get_parent().get_child(2).text = "%d / 10"%int(arr.value)
 var rate = float(profile.get("soft_drop",-1.0))
 default_soft = rate < 0
 instant_soft.set_pressed_no_signal(rate == 0)
 soft.set_value_no_signal(4 if rate <= 0 else FIXED_RATES.find(rate)+1)
 _soft_label()

func values() -> Dictionary:
 return {"das_level":int(das.value),"arr_level":int(arr.value),"soft_drop":0.0 if instant_soft.button_pressed else (-1.0 if default_soft else FIXED_RATES[int(soft.value)-1])}

func _soft_label():
 var rate = float(values().soft_drop)
 soft.editable = rate != 0
 soft.modulate.a = 0.45 if rate == 0 else 1.0
 soft_value.text = "Default" if rate < 0 else ("Instant" if rate == 0 else "%d / s"%int(rate))
 soft_value.tooltip_text = Settings.soft_text(rate)
