# ROADMAP

## Done — v0.1.0 first playable (this milestone)
- [x] Phase 0: env (macOS arm64, `/Volumes/ns_external`, 521G free, writable), Godot 4.7.2 verified (`4.7.2.stable.official`), Git repo + `.gitignore`.
- [x] Phase 1: empty game (1280×800, stretch, main menu boots).
- [x] Phase 2: core architecture (GameState/Time/Resources/History/Events/Saves/seed + headless tests).
- [x] Phase 3: campaign interface (new-migration flow, opening, star map, Asteria dashboard, live values, time).
- [x] Phase 4: narrative event (generic panel, hydroponics ×3 choices, persistent consequences + history + save/reload).
- [x] Phase 5: combat (interceptor, weapon, 4 enemy kinds, waves, ark defence, HUD, effects, balanced difficulty).
- [x] Phase 6: connected games (event → combat → CombatResult → campaign/history/save/reload verified).
- [x] Phase 7: first playable (5 events, settings/pause/audio buses, macOS export, tag).
- Definition of done (22 steps): all verified headless + boot-checked. See DEV_LOG.

## Next — v0.2 The Fleet
All six arkships, specializations, resource exchange, formation, per-ship dashboards, fleet-level events.

## Then
- v0.3 Generations — named characters, aging/death/succession, families, legacy traits.
- v0.4 Society — factions, strikes, crime, ideologies, ship governments.
- v0.5 Exploration — larger map, sensors/probes/resources/derelicts/anomalies.
- v0.6 First Contact — comms, diplomacy, trade, misunderstanding tracks.
- v0.7 War — classes, capitals, fleet battles, boarding.
- v0.8 Fracture — separatism, espionage, civil war triggers.
- v0.9 Transformation — cybernetics/genetics/AI/alien tech, divergence.
- v1.0 Long Migration — centuries campaign, Eiren endgame + alternatives.

## Non-goals for the slice (kept out deliberately)
Six-ship sim, 550-year content, hundreds of systems, diplomacy/politics/civil war, family trees, tech trees, procedural aliens, multiplayer, 3D cities, per-citizen sim, external frameworks, native optimization.
