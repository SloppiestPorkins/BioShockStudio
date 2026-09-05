---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Grenade Launcher not equipable in-editor; Tommy Gun's ammo drum detached from the gun

Two user reports (in-editor, 5 Sept 2026) right after h12 (Tommy Gun fire mode + grip-socket
root-bone alignment) and h14 (Grenade Launcher mesh import) both landed:

## 1. Grenade Launcher not equipable

Already confirmed NOT an input-binding gap: `WeaponSlot4` action mapping exists
(`Config/DefaultInput.ini`: `Key=Four`), `AShockPlayer::HandleWeaponSlot4Input` is bound
in `SetupPlayerInputComponent`, and a direct headless call to
`GiveWeaponByDef(TEXT("GrenadeLauncher"), 4)` + equip resolves a real mesh (verified via
`run_weapon_meshes.py`, 0 failures, 5 Sept 2026). So the def/mesh/input-binding path is
fine in isolation — something about actually pressing 4 in a live PIE session doesn't
result in a usable weapon. Investigate what `HandleWeaponSlot4Input` /
`SelectWeaponSlot(4)` actually does at runtime that a headless `GiveWeaponByDef` + direct
`EquipWeapon` call bypasses — e.g. does slot selection require the weapon to already be
"owned" via some inventory/pickup flag that `EquipStarterWeapon` sets differently than a
raw `GiveWeaponByDef` call in a test script, or does something in the equip path throw/
early-return silently for this specific weapon (fire mode `Projectile`, different from
every other starter's hitscan/melee/beam)? Don't guess — trace the actual call path
`HandleWeaponSlot4Input → SelectWeaponSlot → EquipWeapon` and find where it diverges from
what the headless verify exercises.

Also consider: this session did headless imports of the GrenadeLauncher assets in a
*separate* `UnrealEditor-Cmd` process; if the user's *interactive* editor was already open
during that import, its in-memory asset registry may simply be stale (new .uasset files
on disk that an already-running editor session never picked up) — note this possibility
in your report even if you find a real code bug, since it's the simplest explanation and
worth ruling out first (ask: does the report reproduce after a full editor restart?).

## 2. Tommy Gun's ammo drum detached from the gun body

Likely regression from h12's `AlignEquippedWeaponRootToGripSocket` (`ShockPlayer.cpp`):
that function calls `WeaponMesh->SetRelativeTransform(RootCS.Inverse())` on
`AShockWeapon::Mesh` to cancel the root bone's component-space offset. If the Tommy
Gun's ammo drum is a **separate** component (a second `SkeletalMeshComponent`/
`StaticMeshComponent` attached to a socket on `Mesh`, or a separate actor entirely) rather
than part of the same skeleton, repositioning `Mesh`'s relative transform would move the
gun body relative to the drum without the drum following, producing exactly this
"detached" look. Confirm: is the ammo drum part of `WP_TommyGun`'s own skeleton (same
mesh, different bone) or a separate component/actor? If it's the same skeleton, the
detach must have some other cause (unrelated to h12) — investigate what actually changed.
If it IS a separate component, `AlignEquippedWeaponRootToGripSocket` needs to also
re-apply to (or account for) that component's attachment, not just the primary `Mesh`.

## Tests / verify

For the equip bug: reproduce via the actual input path in a headless test if possible
(drive the same `HandleWeaponSlot4Input` call the real binding invokes, not a direct
`EquipWeapon`), and assert the weapon becomes the active/equipped one afterward. For the
drum: if it's a separate component, add a headless assertion that its world transform
stays coincident with wherever it's meant to attach after `AlignEquippedWeaponRootToGripSocket`
runs (mirroring the grip-align assertions h12 already added to `verify_viewmodel_anims.py`).

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- No live UE session in this worktree — headless assertions are the evidence; note
  explicitly if either bug turns out to only be reproducible with a live editor session
  (e.g. the stale-registry possibility above) rather than something headless testing can
  catch, so a human knows to just restart the editor and re-check first.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
