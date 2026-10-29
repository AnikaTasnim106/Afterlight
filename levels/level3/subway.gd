extends LevelBase
## Level 3 — Underground (l3b). Pitch-dark Line 2 tunnel under the river.
## Flashlight on Alex, dormant infected in the dark (sneak + takedowns work
## here too). Set pieces:
##   * the flashlight dies for a second — and something is right there;
##   * through the stalled train: a dead passenger's phone starts ringing
##     (rule 2) — silence it fast or the carriage wakes up;
##   * a maintenance shutter blocks the way up: HOLD E to crank it open while
##     the clanking pulls everything in the tunnel toward you.

const TRACK_Y := 300.0
const EXIT_X := 6650.0

var gun: GunController
var mara: Companion
var ward: Actor
var flashlight: SoftLight
var stage := "tunnel"
var _takedown: Zombie
var _train_said := false
const GATE_X := 5470.0
const PHONE_X := 3880.0
var _scare_done := false
var _phone_state := ""      # "" → "ringing" → "silenced" / "woke"
var _phone_t := 0.0
var _ring_t := 0.0
var _phone_light: SoftLight
var _train_z: Array = []
var _crank := 0.0
var _gate_open := false


func _ready() -> void:
	super._ready()
	alex.can_crouch = true
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 16
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	mara = Cast.make("mara", "companion") as Companion
	mara.position = Vector2(380, 0)
	$Actors.add_child(mara)
	mara.armed = true
	mara.range_px = 300.0
	ward = Cast.make("ward")
	ward.position = Vector2(250, 0)
	$Actors.add_child(ward)
	ward.rig.prop_front = "case"
	for a in [mara, ward]:
		a.add_to_group("living")
		a.max_hp = 4
		a.hp = 4
	register("mara", mara)
	register("ward", ward)
	mara.died.connect(func(): fail("Mara didn't make it."))
	ward.died.connect(func(): fail("Dr. Ward didn't make it."))
	alex.died.connect(func(): fail("Alex didn't make it."))
	flashlight = SoftLight.new()
	flashlight.radius = 950.0
	flashlight.base_energy = 1.35
	flashlight.color = Color(1.0, 0.95, 0.8)
	flashlight.position = Vector2(260, -320)
	alex.add_child(flashlight)
	for p in [[2650, "zombie_a", 1], [3450, "zombie_b", -1], [4050, "zombie_c", 1], [4800, "zombie_a", -1], [5150, "zombie_b", 1]]:
		var z := Cast.make(p[1], "zombie") as Zombie
		z.position = Vector2(p[0], TRACK_Y)
		z.max_hp = 3
		$Actors.add_child(z)
		z.hp = 3
		z.rig.facing = p[2]
		z.sight = 420.0
	# dormant passengers in the carriage
	for p in [[3500.0, "zombie_c", -1], [3700.0, "zombie_a", 1], [4150.0, "zombie_b", -1], [4300.0, "zombie_c", 1]]:
		var z := Cast.make(p[1], "zombie") as Zombie
		z.position = Vector2(p[0], TRACK_Y)
		z.max_hp = 3
		$Actors.add_child(z)
		z.hp = 3
		z.rig.facing = p[2]
		z.sight = 160.0
		z.hearing_mult = 0.0
		_train_z.append(z)
	_phone_light = SoftLight.new()
	_phone_light.radius = 260.0
	_phone_light.base_energy = 0.0
	_phone_light.color = Color(0.6, 0.9, 1.6)
	_phone_light.position = Vector2(PHONE_X, TRACK_Y - 60)
	add_child(_phone_light)
	enable("exit")
	enable("takedown", false)
	enable("phone", false)
	enable("crank")
	alex.global_position = Vector2(520, -2)
	ui.set_hud("DAY 3", "7:20 PM", "LINE 2  ·  UNDERGROUND", "")
	await chapter_intro("", "")
	cam.follow_offset = Vector2(150, -380)
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	cam.follow(alex, 0.85, 0.4)
	dialog.partner_id = "ward"
	await dialog.run(CityLines.tunnel_start())
	dialog.end()
	mara.follow_target = alex
	mara.follow_dist = 170.0
	ward.follow_target = alex
	ward.follow_dist = 290.0
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["MARA", mara], ["DR. WARD", ward]]
	ui.over.set_hint("C sneak · E behind a wanderer: takedown · W/S stairs · shots echo down here")
	set_objective("Follow the tunnel to the marina exit")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _physics_process(_dt: float) -> void:
	if _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	flashlight.position.x = 260.0 * alex.rig.facing
	for a in [mara, ward]:
		a.crouching = alex.crouching
		a.nav_run = a.global_position.distance_to(alex.global_position) > 500.0
	_takedown = null
	if not Inputs.input_locked and alex.stair == null:
		for z in get_tree().get_nodes_in_group("zombies"):
			var zz := z as Zombie
			if absf(zz.global_position.x - alex.global_position.x) < 140.0 and absf(zz.global_position.y - alex.global_position.y) < 40.0 and zz.unaware_of(alex):
				_takedown = zz
				break
	var td: Interactable = $Interactables/takedown
	td.enabled = _takedown != null
	if _takedown:
		td.global_position = _takedown.global_position
	if not _train_said and alex.global_position.x > 3000.0:
		_train_said = true
		bark(CityLines.train())
	if not _scare_done and alex.stair == null and alex.global_position.y > 200.0 and alex.global_position.x > 2550.0:
		_scare_done = true
		_jump_scare()
	_phone_tick(_dt)
	mara.range_px = 950.0 if (_crank > 0.0 and not _gate_open) or _phone_state == "woke" else 300.0


