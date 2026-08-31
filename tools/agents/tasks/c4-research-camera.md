---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C4 — the Research Camera (holster slot 7). Photograph enemies → research points per
archetype → research level → a damage bonus vs that archetype. Finishes the C4 weapon list.

## Context (already shipped, do not rewrite)
- `AShockPlayer` holster: `WeaponSlots[8]` (Wrench0 / Pistol1 / MachineGun2 / Shotgun3 /
  GrenadeLauncher4 / ChemThrower5 / Crossbow6 / **Camera7**), `GiveWeaponByDef(name, slot)` /
  `GiveWeapon(class, slot)` / `SelectWeaponSlot` / `NextWeapon` / `PrevWeapon`.
  `EquipStarterWeapon` gives Wrench/Pistol/TommyGun/Shotgun/ChemThrower/Crossbow, opens on
  TommyGun (slot 2), one hit still 100 → 75.
- `AShockWeapon` + `UShockWeaponDef::Resolve` (7 weapons). `EWeaponFireMode` {Hitscan,
  Projectile, Melee, Shotgun, Beam}. HUD reads the weapon fields + shows the active name.
- `ABaseShockAI`: public `FName AITypeName` (the archetype key, e.g. `Agg_BabyJane`), set by
  `ConfigureIdentity(type, label)` / `ApplyArchetypeLookup`. `IsDead()`. `GetActorLocation`.
- `UShockDamageLibrary::ApplyDamage(Target, Amount, Instigator, DamageType)` in
  `ShockDamageLibrary.cpp` — the one shared damage entry point (weapons, plasmids, turret all
  call it). `AShockPlayer` / `ABaseShockAI` both derive `AShockPawn`.
- `AShockPlayer::FindLocalOrFirst(World)`.
- The Research Camera is `Camera*.uc` / `ResearchCamera*.uc` / `Research*.uc` in
  `tmp/uc_shockgame/` (and `Camera*Goal/Action.uc` in `tmp/uc_shockai/`) — research levels,
  point thresholds, per-level bonus, and the "photo quality" factors (framing, distance,
  target activity) if the `defaultproperties` carry them. Grab real numbers where present;
  PLAUSIBLE-label the rest.

## Do
1. **`AShockResearchCamera` : `AShockWeapon`** (or a sibling `AActor` in the holster — your
   call, but it must sit in `WeaponSlots[7]` and respond to the Fire input path). Override
   `FireAt` (or add `TakePhoto(AShockPlayer* Photographer)`): cone + LoS + range check for the
   nearest live `ABaseShockAI` in view; compute a **photo score 0..1** from PLAUSIBLE factors
   — centering (dot of aim vs to-target), distance (band, too close / too far = worse),
   target-is-in-combat bonus. Award `PhotoScore * BasePhotoPoints` (PLAUSIBLE ~100) to the
   player's research for that AI's `AITypeName`. Rate-limit (one useful photo per target per
   ~2s — track last-photographed time per target or a short global cooldown). Log
   `BIOSHOCK_PHOTO archetype=<n> score=<f> points=<f> level=<n>`.
2. **`AShockPlayer` research store**: `TMap<FName, float> ResearchPointsByArchetype`,
   `AddResearchPoints(FName Archetype, float Points)`, `int32 GetResearchLevel(FName)` from
   ascending thresholds (`ResearchLevelThresholds` = PLAUSIBLE `{0, 100, 300, 700, 1500}` →
   levels 0..4, or the `.uc` values if found), `float GetResearchDamageMultiplier(FName)` =
   `1 + Level * ResearchDamageBonusPerLevel` (PLAUSIBLE ~0.10 → +10%/level). A
   `BIOSHOCK_RESEARCH archetype=<n> level=<old>-><new>` log on level-up.
3. **Wire the bonus into `UShockDamageLibrary::ApplyDamage`**: when `Target` is an
   `ABaseShockAI` with a non-None `AITypeName` and the `Instigator` resolves to an
   `AShockPlayer` (instigator is the player, or `instigator->GetInstigator()` / owner chain
   is — a small helper `ResolvePlayerFrom(AActor*)`), multiply `Amount` by
   `Player->GetResearchDamageMultiplier(AITypeName)` **before** the existing damage math.
   Nothing else in `ApplyDamage` changes; multiplier is 1.0 until the player has research, so
   **every existing damage number (slice 100 → 75, all the run_* verifies) is unchanged at
   research level 0.**
4. **Slice + input**: `EquipStarterWeapon` → `GiveWeapon(AShockResearchCamera::StaticClass(), 7)`
   (or `GiveWeaponByDef("ResearchCamera", 7)` if you add a def). Still opens on TommyGun.
   Add a `Camera` def to `Resolve` only if you went the def route; otherwise note it.
   `WeaponSlot7` isn't needed (slot 7 reached via `NextWeapon`); add it only if trivial.
   HUD: when the camera is the active weapon, show the current research level of whatever
   archetype is centred in view (small, optional — note TODO if fiddly).
5. `run_research_camera.py` / `verify_research_camera.py` — headless: spawn player + camera in
   slot 7 + an AI (`AITypeName` set). Take several photos of the centred AI → research points
   accumulate, level crosses a threshold, `GetResearchDamageMultiplier` rises above 1.0. A
   photo of an AI **out of the cone / behind cover** scores ~0. After levelling: a TommyGun
   `FireAt` on that archetype now deals **more** than the base 25 (e.g. 25 * multiplier); an
   AI of a **different** `AITypeName` still takes base 25 (research is per-archetype). Base
   (level-0) damage is exactly 25 — no regression. `Success - N error(s)`. Use the
   `verify_plasmid.py` teardown pattern (guarded `_destroy_all` + reset per section).
6. `docs/FULL_GAME_CONVERSION.md` C4: tick the Research Camera + per-archetype research; note
   "the C4 weapon list is complete (7 combat weapons + Research Camera)". TODOs: research
   rewards beyond the damage bonus (plasmid unlocks, one-time bonuses), the research film /
   photo-subject variety, upgrade stations, ammo-type switching.

## Constraints
- `tools/ue5/**` (+ `setup_playable_slice.py` if you add a key) + one C4 doc edit. No
  `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **Zero damage regression at research level 0**: `run_game_possess.py` still logs
  **100 → 75, fire=1, failures []** (I run the `-game` possess at a checkpoint — you need
  `-CleanModule` + headless `run_*` only). `run_weapon_beam` / `run_weapon_slots` /
  `run_weapon_def` / `run_plasmid` / `run_ai_brain` / `run_ai_combat` / `run_hit_reaction` /
  `run_hacking` stay green (they run at research level 0 → multiplier 1.0).
- Do NOT change the base damage numbers, the AI brain, plasmids, hacking, the weapon defs, the
  encounter, or the HUD's existing rows. The only `ApplyDamage` change is one multiply guarded
  on "instigator is a player with research > 0".
- Real numbers from the decompiled `.uc` where present; every invented value gets a
  `PLAUSIBLE` comment. `docs/ENGINEERING_RULES.md` — smallest correct change.
- **Partial is fine**: `AShockResearchCamera` + the research store + the `ApplyDamage`
  multiplier + the verify, with the photo-score factors simplified (centering + range only)
  and the HUD readout noted TODO — as long as it compiles and every existing `run_*` verify
  stays green at level 0.
