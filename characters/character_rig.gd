@tool
class_name CharacterRig
extends Node2D
## Procedural vector character.
##
## The rig computes a skeleton every frame (hip, spine, neck, head, 2 arms,
## 2 legs) and draws clothing/skin shapes along the bones.
##  - Locomotion: feet follow a gait curve and legs are solved with 2-bone IK,
##    so feet plant on the ground instead of sliding.
##  - Arms: FK swing while walking, blended with named poses (hold_radio,
##    point, phone...) for acting.
##  - Face: expression presets blend smoothly; blinking and mouth flaps are
##    automatic.
##  - Turning: the body squashes through the turn and the head leads.
## Origin = ground point under the character. Drawn facing +X, flipped by `facing`.
## Everything renders live in the editor (it is a @tool script).

signal turned

@export var design: CharacterDesign:
	set(v):
		design = v
		queue_redraw()

@export_range(-1, 1, 2) var facing := 1:
	set(v):
		v = -1 if v < 0 else 1
		if v != facing:
			facing = v
			_start_turn()

@export_enum("neutral", "smile", "happy", "worried", "scared", "sad", "surprised", "determined", "angry", "curious", "tired") var expression := "neutral"

@export var talking := false
@export_enum("none", "hold_radio", "radio_ear", "point", "phone", "open_hand", "reach", "chest", "fist", "wave", "shrug") var pose_front := "none"
@export_enum("none", "hold_radio", "point", "open_hand", "reach", "chest", "wave", "shrug") var pose_back := "none"
@export_enum("none", "radio", "phone", "mug") var prop_front := "none"
## -1..1 where the eyes look (x is along facing, y down).
@export var look := Vector2.ZERO
@export_range(0.0, 1.0) var crouch := 0.0
@export var preview_walk_speed := 0.0

## Set every frame by the owning Actor (signed px/s in world space).
var velocity_x := 0.0

# --- gameplay states (set by Actor / combat / AI) ---
var ground_slope := 0.0     ## world dy/dx under the feet (stairs)
var limp := 0.0             ## 0..1 injured-leg gait
var zombie := false         ## shambling gait, drooping arms
var aiming := false
var aim_angle := 0.0        ## world radians
var recoil := 0.0
var reload_t := -1.0        ## 0..1 while reloading
var flinch := 0.0
var down := 0.0             ## 0 standing .. 1 lying down
var down_dir := 1.0         ## +1 falls forward, -1 backward
var sit := 0.0
var carry := ""             ## "baby"
var baby_crying := false
var hurt_flash := 0.0
var _aim_w := 0.0
var _reload_w := 0.0
var _carry_w := 0.0
var _zombie_jitter := 0.0

# --- runtime state -----------------------------------------------------------
var _time := 0.0
var _gait := 0.0
var _move := 0.0
var _run := 0.0
var _vis := 1.0
var _turn_p := 1.0
var _turn_from := 1.0
var _head_sign := 1.0
var _face := {}
var _blink := 0.0
var _blink_next := 2.0
var _mouth_flap := 0.0
var _flap_timer := 0.0
var _flap_target := 0.0
var _gesture := ""
var _gesture_timer := 0.0
var _pw_front := 0.0
var _pw_back := 0.0
var _pa_front := Vector2.ZERO
var _pa_back := Vector2.ZERO
var _head_lag := 0.0
var _prev_vel := 0.0
var _rng := RandomNumberGenerator.new()
var _pony: Array[Vector2] = []
var _pony_vel: Array[Vector2] = []

# skeleton (body space, facing +X)
var J := {}

const EXPR := {
	"neutral":    {"by": 0.0,  "bt": 0.0,  "ba": 0.0, "eo": 1.0,  "es": 0.0, "mc": 0.12, "mo": 0.0,  "mw": 1.0},
	"smile":      {"by": 0.1,  "bt": 0.0,  "ba": 0.0, "eo": 0.95, "es": 0.35, "mc": 0.6,  "mo": 0.05, "mw": 1.05},
	"happy":      {"by": 0.25, "bt": 0.0,  "ba": 0.0, "eo": 0.9,  "es": 0.9, "mc": 0.9,  "mo": 0.25, "mw": 1.15},
	"worried":    {"by": 0.15, "bt": 0.85, "ba": 0.0, "eo": 1.05, "es": 0.0, "mc": -0.35, "mo": 0.0, "mw": 0.8},
	"scared":     {"by": 0.55, "bt": 0.6,  "ba": 0.0, "eo": 1.3,  "es": 0.0, "mc": -0.4, "mo": 0.45, "mw": 0.72},
	"sad":        {"by": 0.0,  "bt": 0.95, "ba": 0.0, "eo": 0.72, "es": 0.0, "mc": -0.6, "mo": 0.0,  "mw": 0.8},
	"surprised":  {"by": 0.8,  "bt": 0.1,  "ba": 0.0, "eo": 1.3,  "es": 0.0, "mc": 0.0,  "mo": 0.7,  "mw": 0.5},
	"determined": {"by": -0.25, "bt": -0.7, "ba": 0.0, "eo": 0.9, "es": 0.0, "mc": -0.1, "mo": 0.0,  "mw": 0.9},
	"angry":      {"by": -0.4, "bt": -1.0, "ba": 0.0, "eo": 0.95, "es": 0.0, "mc": -0.55, "mo": 0.1, "mw": 0.9},
	"curious":    {"by": 0.3,  "bt": 0.2,  "ba": 0.7, "eo": 1.08, "es": 0.0, "mc": 0.2,  "mo": 0.0,  "mw": 0.7},
	"tired":      {"by": -0.1, "bt": 0.3,  "ba": 0.0, "eo": 0.5,  "es": 0.0, "mc": -0.1, "mo": 0.0,  "mw": 0.9},
	"hurt":       {"by": 0.3,  "bt": 0.9,  "ba": 0.0, "eo": 0.55, "es": 0.0, "mc": -0.7, "mo": 0.35, "mw": 0.85},
	"relieved":   {"by": 0.2,  "bt": 0.5,  "ba": 0.0, "eo": 0.8,  "es": 0.3, "mc": 0.45, "mo": 0.05, "mw": 1.0},
	"zombie":     {"by": -0.15, "bt": 0.5, "ba": 0.3, "eo": 1.05, "es": 0.0, "mc": -0.35, "mo": 0.4, "mw": 0.75},
}

## Arm poses: x = upper arm angle from straight down (+ = forward),
## y = elbow flex (+ = forearm folds forward).
const POSES := {
	"hold_radio": Vector2(0.35, 1.35),
	"radio_ear": Vector2(0.55, 2.45),
	"point": Vector2(1.45, 0.08),
	"phone": Vector2(0.3, 1.7),
	"open_hand": Vector2(0.6, 0.95),
	"reach": Vector2(1.05, 0.25),
	"chest": Vector2(0.35, 2.05),
	"fist": Vector2(0.25, 1.9),
	"wave": Vector2(0.9, 2.2),
	"shrug": Vector2(0.45, 1.3),
}

const GESTURES := ["open_hand", "open_hand", "chest", "", "point", ""]


func _ready() -> void:
	_rng.seed = hash(name)
	_vis = float(facing)
	_head_sign = float(facing)
	_face = EXPR["neutral"].duplicate()
	set_process(true)


# --- public helpers -----------------------------------------------------------

