extends Node
## Registers input actions in code so project.godot stays readable.
## Edit the table below to rebind keys.

const BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"run": [KEY_SHIFT],
	"interact": [KEY_E],
	"advance": [KEY_SPACE, KEY_ENTER],
	"choice_1": [KEY_1],
	"choice_2": [KEY_2],
	"choice_3": [KEY_3],
	"restart": [KEY_R],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"reload": [KEY_R],
	"bandage": [KEY_H],
	"rules": [KEY_TAB, KEY_N],
	"skip": [KEY_ESCAPE],
	"crouch": [KEY_C],
}

const MOUSE_BINDINGS := {
	"shoot": [MOUSE_BUTTON_LEFT],
}

## Web: the click that gives the game keyboard focus must not count as a shot.
var _need_focus_click := OS.has_feature("web")
var _block_shot_until := 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_need_focus_click = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_block_shot_until = Engine.get_process_frames() + 12


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_need_focus_click = false
	elif event is InputEventMouseButton and event.pressed:
		if _need_focus_click:
			_need_focus_click = false
			_block_shot_until = Engine.get_process_frames() + 3


## False for the focus click (and a moment after the window regains focus).
func shot_allowed() -> bool:
	return Engine.get_process_frames() > _block_shot_until


## True while a cutscene owns the characters.
var input_locked := false


## Dev capture: env SHOTS="1.5,4,9" saves screenshots to $SHOT_DIR at those
## seconds; SHOT_QUIT=1 quits after the last one.
var _shots: Array = []
var _shot_t := 0.0


func _ready() -> void:
	var env := OS.get_environment("SHOTS")
	if env != "":
		for s in env.split(","):
			_shots.append(float(s))
	for action in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	for action in MOUSE_BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for b in MOUSE_BINDINGS[action]:
			var mb := InputEventMouseButton.new()
			mb.button_index = b
			InputMap.action_add_event(action, mb)
	# Ctrl also shoots (laptop trackpads) — not in browsers, where Ctrl+W closes the tab
	if not OS.has_feature("web"):
		var ctrl := InputEventKey.new()
		ctrl.physical_keycode = KEY_CTRL
		InputMap.action_add_event("shoot", ctrl)


## Command-line flags after `--`, e.g. `godot --path . -- --demo`
func has_flag(flag: String) -> bool:
	return flag in OS.get_cmdline_user_args()


func _process(dt: float) -> void:
	if _shots.is_empty():
		return
	_shot_t += dt
	if _shot_t >= _shots[0]:
		var path := OS.get_environment("SHOT_DIR") + "/shot_%05.1f.png" % _shots[0]
		get_viewport().get_texture().get_image().save_png(path)
		_shots.pop_front()
		if _shots.is_empty() and OS.get_environment("SHOT_QUIT") == "1":
			get_tree().quit()
