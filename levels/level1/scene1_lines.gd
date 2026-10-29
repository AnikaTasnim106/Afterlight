class_name Scene1Lines
## Level 1 · Scene 1 — "A normal evening". All dialogue lives here.
## Edit freely: each line carries the speaker's acting (face / pose / prop)
## and the camera shot. See core/dialogue_runner.gd for the format.
##
## Expressions: neutral smile happy worried scared sad surprised determined angry curious tired
## Poses: none hold_radio radio_ear point phone open_hand reach chest fist wave shrug
## Props: none radio phone mug
## Shots: two close wide keep


# --- small interactions --------------------------------------------------------

static func kettle() -> Array:
	return [
		{think = "Two sugars for her. None for me.", face = "smile"},
		{think = "One of us has to be the responsible one.", face = "neutral"},
	]


static func kettle_again() -> Array:
	return [{think = "Kettle's still warm. June's tea first.", face = "neutral"}]


static func photo() -> Array:
	return [
		{think = "June's first fishing trip. She caught a boot.", face = "smile"},
		{think = "She still says it was a 'rare species of fish'.", face = "happy"},
	]


static func fridge() -> Array:
	return [{think = "Eggs, rice, half a lemon... and June's 'do not eat' circuit board.", face = "tired"}]


static func bookshelf() -> Array:
	return [{think = "Radio manuals, more radio manuals, and one cookbook nobody has opened.", face = "smile"}]


static func door_early() -> Array:
	return [{think = "Not going anywhere tonight. Movie night, if June ever leaves that radio.", face = "neutral"}]


static func window_early() -> Array:
	return [{think = "More helicopters than usual. Probably a traffic jam on the bridge.", face = "curious", look = Vector2(0.3, -0.2)}]


static func june_no_tea() -> Array:
	return [
		{say = "june", t = "Is my tea coming, or is it *imaginary* tea?", face = "smile", shot = "two"},
		{think = "Right. The kettle.", face = "smile"},
	]


static func june_busy() -> Array:
	return [{say = "june", t = "Shh... I'm listening. Check the *TV* for me?", face = "curious", pose = "radio_ear", shot = "two"}]


# --- conversation 1: tea -----------------------------------------------------------

static func conv1_tea(give_mug: Callable) -> Array:
	return [
		{say = "june", t = "Is that for me, or are you just showing it off?", face = "smile", pose = "none", prop = "none", shot = "two", react = {alex = "smile"}},
		{choice = [
			{t = "\"Two sugars. Exactly how you like it.\"", add = {june_bond = 1}, then = [
				{say = "alex", t = "Two sugars. Exactly how you like it.", face = "smile", shot = "close"},
				{say = "june", t = "See? This is why you're my *favourite* brother.", face = "happy", shot = "close"},
				{say = "alex", t = "I'm your *only* brother.", face = "smile", pose = "shrug"},
				{say = "june", t = "Still counts.", face = "happy", pose = "point"},
			]},
			{t = "\"Only if you stop soldering at the dinner table.\"", set = {teased_june = true}, then = [
				{say = "alex", t = "Only if you stop soldering at the dinner table.", face = "smile", shot = "close", pose = "point"},
				{say = "june", t = "That was *one* time. And the toaster works better now.", face = "angry", pose = "open_hand", shot = "close"},
				{say = "alex", t = "It makes toast in four seconds, June.", face = "tired", pose = "shrug"},
				{say = "june", t = "Exactly. You're *welcome.*", face = "happy", pose = "chest"},
			]},
			{t = "\"What are you working on?\"", set = {asked_radio = true}, then = [
				{say = "alex", t = "What are you working on now?", face = "curious", shot = "close"},
				{say = "june", t = "Scanning the *emergency bands.* Hospitals have been talking non-stop since noon.", face = "curious", pose = "hold_radio", prop = "radio", shot = "close"},
				{say = "alex", t = "Talking about what?", face = "worried"},
				{say = "june", t = "Code words. I can't crack them. *Yet.*", face = "determined"},
			]},
		]},
		{do = give_mug},
		{say = "june", t = "Hey... the news has been weird all day. Can you check the *TV?* I want to keep listening.", face = "worried", pose = "radio_ear", prop = "radio", shot = "two", react = {alex = "neutral"}},
		{say = "alex", t = "Sure. Drink your tea before it gets cold.", face = "smile", pose = "none"},
	]


# --- TV ---------------------------------------------------------------------------------

