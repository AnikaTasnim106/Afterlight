class_name Actor
extends CharacterBody2D
## A character in the world: physics body + CharacterRig.
##  - player_controlled: A/D walk, Shift run, W/S take stairs.
##  - scripted: walk_to(x) on the same floor (cutscenes).
##  - NPC/AI: set nav_target (or follow_target) and the actor paths across
##    floors and stairs by itself (see core/nav.gd).
## Also holds health, hurt reactions and death.

signal arrived
signal died
signal hurt_taken(amount: int)

@export var player_controlled := false
@export var gravity := 2400.0
@export var accel := 2000.0
@export var decel := 2600.0
@export var max_hp := 5
@export var speed_scale := 1.0
## Running makes noise (rule 2). Only used for the player.
@export var footstep_noise := false

@onready var rig: CharacterRig = $Rig

var hp := 5
var alive := true
var stair: StairFlight = null
var stair_t := 0.0
var stair_dir := 1.0
var nav_target := Vector2.INF
var nav_stop := 40.0
var nav_run := false
var follow_target: Node2D = null
var follow_dist := 180.0
var last_floor_pos := Vector2.ZERO
var running := false
var invulnerable := false
## Sneaking (player holds C): slow, silent, hard to see.
var crouching := false
## Set by the level while crouched behind cover (cars, counters).
var in_cover := false
var can_crouch := false

var _target_x := NAN
var _target_run := false
var _face_after := 0
var _knock := 0.0
var _step_noise_t := 0.0


func _ready() -> void:
	hp = max_hp
	add_to_group("actors")
	last_floor_pos = global_position


func _physics_process(dt: float) -> void:
	if not alive:
		velocity.x = move_toward(velocity.x, 0.0, decel * dt)
		velocity.y += gravity * dt
		move_and_slide()
		rig.velocity_x = 0.0
		return
	if stair:
		_stairs_process(dt)
		return
	var d := rig.design
	var dir := 0.0
	running = false
	if player_controlled and not Inputs.input_locked:
		dir = Input.get_axis("move_left", "move_right")
		crouching = can_crouch and Input.is_action_pressed("crouch")
		running = Input.is_action_pressed("run") and not crouching
		if _try_enter_stairs():
			return
	elif not is_nan(_target_x):
		var dx := _target_x - global_position.x
		var stop_dist := maxf(6.0, absf(velocity.x) * absf(velocity.x) / (2.0 * decel))
		if absf(dx) <= stop_dist:
			dir = 0.0
			if absf(velocity.x) < 30.0:
				_target_x = NAN
				velocity.x = 0.0
				if _face_after != 0:
					rig.facing = _face_after
				arrived.emit()
		else:
			dir = signf(dx)
			running = _target_run
	else:
		dir = _nav_dir()
		running = nav_run
	var max_speed := (d.run_speed if running else d.walk_speed) * speed_scale
	if crouching:
		max_speed *= 0.45
	rig.crouch = move_toward(rig.crouch, 0.75 if crouching else 0.0, dt * 4.0)
	var want := dir * max_speed
	var rate := accel if absf(want) > absf(velocity.x) else decel
	velocity.x = move_toward(velocity.x, want, rate * dt)
	if _knock != 0.0:
		velocity.x += _knock
		_knock = 0.0
	velocity.y += gravity * dt
	move_and_slide()
	rig.velocity_x = velocity.x
	rig.ground_slope = 0.0
	if absf(dir) > 0.1 and not rig.aiming:
		rig.facing = int(signf(dir))
	if is_on_floor():
		last_floor_pos = global_position
	elif OS.get_environment("BOT_TRACE") == "1" and player_controlled == false and name == "Alex" and velocity.y > 900.0 and not has_meta("_fell"):
		set_meta("_fell", true)
		print("FALL DEBUG pos=", global_position, " last_floor=", last_floor_pos, " target_x=", _target_x, " nav=", nav_target)
	_footsteps(dt)


var _step_snd_t := 0.0
var _step_i := 0

func _footsteps(dt: float) -> void:
	# audible steps for Alex (quiet when walking, silent-ish when sneaking)
	if footstep_noise and is_on_floor() and absf(velocity.x) > 60.0:
		_step_snd_t -= dt
		if _step_snd_t <= 0.0:
			_step_snd_t = 0.3 if running else (0.62 if crouching else 0.45)
			_step_i = (_step_i + 1) % 3
			Audio.sfx("step%d" % _step_i, global_position, -4.0 if running else (-20.0 if crouching else -11.0), 0.12)
	if not footstep_noise or not running or absf(velocity.x) < 200.0:
		return
	_step_noise_t -= dt
	if _step_noise_t <= 0.0:
		_step_noise_t = 0.45
		Sound.emit(global_position, 650.0, "footsteps")


