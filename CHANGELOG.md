# CHANGELOG

## [0.1.1] — Modal dialog centering fix
- Fixed all modal dialogs (New Migration, Settings, Fleet History, combat Pause / end panel) rendering off-screen bottom-right. Cause: `set_anchors_preset(PRESET_CENTER)` followed by a manual `position` offset, which Godot interprets as center + offset. All dialogs now use full-rect `CenterContainer` wrappers. Added Esc-to-close on New Migration / Settings.
- Extended `test_menu.gd`: asserts BEGIN EXODUS / BACK / CLOSE / RETURN TO FLEET are visible and enclosed by the viewport, and that BEGIN EXODUS emits `start_requested`.

## [0.1.0] — First playable vertical slice

- Campaign core: `CampaignState` (schema v1), `CampaignDate`, `CombatResult`, deterministic seeds, atomic versioned saves.
- Systems: Time (30-day advances, event gating), Population (aggregate births/deaths/starvation), Resources (food/energy/materials/medicine/morale/hull/readiness), Events (data-driven `events.json`, costs, delayed effects, combat trigger), History (permanent log + delayed queue), Fleet (combat-result application, hull repair), Characters (flag-backed roster stub), Save (atomic tmp+rename, validation).
- Content: 5 events (hydroponics with 3 choices, reactor, probe with delayed payoff, unknown contact → combat, memorial after casualties).
- Strategy UI: Asteria dashboard, 7 conceptual districts, star map (Charon/Galene/Hollow/Thresher), objective tracker, recent + full history, Advance/Repair/Save/Menu, New Migration (name/seed/difficulty) + Settings (volume/mute).
- Opening: Earth receding, 6 arkships, Exodus lines, click/Esc skip.
- Combat: interceptor (move/fire/boost/invuln, 8 HP), Drone/Raider/Striker/Elite (1/2/2/16 HP), 4 waves, Arkship defence line, breach damage, HUD, starfield parallax, explosions/flashes/shake, threat warnings, pause, win/lose end panel with return-to-fleet.
- Wiring: event → combat brief → combat scene → result → campaign → history → save → continue; game-over guard (hull/population).
- Tests (headless): campaign roundtrip/validation, full event→combat→memorial loop, combat conclusion/balance, menu + scene presence.
- Docs: vision, story bible, architecture, roadmap, data formats, dev log.
- Build: macOS development export. Tag `v0.1.0-first-playable`.
