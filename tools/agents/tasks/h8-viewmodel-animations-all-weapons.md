---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# First-person viewmodel animations: fix grip-socket resolution, wire up per-weapon fidget/fire/reload

## Root cause — confirmed, not guessed

`AShockPlayer::EquipWeapon` (`ShockPlayer.cpp` ~line 344-356) resolves which socket to
attach the weapon and frame the viewmodel against with a **hardcoded 3-item candidate
list**:

```cpp
static const FName Candidates[] = {
    TEXT("TommyGun"), TEXT("R_Grip"), TEXT("R_grip")};
for (const FName Candidate : Candidates)
{
    if (ViewHands->DoesSocketExist(Candidate)) { GripSocket = Candidate; break; }
}
```

The hands skeleton does **not** have one shared grip socket — it has a separately named
socket per weapon. Confirmed in `docs/research/context.md` (~line 156): *"The hands
skeleton's `Pistol` socket proves something attaches at..."*. So only `TommyGun` ever
matched; every other weapon fell through to `GripSocket = NAME_None`, which
`FrameViewmodel` treats as "no socket correction" (falls back to a raw offset, not a
crash, but wrong/no positioning) — and, separately from the socket issue, **nothing in
this codebase ever switches which animation is playing based on the equipped weapon**.
`EnsureViewHands()` loads `NEWPlayerHands` and plays `FidgetTommygun` exactly once,
gated by `if (!ViewHands || ViewHands->GetSkeletalMeshAsset()) return;` — every weapon,
forever, shows the same hardcoded Tommy Gun idle pose. There is no fire/reload/equip
animation trigger anywhere.

## What's actually available — confirmed by listing the asset folder, not assumed

`Content/BioShockWeapons/NEWPlayerHands/Animations/` (4 Sept 2026):

| Weapon | Fidget | Fire | Reload | Equip/Unequip | ZoomedIn variants |
|---|---|---|---|---|---|
| TommyGun | `FidgetTommygun` (+`EmptyFidgetTommygun`) | `FireTommyGun` | `ReloadTommyGun` | `EquipTommygun` / `UnequipTommygun` | Fidget/Fire/ZoomingIn/ZoomingOut |
| Pistol | `FidgetPistol` (+`EmptyFidgetPistol`) | `FireSinglePistol` | `FastReloadPistol` | `EquipPistol` / `UnequipPistol` | Fidget/Fire/ZoomingIn/ZoomingOut |
| Crossbow | `FidgetCrossbow` (+`EmptyFidgetCrossbow`, +3 `_Accent_*` variants) | `FireCrossbow` | `ReloadCrossbow` | `EquipCrossbow` / `UnequipCrossbow` | Fidget/Fire/ZoomingIn/ZoomingOut |
| **Shotgun** | **none** | **none** | **none** | **none** | **none** |
| **ChemicalThrower** | **none** | **none** | **none** | **none** | **none** |
| **Wrench** | n/a — no mesh imported at all yet (h3, `WP_WrenchMesh` is a StaticMesh, blocked separately) | | | | |

Confirm each exact asset path resolves before hardcoding it (`unreal.load_asset` in a
headless probe), same discipline as `h1-enemy-animation` — the table above is from
filenames on disk, not opened and checked one by one.

## What to do

1. **Fix grip socket resolution generically.** Resolve the socket name from the
   equipped weapon's own identity (whatever `UShockWeaponDef`/`GiveWeaponByDef` resolved
   it as — "TommyGun", "Pistol", "Crossbow", "Shotgun", "ChemicalThrower") rather than a
   fixed candidate list. Fall back sensibly (e.g. no correction, logged once) for a
   weapon whose name doesn't match any socket — don't crash, and don't guess a
   substitute socket.
2. **Build a state-driven ViewHands animation system**, mirroring the pattern already
   proven for enemies in `h1-enemy-animation` (`ABaseShockAI::TickAnimationDriver` /
   `ApplyCombatAnimation` in `BaseShockAI.cpp` — same idea: cache loaded sequences,
   only call `PlayAnimation` when the resolved state actually changes, one-shot vs loop
   handling by duration not a hardcoded timer):
   - On equip: play `Equip<Weapon>` once (non-looping), then fall to `Fidget<Weapon>`
     (looping) once the equip clip finishes (use its own `GetPlayLength()`).
   - Idle: `Fidget<Weapon>`, looping.
   - On fire: `Fire<Weapon>` (TommyGun) / `FireSingle<Weapon>` (Pistol) — check the
     actual asset name per weapon, don't assume one naming convention covers all three —
     non-looping, then return to Fidget.
   - Reload: `Reload<Weapon>` (Crossbow, TommyGun) / `FastReload<Weapon>` (Pistol) —
     again, check per-weapon naming, non-looping.
   - Unequip: `Unequip<Weapon>` on weapon switch, if there's a clean hook for "about to
     switch away" (`UpdateWeaponSlotVisibility` or wherever slot switching happens) —
     don't force this in if there's no natural hook, a missing unequip animation is a
     smaller gap than a crash or a hacky forced hook.
   - Zoomed-in variants (`ZoomedInFidget*`, `ZoomingIn*`, `ZoomingOut*`, `ZoomedInFire*`)
     exist for TommyGun/Pistol/Crossbow — wire these in only if there's already a clear
     "is the player aiming down sights" signal to hook off; if that concept doesn't
     exist in this codebase yet, leave zoom animations out rather than inventing an ADS
     system as a side effect of this task.
3. **Shotgun and ChemicalThrower have zero first-person animations.** Do not guess
   substitutes or silently reuse another weapon's clips. The correct behaviour is
   whatever `EnsureViewHands`' base idle pose already is (or holding the last pose) —
   say clearly in the result that these two are unanimated pending an asset import, not
   something this task's code can fix.
4. **Wrench**: excluded from this task entirely — no mesh exists yet (blocked on the
   StaticMesh viewmodel gap from `h3-weapon-mesh-import`).

## Tests / verify

Extend or add a headless verify script (model the shape on `verify_weapon_feedback.py`
and `h1`'s `verify_ai_animation.py`): equip each of TommyGun/Pistol/Crossbow in turn via
`GiveWeaponByDef` + `EquipWeapon`, assert the grip socket resolved to that weapon's own
socket name (not empty, not a stale TommyGun match), assert the idle/fidget animation
for that specific weapon is playing (not always `FidgetTommygun`), fire once and assert
the fire animation for that weapon plays, then let it finish and assert it returns to
that weapon's own fidget. Also assert Shotgun/ChemicalThrower equip cleanly (no crash,
no animation asserted since none exist).

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- No live UE session in this worktree — headless assertions are the evidence; a human
  confirms the actual look and feel in the editor afterward, especially for socket
  positioning and fire-animation timing, which are exactly the kind of thing a headless
  check can't fully judge.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