func say_beat() -> void:
	## Small head nod — call on emphasised words.
	_head_lag -= 0.06


func is_turning() -> bool:
	return _turn_p < 1.0


func head_global_position() -> Vector2:
	if J.is_empty():
		return global_position + Vector2(0, -400)
	return to_global(Vector2(J.head.x * _vis, J.head.y))


func _start_turn() -> void:
	_turn_from = _vis
	_turn_p = 0.0


# --- simulation ---------------------------------------------------------------

func _process(dt: float) -> void:
	if design == null:
		return
	dt = minf(dt, 0.05)
	_time += dt
	var vx := velocity_x
	if Engine.is_editor_hint() and preview_walk_speed != 0.0:
		vx = preview_walk_speed * facing
	_simulate(dt, vx)
	_solve()
	_update_ponytail(dt)
	queue_redraw()


func _simulate(dt: float, vx: float) -> void:
	var d := design
	recoil = move_toward(recoil, 0.0, dt * 6.0)
	flinch = move_toward(flinch, 0.0, dt * 3.0)
	hurt_flash = move_toward(hurt_flash, 0.0, dt * 3.5)
	_aim_w = move_toward(_aim_w, 1.0 if aiming else 0.0, dt * 7.0)
	_reload_w = move_toward(_reload_w, 1.0 if reload_t >= 0.0 else 0.0, dt * 8.0)
	_carry_w = move_toward(_carry_w, 1.0 if carry != "" else 0.0, dt * 5.0)
	if zombie:
		_zombie_jitter = sin(_time * 2.3) * 0.5 + sin(_time * 5.1 + 1.0) * 0.5
	modulate = Color(1.0, 1.0 - hurt_flash * 0.6, 1.0 - hurt_flash * 0.6)
	var speed: float = absf(vx)
	_move = move_toward(_move, clampf(speed / 60.0, 0.0, 1.0), dt * 5.0)
	_run = move_toward(_run, clampf((speed - d.walk_speed * 1.15) / (d.run_speed - d.walk_speed * 1.15), 0.0, 1.0), dt * 4.0)

	# Gait phase: one full cycle = two steps. Stride matched to speed so planted feet don't slide.
	var stride := _stride()
	if speed > 1.0:
		var irregular := (1.0 + 0.45 * _zombie_jitter) if zombie else 1.0
		if limp > 0.0:
			irregular *= 1.0 - 0.35 * limp * maxf(0.0, sin(_gait * TAU))
		_gait += speed * dt / (2.0 * stride) * irregular
	else:
		# settle into a neutral phase when stopping
		_gait = lerpf(_gait, roundf(_gait * 2.0) / 2.0, dt * 3.0)

	# Turning
	if _turn_p < 1.0:
		_turn_p = minf(1.0, _turn_p + dt / 0.2)
		var e := _turn_p * _turn_p * (3.0 - 2.0 * _turn_p)
		_vis = lerpf(_turn_from, float(facing), e)
		if _turn_p > 0.3:
			_head_sign = float(facing)
		if _turn_p >= 1.0:
			turned.emit()
	else:
		_vis = float(facing)
		_head_sign = float(facing)

	# Head lag from acceleration (secondary motion)
	var accel := (vx - _prev_vel) / maxf(dt, 0.001)
	_prev_vel = vx
	_head_lag = lerpf(_head_lag, clampf(-accel * facing * 0.00004, -0.08, 0.08), dt * 6.0)

	# Face blending
	var target: Dictionary = EXPR.get(expression, EXPR["neutral"])
	for k in target:
		_face[k] = lerpf(float(_face.get(k, target[k])), float(target[k]), clampf(dt * 9.0, 0.0, 1.0))

	# Blink
	_blink_next -= dt
	if _blink_next <= 0.0:
		_blink = 1.0
		_blink_next = _rng.randf_range(1.8, 4.6)
	_blink = maxf(0.0, _blink - dt / 0.14)

	# Mouth flaps while talking
	if talking:
		_flap_timer -= dt
		if _flap_timer <= 0.0:
			_flap_timer = _rng.randf_range(0.06, 0.13)
			_flap_target = 0.0 if _rng.randf() < 0.22 else _rng.randf_range(0.25, 0.85)
	else:
		_flap_target = 0.0
	_mouth_flap = lerpf(_mouth_flap, _flap_target, clampf(dt * 22.0, 0.0, 1.0))

	# Talking gestures (only when no explicit pose)
	if talking and pose_front == "none":
		_gesture_timer -= dt
		if _gesture_timer <= 0.0:
			_gesture_timer = _rng.randf_range(1.1, 2.2)
			_gesture = GESTURES[_rng.randi() % GESTURES.size()]
	elif not talking:
		_gesture = ""

	var want_f := pose_front if pose_front != "none" else (_gesture if _move < 0.5 else "")
	var want_b := pose_back if pose_back != "none" else ""
	_pw_front = move_toward(_pw_front, 1.0 if want_f != "" else 0.0, dt * 4.5)
	_pw_back = move_toward(_pw_back, 1.0 if want_b != "" else 0.0, dt * 4.5)
	if want_f != "":
		_pa_front = _pa_front.lerp(POSES[want_f], clampf(dt * 8.0, 0.0, 1.0))
	if want_b != "":
		_pa_back = _pa_back.lerp(POSES[want_b], clampf(dt * 8.0, 0.0, 1.0))


func _stride() -> float:
	var d := design
	return lerpf(lerp(70.0, 112.0, _move), 175.0, _run) * (d.leg_len() / 202.0) * lerpf(1.0, d.bounce, 0.5)


static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _foot_offset(t: float, stride: float, lift: float) -> Vector3:
	## returns (x, y, rotation) of the ankle relative to the hip line
	t = fposmod(t, 1.0)
	if t < 0.5:
		var u := t / 0.5
		return Vector3(lerpf(stride * 0.5, -stride * 0.5, u), 0.0, -0.18 * _ease(clampf((u - 0.7) / 0.3, 0.0, 1.0)))
	var u2 := (t - 0.5) / 0.5
	var x: float = lerpf(-stride * 0.5, stride * 0.5, _ease(u2))
	var y := -lift * sin(PI * u2)
	var rot := 0.35 * sin(PI * u2) - 0.18 * (1.0 - u2)
	return Vector3(x, y, rot)


