extends LevelBase
## Level 6 — The Quarantine Wing.
##   l6a  Service tunnel → stairs → the east wing corridor → Ward 4's door.
##        HOLD E at the panel while June overrides the lock from inside. It's
##        loud: they come. Release E to shoot, then keep holding.
##        Reunion: June and Theo. Theo is scratched and feverish.
##   l6b  Get June and Theo (slow, sick) back through the wing and the tunnel
##        to Dr. Chen at the basement lab hatch. The first field dose.

const WING_Y := -450.0
const PANEL_X := 6450.0
const HATCH_X := 180.0

@onready var blocker: StaticBody2D = $DoorBlock

var gun: GunController
var mara: Companion
var june: Actor
var theo: Actor
var chen: Actor
var ward: Actor
var stage := ""
var progress := 0.0
var _spawn_t := 2.0
var _budget := 0
var _holding := false


func _ready() -> void:
	super._ready()
	alex.can_crouch = true
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 24
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	mara = Cast.make("mara", "companion") as Companion
	$Actors.add_child(mara)
	mara.armed = true
	mara.range_px = 900.0
	mara.add_to_group("living")
	june = Cast.make("june")
	june.position = Vector2(7000, WING_Y)
	$Actors.add_child(june)
	june.rig.prop_front = "radio"
	june.rig.pose_front = "radio_ear"
	theo = Cast.make("theo")
	theo.position = Vector2(7250, WING_Y)
	$Actors.add_child(theo)
	theo.rig.expression = "tired"
	theo.rig.sit = 1.0
	chen = Cast.make("chen")
	chen.position = Vector2(-200, 0)
	$Actors.add_child(chen)
	ward = Cast.make("ward")
	ward.position = Vector2(-350, 0)
	$Actors.add_child(ward)
	chen.visible = false
	ward.visible = false
	for p in [["mara", mara], ["june", june], ["theo", theo], ["chen", chen], ["ward", ward]]:
		register(p[0], p[1])
	alex.died.connect(func(): fail("Alex didn't make it."))
	enable("panel", false)
	enable("hatch", false)
	if Game.phase == "l6b":
		_escape(true)
	else:
		Game.phase = "l6a"
		_tunnel()


func _zombie(pos: Vector2, design := "") -> Zombie:
	var z := Cast.make(design if design != "" else ["zombie_a", "zombie_b", "zombie_c"][randi() % 3], "zombie") as Zombie
	z.position = pos
	z.max_hp = 3
	$Actors.add_child(z)
	z.hp = 3
	return z


# =====================================================================================

func _tunnel() -> void:
	alex.global_position = Vector2(300, -2)
	mara.global_position = Vector2(160, 0)
	for x in [1300.0, 2200.0, 2800.0]:
		var z := _zombie(Vector2(x, 0))
		z.sight = 420.0
		z.rig.facing = 1
	for x in [4300.0, 5000.0, 5600.0, 6100.0]:
		_zombie(Vector2(x, WING_Y)).rig.facing = -1
	ui.set_hud("DAY 5", "1:10 AM", "SERVICE TUNNEL", "")
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("LEVEL 6", "THE QUARANTINE WING", 1.4)
	cam.follow_offset = Vector2(150, -400)
	cam.cut(alex.global_position + cam.follow_offset, 0.85)
	ui.fade(false, 1.0)
	ui.show_hud(true)
	cam.follow(alex, 0.85, 0.4)
	dialog.partner_id = "mara"
	await dialog.run(WingLines.tunnel())
	dialog.end()
	mara.follow_target = alex
	mara.follow_dist = 160.0
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["MARA", mara]]
	ui.over.set_hint("C sneak · E takedown not available here — they're too many · W/S stairs")
	stage = "approach"
	enable("panel")
	set_objective("Reach Ward 4 — up the stairs, end of the east wing")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _physics_process(dt: float) -> void:
	if _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	mara.nav_run = mara.global_position.distance_to(alex.global_position) > 450.0
	for a in [june, theo]:
		if a.follow_target:
			a.nav_run = false
	if stage == "door" or stage == "escape":
		_spawn_t -= dt
		var alive := get_tree().get_nodes_in_group("zombies").size()
		if _spawn_t <= 0.0 and _budget > 0 and alive < 5:
			_spawn_t = randf_range(3.0, 4.5)
			_budget -= 1
			if stage == "door":
				_zombie(Vector2(3800, WING_Y)).nav_target = Vector2(PANEL_X, WING_Y)
			else:
				var behind := Vector2(alex.global_position.x + 1300.0, alex.global_position.y)
				var f := Nav.floor_at(get_tree(), behind)
				if f:
					var z := _zombie(Vector2(clampf(behind.x, f.x_range().x + 20.0, f.x_range().y - 20.0), f.top_y()))
					z.state = "investigate"
					z.nav_target = theo.global_position
	if stage == "door":
		set_objective("Hold E at the panel — override %d%%" % int(progress * 100.0))
	if stage == "escape" and alex.stair == null and absf(alex.global_position.y) < 40.0 and alex.global_position.x < HATCH_X + 200.0:
		enable("hatch")


