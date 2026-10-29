extends LevelBase
## Alex & June's apartment (4C). Hosts Scenes 1, 3, 4 and 5 depending on
## Game.phase:
##   s1  A normal evening (tea, TV, radio, window) → leave to check the building
##   s3  June is gone (empty flat, her texts, reply fails) → flows into s4
##   s4  The emergency rules (notice + preparation tasks) → sleep → s5
##   s5  The next morning (June's radio voice, rooftop announcement) → stairwell

@onready var june: Actor = $Actors/June
@onready var tv: TV = $Props/TV
@onready var window_view: WindowView = $Props/Window
@onready var siren: SoftLight = $Lights/Siren
@onready var tv_light: SoftLight = $Lights/TVLight
@onready var june_spot: Interactable = $Interactables/june
@onready var front_door: VectorProp = $Props/FrontDoor

var stage := ""
var tasks := {}

const S1_OBJ := {
	"tea": "Make tea for June (kitchen)",
	"bring": "Bring June her tea",
	"tv": "Check the TV news",
	"radio": "June is calling you",
	"window": "Look out the window",
	"leave": "Check the building — front door",
}


func _ready() -> void:
	super._ready()
	register("june", june)
	var all := ["kettle", "june", "tv", "photo", "fridge", "bookshelf", "window", "door", "phone", "storage", "supplies", "sofa", "receiver", "pack", "chair"]
	for id in all:
		enable(id, false)
	match Game.phase:
		"s3":
			_scene3()
		"s4":
			_setup_after(false)
			_scene4(true)
		"s5":
			_setup_morning()
			_scene5()
		_:
			Game.phase = "s1"
			_scene1()


func _process(dt: float) -> void:
	june_spot.global_position.x = june.global_position.x
	super._process(dt)


func interact(id: String) -> void:
	match Game.phase:
		"s1":
			await _s1_interact(id)
		"s3", "s4":
			await _s4_interact(id)
		"s5":
			await _s5_interact(id)


# ===================================================================================
# Scene 1
# ===================================================================================

func _scene1() -> void:
	for id in ["kettle", "june", "tv", "photo", "fridge", "bookshelf", "window", "door"]:
		enable(id)
	_june_idle()
	window_view.unrest = 0.15
	siren.base_energy = 0.0
	tv.news_stage = 0
	stage = "tea"
	ui.set_hud("DAY 1", "7:42 PM", "APARTMENT 4C", S1_OBJ[stage])
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	await ui.title_card("AFTERLIGHT", "LEVEL 1  ·  THE FIRST EVACUATION", 1.4)
	cam.cut(Vector2(2100, -330), 0.52, 0.008)
	ui.fade(false, 1.2)
	await wait(2.2)
	ui.show_hud(true)
	cam.follow(alex, 1.0, 1.6)
	await wait(1.0)
	Inputs.input_locked = false
	if autoplay:
		for id in ["photo", "kettle", "june", "tv", "june", "window", "door"]:
			if id == "june":
				await bot_walk(june.global_position.x - 150.0)
			await bot_use(id)


func _june_idle() -> void:
	june.rig.facing = 1
	june.rig.pose_front = "hold_radio"
	june.rig.prop_front = "radio"
	june.rig.expression = "curious"
	june.rig.look = Vector2(0.4, 0.45)


func _s1_stage(s: String) -> void:
	stage = s
	if S1_OBJ.has(s):
		set_objective(S1_OBJ[s])


func _s1_interact(id: String) -> void:
	match id:
		"kettle":
			if stage == "tea":
				await think(Scene1Lines.kettle())
				alex.rig.pose_front = "hold_radio"
				alex.rig.prop_front = "mug"
				_s1_stage("bring")
			else:
				await think(Scene1Lines.kettle_again())
		"june":
			match stage:
				"tea":
					await conversation("june", Scene1Lines.june_no_tea())
				"bring":
					await conversation("june", Scene1Lines.conv1_tea(_give_mug))
					_june_idle()
					_s1_stage("tv")
				"radio":
					ui.set_hud("DAY 1", "7:58 PM", "APARTMENT 4C", S1_OBJ[stage])
					await conversation("june", Scene1Lines.conv2_radio(func(): cam.shake(3.0)), false)
					await _sirens()
					_s1_stage("window")
				_:
					await conversation("june", Scene1Lines.june_busy())
					_june_idle()
		"tv":
			if stage == "tv":
				await _tv_scene()
			else:
				await think([{think = "The news ticker keeps getting longer.", face = "worried"}])
		"window":
			if stage == "window":
				await _window_scene()
			else:
				await think(Scene1Lines.window_early())
		"door":
			if stage == "leave":
				await _leave_s1()
			else:
				await think(Scene1Lines.door_early())
		"photo":
			await think(Scene1Lines.photo())
		"fridge":
			await think(Scene1Lines.fridge())
		"bookshelf":
			await think(Scene1Lines.bookshelf())


