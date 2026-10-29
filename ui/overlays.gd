class_name Overlays
extends Control
## Extra screen overlays: door peephole view, radio tuner, combat HUD.

signal tuned

var font_title: Font = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var font_mono: Font = preload("res://assets/fonts/ShareTechMono-Regular.ttf")
var font_body: Font = preload("res://assets/fonts/Nunito.ttf")

# --- peephole ---
var _peep: Node2D
var _peep_mask: Node2D
var _peep_zombie: CharacterRig
var _peep_t := 0.0

# --- tuner ---
var tuning := false
var freq := 141.20
var target_freq := 146.52
var _lock_t := 0.0
var bot_tune := false

# --- combat HUD ---
var combat_visible := false
var hp := 5
var max_hp := 5
var ammo := Vector2i(8, 8)
var bandages := 0
var survivors: Array = []   # [[name, Actor]]
var baby_level := 0.0
var _hint := ""
var _hint_a := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(1920, 1080)
	_peep = Node2D.new()
	_peep.position = Vector2(960, 520)
	_peep.visible = false
	add_child(_peep)
	_peep_mask = Node2D.new()
	_peep_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_peep_mask.draw.connect(func(): _peep_mask.draw_circle(Vector2.ZERO, 330, Color.WHITE))
	_peep.add_child(_peep_mask)
	var bg := Node2D.new()
	bg.draw.connect(func(): _draw_corridor(bg))
	_peep_mask.add_child(bg)
	_peep_zombie = CharacterRig.new()
	_peep_zombie.design = load("res://characters/designs/zombie_b.tres")
	_peep_zombie.zombie = true
	_peep_zombie.expression = "zombie"
	_peep_zombie.position = Vector2(-60, 330)
	_peep_zombie.scale = Vector2(0.95, 0.95)
	_peep_mask.add_child(_peep_zombie)
	var rim := Node2D.new()
	rim.draw.connect(func():
		rim.draw_arc(Vector2.ZERO, 335, 0, TAU, 96, Color(0.02, 0.02, 0.03), 24.0, true)
		for i in 12:
			rim.draw_arc(Vector2.ZERO, 330 - i * 6, 0, TAU, 96, Color(0, 0, 0, 0.06 * (12 - i)), 6.0, true))
	_peep.add_child(rim)


func _draw_corridor(ci: Node2D) -> void:
	# fisheye corridor (dim, flickering light)
	var flick := 0.75 + 0.25 * absf(sin(_peep_t * 7.0)) if fposmod(_peep_t, 3.0) < 0.4 else 1.0
	Vec.rect(ci, Rect2(-340, -340, 680, 680), Color(0.16, 0.16, 0.14) * flick)
	Vec.fill(ci, PackedVector2Array([Vector2(-340, -340), Vector2(-120, -140), Vector2(-120, 200), Vector2(-340, 340)]), Color(0.24, 0.23, 0.2) * flick)
	Vec.fill(ci, PackedVector2Array([Vector2(340, -340), Vector2(120, -140), Vector2(120, 200), Vector2(340, 340)]), Color(0.22, 0.21, 0.19) * flick)
	Vec.fill(ci, PackedVector2Array([Vector2(-120, 200), Vector2(120, 200), Vector2(340, 340), Vector2(-340, 340)]), Color(0.3, 0.28, 0.26) * flick)
	Vec.rect(ci, Rect2(-120, -140, 240, 340), Color(0.12, 0.12, 0.11) * flick)
	Vec.glow(ci, Vector2(0, -150), 160, Color(1.0, 0.95, 0.7, 0.35 * flick))
	Vec.rect(ci, Rect2(-260, -60, 70, 200), Color(0.35, 0.22, 0.16) * flick)


func show_peephole(on: bool) -> void:
	_peep.visible = on


func _process(dt: float) -> void:
	_peep_t += dt
	if _peep.visible:
		_peep_zombie.position.x = -60 + sin(_peep_t * 0.6) * 90.0
		_peep_zombie.velocity_x = cos(_peep_t * 0.6) * 54.0
		_peep_zombie.facing = 1 if cos(_peep_t * 0.6) > 0 else -1
		_peep_mask.get_child(0).queue_redraw()
	Audio.loop("tuner", "static", tuning, null, -6.0 - 14.0 * clampf(1.0 - absf(freq - target_freq) / 1.2, 0.0, 1.0))
	if tuning:
		var dir := Input.get_axis("move_left", "move_right")
		if bot_tune:
			dir = signf(target_freq - freq)
		freq = clampf(freq + dir * dt * (0.9 if absf(freq - target_freq) > 0.4 else 0.25), 140.0, 150.0)
		if absf(freq - target_freq) < 0.06:
			_lock_t += dt
			if _lock_t > 1.2:
				tuning = false
				freq = target_freq
				tuned.emit()
		else:
			_lock_t = 0.0
	_hint_a = move_toward(_hint_a, 1.0 if _hint != "" else 0.0, dt * 4.0)
	queue_redraw()


