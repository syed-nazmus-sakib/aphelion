# ARCHITECTURE

## Runtime
Godot 4.7.2 stable, typed GDScript, GL Compatibility, 1280×800, `canvas_items` stretch. No C#/GDExtension. Single-player. Autoloads: `Campaign` (active `CampaignState`), `SaveManager` (path + save/load).

## Core (`game/core/`)
- `CampaignState` — authoritative data: name, seeds (`seed_value`, `rng_seed`/`rng_state`), `day`, `population`, `resources` (food/energy/materials/medicine/morale/hull/readiness with bounds), `flags`, `history[{day,type,label,detail}]`, `location`, `active_event`, `pending_combat`, `last_result`. `to_dict`/`from_dict` with strict schema v1 validation.
- `CampaignDate` — day → Year/Month/Day labels (30-day months).
- `CombatResult` — victory, hull_damage, casualties, kills, salvage + validation.

## Systems (`game/systems/`, all `RefCounted`, no nodes)
- `TimeSystem.advance(state, days)` — day ticks, `PopulationSystem.daily_tick`, delayed-effect queue, stops and sets `active_event` when due. Blocked while event/combat open or hull/population dead.
- `PopulationSystem` — aggregate math only: births − deaths, food drain, energy trickle, material output, starvation losses + history.
- `ResourceSystem` — clamped get/set/add, can_afford/spend/produce.
- `EventSystem` — loads `content/events.json`, normalizes/validates, `available(state)` (day/flag/casualty gates), `choose(state, id, idx)` (affordability, gains, delayed flags, `sets_pending_combat`, history).
- `HistorySystem` — record, `delay:effect:due:payload` flags, due-pull, flag helpers.
- `FleetSystem.apply_combat_result` (one-shot via `encounter_resolved` flag + history) and `repair` (100 materials/hull, max 10).
- `CharacterSystem` — flag-backed roster stub (`character:name:role`) for future generations.
- `SaveSystem` — atomic write (tmp + reload-verify + rename), strict load validation.

## Combat (`game/combat/`)
Pure-logic `MigrationInterceptor` / `MigrationEnemy` (DRONE weaver, RAIDER chaser, STRIKER diver, ELITE 16-HP mini-boss) / `MigrationProjectile` / `MigrationWaves` (4 waves) / `CombatArena` (step, breach, win/lose incl. player-death defeat). Rendering/input/HUD in `CombatView` (Node2D `_draw`: parallax stars, grid, arkship + hull bar, ships, projectiles, explosions/flashes/shake, threat warnings; `_process` input WASD/arrows+Space/mouse+Shift+Esc). Scene: `scenes/combat.tscn`.

## Strategy (`game/strategy/star_map.gd`, `game/ui/strategy_view.gd`)
`StarMap` draws Charon (current) / Galene (next) / Hollow (danger) / Thresher (resource) with radar sweep, click-to-inspect intel (threat/salvage/transit) and course plotting (`FleetSystem.plot_course` → `course:<id>` save flag). Dashboard (`StrategyView`) sits on a `SpaceBackground` starfield and shows the live `ArkshipDiagram`, seven `StatBar` gauges (snap on first paint, ease + flash on change), population counter with delta flash, objective state machine, alert strip, recent log, top-center toasts, and a history overlay. Shared UI kit: `ui/theme_kit.gd` (palette + helpers), project theme `ui/migration_theme.tres` (`gui/theme/custom`), widgets `StatBar` / `SpaceBackground` / `SensorScope` / `menu_convoy.gd`.

## Flow (`game/ui/campaign_controller.gd`, `game/scenes/main.tscn`)
Menu → NewMigration (name/seed/difficulty) → Opening (animated) → Strategy ⇄ Event ⇄ CombatBrief → Combat → Aftermath → Strategy; Continue bypasses Opening; Menu saves. Transitions cross-fade via a CanvasLayer (instant cuts when headless); controller emits toasts for advance/repair/save/course/choice/combat outcomes. Combat lives under `CombatHolder` and is freed after applying results.

## Determinism
Campaign seed stored; `CampaignState` RNG state round-trips through saves. Wave/combat visuals seed from `seed+day`.

## Testing
Headless SceneTree scripts: `test_campaign` (roundtrip/schema/negatives/atomic save/RNG), `test_loop` (event→combat→memorial→history), `test_combat` (arena concludes, sane result), `test_menu` (buttons/signals/scenes/dialog centering), `test_visual` (theme, widgets, map interaction, plot-course + save roundtrip, toasts, event chips/keyboard). Runner: `tools/scripts/run_tests.sh`. Windowed screenshots: `tests/capture_previews.gd` → `logs/previews/`.

## Future hooks
Districts become simulated entities; characters gain aging/succession; events gain conditions/delayed chains; star map gains procedural generation; combat gains classes/capital ships — all without breaking save schema v1 (bump + migrate when fields change).