func interact(id: String) -> void:
	match id:
		"panel":
			if stage == "approach":
				stage = "door"
				_budget = 7
				Inputs.input_locked = true
				dialog.partner_id = "mara"
				await dialog.run(WingLines.door_panel())
				ui.hide_caption()
				Inputs.input_locked = false
			if stage == "door":
				await _hold_panel()
		"hatch":
			if stage == "escape":
				var ok := theo.global_position.distance_to(alex.global_position) < 600.0 and june.global_position.distance_to(alex.global_position) < 600.0
				if not ok:
					await think([{think = "Wait for June and Theo.", face = "worried"}])
				else:
					await _lab()


func _hold_panel() -> void:
	gun.set_active(false)
	alex.rig.pose_front = "reach"
	_holding = true
	var beep := 0.0
	while progress < 1.0:
		await get_tree().physics_frame
		if not is_inside_tree():
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
		progress = minf(1.0, progress + dt / 11.0)
		beep -= dt
		if beep <= 0.0:
			beep = 1.5
			Sound.emit($Interactables/panel.global_position + Vector2(0, -200), 1600.0, "alarm")
			cam.shake(1.0)
	_holding = false
	alex.rig.pose_front = "none"
	gun.set_active(true)
	if progress >= 1.0 and stage == "door":
		await _open_ward()


func _open_ward() -> void:
	stage = "reunion"
	Inputs.input_locked = true
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Zombie).die()
	blocker.queue_free()
	$Props/Ward4Door.label = "W4_open"
	$Props/Ward4Door.queue_redraw()
	gun.set_active(false)
	ui.over.combat_visible = false
	alex.walk_to(6850.0)
	mara.stop_nav()
	mara.walk_to(6700.0)
	await alex.arrived
	june.rig.pose_front = "none"
	june.rig.prop_front = "radio"
	ui.letterbox(true, 0.5)
	june.walk_to(6980.0, true, -1)
	await wait(0.6)
	june.rig.pose_front = "reach"
	alex.rig.pose_front = "reach"
	Audio.music("sad", 2.5)
	dialog.partner_id = "june"
	await dialog.run(WingLines.reunion().slice(0, 4))
	june.rig.pose_front = "none"
	alex.rig.pose_front = "none"
	dialog.partner_id = "theo"
	await dialog.run(WingLines.reunion().slice(4))
	await dialog.run(WingLines.theo_bitten())
	ui.hide_caption()
	Game.set_flag("june_found", true)
	Game.set_flag("theo_found", true)
	Game.phase = "l6b"
	Game.save_checkpoint("l6b")
	await _escape(false)


