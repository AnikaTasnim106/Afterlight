class_name HomeLines
## Level 1 · Scenes 3, 4, 5 in the apartment — all dialogue and thoughts.


# --- Scene 3: June is gone ------------------------------------------------------------

static func return_home() -> Array:
	return [
		{think = "The door's open.", face = "worried"},
		{think = "June? ...June!", face = "scared"},
	]


static func empty_desk() -> Array:
	return [
		{think = "Her handheld radio is gone. She took it.", face = "worried"},
		{think = "The big receiver's still here. Still warm.", face = "sad"},
	]


static func tipped_chair() -> Array:
	return [{think = "They left in a hurry. Her tea's still on the table.", face = "sad"}]


const JUNE_TEXTS := [
	["8:19 PM", "Soldiers are here. They're making EVERYONE leave right now"],
	["8:20 PM", "I told them my brother is downstairs. They won't wait"],
	["8:22 PM", "I waited as long as they let me. I'm so sorry"],
	["8:23 PM", "I have my radio. They said something about a stadium? Please find me"],
]


static func reply_choice() -> Array:
	return [
		{choice = [
			{t = "\"I'm coming. Tell me where you are.\"", set = {reply = "coming"}},
			{t = "\"Stay with the soldiers. I'll find you.\"", set = {reply = "stay"}},
			{t = "\"Keep your radio on. Always.\"", set = {reply = "radio"}},
		]},
	]


static func reply_text(key: String) -> String:
	match key:
		"stay":
			return "Stay with the soldiers. I'll find you. I promise."
		"radio":
			return "Keep your radio on. Always. I'll find your channel."
	return "I'm coming. Tell me where you are."


static func not_delivered() -> Array:
	return [
		{think = "Not delivered.", face = "sad", look = Vector2(0.1, 0.5)},
		{think = "No network. Of course there's no network.", face = "sad"},
		{think = "I told her I'd be back in ten minutes.", face = "sad"},
	]


# --- Scene 4: the official rules --------------------------------------------------

static func after_notice() -> Array:
	return [
		{think = "Six rules. Okay.", face = "determined"},
		{think = "I can't find her if I'm dead. Follow the rules. Then find her.", face = "determined"},
	]


static func lock_door() -> Array:
	return [
		{think = "Deadbolt. Chain.", face = "determined"},
		{think = "Nobody gets in tonight.", face = "determined"},
	]


static func silence_phone() -> Array:
	return [{think = "Silent mode. No rings, no alarms. Nothing that makes noise.", face = "determined"}]


static func supplies_intro() -> Array:
	return [{think = "Six bottles of water. Rice, lentils, five cans. Maybe four days. Maybe.", face = "worried"}]


static func supplies_choice() -> Array:
	return [
		{choice = [
			{t = "Eat a small portion. Save the rest.", set = {conserved_food = true}, then = [
				{think = "Half a can of beans. It'll do.", face = "tired"},
			]},
			{t = "Eat properly tonight. Big day tomorrow.", set = {conserved_food = false}, then = [
				{think = "If tomorrow's going to be bad, I need my strength.", face = "neutral"},
			]},
		]},
	]


static func pack_bag(has_ammo: bool) -> Array:
	var lines := [
		{think = "Go-bag: water, flashlight, charger, first-aid kit.", face = "determined"},
		{think = "Two bandage rolls. Hope I don't need them.", face = "worried"},
	]
	if not has_ammo:
		lines.append({think = "The spare magazine is still in the storage box. I should grab it.", face = "neutral"})
	return lines


static func storage_box() -> Array:
	return [
		{think = "Dad's old storage box. Spare magazine, eight rounds.", face = "neutral"},
		{think = "I hoped I'd never need this.", face = "worried"},
	]


static func window_night() -> Array:
	return [
		{think = "Someone's stumbling down the middle of the street. Walking into a car. Again.", face = "scared", look = Vector2(0.3, 0.3)},
		{think = "Rule three. Don't approach. Don't open the door.", face = "determined"},
	]


static func tasks_left() -> Array:
	return [{think = "Not yet. Lock up, silence the phone, check supplies, pack the bag.", face = "determined"}]


static func sleep() -> Array:
	return [
		{think = "Rule six. Wait for official instructions.", face = "tired"},
		{think = "Wherever you are, June... hold on.", face = "sad"},
	]


# --- Scene 5: the next morning ----------------------------------------------------

static func wake_up() -> Array:
	return [
		{think = "Did I sleep? I don't think I slept.", face = "tired"},
		{think = "...Static. June's receiver is picking something up.", face = "curious"},
	]


static func tune_known() -> Array:
	return [{think = "One-four-six point five two. June's channel. She made me memorise it.", face = "determined"}]


static func tune_unknown() -> Array:
	return [{think = "I don't know her frequency. I'll have to scan for it.", face = "worried"}]


static func june_transmission() -> Array:
	return [
		{say = "radio", t = "...Alex? If anyone hears this — it's *June.*", hold = 1.0},
		{say = "radio", t = "They're moving us again. They won't say where. I'm okay, I'm—", hold = 0.8},
		{say = "radio", t = "*[a man's voice]* Hey! Give me that—", hold = 0.6},
		{say = "radio", t = "*[static]*", hold = 0.8},
		{say = "alex", t = "June? *June!*", face = "scared", shot = "close"},
		{choice = [
			{t = "\"Hold on. I'm coming.\"", add = {june_bond = 1}, then = [
				{think = "She's alive. That's all that matters right now.", face = "determined"},
			]},
			{t = "Keep listening.", then = [
				{think = "Nothing. Just static. But she's alive.", face = "sad"},
			]},
		]},
	]


static func announcement() -> Array:
	return [
		{say = "news", t = "OFFICIAL NOTICE: rooftop evacuation by helicopter, *08:30.* Residents of Tower 9, proceed to the *roof.*", hold = 1.4},
		{say = "news", t = "Move *quietly.* Do not use the elevators.", hold = 1.2},
		{think = "The roof. Seven floors. Quietly.", face = "determined"},
	]


static func peephole() -> Array:
	return [
		{think = "Someone's in the corridor. Swaying. Not right.", face = "scared"},
		{think = "Rule three. Don't open the door. Wait.", face = "determined"},
	]


static func peephole_clear() -> Array:
	return [{think = "...It wandered off toward the lift. Now. Quietly.", face = "determined"}]


static func before_leave(packed: bool) -> Array:
	if packed:
		return [{think = "Bag. Gun. Phone on silent. Let's go.", face = "determined"}]
	return [{think = "I should take the go-bag first.", face = "neutral"}]
