class_name GunController
extends Node2D
## Alex's handgun. Child of the Alex actor; enable it in combat scenes.
## Mouse aims, LMB (or Ctrl) shoots, R reloads, H uses a bandage.
## Every shot is LOUD: it emits a big Noise event that pulls zombies in.

signal ammo_changed(in_mag: int, reserve: int)
signal empty_clicked

@export var mag_size := 8
@export var damage_body := 1
@export var damage_head := 3
@export var fire_cooldown := 0.3
@export var reload_time := 1.35
@export var shot_noise := 1700.0

var actor: Actor
var cam: CameraDirector
var in_mag := 8
var reserve := 8
var active := false
var reloading := false
var bandaging := false
## Testing bot: when set, aims here instead of the mouse.
var bot_aim := Vector2.INF

var _cool := 0.0


func _ready() -> void:
	actor = get_parent() as Actor


func set_active(on: bool) -> void:
	active = on
	actor.rig.aiming = on
	actor.rig.prop_front = "gun" if on else "none"
	ammo_changed.emit(in_mag, reserve)


func _process(dt: float) -> void:
	_cool = maxf(0.0, _cool - dt)
	if not active:
		return
	var rig := actor.rig
	var can_act := actor.alive and not Inputs.input_locked
	rig.aiming = can_act and not reloading and not bandaging
	if not can_act:
		return
	var aim_at := bot_aim if bot_aim != Vector2.INF else get_global_mouse_position()
	var shoulder := actor.global_position + Vector2(0, -320)
	rig.aim_angle = (aim_at - shoulder).angle()
	if absf(aim_at.x - actor.global_position.x) > 20.0:
		rig.facing = int(signf(aim_at.x - actor.global_position.x))
	if bot_aim == Vector2.INF:
		if Input.is_action_just_pressed("shoot") and Inputs.shot_allowed():
			fire()
		if Input.is_action_just_pressed("reload"):
			reload()
		if Input.is_action_just_pressed("bandage"):
			use_bandage()


func fire() -> void:
	if reloading or bandaging or _cool > 0.0 or not actor.alive:
		return
	if in_mag <= 0:
		empty_clicked.emit()
		Audio.sfx("click", actor.global_position + Vector2(0, -300), -4.0)
		_cool = 0.25
		return
	in_mag -= 1
	_cool = fire_cooldown
	var rig := actor.rig
	rig.recoil = 1.0
	var origin := rig.muzzle_global_position()
	var dir := Vector2.from_angle(rig.aim_angle)
	# hit test starts at the shoulder so point-blank shots still connect
	var shoulder := actor.global_position + Vector2(0, -330)
	var hit_dist := 1900.0
	var victim: Actor = null
	var headshot := false
	for z in get_tree().get_nodes_in_group("zombies"):
		var za := z as Actor
		if za == null or not za.alive:
			continue
		var zones: Array = za.rig.hit_zones()
		var th := _ray_circle(shoulder, dir, zones[0], zones[1])
		var tb := _ray_capsule(shoulder, dir, zones[2], zones[3], zones[4])
		var t := minf(th, tb)
		if t < hit_dist:
			hit_dist = t
			victim = za
			headshot = th <= tb
	var end := shoulder + dir * hit_dist
	if hit_dist >= 1900.0:
		end = origin + dir * 1900.0
	_spawn_tracer(origin, end, victim != null)
	_spawn_flash(origin)
	if victim:
		victim.hurt(damage_head if headshot else damage_body, actor.global_position.x)
	if cam:
		cam.shake(5.0)
	Sound.emit(origin, shot_noise, "gunshot")
	ammo_changed.emit(in_mag, reserve)


func reload() -> void:
	if reloading or in_mag >= mag_size or reserve <= 0 or not actor.alive:
		return
	reloading = true
	Audio.sfx("reload", actor.global_position + Vector2(0, -300), -2.0)
	var rig := actor.rig
	rig.reload_t = 0.0
	var tw := create_tween()
	tw.tween_property(rig, "reload_t", 1.0, reload_time)
	await tw.finished
	rig.reload_t = -1.0
	var need := mag_size - in_mag
	var take := mini(need, reserve)
	in_mag += take
	reserve -= take
	reloading = false
	ammo_changed.emit(in_mag, reserve)


func use_bandage() -> void:
	if bandaging or int(Game.flag("bandages", 0)) <= 0 or actor.hp >= actor.max_hp:
		return
	bandaging = true
	Audio.sfx("bandage", actor.global_position + Vector2(0, -300), -2.0)
	actor.rig.pose_front = "chest"
	await get_tree().create_timer(1.4).timeout
	actor.rig.pose_front = "none"
	Game.add("bandages", -1)
	actor.heal(2)
	bandaging = false
	ammo_changed.emit(in_mag, reserve)


static func _ray_circle(o: Vector2, d: Vector2, c: Vector2, r: float) -> float:
	var oc := o - c
	var b := oc.dot(d)
	var cc := oc.dot(oc) - r * r
	var disc := b * b - cc
	if disc < 0.0:
		return INF
	var t := -b - sqrt(disc)
	if t > 0.0:
		return t
	var t2 := -b + sqrt(disc)
	return 0.0 if t2 > 0.0 else INF


static func _ray_capsule(o: Vector2, d: Vector2, a: Vector2, b: Vector2, r: float) -> float:
	# sample along the ray (cheap and good enough for gameplay)
	var best := INF
	var t := 0.0
	while t < 1900.0:
		var p := o + d * t
		var seg := Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_to(seg) <= r:
			best = t
			break
		t += 14.0
	return best


func _spawn_tracer(a: Vector2, b: Vector2, hit: bool) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([a, b])
	line.width = 3.0
	line.default_color = Color(2.2, 1.8, 1.0, 0.9)
	line.z_index = 30
	get_tree().current_scene.add_child(line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.12)
	tw.tween_callback(line.queue_free)
	if hit:
		var puff := _Puff.new()
		puff.global_position = b
		get_tree().current_scene.add_child(puff)


func _spawn_flash(at: Vector2) -> void:
	var l := PointLight2D.new()
	l.texture = Vec.glow_texture()
	l.texture_scale = 4.0
	l.color = Color(1.0, 0.8, 0.45)
	l.energy = 2.2
	l.global_position = at
	get_tree().current_scene.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, 0.1)
	tw.tween_callback(l.queue_free)
	var f := _Flash.new()
	f.global_position = at
	get_tree().current_scene.add_child(f)


class _Flash extends Node2D:
	var t := 0.0
	func _ready() -> void:
		z_index = 31
	func _process(dt: float) -> void:
		t += dt / 0.06
		if t >= 1.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		Vec.glow(self, Vector2.ZERO, 46.0 * (1.0 - t * 0.5), Color(3.0, 2.2, 1.0, 1.0 - t))


class _Puff extends Node2D:
	## Dust/impact puff (stylised, no blood).
	var t := 0.0
	func _ready() -> void:
		z_index = 31
	func _process(dt: float) -> void:
		t += dt / 0.35
		if t >= 1.0:
			queue_free()
		queue_redraw()
	func _draw() -> void:
		for i in 5:
			var a := TAU * i / 5.0 + 0.4
			Vec.circle(self, Vector2.from_angle(a) * 26.0 * t, 9.0 * (1.0 - t), Color(0.85, 0.85, 0.8, 0.7 * (1.0 - t)))
