class_name CityLines
## Level 3 — Dead City. Dialogue.


static func truck_dies() -> Array:
	return [
		{say = "mara", t = "That's not a good noise.", face = "worried", shot = "two"},
		{say = "ward", t = "Harbor Point is twenty kilometres north. The samples need to stay *cold* — they've got maybe six hours.", face = "worried"},
		{say = "alex", t = "Then we walk. And we stay *quiet.* Rule two.", face = "determined", shot = "close"},
		{say = "mara", t = "I'll hold my fire. Unless something tries to eat me.", face = "neutral"},
	]


static func first_wanderer() -> Array:
	return [{think = "One of them. Facing away. If I sneak up behind it... no noise at all.", face = "determined"}]


static func alarm() -> Array:
	return [{say = "mara", t = "*Car alarm!* Move— they'll all come for that!", face = "scared", shot = "keep"}]


static func pharmacy_standoff() -> Array:
	return [
		{say = "leo", t = "That's *far* enough. This place is ours.", face = "angry", pose = "point", shot = "two"},
		{say = "alex", t = "We're not here to take anything from you. We need ice packs. That's all.", face = "determined", pose = "open_hand", shot = "close"},
		{say = "ruth", t = "Leo. Look at them. They're not raiders. That one's a *doctor.*", face = "worried", shot = "close"},
		{say = "leo", t = "Everyone's somebody, Ruth. Everyone's hungry too.", face = "tired"},
		{choice = [
			{t = "Offer a bandage and some food.", set = {shared_supplies = true}, add = {bandages = -1}, toast = "Leo's group will remember that.", then = [
				{say = "alex", t = "Here. Bandage, water, two cans. It's not much.", face = "determined", shot = "close", pose = "reach"},
				{say = "leo", t = "...It's more than anyone's offered in three days.", face = "sad", shot = "close"},
				{say = "kai", t = "There's a box of bullets in the security office. We can't use them. Take it.", face = "neutral", shot = "close"},
			]},
			{t = "\"We all need to get out of this city.\"", set = {talked_leo = true}, then = [
				{say = "alex", t = "We all need to get out of this city. Fighting each other won't help.", face = "determined", shot = "close"},
				{say = "leo", t = "...Fine. Get your ice and go.", face = "tired"},
			]},
			{t = "Keep your hand near your gun.", set = {threatened_leo = true}, then = [
				{say = "alex", t = "We're taking the ice packs. Nobody needs to get hurt.", face = "angry", shot = "close"},
				{say = "leo", t = "Easy. *Easy.* Take them and get out.", face = "scared"},
				{say = "ruth", t = "This is what it does to people. All of us.", face = "sad"},
			]},
		]},
	]


static func cooler() -> Array:
	return [
		{think = "Ice packs. Still frozen — the backup generator's keeping this cooler alive.", face = "relieved"},
		{say = "ward", t = "That's *hours* more for the samples. Thank you.", face = "relieved", shot = "two"},
	]


static func leo_route(shared: bool) -> Array:
	if shared:
		return [
			{say = "leo", t = "Don't take Main Street north. There's a pack of them near the bridge. Hundreds.", face = "worried", shot = "two"},
			{say = "leo", t = "The subway — Line 2 — runs under the river. Dark, but quiet. It comes up at the marina.", face = "neutral"},
			{say = "alex", t = "Thank you, Leo.", face = "smile"},
		]
	return [
		{say = "kai", t = "*[whispering]* Hey. Take the subway — Line 2. Main Street's full of them.", face = "worried", shot = "close"},
	]


static func mara_backroom() -> Array:
	return [
		{say = "mara", t = "Theo always said I worry like it's a job. Turns out it was good practice.", face = "tired", shot = "two"},
		{choice = [
			{t = "\"What's he like?\"", add = {mara_trust = 1}, then = [
				{say = "alex", t = "What's he like? Theo.", face = "curious", shot = "close"},
				{say = "mara", t = "Loud. Kind. Plays guitar badly and sings worse. Makes every stranger his friend in ten minutes.", face = "smile", shot = "close"},
				{say = "mara", t = "...If anyone's okay out there, it's him.", face = "sad"},
			]},
			{t = "\"Get some rest. I'll watch the door.\"", then = [
				{say = "alex", t = "Get some rest. I'll watch the door.", face = "neutral", shot = "close"},
				{say = "mara", t = "You'll wake me in an hour. That's not a question.", face = "neutral"},
			]},
		]},
	]


static func horde_warning() -> Array:
	return [
		{say = "mara", t = "*Down.* Behind the bus. Look at them all...", face = "scared", shot = "keep"},
		{think = "Crouch behind cover. Don't move. Let them pass.", face = "scared"},
	]


static func subway_entry() -> Array:
	return [{think = "Line 2. Under the river. Into the dark.", face = "determined"}]


# --- subway -------------------------------------------------------------------------

static func tunnel_start() -> Array:
	return [
		{say = "ward", t = "It's pitch black down here.", face = "scared", shot = "two"},
		{think = "Flashlight on. Keep it low. Move slow.", face = "determined"},
	]


static func train() -> Array:
	return [{say = "mara", t = "The train's blocking the tunnel. We go *through* it.", face = "determined", shot = "keep"}]


static func exit_ladder() -> Array:
	return [
		{say = "ward", t = "Daylight. And the river.", face = "relieved", shot = "two"},
		{say = "mara", t = "Harbor Point's on the other side. Look — you can see the antenna.", face = "determined", pose = "point"},
	]


static func june_radio() -> Array:
	return [
		{say = "radio", t = "*[146.52]* ...Alex. If you're coming — the east wing. Ward Four. They locked the doors. Please hurry.", hold = 1.0},
		{say = "alex", t = "*Ward Four.* We're coming, June.", face = "determined", shot = "two"},
	]


static func kai_talk() -> Array:
	return [
		{say = "kai", t = "You're the ones from the truck? ...Sorry. Leo gets scary when he's scared.", face = "worried", shot = "two"},
		{say = "kai", t = "I keep this radio on all night. There's a girl on *one-four-six-five-two.* She reads out names. Who's alive, which camp they're in.", face = "neutral", pose = "hold_radio", prop = "radio"},
		{say = "alex", t = "...That's my sister. That's *June.*", face = "surprised", shot = "close"},
		{say = "kai", t = "No way. She's the only thing that makes the nights okay. Ruth cries when she reads a name we know.", face = "smile", shot = "close"},
		{choice = [
			{t = "\"Keep listening. She'll need people who listen.\"", set = {kai_listens = true}, then = [
				{say = "alex", t = "Keep listening, Kai. One day she'll need people who listen.", face = "smile", shot = "close"},
				{say = "kai", t = "Every night. Promise.", face = "smile"},
			]},
			{t = "\"Did she say anything about Harbor Point?\"", then = [
				{say = "alex", t = "Did she say anything about Harbor Point?", face = "worried", shot = "close"},
				{say = "kai", t = "Only that nobody's allowed out. She sounded... *brave* about it. Like she was waiting for someone.", face = "neutral"},
				{say = "alex", t = "She is.", face = "determined", shot = "close"},
			]},
		]},
		{say = "kai", t = "Tell her Kai from Main Street says hi. When you find her.", face = "smile", pose = "none", prop = "none", shot = "two"},
	]
