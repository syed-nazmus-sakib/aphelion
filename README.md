# THE LAST MIGRATION

A generational interstellar strategy game: six Arkships carry ~2.7M people on a ~550-year voyage to Eiren IV. Strategy, arkship management, real-time combat, and accumulated history interconnect — combat damage harms civilization, civilization sets combat capacity, decisions persist for centuries.

## First playable (vertical slice)

- One arkship (Asteria, ~450,000 souls), one tiny region (Charon Reach: current / next / danger / resource).
- Arkship dashboard with population, food, energy, materials, medicine, morale, hull, readiness + conceptual districts.
- 5 data-driven events (hydroponics, reactor, probe, unknown contact → combat, memorial).
- Real-time interceptor combat (Drone / Raider / Striker / Elite, 4 waves) with Arkship defence objective; results feed back into campaign (hull, casualties, salvage, morale, history).
- Save / continue with versioned atomic JSON saves. Deterministic campaign seeds.

## Living interface (v0.2)

- Animated starfield + soft nebula on menu and strategy; radar sweep and click-to-inspect contacts with `PLOT COURSE`.
- Live Asteria diagram (district fills, hull integrity, engine plume), eased stat gauges with delta flashes, population count-up.
- Event choices show affordability-aware effect chips (keyboard 1–3); top-center toasts; screen fade transitions; sensor-scope combat brief; typewriter opening with receding Earth.

## Run

- Editor: `tools/godot/godot --path game` (Godot 4.7.2 stable, macOS arm64, GL Compatibility).
- Play: open `game/project.godot`, run main scene `res://scenes/main.tscn`.
- Headless tests: `tools/scripts/run_tests.sh` (all 5 suites) or individually:
  - `tools/godot/godot --headless --path game --script res://tests/test_campaign.gd`
  - `tools/godot/godot --headless --path game --script res://tests/test_loop.gd`
  - `tools/godot/godot --headless --path game --script res://tests/test_combat.gd`
  - `tools/godot/godot --headless --path game --script res://tests/test_menu.gd`
  - `tools/godot/godot --headless --path game --script res://tests/test_visual.gd`
- Screenshots (windowed): `tools/godot/godot --path game --script res://tests/capture_previews.gd` → `logs/previews/`.

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

First playable loop works end-to-end: menu → new migration → opening → strategy → event → combat → aftermath → history → save → quit → continue. v0.2 Living Interface adds the animated dashboard, interactive star map, visual events, and toasts/fades. See `docs/ROADMAP.md` and `CHANGELOG.md`.
