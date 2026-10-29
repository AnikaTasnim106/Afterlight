class_name BuildingLines
## Level 1 · Scene 2 — "Checking the building". Neighbours give conflicting stories.


static func intro() -> Array:
	return [{think = "Ten minutes. Ask around, then straight back to June.", face = "determined"}]


static func mrs_chowdhury() -> Array:
	return [
		{say = "chowdhury", t = "Alex, *dear.* Is it the flu? My son says it is only a bad flu.", face = "worried", shot = "two"},
		{choice = [
			{t = "\"Probably. Stay inside tonight, Mrs. Carter.\"", then = [
				{say = "alex", t = "Probably. But stay inside tonight, Mrs. Carter.", face = "smile", shot = "close"},
			]},
			{t = "\"June's radio says it's something worse.\"", then = [
				{say = "alex", t = "June's radio picked up something. It sounded worse than flu.", face = "worried", shot = "close"},
				{say = "chowdhury", t = "Radios, radios. That girl should be *sleeping.*", face = "tired"},
			]},
			{t = "\"Have you seen anything strange?\"", then = [
				{say = "alex", t = "Have you seen anything strange today?", face = "curious", shot = "close"},
				{say = "chowdhury", t = "Only the Miller boy shouting in the stairwell. Young people.", face = "neutral"},
			]},
		]},
		{say = "chowdhury", t = "We have lived through worse. The government will *handle it.* Go home and lock your door.", face = "determined", shot = "close"},
	]


static func rafi() -> Array:
	return [
		{say = "rafi", t = "Bro! Did you hear? My cousin's in the army — they're *sealing the bridges* tonight. Nobody gets out.", face = "scared", pose = "phone", prop = "phone", shot = "two"},
		{choice = [
			{t = "\"Who told him that?\"", then = [
				{say = "alex", t = "Who told him that?", face = "curious", shot = "close"},
				{say = "rafi", t = "He's IN the army! He *knows!*", face = "angry", pose = "open_hand"},
			]},
			{t = "\"Don't spread rumours, Ryan.\"", then = [
				{say = "alex", t = "Don't spread rumours, Ryan. People are scared enough.", face = "determined", shot = "close"},
				{say = "rafi", t = "Rumours? Look *outside,* man!", face = "angry", pose = "point"},
			]},
			{t = "\"Is your cousin okay?\"", set = {asked_cousin = true}, then = [
				{say = "alex", t = "Is your cousin okay?", face = "worried", shot = "close"},
				{say = "rafi", t = "...He stopped answering an hour ago.", face = "sad", pose = "phone"},
			]},
		]},
		{say = "rafi", t = "Some say it's a *gas leak.* Some say terrorists. I don't know what to believe anymore.", face = "worried", pose = "none", prop = "none"},
	]


static func door_3b() -> Array:
	return [
		{say = "voices", t = "*[from 3B]* Just the essentials! We leave for the village *now!*", hold = 0.8},
		{say = "voices", t = "*[from 3B]* And if the roads are closed?! — Then we walk!", hold = 0.8},
		{think = "Everyone's got a different story.", face = "worried"},
	]


static func nadia() -> Array:
	return [
		{say = "nadia", t = "Alex? Sorry — she won't settle tonight.", face = "tired", shot = "two"},
		{say = "nadia", t = "I called the hospital hotline. They said stay home, avoid crowds... they called it a *'violent outbreak'.* What does that even mean?", face = "worried", shot = "close"},
		{choice = [
			{t = "\"It means we stay inside. Lock up.\"", then = [
				{say = "alex", t = "It means we stay inside. Lock your door.", face = "determined", shot = "close"},
			]},
			{t = "\"Do you need anything? Water? Milk?\"", set = {helped_nadia = true}, toast = "Nina will remember that.", then = [
				{say = "alex", t = "Do you need anything? Water, milk for her?", face = "worried", shot = "close"},
				{say = "nadia", t = "We're okay for tonight. Thank you, Alex. Really.", face = "relieved"},
			]},
			{t = "\"Try to keep her quiet tonight.\"", then = [
				{say = "alex", t = "Try to keep her quiet tonight, if you can.", face = "worried", shot = "close"},
				{say = "nadia", t = "She's a *baby,* Alex. I'm trying.", face = "angry"},
			]},
		]},
		{say = "nadia", t = "My husband's stuck at work across the river. They closed the bridge.", face = "sad"},
	]


static func das_arrives() -> Array:
	return [
		{say = "das", t = "Alex! Alex — help me. My *leg.*", face = "hurt", shot = "two"},
		{say = "alex", t = "Mr. Daniels! What happened?", face = "scared", shot = "close"},
		{say = "das", t = "A man in the parking lot. He was... *wrong.* He grabbed me. Tried to bite me. I fell down the ramp.", face = "scared", shot = "close"},
		{choice = [
			{t = "\"Did he bite you?\"", then = [
				{say = "alex", t = "Did he bite you? Did he break the skin?", face = "worried", shot = "close"},
				{say = "das", t = "No, no. Just my leg. I hit the ramp.", face = "hurt"},
			]},
			{t = "\"Lean on me. Let's get you home.\"", then = [
				{say = "alex", t = "Lean on me. Let's get you home.", face = "determined", shot = "close"},
			]},
		]},
		{say = "das", t = "My door — *2B.* Slowly, slowly...", face = "hurt"},
	]


static func upstairs_shout() -> Array:
	return [
		{say = "voices", t = "*[from upstairs]* EVERYBODY OUT! *MOVE! NOW!*", hold = 0.8},
		{say = "das", t = "That's coming from upstairs— your floor! *Go!* Your sister!", face = "scared", shot = "two"},
		{think = "June.", face = "scared"},
	]


static func corridor_empty() -> Array:
	return [{think = "Everyone's gone. Doors left wide open.", face = "scared"}]


static func chowdhury_gone() -> Array:
	return [{think = "Her shawl's on the floor. She'd never leave it.", face = "sad"}]
