class_name WingLines
## Level 6 — The Quarantine Wing. Dialogue.


static func tunnel() -> Array:
	return [
		{say = "mara", t = "Pipes, steam, and that smell. We're under the east wing now.", face = "worried", shot = "two"},
		{say = "radio", t = "*[146.52]* ...Alex? Your radio's close — I can see you on my scanner. Ward 4 is up the stairs, end of the hall.", hold = 1.0},
		{say = "alex", t = "June. We're coming. Hold on.", face = "determined", shot = "close"},
	]


static func door_panel() -> Array:
	return [
		{say = "radio", t = "*[June]* The lock runs on the old intercom system. Hold the transmit button on the panel — I'll *override it from in here.*", hold = 1.0},
		{say = "radio", t = "*[June]* It takes time. And it's going to be *loud.* I'm sorry.", hold = 0.8},
		{say = "mara", t = "Then I'll keep them off you. Do it.", face = "determined", shot = "two"},
	]


static func reunion() -> Array:
	return [
		{say = "june", t = "*Alex!*", face = "happy", shot = "two"},
		{say = "alex", t = "June. You're okay. You're okay.", face = "relieved", shot = "close"},
		{say = "june", t = "I waited. I told them I had to wait for you, they didn't listen—", face = "sad", shot = "close"},
		{if_flag = "dismissed_radio", then = [
			{say = "alex", t = "I should have listened to your radio that night. I'm sorry.", face = "sad"},
			{say = "june", t = "You're here now. That's the part that counts.", face = "smile"},
		], otherwise = [
			{say = "june", t = "You heard me. On one-four-six. I knew you would.", face = "smile"},
		]},
		{say = "mara", t = "...*Theo?*", face = "scared", shot = "two"},
		{say = "theo", t = "Mara? Mara! What are you— how did you—", face = "surprised", shot = "close"},
		{say = "mara", t = "Twenty minutes late. *Again.* I'm sorry. I'm so sorry.", face = "sad", shot = "close"},
		{say = "theo", t = "Hey. Hey. You came. That's what you do.", face = "smile"},
	]


static func theo_bitten() -> Array:
	return [
		{say = "june", t = "Theo got *scratched* yesterday. Holding the door so the rest of us could barricade.", face = "worried", shot = "two"},
		{say = "theo", t = "I'm fine. A bit of a fever. I'm fine.", face = "tired"},
		{say = "mara", t = "You're *burning up.*", face = "scared", shot = "close"},
		{choice = [
			{t = "\"Dr. Chen's dose is almost ready. We go now.\"", then = [
				{say = "alex", t = "Dr. Chen's dose is almost ready. Early cases respond — we go *now.*", face = "determined", shot = "close"},
			]},
			{t = "\"Mara. Remember what I promised.\"", need = "promised_theo", add = {mara_trust = 1}, then = [
				{say = "alex", t = "Mara. Remember what I said on the dock. That's what the compound is for.", face = "determined", shot = "close"},
				{say = "mara", t = "...Then help me carry him.", face = "determined"},
			]},
		]},
	]


static func escape_start() -> Array:
	return [
		{say = "june", t = "The noise from the door — *everything* on this floor heard it.", face = "scared", shot = "two"},
		{say = "alex", t = "Stay behind me. Both of you. Back to the tunnel, then the lab.", face = "determined"},
	]


static func lab_arrive() -> Array:
	return [
		{say = "chen", t = "Bring him here— *quickly.* First field dose. It's not finished testing.", face = "determined", shot = "two"},
		{say = "mara", t = "Do it.", face = "determined", shot = "close"},
		{wait = 1.6},
		{say = "ward", t = "Pulse steadying. Fever's... dropping. Isaac, it's *working.*", face = "surprised", shot = "two"},
		{say = "theo", t = "...Mara? Why is everyone staring at me?", face = "tired"},
		{say = "mara", t = "*[laughing, crying]* Shut up. Just shut up.", face = "happy", shot = "close"},
		{say = "chen", t = "This proves it works. But there are a thousand Theos out there. We have to get the protocol *out* — to every safe zone.", face = "determined", shot = "two"},
		{say = "june", t = "The hospital antenna on the roof. Boosted right, it could reach every emergency band in the region.", face = "curious"},
		{say = "june", t = "I can do it. *I can do it.* I just need time up there.", face = "determined", shot = "close"},
	]