func _give_mug() -> void:
	alex.rig.prop_front = "none"
	alex.rig.pose_front = "none"
	june.rig.prop_front = "mug"
	june.rig.pose_front = "hold_radio"
	june.rig.expression = "happy"
	await wait(1.0)


func _tv_scene() -> void:
	Inputs.input_locked = true
	alex.walk_to(tv.global_position.x + 260.0, false, -1)
	await alex.arrived
	ui.letterbox(true, 0.5)
	alex.rig.look = Vector2(0.2, -0.5)
	cam.shot(tv.global_position + Vector2(40, -300), 2.2, 1.2, 0.02)
	await wait(1.2)
	ui.set_hud("DAY 1", "7:51 PM", "APARTMENT 4C", "")
	await dialog.run(Scene1Lines.tv_news(func(n): tv.news_stage = n, _tv_off))
	alex.rig.look = Vector2.ZERO
	ui.hide_caption()
	cam.shot(june.rig.head_global_position() + Vector2(0, 120), 1.6, 1.0)
	june.rig.facing = -1
	june.rig.expression = "scared"
	await wait(0.9)
	await dialog.run(Scene1Lines.june_calls())
	ui.hide_caption()
	ui.letterbox(false, 0.5)
	cam.follow(alex, 1.0, 1.2)
	alex.rig.expression = "worried"
	_s1_stage("radio")
	Inputs.input_locked = false


func _tv_off() -> void:
	tv.powered = false
	tv_light.base_energy = 0.0
	await wait(0.4)


func _sirens() -> void:
	siren.base_energy = 0.45
	window_view.unrest = 0.85
	cam.shake(7.0)
	june.rig.expression = "surprised"
	alex.rig.expression = "surprised"
	await wait(0.8)
	await dialog.run([
		{say = "june", t = "What was *that?!*", face = "scared", shot = "two"},
		{say = "alex", t = "The window. Come on.", face = "determined", pose = "point"},
	])
	dialog.end()
	june.walk_to(window_view.global_position.x + 120.0, false, -1)


func _window_scene() -> void:
	Inputs.input_locked = true
	ui.set_hud("DAY 1", "8:04 PM", "APARTMENT 4C", "")
	alex.walk_to(window_view.global_position.x - 40.0, false, 1)
	june.walk_to(window_view.global_position.x + 110.0, false, -1)
	await alex.arrived
	ui.letterbox(true, 0.6)
	window_view.unrest = 1.0
	cam.shot(window_view.global_position + Vector2(30, -200), 1.35, 1.6, 0.015)
	alex.rig.look = Vector2(0.3, -0.3)
	june.rig.look = Vector2(0.3, -0.3)
	await wait(1.8)
	dialog.face_each_other("alex", "june")
	await dialog.run(Scene1Lines.window_scene())
	dialog.end()
	_june_idle()
	june.rig.facing = -1
	june.rig.look = Vector2.ZERO
	june.rig.expression = "worried"
	_s1_stage("leave")


func _leave_s1() -> void:
	Inputs.input_locked = true
	alex.walk_to($Interactables/door.global_position.x + 40.0, false, -1)
	await alex.arrived
	await dialog.run(Scene1Lines.door_leave())
	ui.hide_caption()
	await finish("s2", "SCENE 2", "CHECKING THE BUILDING")


# ===================================================================================
# Scenes 3 + 4
# ===================================================================================

func _setup_after(door_open: bool) -> void:
	june.visible = false
	june.set_physics_process(false)
	front_door.label = "4C_open" if door_open else "4C"
	front_door.queue_redraw()
	var chair: Node2D = $Props/Chair
	chair.rotation = -1.35
	chair.position += Vector2(-60, -30)
	tv.news_stage = 2
	window_view.unrest = 0.7
	siren.base_energy = 0.15
	alex.rig.prop_front = "none"


