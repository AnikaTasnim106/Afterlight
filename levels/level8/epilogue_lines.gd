class_name EpilogueLines
## Level 8 — Afterlight (epilogue). Dialogue.


static func opening() -> Array:
	return [
		{say = "june", t = "Six weeks. The bakery's open again. *The bakery,* Alex.", face = "happy", shot = "two"},
		{say = "alex", t = "Everyone came out today. Look at them.", face = "smile", shot = "close"},
		{say = "june", t = "Say hi to people. You're terrible at it, so I'll supervise.", face = "smile"},
	]


static func hale() -> Array:
	return [
		{say = "hale", t = "Recovery Team Three, back from the north side. Forty-one doses delivered. Zero lost.", face = "smile", shot = "two"},
		{if_flag = "joined_recovery", then = [
			{say = "hale", t = "Your seats are still on the bird, you two. Monday.", face = "smile"},
			{say = "june", t = "I'm bringing better antennas this time.", face = "happy"},
		], otherwise = [
			{say = "hale", t = "Glad you went home, Alex. Somebody had to show us what 'after' looks like.", face = "smile"},
		]},
		{say = "alex", t = "Thank you. For the helicopter. For all of it.", face = "smile", shot = "close"},
	]


static func carter() -> Array:
	return [
		{say = "chowdhury", t = "Alex! I made too much food. I *always* make too much food now. Rule four has ruined me.", face = "happy", shot = "two"},
		{say = "rafi", t = "She's been rationing biscuits for six weeks. There are no shortages anymore, Mum.", face = "smile"},
		{say = "chowdhury", t = "You never know. *You never know.*", face = "smile"},
	]


static func daniels() -> Array:
	return [
		{say = "das", t = "Look at this. No cane. No limp. Dr. Ward says I walk like a man of sixty.", face = "happy", shot = "two"},
		{say = "alex", t = "You *are* sixty, Mr. Daniels.", face = "smile", shot = "close"},
		{say = "das", t = "Exactly! Finally my legs agree with my birth certificate.", face = "happy"},
		{say = "das", t = "You carried me down those stairs, you know. I haven't forgotten.", face = "smile", shot = "close"},
		{say = "das", t = "So. Race you to the pharmacy. Loser buys the bread.", face = "happy", shot = "two"},
		{choice = [
			{t = "\"You're on.\"", set = {race_on = true}, then = [
				{say = "alex", t = "You're on, old man.", face = "happy", shot = "close"},
			]},
			{t = "\"I'll buy the bread anyway.\"", set = {race_on = false}, then = [
				{say = "alex", t = "I'll buy the bread anyway. Enjoy the walk.", face = "smile", shot = "close"},
				{say = "das", t = "Coward! A *kind* coward.", face = "happy"},
			]},
		]},
	]


static func race_result(won: bool) -> Array:
	if won:
		return [
			{say = "das", t = "*[wheezing]* Rematch. Next week. I was... pacing myself.", face = "happy", shot = "two"},
			{say = "june", t = "Alex. You *raced a sixty-year-old.*", face = "smile"},
		]
	return [
		{say = "das", t = "Ha! Sixty and *undefeated!* Sourdough, please.", face = "happy", shot = "two"},
		{say = "june", t = "You lost to Mr. Daniels. I'm telling everyone.", face = "happy"},
	]


static func photo_call() -> Array:
	return [
		{say = "sam", t = "Wait! WAIT! Before you go — *group photo!* Everybody!", face = "happy", shot = "two"},
		{say = "hale", t = "You heard the kid. Fall in.", face = "smile"},
	]


static func photo_after() -> Array:
	return [
		{think = "Everyone who made it. Everyone who waited, and everyone who came.", face = "smile"},
	]


static func nina() -> Array:
	return [
		{say = "nina", t = "Alex! Come here — *meet him properly.* Nick, this is the one.", face = "happy", shot = "two"},
		{say = "nick", t = "I was stuck at the depot for nine days. Every night I listened to the radio and thought... they're gone.", face = "sad", shot = "close"},
		{say = "nick", t = "Then a girl on one-four-six read out the evacuee lists. *Nina and baby — Relief Zone Bravo.*", face = "smile"},
		{say = "june", t = "...That was me. I read those lists for hours.", face = "surprised", shot = "two"},
		{if_flag = "helped_nadia", then = [
			{say = "nina", t = "And *you* held the door so I could get up those stairs. Both of you, then.", face = "smile"},
		], otherwise = [
			{say = "nina", t = "Both of you got us here. I mean that.", face = "smile"},
		]},
		{say = "nick", t = "Thank you. That's all I've got. Thank you.", face = "smile", shot = "close"},
	]