func _jump_scare() -> void:
	var e := flashlight.base_energy
	for k in 3:
		flashlight.base_energy = 0.0
		await wait(0.08)
		flashlight.base_energy = e
		await wait(0.1)
	flashlight.base_energy = 0.0
	ui.toast("[the flashlight dies]")
	await wait(1.3)
	var z := Cast.make("zombie_b", "zombie") as Zombie
	z.position = Vector2(alex.global_position.x + 230.0 * alex.rig.facing, TRACK_Y)
	z.max_hp = 3
	$Actors.add_child(z)
	z.hp = 3
	z.rig.facing = -alex.rig.facing
	z.state = "chase"
	flashlight.base_energy = e * 1.3
	Audio.sfx("scare", Vector2.INF, -2.0, 0.0)
	cam.shake(9.0)
	Sound.emit(z.global_position + Vector2(0, -250), 300.0, "growl")
	await wait(0.25)
	flashlight.base_energy = e


func _phone_tick(dt: float) -> void:
	if _phone_state == "" and alex.global_position.y > 200.0 and alex.global_position.x > PHONE_X - 420.0:
		_phone_state = "ringing"
		_phone_t = 5.0
		enable("phone")
		ui.rule_flash(2)
		bark([{say = "mara", t = "A *phone!* Kill it — before they wake up!", face = "scared", shot = "keep", hold = 0.3}])
	if _phone_state != "ringing":
		return
	_phone_t -= dt
	_ring_t -= dt
	_phone_light.base_energy = 1.4 if fposmod(_phone_t, 0.5) < 0.25 else 0.3
	set_objective("SILENCE THE PHONE — %.1f" % maxf(0.0, _phone_t))
	if _ring_t <= 0.0:
		_ring_t = 0.9
		Sound.emit(Vector2(PHONE_X, TRACK_Y - 60), 700.0, "ring")
	if _phone_t <= 0.0:
		_phone_state = "woke"
		enable("phone", false)
		_phone_light.base_energy = 0.0
		set_objective("They're awake — get through the train!")
		for z in _train_z:
			var zz := z as Zombie
			if is_instance_valid(zz) and zz.alive:
				zz.sight = 650.0
				zz.hearing_mult = 1.0
				zz.state = "investigate"
				zz.nav_target = alex.global_position
		cam.shake(3.0)


func interact(id: String) -> void:
	match id:
		"takedown":
			if _takedown and _takedown.alive:
				var z := _takedown
				Inputs.input_locked = true
				alex.rig.facing = int(signf(z.global_position.x - alex.global_position.x))
				alex.rig.pose_front = "reach"
				await wait(0.25)
				z.die(signf(z.global_position.x - alex.global_position.x))
				Audio.sfx("takedown", z.global_position + Vector2(0, -250))
				cam.shake(1.5)
				await wait(0.35)
				alex.rig.pose_front = "none"
				Inputs.input_locked = false
		"phone":
			if _phone_state == "ringing":
				_phone_state = "silenced"
				enable("phone", false)
				alex.rig.pose_front = "reach"
				await wait(0.3)
				alex.rig.pose_front = "none"
				_phone_light.base_energy = 0.0
				Game.add("quiet_points", 1)
				set_objective("Follow the tunnel to the marina exit")
				await think([{think = "...Silence. Nobody move.", face = "scared"}])
				for z in _train_z:
					if is_instance_valid(z) and (z as Zombie).alive:
						(z as Zombie).hearing_mult = 0.6
		"crank":
			if not _gate_open:
				await _hold_crank()
		"exit":
			var ok := ward.global_position.distance_to(alex.global_position) < 600.0
			if not ok:
				await think([{think = "Wait for Dr. Ward.", face = "worried"}])
				return
			gun.set_active(false)
			ui.over.combat_visible = false
			Inputs.input_locked = true
			await ui.fade(true, 0.6).finished
			$CanvasModulate.color = Color(0.85, 0.75, 0.72)
			flashlight.base_energy = 0.0
			ui.letterbox(true, 0.01)
			await ui.fade(false, 0.8).finished
			dialog.partner_id = "ward"
			await dialog.run(CityLines.exit_ladder())
			dialog.partner_id = "mara"
			await dialog.run(CityLines.june_radio())
			ui.hide_caption()
			Game.set_flag("june_ward4", true)
			Game.set_flag("level3_complete", true)
			await finish("l4a", "END OF LEVEL 3", "DEAD CITY")