func _scene3() -> void:
	_setup_after(true)
	alex.global_position = Vector2(300, 78)
	alex.rig.facing = 1
	ui.set_hud("DAY 1", "8:31 PM", "APARTMENT 4C", "Find June")
	await chapter_intro("", "")
	cam.cut(alex.global_position + Vector2(300, -380), 1.0)
	cam.follow(alex, 1.0, 1.2)
	await wait(0.6)
	await dialog.run(HomeLines.return_home())
	ui.hide_caption()
	Inputs.input_locked = false
	stage = "search"
	for id in ["receiver", "chair"]:
		enable(id)
	set_objective("Search the apartment for June")
	if autoplay:
		await bot_use("chair")
		await bot_use("receiver")


func _june_texts() -> void:
	# her messages finally come through
	Inputs.input_locked = true
	await wait(0.4)
	ui.toast("Phone: 4 new messages")
	ui.phone.clear()
	ui.phone.set_time("8:34", false)
	ui.letterbox(true, 0.6)
	alex.rig.pose_front = "phone"
	alex.rig.prop_front = "phone"
	alex.rig.look = Vector2(0.3, 0.5)
	alex.rig.expression = "worried"
	cam.shot(alex.rig.head_global_position() + Vector2(-260, 60), 1.8, 1.4, 0.02)
	await ui.phone.open()
	for m in HomeLines.JUNE_TEXTS:
		ui.phone.add_message(false, m[1], m[0])
		await wait(1.5)
	alex.rig.expression = "sad"
	await dialog.run(HomeLines.reply_choice())
	var row := ui.phone.add_message(true, HomeLines.reply_text(str(Game.flag("reply", "coming"))), "8:35 PM  · sending...")
	await wait(1.6)
	row.queue_free()
	ui.phone.add_message(true, HomeLines.reply_text(str(Game.flag("reply", "coming"))), "", "failed")
	await wait(1.4)
	await dialog.run(HomeLines.not_delivered())
	ui.hide_caption()
	await ui.phone.close()
	alex.rig.pose_front = "none"
	alex.rig.prop_front = "none"
	alex.rig.look = Vector2.ZERO
	await wait(0.6)
	ui.letterbox(false, 0.6)
	cam.follow(alex, 1.0, 1.0)
	Game.phase = "s4"
	Game.save_checkpoint("s4")
	await _scene4()


func _scene4(direct := false) -> void:
	Inputs.input_locked = true
	if direct:
		ui.set_hud("DAY 1", "9:12 PM", "APARTMENT 4C", "")
		await chapter_intro("", "")
		alex.global_position = Vector2(1700, 78)
		cam.cut(alex.global_position + Vector2(0, -400), 1.0)
		cam.follow(alex, 1.0, 0.5)
	ui.set_hud("DAY 1", "9:12 PM", "APARTMENT 4C", "")
	# the alert: phone + TV at the same time
	tv.powered = true
	tv.news_stage = 3
	tv_light.base_energy = 0.9
	cam.shake(4.0)
	ui.phone.clear()
	ui.phone.set_time("21:12", true)
	ui.phone.show_alert("EMERGENCY ALERT", "City Emergency Notice in effect. Read and follow ALL instructions. Stay tuned to official channels.")
	await ui.phone.open()
	ui.phone.buzz()
	await wait(2.2)
	await ui.phone.close()
	Game.set_flag("rules_known", true)
	await ui.notice.present(autoplay)
	await dialog.run(HomeLines.after_notice())
	ui.hide_caption()
	ui.toast("TAB  ·  view the rules any time")
	stage = "prepare"
	tasks = {"lock": false, "phone": false, "supplies": false, "pack": false}
	for id in ["door", "phone", "supplies", "pack", "storage", "window", "sofa", "tv", "photo"]:
		enable(id)
	_update_tasks()
	Inputs.input_locked = false
	if autoplay:
		for id in ["door", "phone", "supplies", "storage", "pack", "window", "sofa"]:
			await bot_use(id)