static func leo() -> Array:
	return [
		{say = "leo", t = "Main Street Pharmacy, open for business. Dosing protocol's on the wall — taped it there the morning I heard it.", face = "smile", shot = "two"},
		{if_flag = "shared_supplies", then = [
			{say = "leo", t = "You left me bandages when you didn't have to. I kept count. Fixed eleven people with them.", face = "smile"},
		], otherwise = [
			{say = "leo", t = "Rough days back then. We were all a bit sharp. No hard feelings.", face = "neutral"},
		]},
		{say = "alex", t = "Glad you made it, Leo.", face = "smile", shot = "close"},
	]


static func mara() -> Array:
	return [
		{say = "theo", t = "*[strumming]* This one's new. It's called 'Twenty Minutes Late.'", face = "smile", shot = "two"},
		{say = "mara", t = "I hate it. I hate this song so much.", face = "happy", shot = "close"},
		{say = "sam", t = "Theo, you dropped your pick at the camp. I kept it safe. *Here.*", face = "happy"},
		{say = "theo", t = "Sam! You kept it this whole time? ...Keep it. You earned it.", face = "smile", shot = "two"},
		{say = "mara", t = "Alex. Thank you. For the dock, for the wing — for not leaving.", face = "smile", shot = "close"},
		{choice = [
			{t = "\"You'd have done the same.\"", then = [
				{say = "alex", t = "You'd have done the same. You *did* the same.", face = "smile", shot = "close"},
			]},
			{t = "\"Dinner. Our place. Friday.\"", then = [
				{say = "alex", t = "Dinner. Our place. Friday. Theo brings the guitar.", face = "happy", shot = "close"},
				{say = "mara", t = "...Yeah. Okay. We'll be there. On time, even.", face = "happy"},
			]},
		]},
	]


static func ward() -> Array:
	return [
		{say = "ward", t = "Every safe zone's reporting the same thing. Early cases recover. Late ones... we're learning.", face = "neutral", shot = "two"},
		{say = "chen", t = "We still don't know where it came from. Maybe we never will.", face = "tired"},
		{say = "ward", t = "But we know how it ends now. That's not nothing.", face = "smile", shot = "close"},
	]


static func not_yet() -> Array:
	return [{say = "june", t = "Not yet — Nina, Mr. Daniels and Mara are all here. Say hi first!", face = "smile", shot = "keep"}]


static func home_arrive() -> Array:
	return [
		{say = "june", t = "Home. It still smells like your terrible tea.", face = "happy", shot = "two"},
		{say = "alex", t = "Hey. I'll have you know my tea is *excellent.*", face = "smile", shot = "close"},
		{say = "june", t = "Wait. One more thing.", face = "smile", prop = "none"},
	]


static func fridge() -> Array:
	return [
		{say = "june", t = "The emergency notice. I kept it the whole way. Bravo, the river, the hospital.", face = "smile", shot = "two"},
		{say = "alex", t = "You want to keep *that?*", face = "surprised", shot = "close"},
		{say = "june", t = "Six rules. They got us here. Lock the door, stay quiet, look after each other...", face = "smile"},
		{say = "june", t = "...and wait for the people who are coming for you. *They came.*", face = "happy", shot = "close"},
		{say = "alex", t = "*We* came.", face = "smile", shot = "close"},
		{if_flag = "dismissed_radio", then = [
			{say = "alex", t = "And next time you tell me to listen to the radio — I'll listen. First time.", face = "smile"},
			{say = "june", t = "I'm putting that in writing.", face = "happy"},
		], otherwise = [
			{say = "june", t = "And you listened. First night. I'm never letting you forget it.", face = "happy"},
		]},
	]


static func last() -> Array:
	return [
		{say = "june", t = "Alex? What do we do now?", face = "neutral", shot = "two"},
		{say = "alex", t = "Now? Tea. Then... whatever comes after.", face = "smile", shot = "close"},
	]
