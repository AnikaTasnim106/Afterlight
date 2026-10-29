@tool
class_name WalkFloor
extends Node2D
## A walkable horizontal surface (corridor floor, stair landing, roof).
## Origin = left end of the top surface. Creates its own collision.
## Part of the navigation graph: NPCs path between WalkFloors via StairFlights.

@export var width := 800.0:
	set(v):
		width = v
		_rebuild()
@export var thickness := 40.0
@export_enum("none", "slab", "concrete") var style := 0:
	set(v):
		style = v
		queue_redraw()
@export var color := Color("4a4648")
## Invisible walls at the ends so nobody walks off into the stairwell void.
@export var wall_left := true
@export var wall_right := true

var _body: StaticBody2D


func _ready() -> void:
	add_to_group("walkfloor")
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _body:
		_body.queue_free()
	_body = StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(width + 80.0, thickness)
	cs.shape = sh
	cs.position = Vector2(width * 0.5, thickness * 0.5)
	_body.add_child(cs)
	for side in [0, 1]:
		if (side == 0 and wall_left) or (side == 1 and wall_right):
			var ws := CollisionShape2D.new()
			var wr := RectangleShape2D.new()
			wr.size = Vector2(20, 640)
			ws.shape = wr
			ws.position = Vector2(-62.0 if side == 0 else width + 62.0, -320)
			_body.add_child(ws)
	add_child(_body)
	queue_redraw()


func top_y() -> float:
	return global_position.y


func x_range() -> Vector2:
	return Vector2(global_position.x, global_position.x + width)


func contains(p: Vector2, tol := 26.0) -> bool:
	return absf(p.y - global_position.y) <= tol and p.x >= global_position.x - 30.0 and p.x <= global_position.x + width + 30.0


func _draw() -> void:
	match style:
		1:
			Vec.rect(self, Rect2(0, 0, width, thickness), color)
			Vec.rect(self, Rect2(0, 0, width, 6), Vec.shade(color, -0.15))
		2:
			Vec.rect(self, Rect2(0, 0, width, thickness + 40), color)
			Vec.rect(self, Rect2(0, 0, width, 8), Vec.shade(color, -0.2))
			Vec.rect(self, Rect2(0, thickness + 30, width, 10), Vec.shade(color, 0.3))
