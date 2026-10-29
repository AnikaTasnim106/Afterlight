extends Control
## Title menu: New Game, Continue (from last checkpoint), Chapter Select.
## Env START_CHAPTER=s3 jumps straight in (testing).

var font_title: Font = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var font_semi: Font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var font_body: Font = preload("res://assets/fonts/Nunito.ttf")
var _box: VBoxContainer
var _chapters: GridContainer
var _help: Control
var _sound: Control
var _t := 0.0


func _ready() -> void:
	var start := OS.get_environment("START_CHAPTER")
	if start != "":
		Game.start_chapter.call_deferred(start)
		return
	size = Vector2(1920, 1080)
	var title := _label("AFTERLIGHT", font_title, 170, Color("f3eee6"), Vector2(0, 230))
	title.size = Vector2(1920, 200)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := _label("A STORY OF THE FIRST NIGHTS  ·  8 LEVELS", font_semi, 40, Color("e9a640"), Vector2(0, 420))
	sub.size = Vector2(1920, 50)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box = VBoxContainer.new()
	_box.position = Vector2(760, 540)
	_box.size = Vector2(400, 0)
	_box.add_theme_constant_override("separation", 14)
	add_child(_box)
	_button(_box, "New Game", func(): Game.start_chapter("s1"))
	var cont := _button(_box, "Continue", func(): Game.continue_game())
	cont.disabled = not Game.has_save()
	_button(_box, "Chapter Select", func(): _chapters.visible = not _chapters.visible)
	_button(_box, "How to Play", func(): _help.visible = true)
	_button(_box, "Sound", func(): _sound.visible = true)
	if not OS.has_feature("web"):
		_button(_box, "Quit", func(): get_tree().quit())
	# two columns so all 21 chapters fit on screen
	_chapters = GridContainer.new()
	_chapters.columns = 2
	_chapters.position = Vector2(1370, 150)
	_chapters.add_theme_constant_override("h_separation", 10)
	_chapters.add_theme_constant_override("v_separation", 8)
	_chapters.visible = false
	add_child(_chapters)
	for k in Game.ORDER:
		var ch: String = k
		_button(_chapters, Game.CHAPTERS[ch].title, func(): Game.start_chapter(ch), 22)
	_help = Pause.build_help(func(): _help.visible = false)
	_help.visible = false
	add_child(_help)
	_sound = Pause.build_sound(func(): _sound.visible = false)
	_sound.visible = false
	add_child(_sound)
	var help := _label("ESC / P in game: pause menu & controls  ·  M: mute", font_body, 22, Color(1, 1, 1, 0.5), Vector2(0, 1010))
	help.size = Vector2(1920, 40)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.get_child(1 if Game.has_save() else 0).grab_focus()


func _label(t: String, f: Font, sz: int, c: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	l.position = pos
	add_child(l)
	return l


func _button(parent: Node, t: String, cb: Callable, sz := 34) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_override("font", font_semi)
	b.add_theme_font_size_override("font_size", sz)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.06, 0.09, 0.85) if st in ["normal", "disabled"] else Color(0.18, 0.13, 0.06, 0.95)
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


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	Vec.vgrad(self, Rect2(0, 0, 1920, 1080), Color("07080d"), Color("1c1520"))
	# distant skyline with a few lit windows and a helicopter light
	for i in 30:
		var x := i * 66.0
		var h := 140.0 + Vec.hash01(i) * 240.0
		Vec.rect(self, Rect2(x, 1080 - h, 62, h), Color("0d0e14"))
		for k in 6:
			if Vec.hash01(i * 7.0 + k) > 0.75:
				Vec.rect(self, Rect2(x + 10 + (k % 3) * 16, 1080 - h + 20 + (k / 3) * 30, 8, 12), Color(1.1, 0.85, 0.5, 0.7))
	Vec.glow(self, Vector2(960, 1080), 900, Color(0.9, 0.35, 0.2, 0.25), 0.4)
	var hx := fposmod(_t * 60.0, 2200.0) - 140.0
	if fposmod(_t, 1.0) < 0.15:
		Vec.glow(self, Vector2(hx, 180), 20, Color(3.0, 0.4, 0.3))
