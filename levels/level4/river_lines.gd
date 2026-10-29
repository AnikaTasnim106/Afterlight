class_name RiverLines
## Level 4 — The River. Dialogue.


static func arrive() -> Array:
	return [
		{say = "ward", t = "The bridges are all down or blocked. We need a boat.", face = "worried", shot = "two"},
		{say = "mara", t = "Someone's on that houseboat. There's a light.", face = "curious", pose = "point"},
	]


static func gus_meet() -> Array:
	return [
		{say = "gus", t = "Stop right there. ...You three don't look *sick.* You look tired.", face = "tired", shot = "two"},
		{say = "alex", t = "We need to get across to Harbor Point.", face = "determined", shot = "close"},
		{say = "gus", t = "Everyone wants Harbor Point. My *Mary Ann* could do it — if she had fuel. Tank's dry.", face = "neutral", shot = "close"},
		{say = "gus", t = "Fuel dock's at the end of the pier. Two cans in the locker. Those *things* wander out there at dusk.", face = "worried"},
		{choice = [
			{t = "\"We'll get the fuel. You'll come with us.\"", set = {gus_trust = true}, then = [
				{say = "alex", t = "We'll get the fuel. And you're coming with us.", face = "determined", shot = "close"},
				{say = "gus", t = "Forty years on this river, son. I'm the only one who knows where the wrecks are.", face = "smile"},
			]},
			{t = "\"Why haven't you crossed already?\"", then = [
				{say = "alex", t = "Why haven't you crossed already?", face = "curious", shot = "close"},
				{say = "gus", t = "Alone? Past the old ferry? I'm brave, not *stupid.*", face = "tired"},
			]},
		]},
	]


static func carry_hint() -> Array:
	return [{think = "I can't hold a gun and a fuel can at the same time. Quiet, then.", face = "worried"}]


static func both_loaded() -> Array:
	return [
		{say = "gus", t = "That's both. She'll run. Give me a minute with the engine.", face = "smile", shot = "two"},
	]


static func mara_promise() -> Array:
	return [
		{say = "mara", t = "Alex. Can I ask you something?", face = "worried", shot = "two"},
		{say = "mara", t = "If we get there and Theo is... if he's one of *them.*", face = "sad", shot = "close"},
		{choice = [
			{t = "\"Then Dr. Ward's compound is for him.\"", add = {mara_trust = 1}, set = {promised_theo = true}, then = [
				{say = "alex", t = "Then that's what Dr. Ward's compound is for. We bring him back.", face = "determined", shot = "close"},
				{say = "mara", t = "...You really believe that.", face = "sad"},
				{say = "alex", t = "I have to. Same as you.", face = "determined"},
			]},
			{t = "\"We don't think about that until we have to.\"", then = [
				{say = "alex", t = "We don't think about that until we have to.", face = "worried", shot = "close"},
				{say = "mara", t = "That's not an answer. ...But it's honest.", face = "tired"},
			]},
		]},
		{say = "mara", t = "Thanks. For not lying to me.", face = "neutral", shot = "two"},
	]


static func cast_off() -> Array:
	return [{say = "gus", t = "All aboard the *Mary Ann.* Hold on to something.", face = "smile", shot = "two"}]


# --- crossing -------------------------------------------------------------------------

static func crossing_start() -> Array:
	return [
		{say = "gus", t = "Old ferry's dead ahead. Wreck's crawling with 'em. Keep them *off my boat!*", face = "worried", shot = "two"},
	]


static func crossing_mid() -> Array:
	return [{say = "mara", t = "They're climbing out of the water— *left side!*", face = "scared", shot = "keep"}]


static func gate() -> Array:
	return [
		{say = "soldier", t = "*Stop!* Turn that boat around! Harbor Point is under *quarantine!*", face = "angry", shot = "two"},
		{say = "ward", t = "I'm Dr. Elena Ward — research team, clearance W-7! I have the *compound samples!*", face = "determined", shot = "close"},
		{say = "soldier", t = "...Dr. Ward? They said you were dead at Bravo.", face = "surprised"},
		{say = "ward", t = "Not yet. These three are with me. All of them.", face = "determined"},
		{say = "soldier", t = "*[into radio]* Open the river gate. Doctor's back.", face = "neutral"},
	]
