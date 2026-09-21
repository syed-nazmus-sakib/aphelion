# DATA FORMATS

## Save (`migrations/save_1.json`, schema_version 1)
```json
{
  "schema_version": 1,
  "campaign_name": "Asteria Prime",
  "seed_value": 41789,
  "rng_seed": "12345",
  "rng_state": "67890",
  "day": 30,
  "population": 449812,
  "resources": {"food": 82.0, "energy": 71.0, "materials": 18420.0, "medicine": 6241.0, "morale": 68.0, "hull": 94.0, "readiness": 77.0},
  "flags": ["event_done:hydroponics_failure", "encounter_resolved", "delay:probe:26:{...}"],
  "history": [{"day": 7, "type": "event", "label": "Hydroponics Fault", "detail": "Emergency sterilization"}],
  "location": "Charon Staging",
  "active_event": "",
  "pending_combat": false,
  "last_result": {"victory": true, "hull_damage": 12.5, "casualties": 40, "kills": 29, "salvage": 174}
}
```
Rules: strict validation on load (types, bounds, non-negative day/population, all 7 resources finite+in-bounds, flags are strings, history entries shaped, `last_result` empty or valid `CombatResult`). Unknown schema → reject (no silent migrate). Writes are atomic: serialize → tmp → reload-verify → rename.

## Events (`game/content/events.json`)
```json
{"events": [{
  "id": "hydroponics_failure", "title": "...", "body": "...",
  "day": 7, "requires_flag": "", "requires_last_result_casualties": false,
  "day_offset_from_trigger": 0, "sets_pending_combat": false,
  "choices": [{
    "label": "Emergency sterilization", "description": "...",
    "effects": {"energy": -50.0, "food": 80.0},
    "delayed_effects": {"energy": 60.0}, "delay_days": 5
  }]}]}
```
`effects` apply immediately via clamped gains (energy/materials/medicine negatives checked for affordability). `delayed_effects` enqueue as `delay:<event>:<due_day>:<json>` flags, paid out by `TimeSystem`. `sets_pending_combat` arms the combat brief. Memorial gates on `encounter_resolved` flag + casualties > 0.

## CombatResult
`{victory: bool, hull_damage: float ≥0, casualties: int ≥0, kills: int ≥0, salvage: int ≥0}`. Applied once (`encounter_resolved`): hull −= damage, population −= casualties, materials += salvage, history entry.

## Conventions
Dates: integer days since Exodus; display via `CampaignDate` (30-day months). RNG: `seed_value` immutable; mutable `rng_seed`/`rng_state` strings round-trip exact `RandomNumberGenerator` state. Flags namespace: `event_done:<id>`, `encounter_resolved`, `delay:*:*:*`, `character:<name>:<role>`.