func _hold_crank() -> void:
	if _crank == 0.0:
		bark([{say = "ward", t = "It's chained to a crank. That's going to be *loud.*", face = "worried", shot = "keep", hold = 0.3}])
		# the clanking carries down the tunnel
		for k in 4:
			var z := Cast.make(["zombie_a", "zombie_b", "zombie_c"][k % 3], "zombie") as Zombie
			z.position = Vector2(2400.0 + k * 260.0, TRACK_Y)
			z.max_hp = 3
			$Actors.add_child(z)
			z.hp = 3
			z.rig.facing = 1
			z.state = "investigate"
			z.nav_target = Vector2(GATE_X, TRACK_Y)
	gun.set_active(false)
	alex.rig.pose_front = "reach"
	var clank := 0.0
	var gate: VectorProp = $Props/Gate
	while _crank < 1.0:
		await get_tree().physics_frame
		if not is_inside_tree() or _ended:
			return
		var held := Input.is_action_pressed("interact")
		if autoplay:
			held = true
			for z in get_tree().get_nodes_in_group("zombies"):
				if (z as Node2D).global_position.distance_to(alex.global_position) < 420.0:
					held = false
		if not held or not alex.alive:
			break
		var dt := get_physics_process_delta_time()
		_crank = minf(1.0, _crank + dt / 6.0)
		gate.position.y = TRACK_Y - _crank * 420.0
		clank -= dt
		if clank <= 0.0:
			clank = 0.8
			Sound.emit(Vector2(GATE_X, TRACK_Y - 200), 1500.0, "clank")
			cam.shake(1.2)
		ui.show_prompt("Cranking… %d%%" % int(_crank * 100.0), Vector2(GATE_X - 80.0, TRACK_Y - 560))
	ui.hide_prompt()
	alex.rig.pose_front = "none"
	gun.set_active(true)
	if _crank >= 1.0:
		_gate_open = true
		$GateBody.queue_free()
		enable("crank", false)
		set_objective("Up the stairs — go!")
		bark([{say = "mara", t = "*It's open!* Up, up, up!", face = "determined", shot = "keep", hold = 0.3}])
	else:
		set_objective("Shutter %d%% — HOLD E to keep cranking" % int(_crank * 100.0))


# --- test bot --------------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	alex.crouching = true
	var t := 0.0
	var goal := Vector2(EXIT_X, 0)
	while not _ended and t < 300.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		alex.crouching = true
		if _takedown:
			alex.nav_target = Vector2.INF
			await do_interact("takedown")
			continue
		var threat: Zombie = null
		var best := 650.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var zz := z as Zombie
			var d := zz.global_position.distance_to(alex.global_position)
			if d < best and (zz.state == "chase" or zz.state == "attack"):
				best = d
				threat = zz
		if threat:
			alex.nav_target = Vector2.INF
			gun.bot_aim = threat.rig.hit_zones()[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
			continue
		if _phone_state == "ringing":
			if absf(alex.global_position.x - PHONE_X) < 60.0:
				alex.nav_target = Vector2.INF
				await do_interact("phone")
			else:
				alex.crouching = false
				alex.nav_target = Vector2(PHONE_X, TRACK_Y)
				alex.nav_run = true
			continue
		if not _gate_open and alex.global_position.y > 200.0:
			if absf(alex.global_position.x - (GATE_X - 90.0)) < 40.0:
				alex.nav_target = Vector2.INF
				await do_interact("crank")
			else:
				alex.nav_target = Vector2(GATE_X - 90.0, TRACK_Y)
			continue
		if alex.stair == null and absf(alex.global_position.x - EXIT_X) < 40.0 and absf(alex.global_position.y) < 30.0:
			alex.nav_target = Vector2.INF
			await do_interact("exit")
			continue
		alex.nav_target = goal
		alex.nav_stop = 20.0
	print("BOT subway t=", t, " hp=", alex.hp, " x=", alex.global_position, " phone=", _phone_state, " gate=", _gate_open)
