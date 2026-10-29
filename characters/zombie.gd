class_name Zombie
extends Actor
## Infected: shamble, react to SOUND, chase what they see, lunge to attack.
## They don't see far — noise is what draws them (gunshots, a crying baby,
## running, a ringing phone).

@export var sight := 650.0
@export var hearing_mult := 1.0
@export var attack_range := 95.0
@export var lunge_windup := 0.5
## Hit damage (brutes hit harder).
@export var damage := 1

var state := "idle"
var _attack_t := 0.0
var _cool := 0.0
var _stagger := 0.0
var _wander_t := 0.0
var _victim: Actor = null


func _ready() -> void:
	super._ready()
	add_to_group("zombies")
	rig.zombie = true
	rig.expression = "zombie"
	Sound.heard.connect(_on_noise)
	hurt_taken.connect(func(_a): _stagger = 0.45)
	died.connect(_on_died)
	_wander_t = randf_range(1.0, 3.0)


func _on_noise(pos: Vector2, radius: float, _kind: String) -> void:
	if not alive or state == "chase" or state == "attack":
		return
	var d := Vector2(pos.x - global_position.x, (pos.y - global_position.y) * 0.75).length()
	if d < radius * hearing_mult:
		state = "investigate"
		var f := Nav.floor_at(get_tree(), pos + Vector2(0, 200))
		nav_target = Vector2(pos.x, f.top_y() if f else pos.y + 200)
		nav_run = d < radius * 0.5
		nav_stop = 30.0


var _groan_t := randf_range(1.5, 6.0)

func _physics_process(dt: float) -> void:
	if alive:
		_think(dt)
		_groan_t -= dt
		if _groan_t <= 0.0:
			_groan_t = randf_range(3.5, 8.0) if state != "chase" else randf_range(1.8, 3.5)
			var cam := get_viewport().get_camera_2d()
			if cam and absf(cam.get_screen_center_position().x - global_position.x) < 1600.0:
				Audio.sfx("groan%d" % (randi() % 3), global_position + Vector2(0, -300), -6.0 if state == "chase" else -12.0, 0.15)
	super._physics_process(dt)


func _think(dt: float) -> void:
	_cool = maxf(0.0, _cool - dt)
	if _stagger > 0.0:
		_stagger -= dt
		nav_target = Vector2.INF
		if state == "attack":
			state = "chase"
			rig.pose_front = "none"
			rig.pose_back = "none"
		return
	var tgt := _find_target()
	if state == "attack":
		_attack_t -= dt
		if _attack_t <= 0.0:
			_lunge()
		return
	if tgt:
		state = "chase"
		_victim = tgt
		var same_floor := absf(tgt.last_floor_pos.y - global_position.y) < 40.0 and stair == null and tgt.stair == null
		var dx := tgt.global_position.x - global_position.x
		if same_floor and absf(dx) < attack_range and _cool <= 0.0:
			state = "attack"
			_attack_t = lunge_windup
			nav_target = Vector2.INF
			rig.facing = int(signf(dx)) if dx != 0.0 else rig.facing
			rig.zombie = false
			rig.pose_front = "reach"
			rig.pose_back = "reach"
			return
		nav_target = tgt.last_floor_pos if tgt.stair else tgt.global_position
		nav_stop = attack_range * 0.6
		nav_run = true
	elif state == "chase":
		state = "investigate"
	elif state == "investigate":
		if nav_target == Vector2.INF or absf(nav_target.x - global_position.x) < 40.0:
			state = "idle"
			nav_target = Vector2.INF
	else:
		_wander_t -= dt
		if _wander_t <= 0.0:
			_wander_t = randf_range(2.0, 4.5)
			if randf() < 0.5:
				nav_target = global_position + Vector2(randf_range(-260, 260), 0)
				nav_run = false
				nav_stop = 20.0
			else:
				nav_target = Vector2.INF


func _find_target() -> Actor:
	var best: Actor = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("living"):
		var a := n as Actor
		if a == null or not a.alive:
			continue
		var dx := absf(a.global_position.x - global_position.x)
		var dy := absf(a.global_position.y - global_position.y)
		var d := dx + dy * 1.6
		var eff_sight := sight
		var close := 300.0
		if a.crouching:
			eff_sight *= 0.4
			close = 160.0
		if a.in_cover:
			# fully hidden — unless one was already on top of you when you ducked
			eff_sight = 0.0
			close = 90.0 if state == "chase" and _victim == a else 0.0
		# they only *see* what's in front of them (they still hear everything)
		var in_front := int(signf(a.global_position.x - global_position.x)) == rig.facing
		var visible := (dy < 120.0 and dx < eff_sight and (in_front or dx < 90.0)) or (d < close and (in_front or d < 70.0))
		if (visible or state == "chase" and d < eff_sight * 1.6) and d < best_d:
			best = a
			best_d = d
	return best


## True when this zombie hasn't noticed `who` and faces away (silent takedown).
func unaware_of(who: Actor) -> bool:
	if not alive or state == "chase" or state == "attack":
		return false
	var away := signf(global_position.x - who.global_position.x)
	return int(away) == rig.facing


func _lunge() -> void:
	Audio.sfx("snarl", global_position + Vector2(0, -300), -2.0, 0.15)
	rig.zombie = true
	rig.pose_front = "none"
	rig.pose_back = "none"
	_cool = 1.25
	state = "chase"
	if _victim and _victim.alive:
		var dx := _victim.global_position.x - global_position.x
		velocity.x = signf(dx) * 520.0
		var same_floor := absf(_victim.global_position.y - global_position.y) < 60.0
		if absf(dx) < attack_range + 45.0 and same_floor:
			_victim.hurt(damage, global_position.x)


func _on_died() -> void:
	Audio.sfx("zdie", global_position + Vector2(0, -250), -4.0, 0.15)
	rig.zombie = false
	rig.pose_front = "none"
	rig.pose_back = "none"
	nav_target = Vector2.INF
	remove_from_group("zombies")
	await get_tree().create_timer(4.0).timeout
	if is_inside_tree():
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 1.5)
		tw.tween_callback(queue_free)
