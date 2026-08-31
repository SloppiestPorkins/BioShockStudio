---
worker: cursor
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: tools/ue5/**
---
Phase C4 first slice of `docs/FULL_GAME_CONVERSION.md`: "the hitscan `AShockWeapon` generalises
to a `UShockWeaponDef` data asset + projectile/beam/hitscan strategies." Framework + two new
fire strategies + the same slice fire behaviour, driven by data.

## Context
- `AShockWeapon` today (`tools/ue5/BioShockRuntime/.../ShockWeapon.{h,cpp}`): hitscan only —
  `HitscanDamage` / `HitscanRange` / `FireRate` / `MagazineSize` / `ReserveAmmo` /
  `ReloadSeconds` / `bEnforceAmmo` as hardcoded UPROPERTYs, `FireAt(Instigator, Start, Dir)`
  line-traces and calls `ApplyAuthoredDamage` → `UShockDamageLibrary::ApplyDamage`. a15 ammo,
  a19 muzzle/tracer feedback. The slice TommyGun is configured in
  `ShockGameMode::EquipStarterWeapon` via `ConfigureHitscan` / `ConfigureAmmo` and does
  **100 → 75 on one hit** (25 dmg). AI splicers also use `AShockWeapon` (a11) with
  `bEnforceAmmo=false`.
- **Real numbers exist**: `bioshock-tool weapons-config` (src, do NOT touch) reads `Weapons.ini`
  via `IniBundle` → per weapon `BaseMagazineSize` / `BaseAccuracy` / `BaseFireRate` /
  `BaseReloadRate` / `CanBeZoomed`, and per ammo a resolved `DamageStimulus` list
  (type / amount / chance). Run it, capture the output, use those values.
- `tmp/uc_shockgame/` has `Weapon.uc`, `Wrench*.uc`, `Frag*/Grenade*` ability/projectile
  classes — hierarchy + `defaultproperties` usable, bodies degraded.

## Do
1. **`UShockWeaponDef`** (UObject, `EditInlineNew`/`DefaultToInstanced`, or a `UDataAsset` —
   your call, but headless-constructable): `WeaponName`, `EWeaponFireMode` (Hitscan / Projectile
   / Melee), `Damage`, `Range`, `Spread` (from `BaseAccuracy`), `FireRate`, `MagazineSize`,
   `ReserveAmmo`, `ReloadSeconds`, `bCanZoom`, `TSubclassOf<AShockProjectile> ProjectileClass`
   (Projectile mode), `MeleeArc`/`MeleeReach` (Melee mode). `static UShockWeaponDef*
   Resolve(FName)` mapping `"TommyGun"`/`"Wrench"`/`"GrenadeLauncher"` → a def with the
   weapons-config numbers baked in (PLAUSIBLE-label anything not in the config).
2. **`AShockWeapon` reads a def**: `void ApplyDef(UShockWeaponDef*)` copies the fields onto the
   existing UPROPERTYs (keep them — a15/a19 and the HUD read them). `FireMode` stored on the
   weapon. `FireAt` branches on `FireMode`:
   - **Hitscan** — exactly today's path, unchanged.
   - **Projectile** — spawn `ProjectileClass` at the muzzle with velocity along `Dir`; the
     projectile handles its own hit (see 3).
   - **Melee** — short sphere/arc trace (`MeleeReach`), damage the first `AShockPawn` hit,
     no ammo/reload gates regardless of `bEnforceAmmo`, its own swing cooldown.
3. **`AShockProjectile`** (new, minimal): `ProjectileMovementComponent` + sphere collision,
   `InitialSpeed`, `Damage`, `ImpactRadius` (0 = direct hit, >0 = `ApplyRadialDamage`),
   `LifeSeconds`. On hit → `UShockDamageLibrary::ApplyDamage` / `ApplyRadialDamage`, spawn a
   debug impact sphere, destroy. Log `BIOSHOCK_PROJECTILE weapon=<n> radius=<r> hit=<0/1>`.
4. **Wire the slice**: `EquipStarterWeapon` → `Weapon->ApplyDef(UShockWeaponDef::Resolve("TommyGun"))`
   instead of the inline `ConfigureHitscan`/`ConfigureAmmo` — **the resolved TommyGun def must
   reproduce today's 25-damage / 50-mag / 150-reserve / rate values so the slice still does
   100 → 75 on one hit.** Give the player a second slot or a swap key (`1`/`2`) only if cheap;
   otherwise just prove Wrench + GrenadeLauncher via the headless verify and note swap as TODO.
5. `run_weapon_def.py` / `verify_weapon_def.py` — headless: `Resolve("TommyGun")` → hitscan
   `FireAt` drops a pawn's health by the def damage; `Resolve("Wrench")` → melee `FireAt`
   hits a pawn in reach, misses one out of reach, ignores ammo; `Resolve("GrenadeLauncher")`
   → `FireAt` spawns an `AShockProjectile` that travels and deals radial damage to 2 clustered
   pawns; `bEnforceAmmo` still gates the hitscan mag/reload. `Success - N error(s)`.
6. `docs/FULL_GAME_CONVERSION.md` C4: tick the def + three fire modes, list the weapons still
   on the old inline path and the tuning gaps.

## Constraints
- `tools/ue5/**` + one C4 doc line. No `src/**`, `tests/**`. No commit/push. Scratch → `$env:TEMP`.
- **`rebuild_runtime_fast.ps1 -CleanModule` MUST compile.**
- **The slice fires identically** — `run_game_possess.py` must still log the possess + slice
  pass with **health 100 → 75, fire=1, failures []** (warm the cook with a direct `-game`
  launch first, then verify). `run_plasmid` / `run_ai_brain` / `run_ai_combat` /
  `run_hit_reaction` / the a15 ammo + a19 feedback verifies stay green.
- Do NOT change the damage library, the AI brain, plasmids, the encounter, or the HUD's
  contract. AI weapons (`bEnforceAmmo=false`, a11) must keep working — `ApplyDef` on an
  AI weapon is optional; if you don't call it they stay on defaults.
- Real numbers from `weapons-config`; every invented value gets a `PLAUSIBLE` comment.
  `docs/ENGINEERING_RULES.md` — smallest correct change, move don't rewrite the hitscan path.
- **Partial is fine**: `UShockWeaponDef` + `ApplyDef` + Melee (Wrench) + the TommyGun def
  reproducing the slice, with Projectile/`AShockProjectile` + GrenadeLauncher noted TODO —
  as long as it compiles and every existing verify stays green.
