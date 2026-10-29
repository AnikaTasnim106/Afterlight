# AFTERLIGHT

A cinematic 2D side-view survival story in 8 levels. Godot **4.5**, GL Compatibility renderer.

## Play
- **Ready builds:** `build/web/` (browser — serve `index.html`, or upload the folder's contents to itch.io), `build/windows/Afterlight.exe`, `build/linux/Afterlight.x86_64`.
- **From source:** Godot 4.5 → Import → `project.godot` → F5.
- Title menu: New Game · Continue (last checkpoint) · Chapter Select · How to Play.
- In game: **ESC / P** = pause menu (Resume · How to Play · Restart Checkpoint · Main Menu).

| Key | Action |
|---|---|
| A / D | walk · **Shift** run (noisy) · **C** (hold) sneak / hide behind cover |
| W / S | stairs up / down |
| E | interact · some actions need **hold E** (doors, cranks, panels) |
| Space / Enter | next dialogue line · 1 / 2 / 3 or click = choice |
| Mouse | aim · **LMB** shoot (Ctrl too, desktop only) · **R** reload · **H** bandage |
| TAB | the six emergency rules |
| ESC / P | pause menu |

## Levels
1. **The First Evacuation** — apartment, neighbours, June evacuated, the six rules, stairwell, rooftop helicopter.
2. **Relief Zone Bravo** — the stadium camp; the east fence fails at night.
3. **Dead City** — stealth downtown, the pharmacy, a horde (hide behind the bus); under the river on Line 2.
4. **The River** — fuel for a boat, a dusk crossing.
5. **Harbor Point** — hospital records by day, guard patrols by night.
6. **The Quarantine Wing** — override Ward 4, June and Theo, the first dose.
7. **The Signal** — bar the roof, June broadcasts the cure; tune the relays, survive till dawn.
8. **Afterlight** — six weeks later.

## Rules → gameplay
1 lock/bar doors (they hold for a while) · 2 noise draws them (rings show how far) · 3 don't approach (peephole, stealth) · 4 conserve (choices) · 5 be ready (go-bag = bandages, ammo) · 6 wait for official instructions — until you become them.

## Audio
Every sound effect, ambience and music track in `assets/audio` was synthesized by a Python program (no samples). `core/audio.gd` plays music/ambience per chapter and turns gameplay noise events into sound.

## Credits
Game & direction: Anika. Made with Claude (Anthropic). Engine: Godot 4.5 (MIT). Fonts: Barlow Condensed, Nunito, Share Tech Mono (SIL OFL). Jam page text: `jam_page/ITCH_PAGE.md`.

## Testing
`godot --path . -- --autoplay` with env `START_CHAPTER=l3a` (any chapter id) `CHAIN=1` plays through with a bot.