static func tv_news(set_stage: Callable, tv_off: Callable) -> Array:
	return [
		{do = set_stage.bind(1)},
		{say = "news", t = "...reports of *violent incidents* across the Eastside district. Several streets are now closed...", hold = 1.4},
		{think = "Eastside. That's two bridges from here.", face = "worried", look = Vector2(0.1, -0.5)},
		{choice = [
			{t = "Turn it up.", set = {heard_warning = true}, then = [
				{say = "news", t = "Police ask residents *not to approach* anyone who appears disoriented or aggressive.", hold = 1.4},
				{think = "Disoriented... or aggressive? What kind of warning is that?", face = "worried"},
			]},
			{t = "Switch it off. Don't scare June.", set = {tv_off = true}, then = [
				{do = tv_off},
				{think = "She's got enough on her mind with that radio.", face = "determined"},
			]},
		]},
	]


static func june_calls() -> Array:
	return [{say = "june", t = "Alex! Come here — *now!*", face = "scared", hold = 0.6}]


# --- conversation 2: the radio -------------------------------------------------------

static func conv2_radio(static_burst: Callable) -> Array:
	return [
		{say = "june", t = "Listen. Just *listen.*", face = "scared", pose = "radio_ear", prop = "radio", shot = "two", react = {alex = "worried"}},
		{do = static_burst},
		{say = "radio", t = "...four... seven... one... *stay indoors...* repeat, stay ind—", hold = 1.2},
		{say = "alex", t = "Someone's pranking the frequency.", face = "worried", shot = "close"},
		{say = "june", t = "On a *military* band? Reading a number code?", face = "determined", pose = "hold_radio", shot = "close"},
		{if_flag = "tv_off", then = [
			{say = "june", t = "Wait. You turned the TV *off?* That means it's bad.", face = "worried"},
			{say = "alex", t = "It means I didn't want you panicking.", face = "tired", pose = "shrug"},
		]},
		{choice = [
			{t = "\"Write down the frequency.\"", set = {recorded_frequency = true}, add = {june_bond = 1}, toast = "June saved the frequency.", then = [
				{say = "alex", t = "Write down the frequency. All of it.", face = "determined", shot = "close", pose = "point"},
				{say = "june", t = "One-four-six point five two. I'll *remember* it.", face = "determined", pose = "hold_radio"},
			]},
			{t = "\"Turn it off. You're scaring yourself.\"", set = {dismissed_radio = true}, add = {june_bond = -1}, toast = "June will remember that.", then = [
				{say = "alex", t = "Turn it off, June. You're scaring yourself.", face = "worried", shot = "close", pose = "open_hand"},
				{say = "june", t = "I'm not a *kid,* Alex. Something is happening.", face = "angry", shot = "close"},
			]},
			{t = "\"Can you trace where it's coming from?\"", set = {traced_radio = true}, then = [
				{say = "alex", t = "Can you trace where it's coming from?", face = "curious", shot = "close"},
				{say = "june", t = "Not with this antenna. But it's *close.* Really close.", face = "worried", pose = "radio_ear"},
			]},
		]},
	]


# --- conversation 3: the window ------------------------------------------------------

static func window_scene() -> Array:
	return [
		{think = "Ambulances. Police. ...Are those *army trucks?*", face = "surprised", look = Vector2(0.4, 0.4)},
		{say = "june", t = "People are *running.* Why is everyone running?", face = "scared", pose = "none", shot = "two", look = Vector2(0.4, 0.3)},
		{choice = [
			{t = "\"Hey. Look at me. We're safe up here.\"", add = {june_bond = 1}, then = [
				{say = "alex", t = "Hey. Look at me. We're safe up here.", face = "determined", pose = "open_hand", shot = "close", look = Vector2.ZERO},
				{say = "june", t = "...Okay. Okay.", face = "sad", look = Vector2(0, 0.3), shot = "close"},
			]},
			{t = "\"I don't know. I'm going to find out.\"", then = [
				{say = "alex", t = "I don't know. I'm going to find out.", face = "determined", shot = "close", look = Vector2.ZERO},
				{say = "june", t = "Don't do anything *stupid.*", face = "worried", shot = "close", look = Vector2.ZERO},
			]},
			{t = "\"Your radio said 'stay indoors'. They knew.\"", need = "recorded_frequency", set = {trusts_radio = true}, add = {june_bond = 1}, then = [
				{say = "alex", t = "Your radio said *'stay indoors'.* Someone knew this was coming.", face = "worried", shot = "close", look = Vector2.ZERO},
				{say = "june", t = "Then we stay. *Together.*", face = "determined", shot = "close", look = Vector2.ZERO},
			]},
		]},
		{say = "alex", t = "I'll ask the neighbours what they've heard. *Lock the door* behind me.", face = "determined", pose = "point", shot = "two", look = Vector2.ZERO},
		{say = "june", t = "Take your phone. And Alex? Come back *quick.*", face = "worried", pose = "hold_radio", look = Vector2.ZERO},
	]


static func door_leave() -> Array:
	return [
		{think = "Deadbolt. Chain. She'll lock it after me.", face = "determined"},
		{think = "Ten minutes. Then I'm back.", face = "worried"},
	]
