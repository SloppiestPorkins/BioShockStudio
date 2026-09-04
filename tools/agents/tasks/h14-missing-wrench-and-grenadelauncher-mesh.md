---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Import the missing Wrench and Grenade Launcher weapon viewmodel meshes

User report (in-editor, 5 Sept 2026): the Wrench and the (Grenade) Launcher are
missing. Confirmed on disk (5 Sept 2026): `Content/BioShockWeapons/` has
`WP_TommyGun/`, `WP_Pistol/`, `WP_Shotgun/`, `WP_ChemicalThrower/`, `WP_Crossbow/` —
**no `WP_Wrench/` and no grenade-launcher folder at all.**

## Wrench — was in scope for h3, still didn't land

`h3-weapon-mesh-import` (already applied) targeted `WP_WrenchMesh` alongside the other
four, which DID succeed (Pistol/Shotgun/ChemicalThrower/Crossbow folders all exist).
Wrench specifically is still missing. h3's own constraints said: "If a mesh export name
doesn't resolve or the import tool produces something unexpected, say so precisely...
rather than silently skipping it" — check `tools/agents/runs/h3-weapon-mesh-import/`
(if not cleaned up) or the applied patch/commit history for what actually happened with
Wrench specifically. Don't re-guess the export name from scratch if h3 already left a
note about why it failed; if no record survives, re-derive it the same way h3 did
(`docs/research/context.md` ~line 176-188 documents where first-person weapon
viewmodels live: `Build/Final/BakedScripts/pc/ShockGame.U`, group `WP_Wrench`,
mesh export name was assumed `WP_WrenchMesh` — confirm this actual export name exists
in that package before assuming it's right; BioShock's wrench may not follow the same
`WP_<Name>Mesh` convention as the firearms since it's a melee weapon with different
animation needs).

## Grenade Launcher — never attempted

Not in h3's table at all. `ShockWeaponDef.cpp`/`.h` and `verify_weapon_def.py` already
reference a GrenadeLauncher def (confirm the exact string key used — "GrenadeLauncher"
or something else) so the gameplay-side def exists; only the mesh import is missing.
Locate its export name in `Build/Final/BakedScripts/pc/ShockGame.U` the same way the
other five were found (do not assume `WP_GrenadeLauncherMesh` without confirming against
the actual package contents — BioShock's in-game name may differ, e.g. "Launcher" or
"RPG").

## What to do

1. Import both meshes via `tools/ue5/import_bioshock.py`, matching the existing
   `/Game/BioShockWeapons/WP_<Name>/WP_<Name>.WP_<Name>` convention used by the other
   five weapons.
2. Wire mesh assignment through the generic data-driven path h3 built (a mesh asset
   path field on `UShockWeaponDef`, applied in `AShockWeapon::ApplyDef` or right after
   `Resolve()` in `GiveWeaponByDef`) — do not add another one-off hardcoded block like
   the original Tommy-Gun-only special case h3 removed.
3. If the Grenade Launcher needs a fire-mode/projectile behavior that doesn't exist yet
   (it's not a hitscan weapon like the others), do not invent projectile physics as a
   side effect of this mesh-import task — get the mesh equipping and rendering
   correctly, and note explicitly if projectile/explosive behavior is a separate gap
   for a future task.

## Tests / verify

Extend the existing weapon-def mesh verify script (from h3) to also assert Wrench and
GrenadeLauncher resolve to a non-null mesh through the real `GiveWeaponByDef` path.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only (asset imports land in
  `C:\Users\Jack\Documents\BioShockUE5\Content\...`, outside this repo, same as every
  other import task).
- No live UE session in this worktree — headless mesh-assigned assertions are the
  evidence; a human confirms the actual look (grip socket alignment especially for the
  Wrench, a melee weapon likely gripped very differently from the firearms) afterward.
- If either mesh export name genuinely doesn't resolve, say so precisely (which weapon,
  what error, what you checked) rather than silently skipping it or guessing a
  substitute asset.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
