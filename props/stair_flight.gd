@tool
class_name StairFlight
extends Node2D
## One flight of stairs between two WalkFloors.
## `bottom` and `top` are local points that must sit on floor surfaces.
## The player steps on with W (at the bottom) or S (at the top) and walks it
## with A/D or W/S. NPCs/zombies use it through Nav.

@export var bottom := Vector2(0, 0):
	set(v):
		bottom = v
		queue_redraw()
@export var top := Vector2(800, -500):
	set(v):
		top = v
		queue_redraw()
@export var concrete := Color("6b6867")
@export var rail := Color("c9a23c")

var _hint: Label
var _hint_text := ""


func _ready() -> void:
	add_to_group("stairs")
	if not Engine.is_editor_hint():
		_hint = Label.new()
		_hint.add_theme_font_override("font", preload("res://assets/fonts/BarlowCondensed-Bold.ttf"))
		_hint.add_theme_font_size_override("font_size", 30)
		_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_hint.add_theme_constant_override("outline_size", 10)
		_hint.z_index = 50
		_hint.modulate.a = 0.0
		add_child(_hint)


func ga() -> Vector2:
	return to_global(bottom)


func gb() -> Vector2:
	return to_global(top)


func slope() -> float:
	var d := top - bottom
	return d.y / d.x if absf(d.x) > 0.01 else 0.0


func _process(_dt: float) -> void:
	if Engine.is_editor_hint() or _hint == null:
		return
	var player := _find_player()
	var txt := ""
	var at := Vector2.ZERO
	if player and player.stair == null and not Inputs.input_locked:
		var p := player.global_position
		if absf(p.x - ga().x) < 60.0 and absf(p.y - ga().y) < 30.0:
			txt = "W  ▲  Upstairs"
			at = bottom
		elif absf(p.x - gb().x) < 60.0 and absf(p.y - gb().y) < 30.0:
			txt = "S  ▼  Downstairs"
			at = top
	if txt != _hint_text:
		_hint_text = txt
		if txt != "":
			_hint.text = txt
			_hint.position = at + Vector2(-90, -560)
		create_tween().tween_property(_hint, "modulate:a", 1.0 if txt != "" else 0.0, 0.15)


func _find_player() -> Actor:
	for n in get_tree().get_nodes_in_group("actors"):
		if n is Actor and n.player_controlled:
			return n
	return null


func _draw() -> void:
	var a := bottom
	var b := top
	var n := maxi(3, int(absf(b.y - a.y) / 34.0))
	var dir := signf(b.x - a.x)
	# stringer (concrete underside)
	var pts := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t)
		pts.append(p + Vector2(-dir * (b.x - a.x) / n * 0.5, 0))
		pts.append(p + Vector2(dir * (b.x - a.x) / n * 0.0, 0))
	var under := PackedVector2Array([a + Vector2(0, 2), b + Vector2(0, 2), b + Vector2(0, 70), a + Vector2(dir * 40.0, 70)])
	Vec.fill(self, under, Vec.shade(concrete, 0.25))
	# steps (treads + risers) along the walking line
	var sx := (b.x - a.x) / n
	var sy := (b.y - a.y) / n
	for i in n:
		var p0 := a + Vector2(sx * i, sy * i)
		var step := PackedVector2Array([p0 + Vector2(0, -sy * 0.5 + 0.0), p0 + Vector2(sx, -sy * 0.5), p0 + Vector2(sx, sy * 0.5 + 6.0), p0 + Vector2(0, sy * 0.5 + 6.0)])
		Vec.fill(self, step, concrete)
		Vec.line(self, p0 + Vector2(0, sy * 0.5 + 0.0), p0 + Vector2(sx, sy * 0.5), Vec.shade(concrete, -0.2), 3.0)
	# handrail + balusters (behind the characters)
	var h := Vector2(0, -210)
	Vec.line(self, a + h, b + h, rail, 6.0)
	for i in n + 1:
		if i % 2 == 0:
			var p := a.lerp(b, float(i) / n)
			Vec.line(self, p, p + h, Vec.shade(rail, 0.35), 3.0)
	Vec.circle(self, a + h, 6, rail)
	Vec.circle(self, b + h, 6, rail)
