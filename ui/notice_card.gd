class_name NoticeCard
extends Control
## The official City Emergency Notice — the six survival rules.
## Shown full-screen when it arrives (Scene 4), then available any time
## with TAB as a compact panel. Rules are gameplay: see README.

signal dismissed

const RULES := [
	["STAY INDOORS AND LOCK DOORS", "Keep doors locked at all times."],
	["AVOID UNNECESSARY NOISE", "Noise attracts affected individuals."],
	["DO NOT APPROACH AGGRESSIVE OR DISORIENTED INDIVIDUALS", "Keep your distance. Do not open doors to strangers."],
	["CONSERVE FOOD AND WATER", "Supply lines may be interrupted for days."],
	["KEEP ESSENTIAL SUPPLIES READY", "Water, first aid, light, phone, documents."],
	["WAIT FOR OFFICIAL EVACUATION INSTRUCTIONS", "Do not travel unless instructed."],
]

var font_title: Font = preload("res://assets/fonts/BarlowCondensed-Bold.ttf")
var font_semi: Font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var font_body: Font = preload("res://assets/fonts/Nunito.ttf")
var font_mono: Font = preload("res://assets/fonts/ShareTechMono-Regular.ttf")

var _compact := false
var _waiting := false
var _labels: Array[Label] = []
var _reveal := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(1920, 1080)
	visible = false


## Full-screen dramatic presentation; awaitable until the player presses Space.
func present(auto := false) -> void:
	_compact = false
	visible = true
	modulate.a = 0.0
	_reveal = 0.0
	queue_redraw()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	tw.tween_property(self, "_reveal", 6.0, 4.2)
	await tw.finished
	if auto:
		await get_tree().create_timer(2.5).timeout
	else:
		_waiting = true
		await dismissed
	var tw2 := create_tween()
	tw2.tween_property(self, "modulate:a", 0.0, 0.4)
	await tw2.finished
	visible = false


func toggle_compact() -> void:
	if visible and not _compact:
		return
	_compact = not visible
	visible = _compact
	_reveal = 6.0
	modulate.a = 1.0
	queue_redraw()


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _waiting and event.is_action_pressed("advance"):
		_waiting = false
		get_viewport().set_input_as_handled()
		dismissed.emit()


func _draw() -> void:
	var r := Rect2(460, 90, 1000, 900) if not _compact else Rect2(1240, 200, 640, 640)
	var s := 1.0 if not _compact else 0.62
	if not _compact:
		draw_rect(Rect2(0, 0, 1920, 1080), Color(0.02, 0.02, 0.04, 0.82))
	Vec.rrect(self, r, 18, Color("f1ece2"))
	Vec.rrect(self, Rect2(r.position, Vector2(r.size.x, 120 * s)), 18, Color("b8261d"))
	Vec.rect(self, Rect2(r.position + Vector2(0, 100 * s), Vector2(r.size.x, 20 * s)), Color("b8261d"))
	_text(font_title, int(56 * s), "CITY EMERGENCY NOTICE", r.position + Vector2(40 * s, 74 * s), Color.WHITE)
	_text(font_mono, int(20 * s), "OFFICE OF CIVIL DEFENCE  ·  ISSUED 21:12  ·  ALL RESIDENTS", r.position + Vector2(40 * s, 106 * s), Color(1, 1, 1, 0.85))
	for i in RULES.size():
		var a := clampf(_reveal - i, 0.0, 1.0)
		if a <= 0.0:
			continue
		var y := r.position.y + (160 + i * 122) * s
		var x := r.position.x + 40 * s
		Vec.circle(self, Vector2(x + 34 * s, y + 34 * s), 34 * s, Color("b8261d", a))
		_text(font_title, int(40 * s), str(i + 1), Vector2(x + 24 * s, y + 50 * s), Color(1, 1, 1, a))
		_icon(i, Vector2(x + 120 * s, y + 34 * s), 30 * s, Color(0.15, 0.13, 0.13, a))
		_text(font_title, int(34 * s), RULES[i][0], Vector2(x + 175 * s, y + 34 * s), Color(0.12, 0.1, 0.1, a))
		_text(font_body, int(24 * s), RULES[i][1], Vector2(x + 175 * s, y + 70 * s), Color(0.3, 0.27, 0.26, a))
	var foot := "Press SPACE to continue" if not _compact else "TAB to close"
	if _reveal >= 6.0:
		_text(font_mono, int(22 * s), foot, r.position + Vector2(r.size.x - 330 * s, r.size.y - 26 * s), Color(0.3, 0.27, 0.26))


