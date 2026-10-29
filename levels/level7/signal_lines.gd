class_name SignalLines
## Level 7 — The Signal. Dialogue.


static func roof() -> Array:
	return [
		{say = "june", t = "This antenna is *huge.* Okay. Okay. Console, protocol file, and about two minutes of nobody touching me.", face = "curious", shot = "two"},
		{say = "radio", t = "*[Dr. Chen]* The protocol's on her drive. Dosing tables, cold storage, the lot. Any safe zone with a fridge can make it.", hold = 1.0},
		{say = "mara", t = "Two roof doors. Stairwells on both sides. Whatever's still in this hospital comes up through those.", face = "determined", shot = "two"},
		{say = "theo", t = "I'll sit with June and hand her cables. I can still do that much.", face = "tired"},
		{say = "june", t = "One thing. When this antenna powers up, it *hums.* Loud. Like, rule-two-loud.", face = "worried", shot = "close"},
		{say = "alex", t = "Then we lock the doors first. Rule one.", face = "determined", shot = "close"},
		{choice = [
			{t = "\"Mara, take the west door.\"", set = {mara_west = true}, then = [
				{say = "alex", t = "Mara, take the west door. I'll handle the east and the relays.", face = "determined"},
				{say = "mara", t = "West. Got it. Don't get clever out there.", face = "smile"},
			]},
			{t = "\"Mara, stay close to June.\"", set = {mara_west = false}, then = [
				{say = "alex", t = "Mara, stay close to June. Nothing touches that console.", face = "determined"},
				{say = "mara", t = "Nothing will. Go.", face = "determined"},
			]},
		]},
	]


static func bar_door() -> Array:
	return [{think = "Fire hose through the handles. It won't hold forever — but it'll hold a while.", face = "determined"}]


static func ready_q() -> Array:
	return [{say = "june", t = "Tell me when. Once I start, I can't stop.", face = "determined", shot = "two"}]


static func start() -> Array:
	return [
		{say = "alex", t = "Do it.", face = "determined", shot = "close"},
		{say = "june", t = "Powering up. *Here comes the noise.*", face = "determined", shot = "two", hold = 0.6},
	]


static func not_ready() -> Array:
	return [{think = "Doors first. Then June.", face = "determined"}]


static func banging(side: String) -> Array:
	return [{say = "mara", t = "The %s door! They're hitting it!" % side, face = "scared", shot = "keep", hold = 0.5}]


static func door_broke(side: String) -> Array:
	return [{say = "theo", t = "%s door's down!" % side, face = "scared", shot = "keep", hold = 0.5}]


static func drift(side: String) -> Array:
	return [{say = "june", t = "Signal's drifting! The *%s relay* — hold the reset till it locks!" % side, face = "scared", shot = "keep", hold = 0.6}]


static func relay_ok() -> Array:
	return [{say = "june", t = "Locked! We're back! *Keep them off me!*", face = "determined", shot = "keep", hold = 0.4}]


static func halfway() -> Array:
	return [{say = "june", t = "Halfway! Zones are picking up the carrier — *don't let up!*", face = "determined", shot = "keep", hold = 0.5}]


static func broadcast_done() -> Array:
	return [
		{say = "june", t = "Transmitting on every emergency band... it's out. *It's out!*", face = "happy", shot = "two"},
		{say = "radio", t = "*[Relief Zone Bravo]* Kestrel net, this is Sgt. Hale at Bravo. We are *receiving* the protocol. Say again — receiving!", hold = 1.0},
		{say = "radio", t = "*[Northgate Shelter]* Northgate copies. Starting cold storage now.", hold = 0.8},
		{say = "radio", t = "*[unknown]* ...this is a pharmacy on Main Street. Leo. We heard you. *Thank you.*", hold = 1.0},
		{say = "alex", t = "Leo made it.", face = "smile", shot = "close"},
		{say = "june", t = "Everyone heard us, Alex. *Everyone.*", face = "happy", shot = "two"},
		{say = "mara", t = "Look east. The sun's coming up.", face = "relieved", pose = "point"},
	]


static func hale_arrives() -> Array:
	return [
		{say = "hale", t = "Harbor Point roof! You the ones who just woke up every radio in the region?", face = "smile", shot = "two"},
		{say = "june", t = "That was me. Mostly me.", face = "happy"},
		{say = "hale", t = "Command's sending birds to every zone. First one's me — I need Dr. Chen's starter batches. Cold cases.", face = "determined"},
		{say = "radio", t = "*[Dr. Chen]* Three cases at the west stair landing. Keep them upright. *Please.*", hold = 0.8},
		{say = "hale", t = "My crew's covering the pad. Bring them out, one at a time.", face = "determined", shot = "two"},
	]


static func case_loaded(n: int) -> Array:
	match n:
		1:
			return [{say = "hale", t = "One! That's Bravo's batch.", face = "smile", shot = "keep", hold = 0.4}]
		2:
			return [{say = "hale", t = "Two. Northgate's covered.", face = "smile", shot = "keep", hold = 0.4}]
	return [{say = "hale", t = "Three. That's all of them. *Good work.*", face = "smile", shot = "keep", hold = 0.4}]


static func farewell() -> Array:
	return [
		{say = "hale", t = "You know what the funny part is? Rule six. 'Wait for official instructions.'", face = "smile", shot = "two"},
		{say = "hale", t = "Turns out the official instructions came from a sixteen-year-old with a radio.", face = "smile"},
		{say = "june", t = "Sixteen and *three quarters.*", face = "happy", shot = "close"},
		{say = "hale", t = "There's a seat on the bird. Recovery teams need people who know how to keep their heads.", face = "neutral", shot = "two"},
		{choice = [
			{t = "\"Not this time. I'm taking my sister home.\"", set = {went_home = true}, then = [
				{say = "alex", t = "Not this time. I'm taking my sister home.", face = "smile", shot = "close"},
				{say = "hale", t = "Good answer. The offer stands.", face = "smile"},
			]},
			{t = "\"After June's safe — I'll come.\"", set = {joined_recovery = true}, then = [
				{say = "alex", t = "After June's safe at home. Then I'll come.", face = "determined", shot = "close"},
				{say = "june", t = "*We'll* come. I'm the radio person, remember?", face = "smile"},
				{say = "hale", t = "Ha. Fair. I'll hold two seats.", face = "smile"},
			]},
		]},
		{say = "mara", t = "Theo and I are staying. Chen needs hands. ...And he still owes me twenty minutes.", face = "smile", shot = "two"},
		{say = "theo", t = "I'll owe you forever, probably.", face = "smile"},
	]
