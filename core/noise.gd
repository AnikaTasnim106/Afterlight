extends Node
## Sound as a gameplay system (autoload "Sound").
## Anything loud calls Sound.emit(); zombies listen to `heard`.
## A faint ring is drawn in the world so the player can *see* how far a sound travels.

signal heard(pos: Vector2, radius: float, kind: String)

var show_rings := true


func emit(pos: Vector2, radius: float, kind: String) -> void:
	heard.emit(pos, radius, kind)
	if show_rings and get_tree().current_scene:
		var ring := _Ring.new()
		ring.max_r = radius
		ring.global_position = pos + Vector2(0, -200)
		ring.col = Color(1.0, 0.55, 0.3) if kind == "gunshot" else (Color(0.5, 0.9, 1.0) if kind == "baby" else Color(1, 1, 1))
		get_tree().current_scene.add_child(ring)


class _Ring extends Node2D:
	var max_r := 600.0
	var t := 0.0
	var col := Color.WHITE

	func _ready() -> void:
		z_index = 40

	func _process(dt: float) -> void:
		t += dt / 0.9
		if t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var r := max_r * (1.0 - pow(1.0 - t, 2.0))
		draw_arc(Vector2.ZERO, r, 0, TAU, 96, Color(col, 0.35 * (1.0 - t)), 4.0, true)
