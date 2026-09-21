# THE LAST MIGRATION

A generational interstellar strategy game: six Arkships carry ~2.7M people on a ~550-year voyage to Eiren IV. Strategy, arkship management, real-time combat, and accumulated history interconnect — combat damage harms civilization, civilization sets combat capacity, decisions persist for centuries.

## First playable (vertical slice)

- One arkship (Asteria, ~450,000 souls), one tiny region (Charon Reach: current / next / danger / resource).
- Arkship dashboard with population, food, energy, materials, medicine, morale, hull, readiness + conceptual districts.
- 5 data-driven events (hydroponics, reactor, probe, unknown contact → combat, memorial).
- Real-time interceptor combat (Drone / Raider / Striker / Elite, 4 waves) with Arkship defence objective; results feed back into campaign (hull, casualties, salvage, morale, history).
- Save / continue with versioned atomic JSON saves. Deterministic campaign seeds.

## Run

- Editor: `tools/godot/godot --path game` (Godot 4.7.2 stable, macOS arm64, GL Compatibility).
- Play: open `game/project.godot`, run main scene `res://scenes/main.tscn`.
- Headless tests:
  - `tools/godot/godot --headless --path game --script res://tests/test_campaign.gd`
  - `tools/godot/godot --headless --path game --script res://tests/test_loop.gd`
  - `tools/godot/godot --headless --path game --script res://tests/test_combat.gd`
  - `tools/godot/godot --headless --path game --script res://tests/test_menu.gd`

## Controls

- Strategy: mouse (Advance 30 days, Repair, Save, Menu, event choices, History overlay).
- Combat: WASD / arrows move, Space / left-mouse fire, Shift boost, Esc pause.
- Opening: click / Esc to advance/skip.

## Project layout

- `game/` — Godot project (`project.godot`, `autoload/`, `core/`, `systems/`, `combat/`, `strategy/`, `arkship/`, `ui/`, `scenes/`, `content/events.json`, `tests/`).
- `docs/` — vision, story bible, architecture, roadmap, data formats, dev log.
- `tools/godot/` — Godot 4.7.2 stable + `godot` wrapper script.
- `builds/` — export outputs (macos/windows/linux).
- `logs/` — local run logs (git-ignored).

## Status

First playable loop works end-to-end: menu → new migration → opening → strategy → event → combat → aftermath → history → save → quit → continue. See `docs/ROADMAP.md` and `CHANGELOG.md`.
