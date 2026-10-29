class_name CinemaUI
extends CanvasLayer
## Screen-space presentation layer: letterbox bars, HUD (day / time /
## location / objective), dialogue captions with word-by-word reveal,
## title cards, and a fade. All styled in the AFTERLIGHT look.

signal line_finished
signal choice_made(index: int)

const AMBER := Color("e9a640")
const TEAL := Color("39c2b4")
const INK := Color("0a0a0e")

const SPEAKER_COLORS := {
	"ALEX": Color("e9a640"),
	"JUNE": Color("39c2b4"),
	"RADIO": Color("7fe0a8"),
	"NEWS": Color("e8735f"),
	"MRS. CARTER": Color("e9d9b8"),
	"RYAN": Color("ff7a6a"),
	"NINA": Color("f2a2b8"),
	"MR. DANIELS": Color("d4b07a"),
	"VOICES": Color("b8b2a8"),
	"MARA": Color("ff6a55"),
	"SOLDIER": Color("b5c08a"),
	"PILOT (RADIO)": Color("9fd0a0"),
	"SGT. HALE": Color("c7d08f"),
	"OFFICER PRICE": Color("aab4c8"),
	"DR. WARD": Color("8fd3ff"),
	"SAM": Color("ffd46a"),
	"SURVIVOR": Color("c9c2b5"),
	"GUS": Color("f2c94c"),
	"LEO": Color("d98c5f"),
	"RUTH": Color("9fb8d9"),
	"KAI": Color("7fd1a8"),
	"DR. CHEN": Color("b8e0ff"),
	"NURSE HOLLY": Color("8fe0d0"),
	"THEO": Color("ffb37a"),
	"GUARD": Color("c7d08f"),
}

var font_title: Font = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var font_semi: Font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var font_body: Font = preload("res://assets/fonts/Nunito.ttf")
var font_mono: Font = preload("res://assets/fonts/ShareTechMono-Regular.ttf")

## In demo/capture mode lines auto-advance instead of waiting for Space.
var auto_advance := false
## What auto_advance goes back to after a bark (true only for the test bot).
var auto_default := false

