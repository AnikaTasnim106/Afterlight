extends LevelBase
## Level 4 — The Crossing (l4b). On the deck of the Mary Ann while Gus steers
## past the old ferry wreck. Infected climb out of the water onto the deck —
## keep them off Gus (at the helm) for about a minute. Then Harbor Point's
## quarantine gate.

const DECK_W := 1500.0

@onready var bg: RiverBG = $Backdrop

var gun: GunController
var mara: Companion
var ward: Actor
var gus: Actor
var stage := "crossing"
var spawned := 0
var _spawn_t := 3.0
var _time := 0.0
var _mid_said := false


func _ready() -> void:
	super._ready()
	gun = alex.get_node("Gun")
	gun.cam = cam
	gun.in_mag = 8
	gun.reserve = 24
	gun.ammo_changed.connect(func(a, r): ui.over.ammo = Vector2i(a, r))
	mara = Cast.make("mara", "companion") as Companion
	mara.position = Vector2(420, 0)
	$Actors.add_child(mara)
	mara.armed = true
	mara.range_px = 900.0
	ward = Cast.make("ward")
	ward.position = Vector2(560, 0)
	$Actors.add_child(ward)
	ward.rig.prop_front = "case"
	gus = Cast.make("gus")
	gus.position = Vector2(980, 0)
	$Actors.add_child(gus)
	gus.rig.facing = 1
	gus.rig.pose_front = "reach"
	for a in [mara, ward, gus]:
		a.add_to_group("living")
		a.max_hp = 4
		a.hp = 4
	for p in [["mara", mara], ["ward", ward], ["gus", gus]]:
		register(p[0], p[1])
	mara.died.connect(func(): fail("Mara didn't make it."))
	ward.died.connect(func(): fail("Dr. Ward didn't make it."))
	gus.died.connect(func(): fail("Gus didn't make it."))
	alex.died.connect(func(): fail("Alex didn't make it."))
	alex.global_position = Vector2(700, -2)
	bg.scroll_speed = 260.0
	ui.set_hud("DAY 3", "8:41 PM", "THE MARY ANN  ·  RIVER", "")
	await chapter_intro("", "")
	cam.follow_offset = Vector2(0, -380)
	cam.cut(Vector2(DECK_W * 0.5, -380), 0.78, 0.004)
	dialog.partner_id = "gus"
	await dialog.run(RiverLines.crossing_start())
	dialog.end()
	cam.cut(Vector2(DECK_W * 0.5, -380), 0.78, 0.004)
	gun.set_active(true)
	ui.over.combat_visible = true
	ui.over.survivors = [["GUS", gus], ["MARA", mara], ["DR. WARD", ward]]
	ui.over.set_hint("Keep them off the deck · protect Gus at the helm · LMB shoot · R reload")
	Inputs.input_locked = false
	if autoplay:
		_bot()


func _physics_process(dt: float) -> void:
	if _ended:
		return
	ui.over.hp = alex.hp
	ui.over.bandages = int(Game.flag("bandages", 0))
	# camera holds the whole deck (no following on a boat)
	if stage == "crossing":
		cam._base_pos = cam._base_pos.lerp(Vector2(DECK_W * 0.5 + (alex.global_position.x - DECK_W * 0.5) * 0.25, -380), dt * 2.0)
	if stage != "crossing":
		return
	_time += dt
	set_objective("Keep them off the boat  ·  %d s to the far shore" % maxi(0, int(55.0 - _time)))
	_spawn_t -= dt
	if _spawn_t <= 0.0 and spawned < 12 and get_tree().get_nodes_in_group("zombies").size() < 4:
		_spawn_t = randf_range(3.0, 4.5)
		spawned += 1
		var left := randf() < 0.55
		var z := Cast.make(["zombie_a", "zombie_b", "zombie_c"][spawned % 3], "zombie") as Zombie
		z.position = Vector2(90.0 if left else DECK_W - 90.0, -2)
		z.max_hp = 2
		$Actors.add_child(z)
		z.hp = 2
		z.rig.facing = 1 if left else -1
		z.state = "investigate"
		z.nav_target = gus.global_position
		z.rig.hurt_flash = 0.6
		cam.shake(2.0)
		if spawned == 3 and not _mid_said:
			_mid_said = true
			_say_async(RiverLines.crossing_mid())
	if _time >= 55.0:
		stage = "gate"
		_arrive()


func _say_async(lines: Array) -> void:
	await dialog.run(lines)
	ui.hide_caption()


func _arrive() -> void:
	for z in get_tree().get_nodes_in_group("zombies"):
		(z as Zombie).die()
	var tw := create_tween()
	tw.tween_property(bg, "scroll_speed", 0.0, 3.0)
	gun.set_active(false)
	ui.over.combat_visible = false
	ui.over.set_hint("")
	Inputs.input_locked = true
	await wait(2.0)
	$Props/Gate.visible = true
	var soldier := Cast.make("soldier")
	soldier.position = Vector2(DECK_W + 260.0, 0)
	$Actors.add_child(soldier)
	soldier.rig.facing = -1
	soldier.rig.prop_front = "rifle"
	soldier.rig.pose_front = "point"
	register("soldier", soldier)
	cam.shot(Vector2(DECK_W * 0.7, -380), 0.9, 1.4)
	ui.letterbox(true, 0.5)
	await wait(1.2)
	ward.walk_to(DECK_W - 160.0, false, 1)
	dialog.partner_id = "soldier"
	await dialog.run(RiverLines.gate())
	ui.hide_caption()
	Game.set_flag("level4_complete", true)
	await finish("l5a", "END OF LEVEL 4", "THE RIVER")


# --- test bot -----------------------------------------------------------------------

func _bot() -> void:
	alex.player_controlled = false
	var t := 0.0
	while not _ended and t < 200.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if Inputs.input_locked or _busy:
			continue
		var threat: Zombie = null
		var best := 1600.0
		for z in get_tree().get_nodes_in_group("zombies"):
			var d := (z as Node2D).global_position.distance_to(gus.global_position)
			if d < best:
				best = d
				threat = z
		if threat:
			var dir := signf(threat.global_position.x - alex.global_position.x)
			if absf(threat.global_position.x - alex.global_position.x) > 900.0:
				alex.walk_to(alex.global_position.x + dir * 200.0)
			gun.bot_aim = threat.rig.hit_zones()[0]
			if gun.in_mag == 0:
				gun.reload()
			else:
				gun.fire()
	print("BOT crossing t=", t, " gus=", gus.hp, " hp=", alex.hp)
