# AFTERLIGHT — itch.io page kit (AI Jam 5)

## Title
AFTERLIGHT

## Short description (tagline)
The city gave everyone six rules. To get her sister back, Alex will have to bend every one of them. A cinematic 2D survival story in 8 levels.

## Genre / tags
Survival, Story Rich, Zombies, Stealth, Narrative, Choices Matter, 2D, Cinematic, Godot

## Description (paste into the page)

**The night the city went quiet, the emergency notice gave everyone six rules.**
Lock your doors. Make no noise. Don't approach them. Conserve. Be ready. Wait for help.

Alex followed the rules. Her little sister June got evacuated without her — and now June's voice is on the radio, one frequency, every night, reading out the names of the living.

AFTERLIGHT is a cinematic side-view survival story about getting your sister back, keeping strangers alive, and what "waiting for help" means when you're the help.

**What you do**
- **Live by the six rules.** They're the game's mechanics: noise draws them, barred doors buy time, supplies run out, crouching behind cover hides you.
- **Sneak or fight.** Silent takedowns, a handgun with real reloads, car alarms that bring the whole street, a horde you can only hide from.
- **Talk your way through.** Dialogue choices are remembered: who you shared bandages with, who you promised things to, whether you listened to the radio the first night.
- **Protect people.** Escort a doctor with the last cold samples, defend your sister while she broadcasts the cure, get your neighbours up the stairwell to the last helicopter.
- **8 levels, ~60–90 minutes**, from a locked apartment to a hospital roof at dawn — and an ending that's actually hopeful.

**Controls**
A / D move · Shift run · C sneak (hold) · W / S stairs · E interact (some actions: hold E) · Space next line · 1/2/3 choose · Mouse aim · Left click shoot · R reload · H bandage · TAB the six rules · ESC / P pause menu (How to Play, Sound) · M mute

Short on time? **Chapter Select** on the title screen jumps to any chapter (Level 3 "Dead City" and Level 7 "The Signal" are good samples).

**Theme (TORCH):** a flashlight is your only light under the river, and the whole story builds to one signal fire — a radio broadcast held up for everyone still out there.

## AI usage (required disclosure — AI Jam 5)
This game was built with heavy AI assistance, as the jam asks:
- **Code:** all GDScript (character rig, AI, combat, dialogue system, levels) written by Claude (Anthropic) from my direction and playtest feedback.
- **Art:** there are no image files — every character, prop and background is vector art drawn in code, written by Claude.
- **Audio:** every sound effect, ambience and music track was synthesized from scratch by a Python program written by Claude (no samples, no stock audio).
- **Story & dialogue:** written with Claude from my story brief (the first brief was drafted with ChatGPT, then rewritten).
- **Me:** creative direction, story decisions, design choices, playtesting, bug reports and feedback every step of the way.

## Credits
- Game & direction: Anika
- Built with: Claude (Anthropic)
- Engine: Godot 4.5 (MIT)
- Fonts: Barlow Condensed, Nunito, Share Tech Mono — SIL Open Font License

## Upload settings
- **Web build:** zip the contents of `build/web/` (index.html at the root of the zip) → upload → tick "This file will be played in the browser".
- Embed: **1280 × 720**, tick **Fullscreen button** and **Automatically start on page load** off (click-to-play), leave **SharedArrayBuffer support** OFF (the build doesn't need threads).
- Optional downloads: `Afterlight.exe` (Windows), `Afterlight.x86_64` (Linux).
- Kind of project: HTML. Pricing: free (jam rule).
- Cover image: `cover.png` (630 × 500). Screenshots: `screenshot_*.png`.