func _text(font: Font, sz: int, t: String, pos: Vector2, col: Color) -> void:
	draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _icon(i: int, c: Vector2, k: float, col: Color) -> void:
	match i:
		0: # house with lock
			Vec.fill(self, PackedVector2Array([c + Vector2(-k, -0.1 * k), c + Vector2(0, -k), c + Vector2(k, -0.1 * k)]), col)
			Vec.rect(self, Rect2(c + Vector2(-0.75 * k, -0.15 * k), Vector2(1.5 * k, k)), col)
			Vec.rect(self, Rect2(c + Vector2(-0.25 * k, 0.25 * k), Vector2(0.5 * k, 0.45 * k)), Color("f1ece2"))
		1: # speaker with slash
			Vec.fill(self, PackedVector2Array([c + Vector2(-k, -0.35 * k), c + Vector2(-0.4 * k, -0.35 * k), c + Vector2(0.2 * k, -0.9 * k), c + Vector2(0.2 * k, 0.9 * k), c + Vector2(-0.4 * k, 0.35 * k), c + Vector2(-k, 0.35 * k)]), col)
			Vec.line(self, c + Vector2(-k, -k), c + Vector2(k, k), Color("b8261d", col.a), 0.25 * k)
		2: # person + X
			Vec.circle(self, c + Vector2(-0.3 * k, -0.6 * k), 0.3 * k, col)
			Vec.capsule(self, c + Vector2(-0.3 * k, -0.2 * k), c + Vector2(-0.3 * k, 0.8 * k), 0.3 * k, 0.3 * k, col)
			Vec.line(self, c + Vector2(0.3 * k, -0.4 * k), c + Vector2(k, 0.3 * k), Color("b8261d", col.a), 0.22 * k)
			Vec.line(self, c + Vector2(k, -0.4 * k), c + Vector2(0.3 * k, 0.3 * k), Color("b8261d", col.a), 0.22 * k)
		3: # water drop
			Vec.fill(self, PackedVector2Array([c + Vector2(0, -k), c + Vector2(0.6 * k, 0.2 * k), c + Vector2(0.4 * k, 0.7 * k), c + Vector2(0, 0.9 * k), c + Vector2(-0.4 * k, 0.7 * k), c + Vector2(-0.6 * k, 0.2 * k)]), col)
		4: # backpack
			Vec.rrect(self, Rect2(c + Vector2(-0.7 * k, -0.6 * k), Vector2(1.4 * k, 1.5 * k)), 0.3 * k, col)
			Vec.stroke(self, Vec.qbez(c + Vector2(-0.4 * k, -0.6 * k), c + Vector2(0, -1.2 * k), c + Vector2(0.4 * k, -0.6 * k), 6), col, 0.18 * k)
		5: # megaphone
			Vec.fill(self, PackedVector2Array([c + Vector2(-k, -0.3 * k), c + Vector2(0.6 * k, -0.9 * k), c + Vector2(0.6 * k, 0.9 * k), c + Vector2(-k, 0.3 * k)]), col)
			Vec.rect(self, Rect2(c + Vector2(-0.6 * k, 0.3 * k), Vector2(0.3 * k, 0.6 * k)), col)