func _solve() -> void:
	var d := design
	var t := _gait
	var stride := _stride()
	var lift: float = lerpf(lerp(14.0, 26.0, _move), 46.0, _run) * d.bounce
	var ankle_h := d.shoe_h * 0.55
	var L := d.leg_len()

	# Hips: bob twice per cycle (lowest on contact, highest on passing)
	var bob := lerpf(lerp(0.0, 7.0, _move), 14.0, _run) * d.bounce * (0.5 - 0.5 * cos(t * TAU * 2.0))
	var breathe := sin(_time * 1.9) * 1.2 * (1.0 - _move)
	var sway := sin(_time * 0.7) * 2.5 * (1.0 - _move)
	var hip_y := -(L * lerpf(0.985, 0.95, _move) - lerpf(0.0, 0.06, _run) * L - crouch * L * 0.28 + ankle_h) - bob + breathe * 0.3
	hip_y += limp * 11.0 * maxf(0.0, sin(t * TAU)) * _move
	hip_y += absf(ground_slope) * stride * 0.3
	# sitting: hips drop to seat height
	var seat_h := d.shin + ankle_h + 6.0
	hip_y = lerpf(hip_y, -seat_h, sit)
	var hip := Vector2(lerpf(sway + _run * 8.0, -d.thigh * 0.15, sit), hip_y)

	# Spine
	var lean := 0.04 * _move + 0.2 * _run + crouch * 0.35 + _head_lag * 0.5 + d.posture
	if zombie:
		lean += 0.22 + 0.06 * _zombie_jitter
	lean += limp * 0.08 - flinch * 0.3 - sit * 0.08
	lean += sin(t * TAU * 2.0) * 0.015 * _move
	var up := Vector2(sin(lean), -cos(lean))
	var fwd := Vector2(-up.y, up.x) # up rotated +90deg -> points forward
	var torso := d.torso_len * (1.0 + 0.012 * sin(_time * 1.9) * (1.0 - _move))
	var chest := hip + up * torso
	var neck := chest + up * d.neck_len

	# Head
	var nod := sin(_time * 5.3) * 0.025 * (1.0 if talking else 0.0)
	var head_tilt := lean * 0.45 + nod + look.y * 0.14 - _head_lag + sin(_time * 0.9) * 0.015
	if zombie:
		head_tilt += 0.18 + sin(_time * 1.3) * 0.14
	var head_up := Vector2(sin(head_tilt), -cos(head_tilt))
	var head := neck + head_up * d.head_radius * 0.92

	# Legs (IK)
	var legs := {}
	for side in ["b", "f"]:
		var phase := 0.0 if side == "b" else 0.5
		var g := _foot_offset(t + phase, stride, lift)
		var idle_x := 13.0 if side == "f" else -11.0
		var fx: float = lerpf(idle_x + sway * 0.5, g.x + hip.x, _move)
		var fy: float = lerpf(0.0, g.y, _move) - ankle_h
		var frot: float = lerpf(0.0, g.z, _move)
		fy += ground_slope * float(facing) * fx
		frot += atan(ground_slope * float(facing)) * 0.7
		if sit > 0.0:
			fx = lerpf(fx, d.thigh * 0.72 + (8.0 if side == "f" else -6.0), sit)
			fy = lerpf(fy, -ankle_h, sit)
		var hj := hip + fwd * (3.0 if side == "f" else -3.0)
		var target := Vector2(fx, fy)
		var knee := _ik(hj, target, d.thigh, d.shin, fwd)
		var ankle := knee + (target - knee).normalized() * d.shin
		legs[side] = {"hip": hj, "knee": knee, "ankle": ankle, "rot": frot}

	# Arms (FK + pose blend)
	var arms := {}
	for side in ["b", "f"]:
		var leg_phase := 0.0 if side == "f" else 0.5 # opposite to same-side leg
		var s := -cos((t + leg_phase) * TAU)
		var swing_amp := lerpf(lerp(0.0, 0.42, _move), 0.95, _run)
		var upper := 0.07 + s * swing_amp + sin(_time * 1.3 + (0.0 if side == "f" else 1.7)) * 0.02 * (1.0 - _move)
		var elbow := 0.18 + maxf(0.0, s) * 0.45 * _move + _run * 1.25 + crouch * 0.4
		var w := _pw_front if side == "f" else _pw_back
		var pa := _pa_front if side == "f" else _pa_back
		upper = lerpf(upper, pa.x - lean, w)
		elbow = lerpf(elbow, pa.y, w)
		if zombie:
			var zs := sin(_time * 1.7 + (0.0 if side == "f" else 2.1)) * 0.12
			upper = 0.5 - lean + zs * 1.4 + s * 0.1
			elbow = 0.3 + zs * 0.6
		if _carry_w > 0.0:
			var cp := Vector2(0.45, 2.0) if side == "f" else Vector2(0.25, 2.15)
			upper = lerpf(upper, cp.x - lean, _carry_w)
			elbow = lerpf(elbow, cp.y, _carry_w)
		if _aim_w > 0.0:
			var wd := Vector2.from_angle(aim_angle)
			var bd := Vector2(wd.x * float(facing), wd.y)
			var a_down := atan2(bd.x, bd.y)
			var au := a_down - lean + recoil * 0.45
			var ae := 0.06 + recoil * 0.35
			if side == "b":
				au = a_down - lean - 0.1
				ae = 0.42
			upper = lerpf(upper, au, _aim_w)
			elbow = lerpf(elbow, ae, _aim_w)
		if _reload_w > 0.0:
			var rp := Vector2(0.55, 1.55)
			if side == "b":
				rp = Vector2(-0.15, 0.3) if reload_t < 0.55 else Vector2(0.5, 1.75)
			upper = lerpf(upper, rp.x - lean, _reload_w)
			elbow = lerpf(elbow, rp.y, _reload_w)
		var sh := chest - up * 10.0 + fwd * (-d.shoulder_half * 0.12 if side == "f" else d.shoulder_half * 0.18)
		var a1 := upper + lean
		var e := sh + Vector2(sin(a1), cos(a1)) * d.upper_arm
		var a2 := a1 + elbow
		var wr := e + Vector2(sin(a2), cos(a2)) * d.forearm
		if sit > 0.0 and _aim_w < 0.5 and _carry_w < 0.5 and w < 0.5:
			# hands rest on the knees
			var knee_target: Vector2 = legs[side].knee
			var reach_dir := (knee_target - sh)
			var ua := atan2(reach_dir.x, reach_dir.y)
			upper = lerpf(upper, ua - 0.25, sit)
			elbow = lerpf(elbow, 0.55, sit)
			a1 = upper + lean
			e = sh + Vector2(sin(a1), cos(a1)) * d.upper_arm
			a2 = a1 + elbow
			wr = e + Vector2(sin(a2), cos(a2)) * d.forearm
		arms[side] = {"sh": sh, "el": e, "wr": wr, "a2": a2}

	J = {"hip": hip, "chest": chest, "neck": neck, "head": head, "tilt": head_tilt,
		"up": up, "fwd": fwd, "legs": legs, "arms": arms, "lean": lean, "stride": stride}


func _ik(a: Vector2, t: Vector2, l1: float, l2: float, prefer: Vector2) -> Vector2:
	var dv := t - a
	var dist: float = clampf(dv.length(), absf(l1 - l2) + 0.5, l1 + l2 - 0.5)
	var base := dv.angle()
	var c: float = clampf((l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist), -1.0, 1.0)
	var off := acos(c)
	var k1 := a + Vector2.from_angle(base + off) * l1
	var k2 := a + Vector2.from_angle(base - off) * l1
	return k1 if (k1 - a).dot(prefer) > (k2 - a).dot(prefer) else k2


func _update_ponytail(dt: float) -> void:
	if design.hair_style != 1 or J.is_empty():
		return
	var r := design.head_radius
	var anchor: Vector2 = J.head + Vector2(-0.9 * r, -0.5 * r).rotated(J.tilt)
	var seg := r * 0.42
	if _pony.size() != 4:
		_pony.clear()
		_pony_vel.clear()
		for i in 4:
			_pony.append(anchor + Vector2(-seg * i * 0.6, seg * i))
			_pony_vel.append(Vector2.ZERO)
	_pony[0] = anchor
	# body-space velocity of the world moving past us (fake inertia)
	for i in range(1, 4):
		var p := _pony[i]
		var v := _pony_vel[i]
		v += Vector2(-absf(velocity_x) * 2.2 - 60.0, 1100.0) * dt
		v *= 0.86
		p += v * dt
		# keep segment length
		var dir := (p - _pony[i - 1])
		if dir.length() < 0.001:
			dir = Vector2(-0.3, 1)
		p = _pony[i - 1] + dir.normalized() * seg
		# stay behind the head
		p.x = minf(p.x, _pony[i - 1].x + seg * 0.2)
		_pony_vel[i] = (p - _pony[i]) / maxf(dt, 0.001) * 0.9
		_pony[i] = p


