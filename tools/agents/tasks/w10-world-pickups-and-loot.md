---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# World pickups and lootable containers — none are placed in the slice

The slice manifest (`1-Medical.ue5-level.json`) places a full economy of items, and **none of it
is in the playable slice** — you can't pick up a health kit, loot a corpse, or grab ammo. Only
the verify-flag `SpawnSliceAmmoPickup` / `SpawnSliceConsumablePickup` debug spawns exist.

## Manifest data (1-Medical)

**Pickups:** `BandagesPickup` ×21 (first aid), `MedHypoPickup` ×11, `EVEHypoPickup` ×11,
`AdamPickup` ×10, ammo — `StandardBulletPickup` ×9 / `StandardBuckshotPickup` ×9 /
`ArmorPiercingBulletPickup` ×8 / `MachineGunBulletPickup` ×5 / `IonicBuckshotPickup` ×6 / etc.,
`AutoHackDevicePickup` ×3, `PowerBarPickup` ×3, food/drink (`ChipsPickup`, `WhiskyPickup`,
`BeerPickup`, `CoffeePickup`, `TwinkiePickup`, `CheapCigarettesPickup`, …), weapon pickups
(`PistolPickup` ×3, `ShotgunPickup`, `WrenchPickup`), plasmid pickups (`ActivePlasmidPickup` ×2,
`EngineeringPlasmidPickup` ×2, `WeaponsPlasmidPickup` ×2, `PhysicalPlasmidPickup`), key items
(`ChompersDentalKeyPickup`), and **`LogPickup` ×15 (audio diaries)**.

**Searchable containers:** `DeadBodyContainer` ×20 (w5 ragdoll pass already made these
ragdolls — add the search-for-loot verb), `FlowerVaseContainer` ×6, `CashRegister` ×10,
`CorpseMaleBooty` ×1, `KeyframedDeadBodyContainer` ×1.

## Runtime that exists

`ShockAmmoPickup`, `ShockConsumablePickup`, `ShockActionSpawnPickup`, `ShockActionPlaceItem`,
inventory (`c3-inventory`), first-aid / EVE-hypo use (`ShockPlayer::UseFirstAid` / `UseEveHypo`).
No world-placed pickup import, no searchable-container verb.

## What to build

1. **`tools/ue5/import_slice_pickups.py`** (mirror `import_slice_doors.py`): place every
   `*Pickup` manifest actor with its mesh + a pickup component. Interaction: BioShock auto-picks
   ammo/health/money on touch, requires a keypress (`Interact`/`F`) for weapons, plasmids, key
   items and diaries. Grant into inventory / ammo pool / EVE / cash. Idempotent, wired into
   `setup_playable_slice` STEPS.
2. **Searchable containers** — a `USearchableComponent` (or extend the door/interaction pattern):
   `Interact` on a `DeadBodyContainer` / `CashRegister` / `FlowerVaseContainer` /
   `*Booty` → a short search, then drop its loot (the manifest record names it, or roll from a
   level loot table — say which). Corpses: search verb + the existing ragdoll.
3. **`LogPickup` → audio diary** — pick up → add the diary to the player's collection and the
   status-menu Messages tab (`w6` / `w1` own the playback + transcript; this places the pickups
   and records "collected"). If the transcript/audio data isn't readily available, place the
   pickup and log the diary id, leave playback to w1.
4. **Weapon pickups** — `PistolPickup` / `ShotgunPickup` / `WrenchPickup` grant the weapon +
   starting ammo and switch to it (BioShock behaviour on first pickup).

## Deliverable

- `docs/research/pickups.md` — the manifest actor list, auto vs keypress rules, container
  search, loot sourcing, what's approximated.
- `import_slice_pickups.py` + `USearchableComponent` + STEPS wiring.
- Headless: `verify_pickups.py` — N pickups placed, each resolves a mesh + grant type; a `-game`
  check that walking the player onto a `BandagesPickup` raises the first-aid count and onto a
  `StandardBulletPickup` raises pistol ammo; a container search drops an item.
- `-game` captures: a health kit on a shelf, a looted corpse.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless. `-run=pythonscript` → JSON. MSYS
  forward-slash + `MSYS_NO_PATHCONV=1`. Kill stray procs between runs.
- Don't reintroduce un-floor-traced spawns.
- Do NOT commit. Diff for review.