# --- scripted movement ---------------------------------------------------------

## Walk (or run) to a world x position on the current floor. `face` = -1/1 to turn when done.
func walk_to(x: float, run := false, face := 0) -> void:
	_target_x = x
	_target_run = run
	_face_after = face


func is_walking() -> bool:
	return not is_nan(_target_x)


func stop_nav() -> void:
	nav_target = Vector2.INF
	follow_target = null


# --- navigation ----------------------------------------------------------------

func _nav_dir() -> float:
	var goal := nav_target
	var stop := nav_stop
	if follow_target:
		goal = follow_target.last_floor_pos if follow_target is Actor else follow_target.global_position
		stop = follow_dist
		# stay put if the leader is close enough on the same floor
		if absf(goal.y - global_position.y) < 30.0 and absf(goal.x - global_position.x) < follow_dist:
			return 0.0
	if goal == Vector2.INF:
		return 0.0
	var step := Nav.next_step(get_tree(), global_position, goal)
	if step.has("stairs"):
		var ex: float = step.x
		if absf(ex - global_position.x) < 14.0:
			attach_stairs(step.stairs, step.end)
			return 0.0
		return signf(ex - global_position.x)
	var dx: float = float(step.walk) - global_position.x
	if absf(dx) <= stop:
		return 0.0
	return signf(dx)


# --- stairs --------------------------------------------------------------------

func _try_enter_stairs() -> bool:
	var up := Input.is_action_pressed("move_up")
	var down_pressed := Input.is_action_pressed("move_down")
	if not up and not down_pressed:
		return false
	for n in get_tree().get_nodes_in_group("stairs"):
		var fl := n as StairFlight
		if up and global_position.distance_to(fl.ga()) < 60.0:
			attach_stairs(fl, "a")
			return true
		if down_pressed and global_position.distance_to(fl.gb()) < 60.0:
			attach_stairs(fl, "b")
			return true
	return false


func attach_stairs(fl: StairFlight, from_end: String) -> void:
	stair = fl
	stair_t = 0.0 if from_end == "a" else 1.0
	stair_dir = 1.0 if from_end == "a" else -1.0
	velocity = Vector2.ZERO
	set_collision_mask_value(1, false)


func _stairs_process(dt: float) -> void:
	var a := stair.ga()
	var b := stair.gb()
	var L := maxf(1.0, a.distance_to(b))
	var input_dir := 0.0
	running = false
	if player_controlled:
		if not Inputs.input_locked:
			var ax := Input.get_axis("move_left", "move_right")
			var vy := Input.get_axis("move_down", "move_up")
			input_dir = clampf(ax * signf(b.x - a.x) + vy, -1.0, 1.0)
			running = Input.is_action_pressed("run")
	elif alive:
		input_dir = stair_dir
		running = nav_run
	var d := rig.design
	var spd := (d.run_speed if running else d.walk_speed) * 0.78 * speed_scale
	stair_t += input_dir * spd * dt / L
	var t := clampf(stair_t, 0.0, 1.0)
	global_position = a.lerp(b, t)
	var hv := (b.x - a.x) / L * input_dir * spd
	velocity = Vector2(hv, (b.y - a.y) / L * input_dir * spd)
	rig.velocity_x = hv
	rig.ground_slope = stair.slope()
	if absf(hv) > 1.0 and not rig.aiming:
		rig.facing = int(signf(hv))
	if stair_t >= 1.0:
		_leave_stairs(b)
	elif stair_t <= 0.0:
		_leave_stairs(a)
	_footsteps(dt)


func _leave_stairs(at: Vector2) -> void:
	stair = null
	global_position = at + Vector2(0, -2)
	set_collision_mask_value(1, true)
	rig.ground_slope = 0.0
	last_floor_pos = at


# --- health ----------------------------------------------------------------------

func hurt(amount: int, from_x: float) -> void:
	if not alive or invulnerable:
		return
	hp -= amount
	rig.flinch = 1.0
	rig.hurt_flash = 1.0
	_knock = signf(global_position.x - from_x) * 260.0
	hurt_taken.emit(amount)
	if not is_in_group("zombies"):
		Audio.sfx("hurt", global_position + Vector2(0, -300), -1.0)
	else:
		Audio.sfx("takedown", global_position + Vector2(0, -300), -12.0, 0.2)
	if hp <= 0:
		die(signf(global_position.x - from_x))


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)


func die(push_dir := 1.0) -> void:
	if not alive:
		return
	alive = false
	stair = null
	set_collision_mask_value(1, true)
	set_collision_layer_value(2, false)
	rig.talking = false
	rig.aiming = false
	# fall away from the hit
	rig.down_dir = 1.0 if signf(push_dir) == float(rig.facing) else -1.0
	var tw := create_tween()
	tw.tween_property(rig, "down", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	died.emit()