# --- drawing ------------------------------------------------------------------

func _draw() -> void:
	if design == null or J.is_empty():
		return
	var d := design
	# ground shadow (not flipped)
	var sw: float = d.hip_half * 2.2 + J.stride * 0.35 * _move
	draw_set_transform(Vector2.ZERO)
	Vec.ellipse(self, Vector2(0, 2), sw * 0.62 * (1.0 + down * 1.6), 9.0, Color(0, 0, 0, 0.28))

	# falling over: rotate the whole body about the feet
	var e := down * down * (3.0 - 2.0 * down)
	var vs := _vis_scale()
	var rot := e * PI * 0.5 * down_dir * signf(vs)
	var origin := Vector2(0, -e * d.leg_radius * 1.3)
	draw_set_transform(origin, rot, Vector2(vs, 1.0))
	_draw_arm("b")
	_draw_leg("b")
	_draw_hood_back()
	_draw_leg("f")
	_draw_torso()
	_draw_tears()
	_draw_holster()
	_draw_neck_accessories()
	if _carry_w > 0.5 and carry == "baby":
		_draw_baby()
	# head uses its own flip so it can lead the turn
	var hs := _head_sign * maxf(absf(_vis), 0.72)
	var head_screen := Vector2(J.head.x * vs, J.head.y)
	draw_set_transform(origin, rot, Vector2(1, 1))
	_draw_head(head_screen, hs)
	draw_set_transform(origin, rot, Vector2(vs, 1.0))
	_draw_arm("f")
	draw_set_transform(Vector2.ZERO)


## World position of the gun muzzle (for bullets / flashes).
func muzzle_global_position() -> Vector2:
	if J.is_empty():
		return global_position + Vector2(0, -330)
	var A: Dictionary = J.arms["f"]
	var dir := Vector2(sin(A.a2), cos(A.a2))
	var p: Vector2 = A.wr + dir * 40.0
	return to_global(Vector2(p.x * _vis_scale(), p.y))


## Rough body hit zones in world space: [head_center, head_radius, torso_a, torso_b, torso_radius]
func hit_zones() -> Array:
	if J.is_empty():
		return [global_position + Vector2(0, -380), 50.0, global_position + Vector2(0, -200), global_position + Vector2(0, -320), 45.0]
	var vs := _vis_scale()
	var f := func(p: Vector2) -> Vector2: return to_global(Vector2(p.x * vs, p.y))
	return [f.call(J.head), design.head_radius * 1.05, f.call(J.hip), f.call(J.chest), design.shoulder_half * 0.95]


func _draw_baby() -> void:
	var A: Dictionary = J.arms["f"]
	var B: Dictionary = J.arms["b"]
	var c: Vector2 = (A.wr + B.wr) * 0.5 + J.up * 14.0
	var shake := Vector2(sin(_time * 40.0), 0) * (1.5 if baby_crying else 0.0)
	Vec.ellipse(self, c + shake, 44, 26, Color("cfe3ea"), J.lean + 0.25)
	Vec.ellipse(self, c + shake + Vector2(-8, 4), 34, 18, Color("b6d2dc"), J.lean + 0.25)
	var hc: Vector2 = c + J.fwd * 34.0 + J.up * 12.0 + shake
	Vec.circle(self, hc, 17, Color("e2b394"))
	Vec.fill(self, Vec.ellipse_pts(hc + Vector2(-4, -8), 16, 10), Color("cfe3ea"))
	if baby_crying:
		Vec.ellipse(self, hc + Vector2(6, 6), 5, 4 + absf(sin(_time * 9.0)) * 3.0, Color("6a2a2a"))
		Vec.stroke(self, PackedVector2Array([hc + Vector2(-2, -1), hc + Vector2(4, 1)]), Color("3a2a2a"), 2.0)
		Vec.stroke(self, PackedVector2Array([hc + Vector2(8, -1), hc + Vector2(13, -2)]), Color("3a2a2a"), 2.0)
	else:
		Vec.stroke(self, Vec.qbez(hc + Vector2(-2, 0), hc + Vector2(2, 3), hc + Vector2(6, 0), 5), Color("3a2a2a"), 2.0)
		Vec.stroke(self, Vec.qbez(hc + Vector2(8, 0), hc + Vector2(11, 3), hc + Vector2(14, 0), 5), Color("3a2a2a"), 2.0)


func _vis_scale() -> float:
	# never fully collapse to zero width mid-turn
	if absf(_vis) < 0.12:
		return 0.12 * (signf(_vis) if _vis != 0.0 else float(facing))
	return _vis


func _draw_leg(side: String) -> void:
	var d := design
	var L: Dictionary = J.legs[side]
	var dark := 0.28 if side == "b" else 0.0
	var pants := Vec.shade(d.pants, dark)
	var lr := d.leg_radius
	Vec.capsule(self, L.hip, L.knee, lr, lr * 0.9, pants)
	Vec.capsule(self, L.knee, L.ankle, lr * 0.9, lr * 0.74, pants)
	# subtle knee crease
	if side == "f":
		Vec.circle(self, L.knee, lr * 0.25, Vec.shade(pants, 0.12))
	if d.bandaged_leg and side == "f":
		for k in 3:
			var p: Vector2 = L.knee.lerp(L.ankle, 0.3 + k * 0.16)
			var n: Vector2 = (L.ankle - L.knee).normalized()
			Vec.capsule(self, p - Vector2(-n.y, n.x) * lr * 0.95, p + Vector2(-n.y, n.x) * lr * 0.95, 4.5, 4.5, Color("e9e4da"))
		Vec.circle(self, L.knee.lerp(L.ankle, 0.46), 4.0, Color("b5554a"))
	_draw_shoe(L.ankle, L.rot, Vec.shade(d.shoes, dark), Vec.shade(d.shoe_accent, dark))


func _draw_shoe(ankle: Vector2, rot: float, col: Color, acc: Color) -> void:
	var d := design
	var l := d.shoe_len
	var h := d.shoe_h
	var pts := PackedVector2Array([
		Vector2(-0.3 * l, -0.55 * h), Vector2(-0.36 * l, -0.1 * h), Vector2(-0.34 * l, 0.45 * h),
		Vector2(0.62 * l, 0.45 * h), Vector2(0.76 * l, 0.18 * h), Vector2(0.68 * l, -0.18 * h),
		Vector2(0.38 * l, -0.42 * h), Vector2(0.05 * l, -0.62 * h),
	])
	Vec.fill(self, Vec.xform(pts, ankle, rot, 1.0), col)
	var sole := PackedVector2Array([Vector2(-0.35 * l, 0.25 * h), Vector2(0.72 * l, 0.25 * h), Vector2(0.7 * l, 0.45 * h), Vector2(-0.34 * l, 0.45 * h)])
	Vec.fill(self, Vec.xform(sole, ankle, rot, 1.0), acc)


