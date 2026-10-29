class_name CampLines
## Level 2 — Relief Zone Bravo. All dialogue.


static func hale_welcome() -> Array:
	return [
		{say = "hale", t = "Welcome to Relief Zone Bravo. Keep your hands where I can see them — just procedure.", face = "determined", shot = "two"},
		{say = "alex", t = "We heard a call about a *breach.*", face = "worried", shot = "close"},
		{say = "hale", t = "A section of fence on the east side. *Contained.* Registration is at the white tent. Food at eighteen hundred.", face = "neutral", shot = "close"},
	]


static func price_records() -> Array:
	return [
		{say = "price", t = "Name of the person you're looking for?", face = "neutral", shot = "two"},
		{say = "alex", t = "June. My sister. She came in on the first evacuation from Tower 9.", face = "determined", shot = "close"},
		{say = "price", t = "June... here. Registered last night. *Transferred* at 07:40 this morning.", face = "neutral", shot = "close"},
		{say = "price", t = "Convoy 7 to *Harbor Point Medical Campus.* Reason: 'specialist screening'.", face = "neutral"},
		{say = "alex", t = "Screening for what? Is she sick?", face = "scared", shot = "close"},
		{say = "price", t = "It doesn't say, sir. I'm sorry. No civilian transport out of here — military only.", face = "sad"},
		{say = "mara", t = "Theo Vale. Nineteen. Tall, curly hair, probably carrying a guitar.", face = "determined", shot = "two"},
		{say = "price", t = "...No Theo Vale in the system. I'm sorry, ma'am.", face = "sad", shot = "close"},
		{say = "mara", t = "Check again.", face = "angry", shot = "close"},
		{say = "price", t = "I checked twice.", face = "sad"},
		{choice = [
			{t = "\"Records can be wrong, Mara.\"", add = {mara_trust = 1}, then = [
				{say = "alex", t = "Records can be wrong. They spelled my building wrong.", face = "worried", shot = "close"},
				{say = "mara", t = "...Yeah. Yeah, okay.", face = "sad"},
			]},
			{t = "\"We'll ask around. Someone saw him.\"", add = {mara_trust = 1}, then = [
				{say = "alex", t = "We'll ask around. Someone here saw him.", face = "determined", shot = "close"},
				{say = "mara", t = "'We'? ...Fine. We.", face = "neutral"},
			]},
			{t = "Say nothing.", then = [
				{think = "There's nothing I can say that would help.", face = "sad"},
			]},
		]},
	]


static func ward_daniels() -> Array:
	return [
		{say = "ward", t = "Clean wound. A sprain and a nasty gash — *no bite.* He'll be fine.", face = "smile", shot = "two"},
		{say = "das", t = "Told you, doctor. Ramps, not monsters.", face = "relieved"},
		{say = "alex", t = "The people who... change. What is it?", face = "worried", shot = "close"},
		{say = "ward", t = "Nobody knows where it started. Bites spread it. A fever, then the confusion, then...", face = "sad", shot = "close"},
		{say = "ward", t = "But some early patients *respond* to a compound we're testing. Early days. Real hope.", face = "determined"},
		{choice = [
			{t = "\"My sister was sent to Harbor Point.\"", set = {told_ward = true}, then = [
				{say = "alex", t = "My sister was sent to Harbor Point. 'Specialist screening'.", face = "worried", shot = "close"},
				{say = "ward", t = "That's my team's lab. If she's there, she's with good people. I promise you that.", face = "smile", shot = "close"},
			]},
			{t = "\"Is it safe here?\"", then = [
				{say = "alex", t = "Is it actually safe here?", face = "worried", shot = "close"},
				{say = "ward", t = "Safer than out there. I'd keep my shoes on at night, though.", face = "tired", shot = "close"},
			]},
		]},
	]


