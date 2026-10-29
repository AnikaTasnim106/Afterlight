class_name LevelBase
extends Node2D
## Shared behaviour for every playable scene:
## interaction prompts (E), conversations, thoughts, chapter intro/outro,
## fail → retry from checkpoint, and the autoplay test bot hooks.

var cam: CameraDirector
var ui: CinemaUI
var alex: Actor
var dialog: DialogueRunner
var autoplay := false

var _busy := false
var _current: Interactable
var _ended := false
var _failing := false


func _ready() -> void:
	cam = $Camera
	ui = $CinemaUI
	alex = $Actors/Alex
	alex.add_to_group("living")
	alex.footstep_noise = true
	dialog = DialogueRunner.new()
	add_child(dialog)
	dialog.ui = ui
	dialog.cam = cam
	dialog.actors = {"alex": alex}
	autoplay = Inputs.has_flag("--autoplay")
	if autoplay:
		ui.auto_advance = true
		ui.auto_default = true
		var env := OS.get_environment("AUTOCHOICES")
		for c in env.split(",", false):
			ui.auto_choices.append(int(c))
	Inputs.input_locked = false


func register(id: String, a: Actor) -> void:
	dialog.actors[id] = a


# --- interaction loop ------------------------------------------------------------

func _process(_dt: float) -> void:
	# Safety net: a cinematic shot left the camera parked, but the player has
	# control again and is walking — go back to following Alex.
	if not Inputs.input_locked and not _ended and cam.is_shot() and alex.alive and absf(alex.velocity.x) > 30.0:
		cam.follow(alex, cam.follow_zoom, 0.8)
	if _busy or Inputs.input_locked or _ended or not alex.alive or alex.stair != null:
		if _current:
			ui.hide_prompt()
			_current = null
		return
	var best: Interactable = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null or not it.enabled or not it.is_visible_in_tree():
			continue
		if absf(it.global_position.y - alex.global_position.y) > 90.0:
			continue
		var d := absf(it.global_position.x - alex.global_position.x)
		if d < it.reach and d < best_d:
			best = it
			best_d = d
	if best != _current:
		_current = best
		if best:
			ui.show_prompt("E   " + best.prompt, best.prompt_position())
		else:
			ui.hide_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current and not _busy and not Inputs.input_locked:
		do_interact(_current.id)


func do_interact(id: String) -> void:
	_busy = true
	ui.hide_prompt()
	_current = null
	alex.velocity.x = 0.0
	await interact(id)
	_busy = false


## Override in each level.
func interact(_id: String) -> void:
	pass


func enable(id: String, on := true) -> void:
	var n := get_node_or_null("Interactables/" + id)
	if n:
		n.enabled = on


# --- dialogue helpers ------------------------------------------------------------

var _barking := false

## Short lines during gameplay: auto-advancing captions that don't lock input.
func bark(lines: Array) -> void:
	if _barking or Inputs.input_locked:
		return
	_barking = true
	ui.auto_advance = true
	for it in lines:
		if Inputs.input_locked or _ended:
			break
		var who: String = it.get("say", "")
		var nm: String = DialogueRunner.NAMES.get(who, who.to_upper()) if who != "" else ""
		var txt: String = it.get("t", "") if who != "" else "( " + str(it.get("think", "")) + " )"
		await ui.say(nm, txt, float(it.get("hold", 0.6)) + 0.6)
	# always hand the caption back in its normal mode, even if a cutscene
	# locked input while this bark was still on screen
	ui.auto_advance = ui.auto_default
	if not Inputs.input_locked:
		ui.hide_caption()
	_barking = false


func think(lines: Array) -> void:
	Inputs.input_locked = true
	await dialog.run(lines)
	ui.hide_caption()
	Inputs.input_locked = false