func _escape(direct: bool) -> void:
	if direct:
		blocker.queue_free()
		$Props/Ward4Door.label = "W4_open"
		alex.global_position = Vector2(6850, WING_Y - 2)
		mara.global_position = Vector2(6700, WING_Y)
		june.global_position = Vector2(6980, WING_Y)
		ui.set_hud("DAY 5", "1:42 AM", "EAST WING · WARD 4", "")
		await chapter_intro("", "")
		cam.follow_offset = Vector2(-150, -400)
		cam.cut(alex.global_position + cam.follow_offset, 0.85)
	cam.follow_offset = Vector2(-150, -400)
	cam.follow(alex, 0.85, 0.5)
	var tw := create_tween()
	tw.tween_property(theo.rig, "sit", 0.0, 0.6)
	theo.rig.limp = 0.8
	theo.speed_scale = 0.75
	theo.rig.expression = "tired"
	dialog.partner_id = "june"
	await dialog.run(WingLines.escape_start())
	dialog.end()
	for a in [june, theo]:
		a.add_to_group("living")
		a.max_hp = 4
		a.hp = 4
	june.died.connect(func(): fail("June didn't make it."))
	theo.died.connect(func(): fail("Theo didn't make it."))
	june.follow_target = alex
	june.follow_dist = 170.0
	theo.follow_target = alex
	theo.follow_dist = 320.0
	mara.follow_target = theo
	mara.follow_dist = 120.0
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["JUNE", june], ["THEO", theo], ["MARA", mara]]
	ui.over.set_hint("Escort June and Theo back to the lab hatch · they're slow · W/S stairs")
	stage = "escape"
	Audio.music("combat", 1.5)
	_budget = 9
	_spawn_t = 3.0
	set_objective("Get June and Theo to Dr. Chen — basement hatch, tunnel west end")
	Inputs.input_locked = false
	if autoplay and direct:
		_bot()


func _lab() -> void:
	stage = "lab"
	Inputs.input_locked = true
	gun.set_active(false)
	ui.over.combat_visible = false
	ui.over.set_hint("")
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Zombie).die()
	chen.visible = true
	ward.visible = true
	chen.global_position = Vector2(80, 0)
	ward.global_position = Vector2(-40, 0)
	chen.rig.facing = 1
	ward.rig.facing = 1
	theo.stop_nav()
	theo.walk_to(260.0)
	ui.letterbox(true, 0.5)
	await wait(1.0)
	theo.rig.sit = 1.0
	Audio.music("hope", 3.0)
	dialog.partner_id = "chen"
	await dialog.run(WingLines.lab_arrive())
	ui.hide_caption()
	Game.set_flag("theo_cured", true)
	Game.set_flag("level6_complete", true)
	await finish("l7a", "END OF LEVEL 6", "THE QUARANTINE WING")


# --- test bot ------------------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	var t := 0.0
	while not _ended and t < 500.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		var protect: Actor = theo if stage == "escape" else alex
		var threat: Zombie = null
		var best := 800.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var zp := (z as Node2D).global_position
			var d := minf(zp.distance_to(alex.global_position), zp.distance_to(protect.global_position))
			if d < best and absf(zp.y - alex.global_position.y) < 400.0:
				best = d
				threat = z
		if threat:
			alex.nav_target = Vector2.INF
			gun.bot_aim = threat.rig.hit_zones()[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
			continue
		if alex.hp <= 2:
			gun.use_bandage()
		match stage:
			"approach", "door":
				var goal := Vector2(PANEL_X, WING_Y)
				if alex.stair == null and absf(alex.global_position.y - WING_Y) < 30.0 and absf(alex.global_position.x - PANEL_X) < 40.0:
					alex.nav_target = Vector2.INF
					await do_interact("panel")
				else:
					alex.nav_target = goal
					alex.nav_stop = 20.0
			"escape":
				if theo.global_position.distance_to(alex.global_position) > 700.0:
					alex.nav_target = Vector2.INF
					continue
				if alex.stair == null and absf(alex.global_position.y) < 30.0 and absf(alex.global_position.x - HATCH_X) < 60.0:
					alex.nav_target = Vector2.INF
					await do_interact("hatch")
				else:
					alex.nav_target = Vector2(HATCH_X, 0)
					alex.nav_stop = 20.0
	print("BOT wing t=", t, " stage=", stage, " hp=", alex.hp, " theo=", theo.hp, " june=", june.hp)