func _draw_arm(side: String) -> void:
	var d := design
	var A: Dictionary = J.arms[side]
	var dark := 0.28 if side == "b" else 0.0
	var sleeve := Vec.shade(d.sleeve, dark)
	var ar := d.arm_radius
	Vec.capsule(self, A.sh, A.el, ar * 1.08, ar * 0.98, sleeve)
	var cuff: Vector2 = A.el.lerp(A.wr, 0.86)
	Vec.capsule(self, A.el, cuff, ar * 0.98, ar * 0.86, sleeve)
	var cuff_col := Vec.shade(d.top_accent if d.top_style == 0 else d.sleeve, dark + 0.15)
	Vec.capsule(self, A.el.lerp(A.wr, 0.78), cuff, ar * 0.9, ar * 0.88, cuff_col)
	var hand_c: Vector2 = A.wr + Vector2(sin(A.a2), cos(A.a2)) * d.hand_radius * 0.35
	var skin := Vec.shade(d.skin, dark)
	if side == "f" and prop_front != "none":
		_draw_prop(prop_front, hand_c, A.a2)
	Vec.circle(self, hand_c, d.hand_radius, skin)
	# thumb nub
	Vec.circle(self, hand_c + Vector2(cos(A.a2), -sin(A.a2)) * d.hand_radius * 0.75, d.hand_radius * 0.42, skin)


func _draw_prop(kind: String, at: Vector2, ang: float) -> void:
	var d := design
	var rot := -ang + PI # align with forearm, pointing away from elbow
	match kind:
		"gun", "rifle":
			var dir := Vector2(sin(ang), cos(ang))
			var perp := Vector2(dir.y, -dir.x)
			if perp.y < 0.0:
				perp = -perp
			if kind == "gun":
				Vec.capsule(self, at - dir * 10.0 - perp * 6.0, at + dir * 46.0 - perp * 6.0, 8.5, 7.5, Color("2c2d33"))
				Vec.line(self, at + dir * 4.0 - perp * 10.0, at + dir * 40.0 - perp * 10.0, Color("4a4c55"), 2.5)
				Vec.capsule(self, at - dir * 4.0, at - dir * 9.0 + perp * 20.0, 7.5, 6.5, Color("1c1c20"))
			else:
				Vec.capsule(self, at - dir * 40.0, at + dir * 70.0, 6.5, 5.0, Color("34382c"))
				Vec.capsule(self, at - dir * 50.0, at - dir * 30.0 + perp * 10.0, 8.0, 7.0, Color("2a2d24"))
				Vec.capsule(self, at + dir * 10.0, at + dir * 10.0 + perp * 22.0, 5.0, 4.5, Color("1c1d18"))
		"can":
			Vec.rrect(self, Rect2(at + Vector2(-22, 0), Vector2(44, 58)), 6, Color("c0342a"))
			Vec.rect(self, Rect2(at + Vector2(-12, -10), Vector2(16, 12)), Color("2a2c31"))
		"bat":
			var dir := Vector2(sin(ang), cos(ang))
			Vec.capsule(self, at - dir * 10.0, at + dir * 90.0, 5.0, 9.0, Color("9a7a52"))
		"case":
			Vec.rrect(self, Rect2(at + Vector2(-30, 4), Vector2(60, 44)), 6, Color("c9ccd1"))
			Vec.rect(self, Rect2(at + Vector2(-30, 20), Vector2(60, 6)), Color("8f949b"))
			Vec.rect(self, Rect2(at + Vector2(-8, 26), Vector2(16, 10)), Color(0.9, 0.3, 0.25))
		"radio":
			var body := PackedVector2Array(Vec.rrect_pts(Rect2(-13, -40, 26, 52), 6))
			Vec.fill(self, Vec.xform(body, at, rot * 0.0 + 0.15, 1.0), Color("3a3d42"))
			Vec.fill(self, Vec.xform(PackedVector2Array(Vec.rrect_pts(Rect2(-8, -32, 16, 10), 2)), at, 0.15, 1.0), Color(0.35, 1.4, 0.9))
			Vec.line(self, at + Vector2(6, -40).rotated(0.15), at + Vector2(9, -78).rotated(0.15), Color("2b2d31"), 4.0)
			Vec.circle(self, at + Vector2(9, -79).rotated(0.15), 3.5, Color("e3a03c"))
			for i in 3:
				Vec.line(self, at + Vector2(-7, -14 + i * 6).rotated(0.15), at + Vector2(7, -14 + i * 6).rotated(0.15), Color("2b2d31"), 2.0)
		"phone":
			var b := PackedVector2Array(Vec.rrect_pts(Rect2(-9, -34, 18, 34), 4))
			Vec.fill(self, Vec.xform(b, at, 0.25, 1.0), Color("1d1f24"))
			Vec.fill(self, Vec.xform(PackedVector2Array(Vec.rrect_pts(Rect2(-7, -31, 14, 27), 2)), at, 0.25, 1.0), Color(0.6, 0.9, 1.6))
		"mug":
			Vec.rrect(self, Rect2(at + Vector2(-12, -26), Vector2(24, 28)), 4, Color("e8dfd0"))
			Vec.rrect(self, Rect2(at + Vector2(-12, -26), Vector2(24, 6)), 2, Color("c9a27a"))


func _torso_shape(scale_w: float, shift: float) -> PackedVector2Array:
	var d := design
	var hip: Vector2 = J.hip
	var chest: Vector2 = J.chest
	var up: Vector2 = J.up
	var fwd: Vector2 = J.fwd
	var sh := d.shoulder_half * scale_w
	var hp := d.hip_half * scale_w
	var off := fwd * shift
	var hem := hip - up * d.hem_drop + off
	var pts := PackedVector2Array()
	pts.append(hem - fwd * (hp + d.hem_flare))
	pts.append(hip + off - fwd * hp * 1.0)
	pts.append(hip.lerp(chest, 0.55) + off - fwd * lerpf(hp, sh, 0.6) * 0.98)
	for i in 9:
		var th := PI - PI * float(i) / 8.0
		pts.append(chest + off + fwd * (sh * cos(th)) + up * (sh * 0.36 * sin(th)))
	pts.append(hip.lerp(chest, 0.55) + off + fwd * lerpf(hp, sh, 0.6) * 1.04)
	pts.append(hip + off + fwd * hp)
	pts.append(hem + fwd * (hp + d.hem_flare))
	# soft hem curve
	pts.append(hem + fwd * hp * 0.3 + up * -2.0)
	pts.append(hem - fwd * hp * 0.4 + up * -2.0)
	return pts