static func sam() -> Array:
	return [
		{say = "sam", t = "Are you looking for someone too? Everyone's looking for someone.", face = "curious", shot = "two"},
		{say = "mara", t = "My brother. Theo. Tall, curly hair—", face = "worried"},
		{say = "sam", t = "*Theo!* With the guitar! He played songs for us last night. He gave me this!", face = "happy", pose = "wave", shot = "close"},
		{think = "A guitar pick on a string.", face = "surprised"},
		{say = "mara", t = "That's his. That's *his.* Where is he?", face = "scared", shot = "close"},
		{say = "sam", t = "He helped the doctors. He went with them this morning. On the big trucks.", face = "neutral", pose = "point"},
		{say = "alex", t = "Convoy 7.", face = "determined", shot = "close"},
		{say = "mara", t = "...Same as your sister.", face = "determined"},
	]


static func nina() -> Array:
	return [
		{say = "nina", t = "They gave us a cot and formula. She finally *sleeps.* Thank you, Alex. For everything.", face = "relieved", shot = "two"},
		{if_flag = "helped_nadia", then = [
			{say = "nina", t = "You offered us milk when the world was ending. I won't forget that.", face = "smile"},
		]},
	]


static func refugee() -> Array:
	return [
		{say = "survivor", t = "They say it's the water. Or the air. Or it fell from a satellite. Everybody knows *something.*", face = "tired", shot = "two"},
	]


static func hale_again() -> Array:
	return [{say = "hale", t = "Get some rest. You look like you climbed seven floors.", face = "neutral", shot = "two"}]


static func mara_fence() -> Array:
	return [
		{say = "mara", t = "I was supposed to pick him up that night. From band practice.", face = "sad", shot = "two"},
		{say = "mara", t = "I was late. Twenty minutes. Traffic. When I got there the street was...", face = "sad", shot = "close"},
		{choice = [
			{t = "\"It's not your fault.\"", add = {mara_trust = 1}, then = [
				{say = "alex", t = "It's not your fault. Nobody knew.", face = "worried", shot = "close"},
				{say = "mara", t = "Everyone keeps saying that. It doesn't make the twenty minutes go away.", face = "sad"},
			]},
			{t = "\"I told June I'd be back in ten.\"", add = {mara_trust = 2}, set = {shared_guilt = true}, then = [
				{say = "alex", t = "I told June I'd be back in ten minutes. I wasn't.", face = "sad", shot = "close"},
				{say = "mara", t = "...So we're both late.", face = "sad"},
				{say = "mara", t = "Then let's not be late *again.*", face = "determined"},
			]},
		]},
		{say = "mara", t = "Harbor Point. First chance we get.", face = "determined", shot = "two"},
	]


# --- night ------------------------------------------------------------------------------

static func breach() -> Array:
	return [
		{say = "hale", t = "The east fence is *down!* Everyone to the motor pool — WEST! *Move!*", face = "angry", shot = "two"},
		{say = "hale", t = "You — take this. You know how to use it?", face = "determined", shot = "close"},
		{say = "mara", t = "I'll figure it out.", face = "determined", shot = "close"},
		{say = "ward", t = "My samples— the compound. If they're lost, we lose *months.*", face = "scared", shot = "two"},
		{say = "alex", t = "Then you stay right behind me, doctor.", face = "determined"},
	]


static func truck() -> Array:
	return [
		{say = "hale", t = "This one's fuelled. Harbor Point is north, over the river. Get her and those samples there.", face = "determined", shot = "two"},
		{say = "alex", t = "Come with us.", face = "worried", shot = "close"},
		{say = "hale", t = "I've got four hundred people to get out. *Go.*", face = "determined", shot = "close"},
	]


static func radio_end() -> Array:
	return [
		{say = "radio", t = "*[146.52]* ...Alex? It's June. If you're out there—", hold = 0.8},
		{say = "radio", t = "Harbor Point isn't letting anyone *leave.* Something's wrong in the east wing—", hold = 0.8},
		{say = "radio", t = "*[static]*", hold = 0.6},
		{say = "mara", t = "Then we go in.", face = "determined", shot = "two"},
	]