func _update_tasks() -> void:
	var names := {"lock": "Lock the door", "phone": "Silence phone", "supplies": "Check supplies", "pack": "Pack go-bag"}
	var parts := []
	for k in tasks:
		parts.append(("✓ " if tasks[k] else "○ ") + names[k])
	var all_done := not tasks.values().has(false)
	set_objective("Rest on the sofa" if all_done else "Prepare:  " + "   ".join(parts))


func _s4_interact(id: String) -> void:
	match id:
		"chair":
			await think(HomeLines.tipped_chair())
		"receiver":
			if stage == "search":
				await think(HomeLines.empty_desk())
				stage = "texts"
				enable("receiver", false)
				enable("chair", false)
				await _june_texts()
		"door":
			if not tasks.lock:
				Inputs.input_locked = true
				alex.walk_to($Interactables/door.global_position.x + 30.0, false, -1)
				await alex.arrived
				front_door.label = "4C"
				front_door.queue_redraw()
				alex.rig.pose_front = "reach"
				await wait(0.5)
				cam.shake(1.5)
				alex.rig.pose_front = "none"
				tasks.lock = true
				Game.set_flag("locked_door", true)
				ui.rule_flash(1)
				await think(HomeLines.lock_door())
				_update_tasks()
			else:
				await think([{think = "Locked. Chain on.", face = "neutral"}])
		"phone":
			if not tasks.phone:
				Inputs.input_locked = true
				alex.rig.pose_front = "phone"
				alex.rig.prop_front = "phone"
				ui.phone.clear()
				ui.phone.show_silent()
				await ui.phone.open()
				await wait(1.0)
				await ui.phone.close()
				alex.rig.pose_front = "none"
				alex.rig.prop_front = "none"
				tasks.phone = true
				Game.set_flag("phone_silent", true)
				ui.rule_flash(2)
				await think(HomeLines.silence_phone())
				_update_tasks()
		"supplies":
			if not tasks.supplies:
				Inputs.input_locked = true
				await dialog.run(HomeLines.supplies_intro())
				ui.rule_flash(4)
				await dialog.run(HomeLines.supplies_choice())
				ui.hide_caption()
				tasks.supplies = true
				cam.follow(alex, 1.0, 0.9)
				Inputs.input_locked = false
				_update_tasks()
		"storage":
			if not Game.flag("ammo_box"):
				await think(HomeLines.storage_box())
				Game.set_flag("ammo_box", true)
				ui.toast("+8 rounds (spare magazine)")
			else:
				await think([{think = "Empty now.", face = "neutral"}])
		"pack":
			if not tasks.pack:
				await think(HomeLines.pack_bag(Game.flag("ammo_box")))
				Game.set_flag("packed", true)
				Game.set_flag("bandages", 2)
				ui.rule_flash(5)
				ui.toast("Go-bag packed  ·  2 bandages")
				tasks.pack = true
				_update_tasks()
		"window":
			await think(HomeLines.window_night())
			ui.rule_flash(3)
		"tv":
			await think([{think = "The same six rules, over and over.", face = "tired"}])
		"photo":
			await think([{think = "I'll find you, June. Rules first. Then I find you.", face = "sad"}])
		"sofa":
			if tasks.values().has(false):
				await think(HomeLines.tasks_left())
			else:
				await _sleep()


func _sleep() -> void:
	Inputs.input_locked = true
	alex.walk_to($Interactables/sofa.global_position.x, false, 1)
	await alex.arrived
	var tw := create_tween()
	tw.tween_property(alex.rig, "sit", 1.0, 0.6)
	await dialog.run(HomeLines.sleep())
	ui.hide_caption()
	ui.rule_flash(6)
	await ui.fade(true, 1.6).finished
	await ui.title_card("DAY 2", "6:47 AM", 1.2)
	Game.phase = "s5"
	Game.save_checkpoint("s5")
	_setup_morning()
	await _scene5()


# ===================================================================================
# Scene 5
# ===================================================================================

