---
worker: cursor
base: main
verify: powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/**, docs/research/**, tmp/**
---

# Vendors — the machines aren't in the world

The station UI works (`verify_stations`, `verify_inventory`, `run_stations.py` pass —
vend / gene-bank / garden / inventory screens render and transact). But the **machines
themselves aren't placed** in `/Game/BioShockSlice/1-Medical`, so there's nothing to walk up to
and use.

## Manifest data (1-Medical)

- `PlaceableVendingStation` ×3 — Circus of Values / El Ammo Bandito (ammo + consumables).
- `PlaceableHealthStation` ×6 — wall health stations (pay → heal).
- `PlaceableGrowthStation` ×1 — Gatherer's Garden (buy plasmids/tonics with ADAM).
- `ResurrectionStation` ×2 — Vita-Chamber (respawn point; `ShockActionActivateResurrectionStation`
  / `DisableOrEnable` already exist as stubs).
- `CashRegister` ×10 — searchable for cash (w10 owns these unless they're vendor-linked).

## Runtime that exists

`ShockStationActor`, `ShockStationMenu`, `ShockBathysphereStation`, `run_stations.py`,
`verify_stations.py`, `c3-inventory`, the plasmid/tonic gene-bank flow.

## What to build

1. **`tools/ue5/import_slice_stations.py`** (mirror `import_slice_doors.py`): place each
   station manifest actor as the right `AShockStationActor` subtype with its mesh, and an
   `Interact` trigger. Idempotent, wired into `setup_playable_slice` STEPS.
2. **Interaction → UI** — `Interact` in range opens the matching station screen (vend / health /
   gene-bank / already-built). Close on move-away or a key.
3. **Stock + transact** — each vending machine's inventory (from the manifest / a shipped
   station-stock record if one exists — `dotnet run ... properties 1-Medical
   <PlaceableVendingStation>`; else a sensible Medical stock list, documented). Buying: check
   cash / ADAM, deduct, grant the item, update the UI. Health station: pay per heal, cap at
   full.
4. **Vita-Chamber** — `ResurrectionStation` becomes the active respawn point when the player
   passes it (BioShock 1 behaviour, no difficulty toggle needed for the slice); on death,
   respawn there at partial health with enemies retaining damage. Coordinate with the existing
   `BindPlayerDeathHandling` / `ShockDeathRespawnHandler`.
5. **`CashRegister`** — if it's a vendor-linked till, wire it; if it's just searchable loot,
   leave it to w10.

## Deliverable

- `docs/research/vendors.md` — station types, stock sourcing, transaction rules, Vita-Chamber
  respawn, what's approximated.
- `import_slice_stations.py` + interaction + STEPS wiring.
- Headless: `verify_vendors.py` — N stations placed by type; a `-game` check that interacting
  with a vending machine opens the screen, buying an item with enough cash deducts + grants and
  with too little is refused; a health station heals for cash; dying near a triggered
  Vita-Chamber respawns the player there.
- `-game` captures: a vending machine with its screen open, a health station, the Gatherer's
  Garden, a Vita-Chamber.

## Constraints

- `tools/ue5/**` only. Editor CLOSED for headless. `-run=pythonscript` → JSON. MSYS
  forward-slash + `MSYS_NO_PATHCONV=1`. Kill stray procs between runs.
- Do NOT commit. Diff for review.
