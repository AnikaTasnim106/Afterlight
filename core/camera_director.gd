class_name CameraDirector
extends Camera2D
## Gameplay follow-cam + cinematic shots.
## follow(node): smooth tracking with look-ahead in the walking direction.
## shot(pos, zoom, secs): tween to a framed composition (close-ups, two-shots).
## Always drifts very slightly (a slow "breathing" push-in, like the reels).

@export var follow_offset := Vector2(0, -400)
@export var look_ahead := 160.0
@export var follow_smooth := 3.2
@export var drift := 6.0

var target: Node2D
var _mode := "follow"
var _tween: Tween
var _shake := 0.0
var _t := 0.0
var _ahead := 0.0
var _base_pos := Vector2.ZERO
var _base_zoom := 1.0
var _push := 0.0
## Zoom of the last gameplay follow() — used when we fall back to following.
var follow_zoom := 1.0


func _ready() -> void:
	_base_pos = global_position
	_base_zoom = zoom.x
	make_current()


func follow(node: Node2D, zoom_level := 1.0, secs := 1.2) -> void:
	target = node
	follow_zoom = zoom_level
	_mode = "follow_blend"
	_kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "_base_zoom", zoom_level, secs)
	_tween.parallel().tween_method(_blend_to_follow, 0.0, 1.0, secs)
	_tween.tween_callback(func(): _mode = "follow")


func _blend_to_follow(w: float) -> void:
	if target:
		_base_pos = _base_pos.lerp(_follow_point(), w)


func shot(pos: Vector2, zoom_level: float, secs := 1.4, push := 0.0) -> Tween:
	## Frame `pos` at `zoom_level`. `push` = extra slow zoom-in per second while holding.
	_mode = "shot"
	_kill()
	_push = push
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "_base_pos", pos, secs)
	_tween.parallel().tween_property(self, "_base_zoom", zoom_level, secs)
	return _tween


func is_shot() -> bool:
	return _mode == "shot"


func cut(pos: Vector2, zoom_level: float, push := 0.0) -> void:
	_mode = "shot"
	_kill()
	_push = push
	_base_pos = pos
	_base_zoom = zoom_level


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _kill() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


func _follow_point() -> Vector2:
	return target.global_position + follow_offset + Vector2(_ahead, 0)


func _process(dt: float) -> void:
	_t += dt
	if target and target is Actor:
		var vx: float = (target as Actor).velocity.x
		_ahead = lerpf(_ahead, clampf(vx / 230.0, -1.0, 1.0) * look_ahead, dt * 1.5)
	if _mode == "follow" and target:
		_base_pos = _base_pos.lerp(_follow_point(), clampf(dt * follow_smooth, 0.0, 1.0))
	if _mode == "shot" and _push != 0.0:
		_base_zoom += _push * dt
	var d := Vector2(sin(_t * 0.31), cos(_t * 0.23)) * drift
	var s := Vector2.ZERO
	if _shake > 0.0:
		s = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, dt * 30.0)
	global_position = _base_pos + d + s
	zoom = Vector2(_base_zoom, _base_zoom)
