# Gameplay fidelity batch (25 Sept) — implementation notes

Facts only from UnrealEd guide chs 25/27/31/32; no guide prose.

## B03 / B11 spawner changes — NOT landed (Claude, 25 Sept)

The task proposed spawning `InitialAITypes` at BeginPlay (B11) and removing the turret's
player-proximity deferral (B03). Both were reverted on review: the code comments they deleted
record a real incident — a spawned splicer and an early turret killed the player through the
airlock wall on level entry — and the audit item does not address the cause (no line-of-sight /
dormancy gating on those AIs). Revisit together with LOS-gated firing and dormant/patrol states,
not alone. import_slice_enemies.py places markers only, so double-spawn was never the risk.

## B08 despawn

Guide never says alarm-timeout bots despawn. Property default is now `-1` (never). Positive
values retain delayed `DespawnAllBots` for opt-in / headless tests.

## B04 defaults vs existing verifies

`verify_security.py` / `verify_hacking.py` call `configure_for_verify` and aim devices; they
do not rely on the old 3000/90 defaults. Camera at ~350 uu still sits inside SightDistance
1000 with half-angle 30 when yawed at the player.

## Verifies touched for old behaviour

- `verify_security.py`: `alarm_clear_despawns_bot` → keep by default; opt-in positive lifetime
  still despawns.
- `ShockHackingMinigame` headless verify: win asserts device Friendly and
  `!IsSecurityHacked()` (was requiring system hack).