var _grade: ColorRect
var _bar_top: ColorRect
var _bar_bot: ColorRect
var _fade: ColorRect
var _hud: Control
var _hud_day: Label
var _hud_time: Label
var _hud_place: Label
var _hud_obj: Label
var _cap_root: Control
var _cap_band: TextureRect
var _cap_name: Label
var _cap_rule: ColorRect
var _cap_text: RichTextLabel
var _title: Control
var _title_main: Label
var _title_sub: Label
var _prompt: Label
var _waiting := false
var _reveal_tween: Tween
var _choice_box: VBoxContainer
var _choice_buttons: Array[Button] = []
var _choosing := false
var _world_prompt: Label
var _prompt_world_pos := Vector2.ZERO
var _toast: Label
var phone: PhoneUI
var notice: NoticeCard
var over: Overlays
var _rule_lbl: Label
## Playtest bot: pre-queued answers for choose() in auto mode.
var auto_choices: Array[int] = []


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# finishing grade (vignette + grain) sits under the UI
	_grade = ColorRect.new()
	_grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/screen_grade.gdshader")
	_grade.material = mat
	root.add_child(_grade)

	_bar_top = _bar(root, true)
	_bar_bot = _bar(root, false)

	# HUD
	_hud = Control.new()
	_hud.position = Vector2(64, 52)
	root.add_child(_hud)
	var dot := ColorRect.new()
	dot.color = AMBER
	dot.size = Vector2(10, 10)
	dot.position = Vector2(0, 11)
	_hud.add_child(dot)
	_hud_day = _label(_hud, font_semi, 26, AMBER, Vector2(20, 0))
	_hud_time = _label(_hud, font_title, 64, Color("f3eee6"), Vector2(-2, 26))
	_hud_place = _label(_hud, font_mono, 22, Color(0.95, 0.93, 0.9, 0.7), Vector2(0, 100))
	var rule := ColorRect.new()
	rule.color = Color(1, 1, 1, 0.25)
	rule.size = Vector2(230, 2)
	rule.position = Vector2(0, 132)
	_hud.add_child(rule)
	_hud_obj = _label(_hud, font_body, 24, Color(0.95, 0.93, 0.9, 0.9), Vector2(0, 144))
	_hud.modulate.a = 0.0

	# captions
	_cap_root = Control.new()
	_cap_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cap_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_cap_root)
	_cap_band = TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0.02, 0.02, 0.04, 0.84), Color(0.02, 0.02, 0.04, 0.93)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	_cap_band.texture = gt
	_cap_band.stretch_mode = TextureRect.STRETCH_SCALE
	_cap_band.position = Vector2(0, 760)
	_cap_band.size = Vector2(1920, 320)
	_cap_root.add_child(_cap_band)
	_cap_name = _label(_cap_root, font_title, 34, AMBER, Vector2(0, 842))
	_cap_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cap_name.size = Vector2(1920, 40)
	_cap_rule = ColorRect.new()
	_cap_rule.size = Vector2(44, 4)
	_cap_rule.position = Vector2(938, 886)
	_cap_root.add_child(_cap_rule)
	_cap_text = RichTextLabel.new()
	_cap_text.bbcode_enabled = true
	_cap_text.fit_content = true
	_cap_text.scroll_active = false
	_cap_text.position = Vector2(260, 902)
	_cap_text.size = Vector2(1400, 120)
	_cap_text.add_theme_font_override("normal_font", font_body)
	_cap_text.add_theme_font_override("bold_font", font_body)
	_cap_text.add_theme_font_size_override("normal_font_size", 40)
	_cap_text.add_theme_font_size_override("bold_font_size", 40)
	_cap_text.add_theme_color_override("default_color", Color("f6f1e8"))
	_cap_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_cap_text.add_theme_constant_override("shadow_offset_y", 3)
	_cap_text.add_theme_constant_override("shadow_offset_x", 0)
	_cap_text.add_theme_constant_override("shadow_outline_size", 8)
	_cap_root.add_child(_cap_text)
	_prompt = _label(_cap_root, font_mono, 20, Color(1, 1, 1, 0.5), Vector2(1700, 1010))
	_prompt.text = "SPACE ▸"
	_cap_root.modulate.a = 0.0

	_fade = ColorRect.new()
	_fade.color = INK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_fade)
	_fade.modulate.a = 0.0

	# title card (above the fade so it can sit on black)
	_title = Control.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_title)
	_title_main = _label(_title, font_title, 150, Color("f3eee6"), Vector2(0, 380))
	_title_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_main.size = Vector2(1920, 170)
	_title_main.add_theme_constant_override("outline_size", 0)
	_title_sub = _label(_title, font_semi, 38, AMBER, Vector2(0, 560))
	_title_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_sub.size = Vector2(1920, 50)
	_title.modulate.a = 0.0

	notice = NoticeCard.new()
	root.add_child(notice)

	# choices
	_choice_box = VBoxContainer.new()
	_choice_box.position = Vector2(560, 640)
	_choice_box.size = Vector2(800, 0)
	_choice_box.add_theme_constant_override("separation", 12)
	root.add_child(_choice_box)
	_choice_box.visible = false

	# interaction prompt (follows a world position)
	_world_prompt = _label(root, font_title, 30, Color("f3eee6"), Vector2.ZERO)
	_world_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_world_prompt.add_theme_constant_override("outline_size", 10)
	_world_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_world_prompt.size = Vector2(500, 40)
	_world_prompt.modulate.a = 0.0

	over = Overlays.new()
	root.add_child(over)
	phone = PhoneUI.new()
	root.add_child(phone)
	_rule_lbl = _label(root, font_title, 40, Color("ff8a6a"), Vector2(0, 300))
	_rule_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rule_lbl.size = Vector2(1920, 50)
	_rule_lbl.modulate.a = 0.0

	# toast ("June will remember that.")
	_toast = _label(root, font_semi, 30, TEAL, Vector2(1300, 250))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_toast.size = Vector2(560, 40)
	_toast.modulate.a = 0.0



func _bar(root: Control, top: bool) -> ColorRect:
	var b := ColorRect.new()
	b.color = INK
	b.size = Vector2(1920, 120)
	b.position = Vector2(0, -120 if top else 1080)
	root.add_child(b)
	return b


