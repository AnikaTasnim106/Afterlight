class_name StairLines
## Level 1 · Scenes 6 & 7 dialogue.


static func start() -> Array:
	return [
		{think = "Floor four to the roof. Three floors. Quietly.", face = "determined"},
	]


static func first_zombie() -> Array:
	return [
		{think = "Someone on the landing. Swaying. Not right.", face = "scared"},
		{think = "If I shoot, everything below us will hear it.", face = "worried"},
	]


static func meet_survivors() -> Array:
	return [
		{say = "nadia", t = "Alex! Oh thank god— Shh, shh, *baby,* please...", face = "scared", shot = "two"},
		{say = "das", t = "My leg gave out on the stairs. Go on without me. Take *her.*", face = "hurt"},
		{choice = [
			{t = "\"Nobody gets left behind.\"", set = {no_one_left = true}, then = [
				{say = "alex", t = "Nobody gets left behind. We go *together.*", face = "determined", shot = "close"},
				{say = "das", t = "...Stubborn boy. Like your father.", face = "relieved"},
			]},
			{t = "\"Nina, stay close. I'll cover Mr. Daniels.\"", then = [
				{say = "alex", t = "Nina, stay right behind me. I'll watch Mr. Daniels.", face = "determined", shot = "close"},
				{say = "nadia", t = "Okay. Okay. Shh, shh...", face = "worried"},
			]},
		]},
		{say = "nadia", t = "She won't *stop crying.* They'll hear us.", face = "scared"},
		{think = "Then we move fast. Rule two is already broken.", face = "determined"},
	]


static func they_heard() -> Array:
	return [{say = "das", t = "Listen— *below us.* Footsteps.", face = "scared", hold = 0.6}]


static func phone_silent() -> Array:
	return [{think = "My phone just buzzed. Silent. Good thing.", face = "neutral"}]


static func phone_loud() -> Array:
	return [{think = "My phone! I never silenced it—", face = "scared"}]


static func roof_wait() -> Array:
	return [{think = "Not without Nina and Mr. Daniels.", face = "determined"}]


# --- Scene 7: roof -----------------------------------------------------------------

static func roof_arrive() -> Array:
	return [
		{say = "nadia", t = "The sky... we made it. We *made* it.", face = "relieved", shot = "two"},
		{think = "No helicopter. Not yet.", face = "worried", look = Vector2(0.3, -0.6)},
		{say = "das", t = "They'll come up the stairs after us. Bar the door if you can.", face = "worried"},
	]


static func heli_arrives() -> Array:
	return [{say = "soldier", t = "MOVE! MOVE! *Get to the bird!*", face = "determined", hold = 0.6}]


static func heli_inside() -> Array:
	return [
		{say = "mara", t = "You cut that close.", face = "neutral", shot = "two"},
		{choice = [
			{t = "\"Story of my week.\"", then = [
				{say = "alex", t = "Story of my week.", face = "tired", shot = "close"},
				{say = "mara", t = "Week's only two days old.", face = "smile"},
			]},
			{t = "\"Are you hurt?\"", then = [
				{say = "alex", t = "Are you hurt?", face = "worried", shot = "close"},
				{say = "mara", t = "Not on the outside.", face = "sad"},
			]},
		]},
		{say = "mara", t = "Mara.", face = "neutral"},
		{say = "alex", t = "Alex.", face = "neutral"},
		{say = "mara", t = "You looking for someone? You've got that look.", face = "curious", shot = "close"},
		{say = "alex", t = "My sister. June. The soldiers took her on the first evacuation.", face = "sad", shot = "close"},
		{say = "mara", t = "My brother, Theo. Same night. *Same story.*", face = "sad"},
	]


static func ask_soldier() -> Array:
	return [
		{say = "alex", t = "The people from the first evacuation — where did they go? A girl, sixteen, yellow hoodie, a radio—", face = "determined", shot = "two"},
		{say = "soldier", t = "Relief Zone Bravo, probably. Evacuation records get checked at the destination.", face = "neutral", shot = "close"},
		{say = "soldier", t = "That's all I've got, sir. Sit down and hold on.", face = "tired"},
	]


static func cliffhanger() -> Array:
	return [
		{say = "pilot", t = "Bravo, this is Kestrel-2, inbound with eleven civilians, ETA four minutes.", hold = 0.8},
		{say = "pilot", t = "*[static]* Kestrel— abort, abort— we have a *breach* on the east fence—", hold = 0.8},
		{say = "pilot", t = "*[static]*", hold = 0.6},
		{say = "mara", t = "...Did he just say *breach?*", face = "scared", shot = "two"},
	]