func conversation(partner: String, lines: Array, close_after := true, gap := 150.0) -> void:
	var other: Actor = dialog.actors[partner]
	var side := -1.0 if alex.global_position.x < other.global_position.x else 1.0
	var target := other.global_position.x + side * gap
	var fl := Nav.floor_at(get_tree(), other.global_position)
	if fl and (target < fl.x_range().x + 40.0 or target > fl.x_range().y - 40.0):
		target = other.global_position.x - side * gap
		target = clampf(target, fl.x_range().x + 40.0, fl.x_range().y - 40.0)
	if absf(alex.global_position.x - target) > 20.0 and absf(alex.global_position.y - other.global_position.y) < 40.0:
		Inputs.input_locked = true
		alex.walk_to(target)
		await alex.arrived
	dialog.begin(partner)
	await wait(0.3)
	await dialog.run(lines)
	if close_after:
		dialog.end()


func wait(s: float) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(s).timeout


func set_objective(t: String) -> void:
	ui.set_objective(t)


# --- chapter flow ---------------------------------------------------------------

func chapter_intro(title: String, sub: String) -> void:
	Inputs.input_locked = true
	ui.set_black(true)
	await wait(0.3)
	if title != "":
		await ui.title_card(title, sub, 1.2)
	ui.fade(false, 1.0)
	ui.show_hud(true)


func finish(next: String, card_title := "", card_sub := "") -> void:
	_ended = true
	Inputs.input_locked = true
	ui.hide_prompt()
	ui.show_hud(false)
	await ui.fade(true, 1.0).finished
	if card_title != "":
		await ui.title_card(card_title, card_sub, 1.4)
	if autoplay:
		print("CHAPTER_DONE ", Game.phase, " -> ", next, " flags=", Game.flags)
		if OS.get_environment("CHAIN") == "1" and next != "":
			Game.goto(next)
		else:
			get_tree().quit()
		return
	if next != "":
		Game.goto(next)


## Something went wrong (Alex or a survivor died): retry from the checkpoint.
func fail(msg: String) -> void:
	if _failing:
		return
	_failing = true
	_ended = true
	Inputs.input_locked = true
	Engine.time_scale = 0.35
	await get_tree().create_timer(0.6 * 0.35).timeout
	Engine.time_scale = 1.0
	await ui.fade(true, 0.8).finished
	await ui.title_card("TRY AGAIN", msg, 1.4)
	if autoplay:
		print("FAILED ", Game.phase, ": ", msg)
		get_tree().quit()
		return
	Game.retry()


# --- autoplay bot helpers -------------------------------------------------------

func bot_walk(x: float, run := false) -> void:
	if not is_inside_tree():
		return
	alex.player_controlled = false
	alex.walk_to(x, run)
	await alex.arrived
	await wait(0.3)


func bot_use(id: String) -> void:
	var n: Interactable = get_node("Interactables/" + id)
	if absf(n.global_position.x - alex.global_position.x) > n.reach * 0.9:
		await bot_walk(n.global_position.x)
	print("BOT use ", id)
	await do_interact(id)
	await wait(0.4)


## Bot climbs/descends stairs by navigating to a world position on another floor.
func bot_go(pos: Vector2, run := false, timeout := 40.0) -> bool:
	alex.player_controlled = false
	alex.nav_target = pos
	alex.nav_run = run
	alex.nav_stop = 20.0
	var t := 0.0
	while t < timeout:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if alex.stair == null and absf(alex.global_position.y - pos.y) < 30.0 and absf(alex.global_position.x - pos.x) < 30.0:
			alex.nav_target = Vector2.INF
			return true
		if not alex.alive:
			return false
		if OS.get_environment("BOT_TRACE") == "1" and fmod(t, 0.5) < get_physics_process_delta_time():
			print("  trace pos=", alex.global_position, " stair=", alex.stair, " mask=", alex.collision_mask, " floor=", alex.is_on_floor())
	alex.nav_target = Vector2.INF
	print("BOT go timeout to ", pos, " at ", alex.global_position)
	return false
