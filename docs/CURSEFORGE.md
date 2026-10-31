# CurseForge listing (copy these into the project form)

This file is not shipped in the addon zip (see `.pkgmeta`).

## Project settings
- **Name:** Solaryn's Expedition
- **Game / category:** World of Warcraft, Addons. Main category: Quests & Leveling (matches `## X-Category`). Add Map & Minimap and Achievements as additional categories if offered.
- **License:** MIT (the repo's LICENSE)
- **Source / issues URL:** https://github.com/SolarynDev/SolarynExpedition (and /issues)
- **Logo:** square PNG/JPG, at least 400x400. Anything from the tracker's gold-on-ink theme works, e.g. the map icon.
- **Game version:** WoW: Forever, 1.60.1 (the packager detects this from `## Interface: 16001`).

## Summary (one sentence, under 255 characters)
Plan your quest log as a walking route, follow it with an on-screen tracker and arrow, and see how much of each zone you've explored. Built for WoW: Forever.

## Description

**Quest an area well without turning the game into "follow the arrow."**

Solaryn's Expedition works out a sensible order for the quests in your log, shows you where to go next, and then gets out of the way. Use it as a route guide, or leave the guide off and use it as a companion for exploring.

### Route guide
- Turns your quest log into a walking route that finishes the objectives around you before sending you back to hand everything in.
- Stays up to date as you accept, progress, finish and hand in quests. Pick up one of three items and the guide moves to the next camp by itself.
- Quests near your level come first; objectives well above you are marked `(!)`. Dungeon and raid quests stay off the route until they're ready to hand in.
- Kill and collect quests are search areas: the tracker says "in the area" once you're close.
- Numbered pins on the world map.

### On-screen tracker
- The current stop, its objectives, a live distance and a direction arrow.
- A progress strip for the whole route and a list of what's next. Click a stop to jump ahead.
- Shelve a quest to leave it off the route, skip a stop, or rebuild on demand.
- Buttons for usable quest items, with a key binding.

### Exploration
- See how much of each zone you've discovered and which areas are left, using your "Explore" achievements and the world map's fog of war.
- Level-appropriate zone suggestions for your character.

### Quest info where you need it
- Mob, NPC and object tooltips show the quest and your progress.
- NPCs you've talked to show the quests they still offer and which of yours they take back. This is learned as you play and shared across your characters.

### Commands
`/sol` opens the panel. `/sol next` starts the guide, `/sol options` opens the settings, `/sol help` lists everything.

### Notes
- **No quest database is shipped.** Locations come from the game client's own quest markers. If a marker is wrong, stand at the right spot and use `/sol pin <questID>` to record it.
- This is a beta release for the WoW: Forever beta client and may change as the API does. Please report problems on the issue tracker, including the output of `/sol report`.

## Screenshots to take (save into `docs/screenshots/`)
Aim for 1280x720 or larger PNGs, UI scale unchanged. Name them as below; the order is the order to upload them.

1. `01-tracker.png`: the tracker mid-quest in a populated zone (current stop card with the arrow, the progress strip, 2-3 "Up next" rows). The hero shot.
2. `02-panel-next.png`: the panel's Next tab with a few suggestions.
3. `03-panel-route.png`: the Route tab with several stops.
4. `04-options.png`: the options window (any page; Route or Tracker looks best).
5. `05-map-pins.png`: the world map with the numbered route pins.
6. `06-zones.png`: the Zones tab with exploration progress.
7. `07-tooltip.png`: a mob tooltip showing the quest line and progress.

Tip: crop out your character name and other addons where you can.

## Release checklist
1. Create the project on CurseForge (author account, then "Create a project" for WoW), fill in the fields above, and add the screenshots.
2. Note the project's numeric ID and add `## X-Curse-Project-ID: <id>` to `SolarynExpedition.toc`.
3. Create an API token at https://www.curseforge.com/account/api-tokens and save it in the GitHub repo under Settings, Secrets and variables, Actions, as `CF_API_KEY`.
4. Make sure Settings, Actions, General, Workflow permissions is "Read and write".
5. Bump the version (TOC and the fallback in `Init.lua`), update `CHANGELOG.md`, commit, then `git tag vX.Y.Z && git push --follow-tags`.
6. The `Release` workflow tests, packages and uploads. The file shows as "Under Review" on CurseForge until a moderator approves it.
