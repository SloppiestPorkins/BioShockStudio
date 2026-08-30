---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Give `ABaseShockAI` a ranged attack option so gun-carrying splicers (Leadhead) shoot the player
instead of only meleeing. Reuse the existing `AShockWeapon` hitscan + `UShockDamageLibrary`.

## Context
- `8556d17` gave the AI an Idle/Chase/Attack tick FSM (melee only via `MeleeRange` /
  `ApplyDamage(..., "Melee")`).
- `AShockWeapon` already does hitscan (`FireAt(Instigator, Start, Dir)` → `ApplyDamage`), used by
  the player. `AShockGameMode::EquipStarterWeapon` shows the spawn+equip pattern.
- `27bc69e` gave AI a `UShockAiArchetype` with `WeaponSlots` (chance-weighted). The archetype
  says whether this AI type carries a gun.

## Do
1. On `ApplyArchetypeLookup` / spawn, if the archetype's resolved `WeaponSlots` name a ranged
   weapon (or add a simple `bIsRanged` on the archetype set by `import_ai_archetypes.py` from the
   `aiType` / weapon-slot name — a Leadhead/Thug/`*Pistol*`/`*Tommy*` heuristic is acceptable,
   label it PLAUSIBLE), spawn an `AShockWeapon` owned by the AI and store it (`AIWeapon`).
2. Extend the FSM: add `RangedRange` (~1600) and `RangedCooldown` (~1.4s). In **Chase**, if the
   AI has a weapon and the target is within `RangedRange`, LoS-clear, and outside `MeleeRange` →
   go to a new **RangedAttack** state (or fold into Attack with a branch). There: face target, on
   cooldown call `AIWeapon->FireAt(this, MuzzleLoc, (Target - Muzzle).GetSafeNormal())`. Keep
   closing if the target moves out of `RangedRange`; drop to melee inside `MeleeRange`.
3. Unarmed AI is unchanged — melee only.
4. Add a small inaccuracy cone to the AI's aim (a few degrees) so it's not pixel-perfect —
   `UPROPERTY` `AimSpreadDegrees` ~3.
5. Extend `verify_ai_combat.py` (or `verify_ai_ranged.py` + driver): headless — an AI given a
   weapon and a target at range fires and drops the target's health without closing to melee;
   an unarmed AI still only melees; LoS-blocked = no fire. `Success - N error(s)`.
6. `docs/UE5_FULL_PORT_PLAN.md` §9: dated line.

## Constraints
- `tools/ue5/**` + one §9 line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1` MUST compile before you finish.**
- Don't touch the player's weapon/fire path or the melee behaviour — add alongside.
- Reuse `AShockWeapon::FireAt` and `UShockDamageLibrary` — do not write a second damage path.
- `docs/ENGINEERING_RULES.md`: smallest correct change, label the ranged/heuristic parts
  PLAUSIBLE, verify each claim.
