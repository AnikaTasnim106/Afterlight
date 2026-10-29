class_name Companion
extends Actor
## An armed ally (Mara). Follows Alex and shoots zombies that come close.
## Not a perfect shot; every shot is loud like Alex's.

@export var range_px := 950.0
@export var fire_interval := 1.05
@export var accuracy := 0.72
@export var damage := 2

var armed := false
var _cool := 0.8
## Companions get knocked down instead of dying; back up after a few seconds.
var downed := false


func hurt(amount: int, from_x: float) -> void:
	if downed or not alive:
		return
	if hp - amount > 0:
		super.hurt(amount, from_x)
		return
	downed = true
	hp = 0
	rig.flinch = 1.0
	rig.hurt_flash = 1.0
	rig.aiming = false
	remove_from_group("living")
	nav_target = Vector2.INF
	var keep := follow_target
	follow_target = null
	var tw := create_tween()
	tw.tween_property(rig, "down", 0.85, 0.4)
	await get_tree().create_timer(6.0).timeout
	if not is_inside_tree():
		return
	var tw2 := create_tween()
	tw2.tween_property(rig, "down", 0.0, 0.6)
	await tw2.finished
	hp = 2
	downed = false
	add_to_group("living")
	follow_target = keep


func _physics_process(dt: float) -> void:
	super._physics_process(dt)
	if not alive or not armed or downed:
		rig.aiming = false
		return
	_cool -= dt
	var target: Actor = null
	var best := range_px
	for z in get_tree().get_nodes_in_group("zombies"):
		var za := z as Actor
		if not za.alive:
			continue
		var d := za.global_position.distance_to(global_position)
		# hiding: don't give the position away unless it's already coming for someone
		if in_cover and za is Zombie and (za as Zombie).state != "chase" and (za as Zombie).state != "attack":
			continue
		if d < best and absf(za.global_position.y - global_position.y) < 300.0:
			best = d
			target = za
	rig.aiming = target != null
	rig.prop_front = "gun"
	if target == null:
		return
	var zones: Array = target.rig.hit_zones()
	var aim: Vector2 = (zones[2] + zones[3]) * 0.5
	rig.aim_angle = (aim - (global_position + Vector2(0, -320))).angle()
	rig.facing = int(signf(target.global_position.x - global_position.x)) if target.global_position.x != global_position.x else rig.facing
	if _cool <= 0.0 and Inputs.input_locked == false:
		_cool = fire_interval * randf_range(0.85, 1.2)
		rig.recoil = 1.0
		Sound.emit(rig.muzzle_global_position(), 1500.0, "gunshot")
		if randf() < accuracy:
			target.hurt(damage, global_position.x)
		var line := Line2D.new()
		line.points = PackedVector2Array([rig.muzzle_global_position(), aim])
		line.width = 2.5
		line.default_color = Color(2.0, 1.7, 1.0, 0.8)
		get_tree().current_scene.add_child(line)
		var tw := line.create_tween()
		tw.tween_property(line, "modulate:a", 0.0, 0.1)
		tw.tween_callback(line.queue_free)
