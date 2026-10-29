extends CanvasLayer
## In-game menu (autoload "Pause"). ESC or P pauses any level:
## Resume · How to Play · Restart checkpoint · Main Menu · Quit.
## The same "How to Play" card is used by the title menu.

const CONTROLS := [
	["MOVE", "A / D  (or ← →)"],
	["RUN", "hold Shift"],
	["SNEAK / HIDE", "hold C  ·  crouch behind cars & cover"],
	["STAIRS", "W / S"],
	["INTERACT", "E   (some actions: HOLD E)"],
	["DIALOGUE", "Space / Enter  next line"],
	["CHOICES", "1 / 2 / 3  or click"],
	["AIM / SHOOT", "Mouse  ·  Left click (or Ctrl)"],
	["RELOAD", "R"],
	["BANDAGE", "H"],
	["THE SIX RULES", "TAB  or  N"],
	["MENU", "ESC  or  P"],
	["MUTE SOUND", "M   (volume: menu → Sound)"],
]
const TIPS := [
	"Noise brings them: gunshots, car alarms, running. Sneak when you can.",
	"Behind a wanderer that hasn't seen you? E = silent takedown.",
	"Your choices are remembered — people you help remember you too.",
]

var font_title: Font = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var font_semi: Font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var font_body: Font = preload("res://assets/fonts/Nunito.ttf")

var _root: Control
var _menu: VBoxContainer
var _help: Control
var _sound: Control
var _hint: Label
var _open := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		for k in [KEY_ESCAPE, KEY_P]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event("pause", ev)
	_hint = Label.new()
	_hint.text = "ESC · MENU    TAB · RULES    M · MUTE"
	_hint.add_theme_font_override("font", font_semi)
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	_hint.position = Vector2(1560, 1046)
	add_child(_hint)
	_root = Control.new()
	_root.size = Vector2(1920, 1080)
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.82)
	dim.size = Vector2(1920, 1080)
	_root.add_child(dim)
	var t := _label(_root, "PAUSED", font_title, 110, Color("f3eee6"), Vector2(0, 150))
	t.size = Vector2(1920, 130)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu = VBoxContainer.new()
	_menu.position = Vector2(760, 360)
	_menu.size = Vector2(400, 0)
	_menu.add_theme_constant_override("separation", 14)
	_root.add_child(_menu)
	make_button(_menu, "Resume", close)
	make_button(_menu, "How to Play", func(): _show_help(true))
	make_button(_menu, "Sound", func(): _show_sound(true))
	make_button(_menu, "Restart Checkpoint", func():
		close()
		Inputs.input_locked = false
		Game.retry())
	make_button(_menu, "Main Menu", func():
		close()
		Inputs.input_locked = false
		get_tree().change_scene_to_file("res://levels/menu.tscn"))
	if not OS.has_feature("web"):
		make_button(_menu, "Quit", func(): get_tree().quit())
	_help = build_help(func(): _show_help(false))
	_help.visible = false
	_root.add_child(_help)
	_sound = build_sound(func(): _show_sound(false))
	_sound.visible = false
	_root.add_child(_sound)


func _in_level() -> bool:
	var s := get_tree().current_scene
	return s != null and s is LevelBase


func _process(_dt: float) -> void:
	_hint.visible = _in_level() and not _open


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or event.is_echo():
		return
	if not _in_level():
		return
	if _open:
		if _help.visible:
			_show_help(false)
		elif _sound.visible:
			_show_sound(false)
		else:
			close()
	else:
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	_open = true
	get_tree().paused = true
	_root.visible = true
	_show_help(false)
	(_menu.get_child(0) as Button).grab_focus()


func close() -> void:
	get_viewport().gui_release_focus()
	_open = false
	get_tree().paused = false
	_root.visible = false


func _show_help(on: bool) -> void:
	_help.visible = on
	_sound.visible = false
	_menu.visible = not on


func _show_sound(on: bool) -> void:
	_sound.visible = on
	_help.visible = false
	_menu.visible = not on


## Volume sliders + mute (also used by the title menu).
func build_sound(on_back: Callable) -> Control:
	var c := Control.new()
	c.size = Vector2(1920, 1080)
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.08, 0.96)
	panel.position = Vector2(560, 240)
	panel.size = Vector2(800, 600)
	c.add_child(panel)
	_label(c, "SOUND", font_title, 64, Color("e9a640"), Vector2(620, 270))
	var y := 400.0
	for row in [["Master", "MASTER"], ["Music", "MUSIC"], ["Effects", "EFFECTS"]]:
		var bus: String = row[0]
		_label(c, row[1], font_semi, 32, Color("f3eee6"), Vector2(620, y - 6))
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.05
		sl.value = Audio.volumes[bus]
		sl.position = Vector2(840, y)
		sl.custom_minimum_size = Vector2(440, 36)
		sl.size = Vector2(440, 36)
		sl.value_changed.connect(func(v: float): Audio.set_volume(bus, v))
		c.add_child(sl)
		y += 90.0
	var mute := CheckButton.new()
	mute.text = "Mute all  (M)"
	mute.add_theme_font_override("font", font_semi)
	mute.add_theme_font_size_override("font_size", 30)
	mute.button_pressed = Audio.muted
	mute.position = Vector2(614, y - 10)
	mute.toggled.connect(func(on: bool): Audio.set_muted(on))
	c.add_child(mute)
	c.visibility_changed.connect(func(): if c.visible: mute.set_pressed_no_signal(Audio.muted))
	var box := VBoxContainer.new()
	box.position = Vector2(860, 750)
	box.size = Vector2(200, 0)
	c.add_child(box)
	make_button(box, "Back", on_back)
	return c


## Builds the "How to Play" card (also used by the title menu).
func build_help(on_back: Callable) -> Control:
	var c := Control.new()
	c.size = Vector2(1920, 1080)
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.05, 0.08, 0.96)
	panel.position = Vector2(360, 120)
	panel.size = Vector2(1200, 840)
	c.add_child(panel)
	var head := _label(c, "HOW TO PLAY", font_title, 64, Color("e9a640"), Vector2(420, 150))
	head.size = Vector2(1080, 80)
	var y := 250.0
	for row in CONTROLS:
		_label(c, row[0], font_semi, 30, Color("e9a640"), Vector2(440, y))
		_label(c, row[1], font_body, 28, Color("f3eee6"), Vector2(780, y + 2))
		y += 44.0
	y += 14.0
	for tip in TIPS:
		_label(c, "•  " + tip, font_body, 22, Color(1, 1, 1, 0.7), Vector2(440, y))
		y += 32.0
	var box := VBoxContainer.new()
	box.position = Vector2(860, 870)
	box.size = Vector2(200, 0)
	c.add_child(box)
	make_button(box, "Back", on_back)
	return c


func _label(parent: Node, t: String, f: Font, sz: int, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.position = pos
	parent.add_child(l)
	return l


func make_button(parent: Node, t: String, cb: Callable, sz := 34) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", font_semi)
	b.add_theme_font_size_override("font_size", sz)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.06, 0.09, 0.9) if st in ["normal", "disabled"] else Color(0.18, 0.13, 0.06, 0.95)
		sb.border_color = Color("e9a640", 0.3 if st in ["normal", "disabled"] else 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(26)
		sb.content_margin_left = 24
		sb.content_margin_right = 24
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