func start_tuning(target: float) -> void:
	target_freq = target
	freq = 141.2
	_lock_t = 0.0
	tuning = true


func set_hint(t: String) -> void:
	_hint = t


func _draw() -> void:
	if tuning:
		_draw_tuner()
	if combat_visible and not Inputs.input_locked:
		_draw_combat()
	if _hint_a > 0.01 and _hint != "" and not Inputs.input_locked:
		draw_string(font_mono, Vector2(64, 1032), _hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.75 * _hint_a))


func _draw_tuner() -> void:
	var r := Rect2(560, 760, 800, 170)
	Vec.rrect(self, r, 16, Color(0.04, 0.06, 0.05, 0.9))
	var sig := clampf(1.0 - absf(freq - target_freq) / 1.2, 0.0, 1.0)
	sig = pow(sig, 2.5)
	draw_string(font_mono, r.position + Vector2(30, 52), "%.2f MHz" % freq, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(0.45, 1.3, 0.8))
	draw_string(font_mono, r.position + Vector2(330, 52), "◀ A   scan   D ▶", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1, 0.6))
	# dial
	Vec.rect(self, Rect2(r.position + Vector2(30, 90), Vector2(740, 4)), Color(0.3, 0.6, 0.45))
	for i in 11:
		var x := r.position.x + 30 + i * 74.0
		Vec.rect(self, Rect2(x, r.position.y + 80, 2, 24), Color(0.3, 0.6, 0.45))
	var nx := r.position.x + 30 + (freq - 140.0) / 10.0 * 740.0
	Vec.rect(self, Rect2(nx - 3, r.position.y + 70, 6, 44), Color(1.4, 0.9, 0.4))
	# signal meter
	for i in 20:
		var on := float(i) / 20.0 < sig + randf() * 0.05
		Vec.rect(self, Rect2(r.position.x + 30 + i * 37, r.position.y + 128, 30, 22), Color(0.4, 1.3, 0.8) if on else Color(0.12, 0.2, 0.16))


func _draw_combat() -> void:
	var x := 64.0
	var y := 900.0
	Vec.rrect(self, Rect2(x - 20, y - 20, 470, 150), 14, Color(0, 0, 0, 0.45))
	draw_string(font_title, Vector2(x, y + 20), "ALEX", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("e9a640"))
	for i in max_hp:
		Vec.rrect(self, Rect2(x + 80 + i * 34, y, 26, 26), 6, Color("e9a640") if i < hp else Color(1, 1, 1, 0.15))
	draw_string(font_title, Vector2(x, y + 76), "%d" % ammo.x, HORIZONTAL_ALIGNMENT_LEFT, -1, 60, Color("f3eee6"))
	draw_string(font_mono, Vector2(x + 70, y + 76), "/ %d" % ammo.y, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, 0.65))
	for i in 8:
		Vec.rrect(self, Rect2(x + 180 + i * 18, y + 48, 10, 28), 3, Color("d9c08a") if i < ammo.x else Color(1, 1, 1, 0.12))
	draw_string(font_mono, Vector2(x + 340, y + 76), "+ %d" % bandages, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.9, 0.9, 0.9, 0.8))
	draw_string(font_mono, Vector2(x + 340, y + 100), "H heal", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.45))
	# survivors (top-right, out of the play area)
	var sx := 1560.0
	var sy := 72.0
	for s in survivors:
		var a: Actor = s[1]
		if a == null or not is_instance_valid(a):
			continue
		Vec.rrect(self, Rect2(sx - 20, sy - 30, 320, 44), 10, Color(0, 0, 0, 0.4))
		draw_string(font_title, Vector2(sx, sy), s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("39c2b4") if a.alive else Color(0.6, 0.3, 0.3))
		for i in a.max_hp:
			Vec.rrect(self, Rect2(sx + 150 + i * 26, sy - 20, 20, 20), 5, Color("39c2b4") if i < a.hp else Color(1, 1, 1, 0.15))
		sy += 54.0
	if baby_level > 0.02:
		Vec.rrect(self, Rect2(sx - 20, sy - 30, 320, 44), 10, Color(0, 0, 0, 0.4))
		draw_string(font_title, Vector2(sx, sy), "BABY CRYING", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.6, 0.9, 1.0))
		Vec.rect(self, Rect2(sx + 150, sy - 18, 130 * baby_level, 16), Color(0.6, 0.9, 1.0))