func _draw_torso() -> void:
	var d := design
	var up: Vector2 = J.up
	var fwd: Vector2 = J.fwd
	var hip: Vector2 = J.hip
	var chest: Vector2 = J.chest
	Vec.fill(self, _torso_shape(1.0, 0.0), d.top_shade)
	Vec.fill(self, _torso_shape(0.88, d.shoulder_half * 0.1), d.top)
	var hem := hip - up * d.hem_drop
	match d.top_style:
		0: # jacket: inner shirt V, zipper, hem band, pocket
			var neck_base := chest + up * d.shoulder_half * 0.3
			var v := PackedVector2Array([neck_base - fwd * 10.0, neck_base + fwd * 16.0, chest - up * 34.0 + fwd * 9.0])
			Vec.fill(self, v, d.inner)
			Vec.line(self, chest - up * 30.0 + fwd * 8.0, hem + fwd * 10.0 + up * 2.0, d.top_accent, 3.0)
			Vec.capsule(self, hem - fwd * (d.hip_half * 0.85), hem + fwd * (d.hip_half * 0.95), 5.0, 5.0, Vec.shade(d.top, 0.25))
			# collar flaps
			Vec.fill(self, PackedVector2Array([neck_base - fwd * 14.0, neck_base - fwd * 2.0 - up * 4.0, chest - up * 14.0 - fwd * 4.0]), d.top_accent)
			Vec.fill(self, PackedVector2Array([neck_base + fwd * 18.0, neck_base + fwd * 6.0 - up * 4.0, chest - up * 16.0 + fwd * 16.0]), Vec.shade(d.top_accent, -0.15))
			Vec.line(self, hip + up * 6.0 + fwd * 14.0, hip + up * 6.0 + fwd * 30.0, Vec.shade(d.top, 0.3), 2.5)
		1: # hoodie: kangaroo pocket, strings
			var p := PackedVector2Array([hem + up * 8.0 - fwd * 8.0, hem + up * 8.0 + fwd * 30.0, hem + up * 42.0 + fwd * 24.0, hem + up * 42.0 - fwd * 2.0])
			Vec.fill(self, p, Vec.shade(d.top, 0.1))
			var nb := chest + up * d.shoulder_half * 0.25
			for k in [-2.0, 12.0]:
				Vec.line(self, nb + fwd * k, nb + fwd * (k + 2.0) - up * 46.0, d.shoe_accent, 2.5)
				Vec.circle(self, nb + fwd * (k + 2.0) - up * 47.0, 3.0, d.shoe_accent)
			Vec.capsule(self, hem - fwd * (d.hip_half * 0.85), hem + fwd * (d.hip_half * 0.95), 4.0, 4.0, Vec.shade(d.top, 0.18))
		2: # suit: lapels and tie
			var nb2 := chest + up * d.shoulder_half * 0.3
			Vec.fill(self, PackedVector2Array([nb2 - fwd * 8.0, nb2 + fwd * 14.0, chest - up * 60.0 + fwd * 6.0]), d.inner)
			Vec.fill(self, PackedVector2Array([nb2 + fwd * 1.0, nb2 + fwd * 7.0, chest - up * 50.0 + fwd * 5.0, chest - up * 56.0 + fwd * 3.0]), d.top_accent)
		4: # kameez: long tunic, embroidered neckline, side slit
			var nb3 := chest + up * d.shoulder_half * 0.28
			Vec.stroke(self, Vec.qbez(nb3 - fwd * 12.0, chest - up * 22.0 + fwd * 4.0, nb3 + fwd * 18.0, 8), d.top_accent, 4.0)
			Vec.line(self, chest - up * 22.0 + fwd * 4.0, chest - up * 60.0 + fwd * 4.0, d.top_accent, 2.5)
			Vec.line(self, hem + fwd * (d.hip_half + d.hem_flare) * 0.9, hem + fwd * (d.hip_half * 0.8) + up * 40.0, d.top_shade, 3.0)
		3: # uniform: chest pockets + belt
			Vec.rrect(self, Rect2(chest - up * 40.0 + fwd * 4.0 - Vector2(0, 0), Vector2(22, 18)), 3, Vec.shade(d.top, 0.12))
			Vec.capsule(self, hip - fwd * d.hip_half, hip + fwd * d.hip_half, 5.0, 5.0, d.top_accent)


func _draw_tears() -> void:
	var d := design
	if not d.torn:
		return
	var hip: Vector2 = J.hip
	var up: Vector2 = J.up
	var fwd: Vector2 = J.fwd
	var dark := Vec.shade(d.top, 0.45)
	for k in 3:
		var p := hip + up * (20.0 + k * 34.0) + fwd * (Vec.hash01(k * 3.0 + d.top.r * 10.0) * 40.0 - 18.0)
		Vec.fill(self, PackedVector2Array([p, p + fwd * 14.0 + up * 6.0, p + fwd * 6.0 - up * 10.0, p - fwd * 8.0 - up * 4.0]), dark)
	# ragged hem
	var hem := hip - up * d.hem_drop
	for k in 4:
		var x := lerpf(-d.hip_half, d.hip_half, k / 3.0)
		Vec.fill(self, PackedVector2Array([hem + fwd * (x - 8.0), hem + fwd * (x + 8.0), hem + fwd * x - up * 12.0]), d.top_shade)


func _draw_hood_back() -> void:
	var d := design
	if d.top_style != 1:
		return
	var c: Vector2 = J.chest + J.up * d.shoulder_half * 0.32 - J.fwd * d.shoulder_half * 0.42
	Vec.ellipse(self, c, d.shoulder_half * 0.58, d.shoulder_half * 0.36, d.top_shade, J.lean)


func _draw_holster() -> void:
	var d := design
	if not d.holster:
		return
	var gun_out := prop_front == "gun"
	var L: Dictionary = J.legs["f"]
	var a: Vector2 = L.hip.lerp(L.knee, 0.12)
	var b: Vector2 = L.hip.lerp(L.knee, 0.5)
	var n := (b - a).normalized()
	var side := Vector2(-n.y, n.x)
	a -= side * 6.0
	b -= side * 6.0
	Vec.capsule(self, a, b, 9.0, 8.0, Color("1d1b1d"))
	# grip sticking up/back
	if not gun_out:
		Vec.capsule(self, a + n * 4.0, a - n * 16.0 - side * 10.0, 6.0, 7.0, Color("2a2a2e"))


func _draw_neck_accessories() -> void:
	var d := design
	var r := d.head_radius
	# neck
	Vec.capsule(self, J.chest - J.up * 4.0, J.neck + J.up * 6.0, r * 0.2, r * 0.19, d.skin_shade)
	if d.scarf:
		var c0: Vector2 = J.chest + J.up * (d.shoulder_half * 0.18)
		Vec.capsule(self, c0 - J.fwd * r * 0.55, c0 + J.fwd * r * 0.6, r * 0.26, r * 0.26, d.scarf_color)
		Vec.capsule(self, c0 + J.fwd * r * 0.35, c0 + J.fwd * r * 0.45 - J.up * r * 1.3, r * 0.18, r * 0.14, Vec.shade(d.scarf_color, 0.15))
		Vec.line(self, c0 - J.fwd * r * 0.4, c0 + J.fwd * r * 0.5, Vec.shade(d.scarf_color, 0.25), 2.0)
	if d.headphones:
		var c: Vector2 = J.chest + J.up * (d.shoulder_half * 0.22)
		var band := PackedVector2Array()
		for i in 13:
			var th := PI * 0.05 + PI * 0.9 * float(i) / 12.0
			band.append(c + J.fwd * cos(th) * r * 0.62 + J.up * -sin(th) * r * 0.16)
		Vec.stroke(self, band, Vec.shade(d.accessory_color, 0.25), 6.0)
		Vec.ellipse(self, c - J.fwd * r * 0.55, r * 0.17, r * 0.24, Vec.shade(d.accessory_color, 0.3), J.lean)
		Vec.ellipse(self, c + J.fwd * r * 0.55, r * 0.2, r * 0.27, d.accessory_color, J.lean)
		Vec.ellipse(self, c + J.fwd * r * 0.58, r * 0.1, r * 0.15, Vec.shade(d.accessory_color, 0.45), J.lean)


