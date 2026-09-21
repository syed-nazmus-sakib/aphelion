# DEV LOG

## v0.1.1 — modal dialogs off-screen (user-reported: stuck on menu)
- Symptom: NEW MIGRATION dialog rendered cut off at the bottom-right; BEGIN EXODUS unreachable; game appeared frozen on the menu.
- Root cause: `PRESET_CENTER` + manual `position = Vector2(...)` in `new_migration.gd`, `settings_panel.gd`, `strategy_view.gd` (history), `combat_view.gd` (pause/end). Center preset anchors at 50%, so the offset pushed panels to center+(x,y).
- Fix: full-rect `CenterContainer` wrappers everywhere; Esc closes New Migration / Settings. Verified headless: all dialog buttons enclosed in the 1280×800 viewport; covered by new `test_menu.gd` assertions.

## v0.1.0 — first playable vertical slice
- Env: macOS 27.0 arm64, external `/Volumes/ns_external` (931G, 521G free, writable). Project root `/Volumes/ns_external/game` (pre-existing skeleton adopted, not wiped). Godot `4.7.2.stable.official.ed1daf0bf` via `tools/godot/godot` wrapper verified.
- Adopted skeleton: core state/date/result, 7 systems, 5 events, interceptor/enemies/waves/projectiles, menu/opening/strategy/event/brief scenes + controller, 3 logic tests. Docs/builds/logs/tools shells already present.
- Fixed load-bearing combat bugs: (1) `test_combat` never concluded — lambda captured `result` by value so signal write was lost; switched to holder array + always-fire. (2) Player death never ended battle — added defeat finish on `health<=0`. (3) Drones unhittable + elite too tanky + breach too hot — retuned (drone weave 72@1.5→48@1.2, hit radius +6→+12, HP 2/3/4/32→1/2/2/16, hostile cooldown 2.6→3.5 / elite 1.1→1.8, speed 230→170, breach/shot 0.5→0.2, striker breach 4→2.5, player 5 HP/1.2s→8 HP/1.5s, hitbox 22→14, wave gap 6→3s). Verified: dumb sweep loses fast (defeat, sane result), skilled AI wins (29 kills, ~4 HP left).
- Built visual combat (`combat_view.gd` + `combat.tscn`): input, parallax stars, grid, arkship + hull bar, 4 enemy glyphs + elite HP bar, projectile trails, explosions/flashes/shake, threat warnings, HUD, pause, end panel.
- Rebuilt strategy (`star_map.gd`, `strategy_view.gd`): Charon/Galene/Hollow/Thresher map, Asteria stats, 7 conceptual districts, objective machine, recent + full history, Advance/Repair/Save/Menu with gating.
- Rewired flow (`campaign_controller.gd`, `main.tscn`): menu → new-migration (name/seed/difficulty) → animated opening (Earth+6 ships, skip) → strategy ⇄ event (with effect previews) ⇄ combat-brief → combat → aftermath → history → save/continue; game-over guard. Fixed two controller bugs: events never shown (checked `available()` after `active_event` set — now presents `active_event` directly) and brief always visible (now only when `pending_combat`).
- Content: hydroponics gained 3rd choice (redirect research) per spec example.
- Tests: all headless green (campaign/loop/combat/menu); `test_menu` rewritten for new signals + scene presence; game boots headless with no errors.
- Assumptions: difficulty modifies starting morale/food only; districts are display-only; audio is buses + mute (no tracks); transitions are instant cuts (no fades).

## Decisions carried forward
- Aggregate population math forever; named characters as flag-backed stubs until v0.3.
- Save schema v1 strict-reject; bump + migrate only when fields change.
- Balance target: first combat winnable by competent play, lost by careless play; casualties in the hundreds so numbers feel like people.