func _setup_morning() -> void:
	_setup_after(false)
	tv.powered = false
	tv_light.base_energy = 0.0
	$CanvasModulate.color = Color(0.72, 0.7, 0.72)
	$Lights/Lamp.base_energy = 0.0
	$Lights/LampFill.base_energy = 0.0
	$Lights/WindowCold.base_energy = 1.1
	$Lights/WindowCold.radius = 1100.0
	$Lights/DeskLamp.base_energy = 0.35
	siren.base_energy = 0.0
	window_view.daylight = 1.0
	window_view.unrest = 0.5
	for id in ["kettle", "june", "tv", "photo", "fridge", "bookshelf", "window", "door", "phone", "storage", "supplies", "sofa", "receiver", "pack", "chair"]:
		enable(id, false)


func _scene5() -> void:
	Inputs.input_locked = true
	alex.global_position = Vector2($Interactables/sofa.global_position.x, 78)
	alex.rig.facing = 1
	alex.rig.sit = 1.0
	alex.rig.expression = "tired"
	ui.set_hud("DAY 2", "6:47 AM", "APARTMENT 4C", "")
	cam.cut(alex.global_position + Vector2(100, -360), 1.2)
	await ui.fade(false, 1.4).finished
	ui.show_hud(true)
	await dialog.run(HomeLines.wake_up())
	ui.hide_caption()
	var tw := create_tween()
	tw.tween_property(alex.rig, "sit", 0.0, 0.5)
	await tw.finished
	cam.follow(alex, 1.0, 1.0)
	stage = "radio"
	enable("receiver")
	set_objective("Check June's radio receiver")
	Inputs.input_locked = false
	if autoplay:
		await bot_use("receiver")
		await bot_use("door")
		await bot_use("door")


func _s5_interact(id: String) -> void:
	match id:
		"receiver":
			if stage == "radio":
				await _radio_scene()
		"door":
			if stage == "peephole":
				Inputs.input_locked = true
				alex.walk_to($Interactables/door.global_position.x + 20.0, false, -1)
				await alex.arrived
				ui.letterbox(true, 0.4)
				ui.over.show_peephole(true)
				await wait(1.2)
				await dialog.run(HomeLines.peephole())
				ui.rule_flash(3)
				await wait(2.0)
				await dialog.run(HomeLines.peephole_clear())
				ui.over.show_peephole(false)
				ui.hide_caption()
				ui.letterbox(false, 0.4)
				stage = "leave"
				Inputs.input_locked = false
				set_objective("Go to the stairwell — front door")
			elif stage == "leave":
				await think(HomeLines.before_leave(true))
				await finish("s6", "SCENE 6", "STAIRWELL EVACUATION")


func _radio_scene() -> void:
	Inputs.input_locked = true
	alex.walk_to($Interactables/receiver.global_position.x - 110.0, false, 1)
	await alex.arrived
	ui.letterbox(true, 0.5)
	cam.shot(alex.rig.head_global_position() + Vector2(120, 60), 1.7, 1.0, 0.01)
	alex.rig.look = Vector2(0.3, 0.4)
	alex.rig.pose_front = "reach"
	if Game.flag("recorded_frequency"):
		await dialog.run(HomeLines.tune_known())
		ui.hide_caption()
		ui.toast("Tuned to 146.52 MHz")
		await wait(0.8)
	else:
		await dialog.run(HomeLines.tune_unknown())
		ui.hide_caption()
		ui.over.bot_tune = autoplay
		ui.over.start_tuning(146.52)
		Inputs.input_locked = false
		alex.player_controlled = false
		await ui.over.tuned
		alex.player_controlled = not autoplay
		Inputs.input_locked = true
		await wait(0.5)
	alex.rig.pose_front = "none"
	await dialog.run(HomeLines.june_transmission())
	ui.hide_caption()
	cam.shake(2.0)
	await wait(0.5)
	alex.rig.look = Vector2.ZERO
	ui.phone.clear()
	ui.phone.set_time("07:58", true)
	ui.phone.show_alert("OFFICIAL EVACUATION", "Tower 9 residents: rooftop helicopter pickup at 08:30. Use the stairs. Move quietly.")
	await ui.phone.open()
	ui.phone.buzz()
	await dialog.run(HomeLines.announcement())
	ui.hide_caption()
	await ui.phone.close()
	ui.letterbox(false, 0.5)
	cam.follow(alex, 1.0, 1.0)
	ui.set_hud("DAY 2", "7:58 AM", "APARTMENT 4C", "")
	stage = "peephole"
	enable("receiver", false)
	enable("door")
	set_objective("Leave for the roof — front door")
	Inputs.input_locked = false