func _label(parent: Node, font: Font, sz: int, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


# --- API --------------------------------------------------------------------

func letterbox(on: bool, secs := 0.8) -> void:
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_bar_top, "position:y", 0.0 if on else -120.0, secs)
	tw.tween_property(_bar_bot, "position:y", 960.0 if on else 1080.0, secs)


func set_hud(day: String, time: String, place: String, objective := "") -> void:
	_hud_day.text = day
	_hud_time.text = time
	_hud_place.text = place
	_hud_obj.text = ("◇  " + objective) if objective != "" else ""


func show_hud(on: bool, secs := 0.6) -> void:
	create_tween().tween_property(_hud, "modulate:a", 1.0 if on else 0.0, secs)


func fade(to_black: bool, secs := 0.8) -> Tween:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, secs)
	return tw


func set_black(on: bool) -> void:
	_fade.modulate.a = 1.0 if on else 0.0


func title_card(main: String, sub: String, hold := 2.0) -> void:
	if main != "":
		Audio.sfx("boom", Vector2.INF, -4.0, 0.0)
	_title_main.text = main
	_title_sub.text = sub
	_title_main.add_theme_constant_override("letter_spacing", 0)
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, 0.9)
	tw.tween_interval(hold)
	tw.tween_property(_title, "modulate:a", 0.0, 0.9)
	await tw.finished


## Show a line of dialogue. Words in *asterisks* are highlighted.
## Awaitable: returns when the player advances (or after a hold in auto mode).
func say(speaker: String, text: String, hold := 1.4) -> void:
	var col: Color = SPEAKER_COLORS.get(speaker, Color("d8d2c8"))
	_cap_name.text = speaker
	_cap_rule.visible = speaker != ""
	_cap_text.add_theme_color_override("default_color", Color("f6f1e8") if speaker != "" else Color(0.85, 0.83, 0.8, 0.85))
	_cap_name.add_theme_color_override("font_color", col)
	_cap_rule.color = col
	# *highlighted phrase* — may span several words
	var bb := ""
	var on := false
	for ch in text:
		if ch == "*":
			on = not on
			bb += ("[color=#%s]" % col.to_html(false)) if on else "[/color]"
		elif ch == "[":
			bb += "[lb]"
		else:
			bb += ch
	if on:
		bb += "[/color]"
	_cap_text.text = "[center]" + bb.strip_edges() + "[/center]"
	_cap_text.visible_ratio = 0.0
	create_tween().tween_property(_cap_root, "modulate:a", 1.0, 0.2)
	_prompt.visible = not auto_advance
	var secs := clampf(text.length() * 0.028, 0.4, 2.6)
	# finish (don't kill) the previous reveal so whoever awaited it resumes
	if _reveal_tween and _reveal_tween.is_running():
		_reveal_tween.custom_step(100.0)
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(_cap_text, "visible_ratio", 1.0, secs)
	await _reveal_tween.finished
	if auto_advance:
		await get_tree().create_timer(hold).timeout
	else:
		_waiting = true
		await line_finished


## Inner thought: grey italics-style caption, no speaker tag.
func think(text: String, hold := 1.2) -> void:
	await say("", "( " + text + " )", hold)


