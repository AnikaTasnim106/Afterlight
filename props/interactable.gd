@tool
class_name Interactable
extends Node2D
## Something Alex can use with E. The level script decides what happens
## (it receives `id`). Shows a prompt when the player is within `reach`.

@export var id := ""
@export var prompt := "Look"
@export var reach := 110.0
## Where the "E  Look" prompt floats, relative to this node.
@export var prompt_offset := Vector2(0, -260)
## Optional: keep this interactable on top of a moving node (an NPC).
@export var follow_path: NodePath
@export var enabled := true:
	set(v):
		enabled = v
		queue_redraw()


func _ready() -> void:
	add_to_group("interactable")


func _process(_dt: float) -> void:
	if not Engine.is_editor_hint() and not follow_path.is_empty():
		var n := get_node_or_null(follow_path) as Node2D
		if n:
			global_position = Vector2(n.global_position.x, n.global_position.y)


func prompt_position() -> Vector2:
	return global_position + prompt_offset


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2(-reach, 0), Vector2(reach, 0), Color(0.2, 1, 0.6, 0.8 if enabled else 0.2), 4.0)
		draw_circle(prompt_offset, 8, Color(0.2, 1, 0.6, 0.8))