# --- head & face --------------------------------------------------------------

func _draw_ear(c: Vector2, sx: float, r: float, tilt: float) -> void:
	var d := design
	Vec.ellipse(self, _hp(c, sx, r, tilt, Vector2(-0.56, 0.08)), r * 0.15, r * 0.21, d.skin)
	Vec.ellipse(self, _hp(c, sx, r, tilt, Vector2(-0.55, 0.08)), r * 0.075, r * 0.12, d.skin_shade)


func _hp(c: Vector2, sx: float, r: float, tilt: float, p: Vector2) -> Vector2:
	## head-local unit point -> screen
	return c + Vector2(p.x * sx, p.y).rotated(tilt * signf(sx)) * r


func _hpoly(c: Vector2, sx: float, r: float, tilt: float, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_hp(c, sx, r, tilt, p))
	return out


func _draw_head(c: Vector2, sx: float) -> void:
	var d := design
	var r := d.head_radius
	var tilt: float = J.tilt
	var f := _face

	# ponytail (behind head)
	if d.hair_style == 1 and _pony.size() == 4:
		for i in 3:
			var a := Vector2(_pony[i].x * _vis_scale(), _pony[i].y)
			var b := Vector2(_pony[i + 1].x * _vis_scale(), _pony[i + 1].y)
			Vec.capsule(self, a, b, r * lerpf(0.24, 0.1, i / 2.0), r * lerpf(0.2, 0.07, i / 2.0), d.hair)
		Vec.circle(self, Vector2(_pony[0].x * _vis_scale(), _pony[0].y), r * 0.13, d.accessory_color)

	# head (slight jaw toward the front-bottom)
	var hpts := []
	for i in 40:
		var th := TAU * float(i) / 40.0
		var k := 1.0
		if th > 0.15 and th < 2.0:
			k += 0.06 * sin((th - 0.15) / 1.85 * PI)
		hpts.append(Vector2(cos(th) * k, sin(th) * k * 1.02))
	Vec.fill(self, _hpoly(c, sx, r, tilt, hpts), d.skin)

	var short_hair := d.hair_style == 0 or d.hair_style == 4
	if not short_hair:
		_draw_ear(c, sx, r, tilt)

	# hair cap (drawn over the skull)
	match d.hair_style:
		0:
			Vec.fill(self, _hpoly(c, sx, r, tilt, [
				Vector2(1.04, -0.5), Vector2(0.98, -0.86), Vector2(1.14, -1.04), Vector2(0.8, -1.12), Vector2(0.74, -1.38),
				Vector2(0.45, -1.18), Vector2(0.2, -1.44), Vector2(-0.05, -1.2), Vector2(-0.38, -1.38), Vector2(-0.55, -1.12),
				Vector2(-0.9, -1.16), Vector2(-0.96, -0.86), Vector2(-1.2, -0.62), Vector2(-1.1, -0.3), Vector2(-1.12, 0.05),
				Vector2(-1.0, 0.42), Vector2(-0.82, 0.52), Vector2(-0.72, 0.3), Vector2(-0.66, 0.0), Vector2(-0.5, -0.34),
				Vector2(-0.2, -0.52), Vector2(0.1, -0.6), Vector2(0.3, -0.46), Vector2(0.42, -0.62), Vector2(0.62, -0.42),
				Vector2(0.78, -0.6), Vector2(0.94, -0.36)]), d.hair)
			# a lighter strand for volume
			Vec.stroke(self, Vec.qbez(_hp(c, sx, r, tilt, Vector2(-0.6, -0.95)), _hp(c, sx, r, tilt, Vector2(-0.1, -1.18)), _hp(c, sx, r, tilt, Vector2(0.5, -0.98)), 8), Vec.shade(d.hair, -0.12), r * 0.035)
		1:
			Vec.fill(self, _hpoly(c, sx, r, tilt, [
				Vector2(0.62, -0.98), Vector2(0.2, -1.14), Vector2(-0.35, -1.12), Vector2(-0.82, -0.88), Vector2(-1.1, -0.42),
				Vector2(-1.16, 0.12), Vector2(-1.08, 0.6), Vector2(-0.9, 0.84), Vector2(-0.66, 0.86), Vector2(-0.56, 0.62),
				Vector2(-0.5, 0.25), Vector2(-0.42, -0.15), Vector2(-0.2, -0.48), Vector2(0.15, -0.66), Vector2(0.45, -0.72)]), d.hair)
			Vec.fill(self, _hpoly(c, sx, r, tilt, [
				Vector2(-0.35, -0.7), Vector2(-0.2, -1.02), Vector2(0.2, -1.1), Vector2(0.6, -0.97), Vector2(0.9, -0.72),
				Vector2(1.03, -0.4), Vector2(0.84, -0.48), Vector2(0.68, -0.3), Vector2(0.5, -0.5), Vector2(0.3, -0.33),
				Vector2(0.1, -0.53), Vector2(-0.14, -0.43), Vector2(-0.35, -0.6)]), d.hair)
			Vec.stroke(self, Vec.qbez(_hp(c, sx, r, tilt, Vector2(-0.7, -0.75)), _hp(c, sx, r, tilt, Vector2(-0.15, -1.05)), _hp(c, sx, r, tilt, Vector2(0.4, -0.9)), 8), Vec.shade(d.hair, -0.14), r * 0.035)
			Vec.rrect(self, Rect2(_hp(c, sx, r, tilt, Vector2(0.2, -0.8)) - Vector2(r * 0.17, r * 0.055), Vector2(r * 0.34, r * 0.11)), r * 0.05, d.top_accent)
		2:
			Vec.fill(self, _hpoly(c, sx, r, tilt, [Vector2(0.95, -0.55), Vector2(0.62, -1.0), Vector2(0.0, -1.15), Vector2(-0.6, -1.02), Vector2(-1.05, -0.6), Vector2(-1.12, -0.05), Vector2(-0.95, 0.35), Vector2(-0.72, 0.25), Vector2(-0.66, -0.1), Vector2(-0.4, -0.5), Vector2(0.1, -0.62), Vector2(0.6, -0.52)]), d.hair)
			Vec.circle(self, _hp(c, sx, r, tilt, Vector2(-1.08, -0.55)), r * 0.32, d.hair)
		3:
			var hc := Color("4a5236")
			Vec.fill(self, _hpoly(c, sx, r, tilt, [Vector2(1.12, -0.32), Vector2(1.02, -0.72), Vector2(0.62, -1.1), Vector2(0.0, -1.24), Vector2(-0.62, -1.12), Vector2(-1.06, -0.72), Vector2(-1.16, -0.25), Vector2(-0.9, -0.2), Vector2(0.2, -0.34)]), hc)
			Vec.fill(self, _hpoly(c, sx, r, tilt, [Vector2(1.14, -0.3), Vector2(0.2, -0.32), Vector2(0.18, -0.42), Vector2(1.08, -0.42)]), Vec.shade(hc, 0.25))
			Vec.stroke(self, PackedVector2Array([_hp(c, sx, r, tilt, Vector2(-0.6, -0.25)), _hp(c, sx, r, tilt, Vector2(-0.4, 0.55)), _hp(c, sx, r, tilt, Vector2(0.1, 0.85))]), Color("23261b"), r * 0.05)
			Vec.circle(self, _hp(c, sx, r, tilt, Vector2(-0.2, -0.85)), r * 0.09, Vec.shade(hc, -0.15))
		4:
			Vec.fill(self, _hpoly(c, sx, r, tilt, [Vector2(0.98, -0.5), Vector2(0.75, -0.95), Vector2(0.25, -1.16), Vector2(-0.35, -1.14), Vector2(-0.9, -0.8), Vector2(-1.1, -0.2), Vector2(-1.02, 0.3), Vector2(-0.82, 0.36), Vector2(-0.7, 0.0), Vector2(-0.55, -0.4), Vector2(-0.1, -0.62), Vector2(0.4, -0.68), Vector2(0.75, -0.55)]), d.hair)
			Vec.stroke(self, Vec.qbez(_hp(c, sx, r, tilt, Vector2(-0.4, -0.95)), _hp(c, sx, r, tilt, Vector2(0.2, -1.12)), _hp(c, sx, r, tilt, Vector2(0.7, -0.8)), 8), Vec.shade(d.hair, -0.12), r * 0.035)

	if short_hair:
		_draw_ear(c, sx, r, tilt)
	if d.stubble:
		for k in 14:
			var sp := Vector2(lerpf(-0.05, 0.75, Vec.hash01(k)), lerpf(0.62, 0.92, Vec.hash01(k + 40.0)))
			if sp.length() < 0.96:
				Vec.circle(self, _hp(c, sx, r, tilt, sp), r * 0.018, Color(d.hair, 0.35))

	# face
	var look_off := Vector2(look.x * 0.07, look.y * 0.05)
	var eo: float = f.eo * (1.0 - sin(_blink * PI)) * d.eye_scale
	var es: float = f.es
	var eyes := [Vector2(0.48, -0.02), Vector2(0.06, -0.03)]
	for i in 2:
		var ep: Vector2 = eyes[i] + look_off
		var narrow := 1.0 if i == 0 else 0.82
		var pos := _hp(c, sx, r, tilt, ep)
		var rx := r * 0.1 * narrow * d.eye_scale
		var ry := r * 0.15 * eo
		if d.blank_eyes:
			Vec.ellipse(self, pos + Vector2(0, ry * 0.55), rx * 1.3, ry * 0.35, Color(0.35, 0.33, 0.38, 0.35), tilt * signf(sx))
			Vec.ellipse(self, pos, rx * 1.05, ry * 0.8, Color(0.9, 0.92, 0.86), tilt * signf(sx))
			Vec.circle(self, pos + Vector2(rx * 0.25 * sx, ry * 0.1), r * 0.028, Color(0.62, 0.64, 0.6))
			continue
		if es > 0.55 or ry < r * 0.035:
			# closed / smiling eye: arc
			var bend := -1.0 if es > 0.55 else 0.25
			var arc := PackedVector2Array([pos + Vector2(-rx * 1.3, 0), pos + Vector2(0, r * 0.07 * bend), pos + Vector2(rx * 1.3, 0)])
			Vec.stroke(self, Vec.qbez(arc[0], arc[1], arc[2], 8), d.eye, r * 0.055)
		else:
			Vec.ellipse(self, pos, rx, ry, d.eye, tilt * signf(sx))
			Vec.circle(self, pos + Vector2(rx * 0.3 * sx, -ry * 0.42), r * 0.035, Color(1, 1, 1, 0.95))

	if d.glasses:
		for i in 2:
			var gp := _hp(c, sx, r, tilt, eyes[i] + look_off * 0.5)
			var gw := r * (0.21 if i == 0 else 0.17)
			Vec.stroke(self, Vec.rrect_pts(Rect2(gp - Vector2(gw, r * 0.17), Vector2(gw * 2.0, r * 0.32)), r * 0.08) + PackedVector2Array([gp - Vector2(gw, r * 0.17) + Vector2(r * 0.08, 0)]), d.glasses_color, r * 0.045)
		Vec.line(self, _hp(c, sx, r, tilt, Vector2(0.23, -0.04)), _hp(c, sx, r, tilt, Vector2(0.29, -0.04)), d.glasses_color, r * 0.04)
		Vec.line(self, _hp(c, sx, r, tilt, Vector2(-0.12, -0.05)), _hp(c, sx, r, tilt, Vector2(-0.5, 0.0)), d.glasses_color, r * 0.04)

	# brows
	var by: float = f.by
	var bt: float = f.bt
	var ba: float = f.ba
	for i in 2:
		var ex: float = eyes[i].x + look_off.x * 0.5
		var w := 0.15 * d.brow_width * (1.0 if i == 0 else 0.85)
		var lift := by * 0.12 + (ba * 0.12 if i == 1 else 0.0)
		var base_y: float = -0.3 - lift - (float(f.eo) - 1.0) * 0.08
		var inner_x := ex - w if i == 0 else ex + w
		var outer_x := ex + w if i == 0 else ex - w
		var a := _hp(c, sx, r, tilt, Vector2(inner_x, base_y - bt * 0.07))
		var b := _hp(c, sx, r, tilt, Vector2(outer_x, base_y + bt * 0.03))
		Vec.capsule(self, a, b, r * 0.05, r * 0.042, d.brow)

	# blush / freckles
	if d.blush:
		Vec.ellipse(self, _hp(c, sx, r, tilt, Vector2(0.62, 0.3)), r * 0.14, r * 0.07, Color(0.95, 0.45, 0.45, 0.35))
	if d.freckles:
		for p in [Vector2(0.55, 0.22), Vector2(0.66, 0.26), Vector2(0.6, 0.33)]:
			Vec.circle(self, _hp(c, sx, r, tilt, p), r * 0.02, Color(d.skin_shade, 0.9))

	if d.mustache:
		Vec.fill(self, _hpoly(c, sx, r, tilt, [Vector2(0.18, 0.34), Vector2(0.4, 0.28), Vector2(0.64, 0.33), Vector2(0.62, 0.42), Vector2(0.4, 0.37), Vector2(0.2, 0.43)]), d.brow)
	# mouth
	var mo: float = clampf(f.mo + _mouth_flap * 0.5, 0.0, 1.0)
	var mc: float = f.mc
	var mw: float = f.mw * 0.2
	var mcen := Vector2(0.4, 0.46) + Vector2(look_off.x * 0.4, 0)
	var left := _hp(c, sx, r, tilt, mcen + Vector2(-mw, -mc * 0.05))
	var right := _hp(c, sx, r, tilt, mcen + Vector2(mw, -mc * 0.05))
	var mid_top := _hp(c, sx, r, tilt, mcen + Vector2(0, mc * 0.09 - mo * 0.02))
	if mo < 0.06:
		Vec.stroke(self, Vec.qbez(left, mid_top, right, 8), d.mouth, r * 0.05)
	else:
		var mid_bot := _hp(c, sx, r, tilt, mcen + Vector2(0, mc * 0.09 + mo * 0.24))
		var top_arc := Vec.qbez(left, mid_top, right, 8)
		var bot_arc := Vec.qbez(right, mid_bot, left, 8)
		var poly := top_arc.duplicate()
		poly.append_array(bot_arc)
		Vec.fill(self, poly, d.mouth)
		if mo > 0.3:
			Vec.ellipse(self, _hp(c, sx, r, tilt, mcen + Vector2(0, mc * 0.09 + mo * 0.15)), r * mw * 0.5, r * mo * 0.06, Color("c4605d"))