## Show 2-3 options; returns the chosen index. Keys 1/2/3 or mouse.
func choose(options: Array) -> int:
	Audio.sfx("ui_choice", Vector2.INF, -8.0, 0.0)
	for b in _choice_buttons:
		b.queue_free()
	_choice_buttons.clear()
	for i in options.size():
		var b := Button.new()
		b.text = "  %d   %s" % [i + 1, options[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", font_body)
		b.add_theme_font_size_override("font_size", 32)
		b.add_theme_color_override("font_color", Color("f6f1e8"))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.custom_minimum_size = Vector2(800, 62)
		for st in ["normal", "hover", "pressed", "focus"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.05, 0.05, 0.08, 0.78) if st == "normal" else Color(0.16, 0.12, 0.06, 0.92)
			sb.border_color = Color(AMBER, 0.35 if st == "normal" else 1.0)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(31)
			sb.content_margin_left = 22
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(func(): _pick(i))
		_choice_box.add_child(b)
		_choice_buttons.append(b)
	_choice_box.position.y = 880 - options.size() * 74
	_choice_box.visible = true
	_choice_box.modulate.a = 0.0
	create_tween().tween_property(_choice_box, "modulate:a", 1.0, 0.25)
	_choosing = true
	if OS.get_environment("LOG_CHOICES") == "1":
		print("CHOICE t=%.1f %s" % [Engine.get_process_frames() / 60.0, str(options)])
	if auto_advance:
		await get_tree().create_timer(1.2).timeout
		var pick: int = auto_choices.pop_front() if not auto_choices.is_empty() else 0
		pick = clampi(pick, 0, _choice_buttons.size() - 1)
		_choice_buttons[pick].grab_focus()
		await get_tree().create_timer(0.5).timeout
		_pick(pick)
		return pick
	var idx: int = await choice_made
	return idx


func _pick(i: int) -> void:
	if not _choosing:
		return
	_choosing = false
	_choice_box.visible = false
	choice_made.emit(i)


func is_busy() -> bool:
	return _choosing or _waiting


func show_prompt(text: String, world_pos: Vector2) -> void:
	_world_prompt.text = text
	_prompt_world_pos = world_pos
	create_tween().tween_property(_world_prompt, "modulate:a", 1.0, 0.15)


func hide_prompt() -> void:
	create_tween().tween_property(_world_prompt, "modulate:a", 0.0, 0.15)


var _big: Label
var _big_tw: Tween

## Huge centered word that pops and fades (countdowns, "GO!").
func big(text: String) -> void:
	if _big == null:
		_big = Label.new()
		_big.add_theme_font_override("font", font_title)
		_big.add_theme_font_size_override("font_size", 220)
		_big.add_theme_color_override("font_color", Color("f3eee6"))
		_big.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		_big.add_theme_constant_override("shadow_offset_y", 6)
		_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_big.size = Vector2(1920, 260)
		_big.position = Vector2(0, 300)
		_big.pivot_offset = Vector2(960, 130)
		add_child(_big)
	if _big_tw and _big_tw.is_valid():
		_big_tw.kill()
	_big.text = text
	_big.modulate.a = 1.0
	_big.scale = Vector2(1.4, 1.4)
	_big_tw = create_tween()
	_big_tw.tween_property(_big, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_big_tw.tween_interval(0.25)
	_big_tw.tween_property(_big, "modulate:a", 0.0, 0.35)


func toast(text: String) -> void:
	_toast.text = text
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.2)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


## Big red reminder of one of the six rules ("RULE 2 · AVOID UNNECESSARY NOISE").
func rule_flash(n: int) -> void:
	Audio.sfx("stinger", Vector2.INF, -7.0, 0.0)
	_rule_lbl.text = "RULE %d  ·  %s" % [n, NoticeCard.RULES[n - 1][0]]
	var tw := create_tween()
	tw.tween_property(_rule_lbl, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.2)
	tw.tween_property(_rule_lbl, "modulate:a", 0.0, 0.6)


func set_objective(text: String) -> void:
	_hud_obj.text = ("◇  " + text) if text != "" else ""
	var tw := create_tween()
	tw.tween_property(_hud_obj, "modulate", Color(2.0, 1.6, 0.8), 0.15)
	tw.tween_property(_hud_obj, "modulate", Color.WHITE, 0.8)


func _process(_dt: float) -> void:
	if _world_prompt.modulate.a > 0.0:
		var sp := get_viewport().get_canvas_transform() * _prompt_world_pos
		# canvas transform is in viewport pixels; UI is laid out at 1920x1080
		sp *= Vector2(1920, 1080) / get_viewport().get_visible_rect().size
		_world_prompt.position = sp - Vector2(250, 20)


func hide_caption() -> void:
	create_tween().tween_property(_cap_root, "modulate:a", 0.0, 0.25)


## TAB is also Godot's GUI focus key, so catch it before the GUI does.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rules") and not event.is_echo() and not get_tree().paused:
		if Game.flag("rules_known"):
			notice.toggle_compact()
		else:
			toast("No emergency notice yet — it arrives later tonight.")
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _choosing:
		for i in _choice_buttons.size():
			if event.is_action_pressed("choice_%d" % (i + 1)):
				_pick(i)
				get_viewport().set_input_as_handled()
				return
		return
	if event.is_action_pressed("advance"):
		if _reveal_tween and _reveal_tween.is_running():
			_reveal_tween.custom_step(10.0)
		elif _waiting:
			_waiting = false
			line_finished.emit()
