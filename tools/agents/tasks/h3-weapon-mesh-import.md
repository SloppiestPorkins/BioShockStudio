---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Import the missing weapon viewmodel meshes; stop hardcoding mesh assignment to Tommy Gun only

## The bug

`AShockGameMode::EquipStarterWeapon` (`ShockGameMode.cpp`, ~line 283) gives the player
Wrench, Pistol, Tommy Gun, Shotgun, ChemicalThrower and Crossbow via
`Player->GiveWeaponByDef(...)`. **Only the Tommy Gun ever gets a mesh** — there's one
hardcoded block right after spawning it:

```cpp
AShockWeapon* TommyGun = Player->GiveWeaponByDef(TEXT("TommyGun"), 2);
if (TommyGun)
{
    TommyGun->InitializeAmmoFullMag(150);
    if (USkeletalMesh* TommyGunMesh = LoadObject<USkeletalMesh>(
            nullptr,
            TEXT("/Game/BioShockWeapons/WP_TommyGun/WP_TommyGun.WP_TommyGun")))
    {
        TommyGun->Mesh->SetSkeletalMesh(TommyGunMesh);
    }
}
```

Nothing equivalent exists for Wrench, Pistol, Shotgun, ChemicalThrower or Crossbow —
confirmed by reading `AShockPlayer::GiveWeaponByDef` and `GiveWeapon`
(`ShockPlayer.cpp` ~line 400-488) in full: they call `UShockWeaponDef::Resolve` /
`ApplyDef` (stats + ammo only, no mesh) and never touch `Weapon->Mesh`. This is why
"no other gun is working" (they equip and presumably fire, but render as no mesh at
all — confirmed separately: **only `WP_TommyGun` exists** under
`Content/BioShockWeapons/` right now; `ls` of that folder returns just `Materials/`,
`NEWPlayerHands/`, `WP_TommyGun/`).

Also just changed (this session, main tree, already committed... actually not yet
committed at hand-off — check `git log`/`git diff` on `ShockGameMode.cpp` if unclear):
the player now starts equipped with the **Wrench** (slot 0), not the Tommy Gun, since
that's the actual first weapon in BioShock. That makes the Wrench mesh the single
most visible gap — right now equipping it shows nothing.

## What to do

1. **Import the missing meshes.** `docs/research/context.md` (~line 176-188)
   already documents exactly where they live and their export names — first-person
   weapon viewmodels are **not** in the map packages, they're in
   `Build/Final/BakedScripts/pc/ShockGame.U` (confirmed, this is where the already-
   working `WP_TommyGun` / `TommyGunMESH` came from):

   | Group | Mesh export name |
   |---|---|
   | `WP_Wrench` | `WP_WrenchMesh` |
   | `WP_Pistol` | `WP_PistolMesh` |
   | `WP_Shotgun` | `WP_ShotgunMesh` |
   | `WP_ChemicalThrower` | `WP_ChemicalThrowerMesh` |
   | `WP_Crossbow` | `WP_CrossbowMesh` |

   Use `tools/ue5/import_bioshock.py` the same way it was used to produce
   `/Game/BioShockWeapons/WP_TommyGun/WP_TommyGun` — check git history / the script's
   own usage docs for the exact invocation used for the Tommy Gun and repeat it per
   weapon. Target path convention to match the existing one:
   `/Game/BioShockWeapons/WP_<Name>/WP_<Name>.WP_<Name>` (adjust to whatever the
   import tool actually produces — the point is consistency with `WP_TommyGun`, not
   this exact string). Textures/materials will very likely come along the same way
   they did for the Tommy Gun.

2. **Stop hardcoding mesh assignment per-weapon in `AShockGameMode`.** Once the
   assets exist, the clean fix is data-driven, not five more copies of the TommyGun
   block: add a mesh asset path field to `UShockWeaponDef` (see
   `ShockWeaponDef.cpp`'s `MakeDef(...)` calls and the `Resolve()` registry — this is
   the same file that already defines `"TommyGun"`, and presumably `"Wrench"`,
   `"Pistol"`, `"Shotgun"`, `"ChemicalThrower"`, `"Crossbow"` entries; confirm they
   exist, they're referenced by `GiveWeaponByDef` already so they should), and set
   the weapon's mesh generically inside `AShockWeapon::ApplyDef` (or right after
   `Resolve()` succeeds in `GiveWeaponByDef`) instead of `AShockGameMode` doing it
   as a special case. Remove the now-redundant Tommy-Gun-only block from
   `EquipStarterWeapon` once the generic path covers it too — confirm the Tommy Gun
   still gets its mesh through the new generic path before deleting the old block,
   don't delete first and hope.

3. **Verify.** Extend or add a headless verify script that resolves each of the 6
   weapon defs, confirms `Weapon->Mesh->GetSkeletalMeshAsset()` is non-null and is
   the expected asset for each, after going through `GiveWeaponByDef` (not by
   calling `SetSkeletalMesh` directly in the test — the test must exercise the real
   equip path). Model it on the existing `verify_weapon_def.py` /
   `verify_weapon_slots.py` pattern already in `tools/ue5/`.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only (asset imports land in
  `C:\Users\Jack\Documents\BioShockUE5\Content\...`, outside this repo — nothing
  game-derived gets committed here, same as every other import task this project has
  done).
- If a mesh export name from the table above doesn't resolve or the import tool
  produces something unexpected, say so precisely (which weapon, what error) rather
  than silently skipping it or guessing a substitute asset.
- No PIE visual check possible from this worktree — headless mesh-assigned assertions
  are the evidence; note that a human confirms the actual look (and the grip-socket
  alignment on each, which is explicitly a look-and-tune value, not something to
  guess at) in the editor afterward.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once
  verified, same style as the existing `h1` entry.
