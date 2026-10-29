class_name HospitalLines
## Level 5 — Harbor Point. Dialogue.


static func lobby() -> Array:
	return [
		{say = "holly", t = "Dr. Ward! They said— oh thank god. And you two... you'll need *visitor badges* and a screening.", face = "surprised", shot = "two"},
		{say = "ward", t = "They're with me, Holly. Give them badges. I'll take the samples up to the lab.", face = "determined"},
		{say = "holly", t = "Records are on two. The lab's on three. Please don't go anywhere *east.*", face = "worried", shot = "close"},
	]


static func records() -> Array:
	return [
		{think = "Transfers from Relief Zone Bravo, Convoy 7...", face = "determined"},
		{think = "'June — 16 — not infected. Contact case. Held for observation: EAST WING, WARD 4.'", face = "worried"},
		{think = "Status, updated last night: 'WARD SEALED.'", face = "scared"},
	]


static func roster() -> Array:
	return [
		{say = "mara", t = "Alex. The duty roster. Look.", face = "scared", pose = "point", shot = "two"},
		{think = "'T. Vale — orderly — East Wing, Ward 4 — night shift.'", face = "surprised"},
		{say = "mara", t = "He's in there. *With her.*", face = "scared", shot = "close"},
	]


static func lab() -> Array:
	return [
		{say = "chen", t = "Elena. You actually brought them.", face = "surprised", shot = "two"},
		{say = "ward", t = "The last two compound batches, cold. Isaac — is it enough?", face = "worried"},
		{say = "chen", t = "With these we can finish a field dose by morning. Early cases respond. *Really* respond.", face = "determined", shot = "close"},
		{say = "alex", t = "Ward 4. My sister is in there. Why is it sealed?", face = "determined", shot = "close"},
		{say = "chen", t = "An outbreak, two nights ago. Staff and patients are still inside — some sick, most not. Protocol says no entry until we have the dose.", face = "sad", shot = "close"},
		{choice = [
			{t = "\"Protocol can wait. People are alive in there.\"", set = {pushed_chen = true}, then = [
				{say = "alex", t = "Protocol can wait. People are alive in there *now.*", face = "angry", shot = "close"},
				{say = "chen", t = "I know. I can't order anyone in. ...But I can't stop anyone either.", face = "tired"},
			]},
			{t = "\"How long until the dose is ready?\"", then = [
				{say = "alex", t = "How long until the dose is ready?", face = "worried", shot = "close"},
				{say = "chen", t = "Dawn, if nothing goes wrong. Things always go wrong.", face = "tired"},
			]},
		]},
		{say = "chen", t = "If someone *were* going in, the old service tunnel from the basement runs under the east wing. The guards patrol at night.", face = "neutral", shot = "two"},
		{say = "ward", t = "Isaac...", face = "worried"},
		{say = "chen", t = "I didn't say anything, Elena.", face = "neutral"},
	]


static func night_start() -> Array:
	return [
		{say = "mara", t = "Basement. Service door, west end of the ground floor. *Quietly.*", face = "determined", shot = "two"},
		{think = "Guards won't shoot us. They'll just lock us in a room until it's too late.", face = "determined"},
	]


static func caught() -> Array:
	return [{say = "guard", t = "Hey! You can't be out here. *Back to your room.*", face = "angry", shot = "keep", hold = 0.6}]


static func hatch() -> Array:
	return [
		{say = "mara", t = "Service tunnel. It smells like rust and something worse.", face = "worried", shot = "two"},
		{say = "alex", t = "Ward 4 is at the other end. *Let's go get them.*", face = "determined", shot = "close"},
	]
