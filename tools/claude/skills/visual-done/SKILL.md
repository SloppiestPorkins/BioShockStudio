---
name: visual-done
description: Load whenever you fix, investigate, or are about to call done any visual, rendering, material, texture, lighting, shadow, exposure, viewmodel, decal, glass, water, god-ray or FX bug in the BioShock UE project (BioshockHavok repo or C:/Users/Jack/Documents/BioShockUE5), and whenever the user sends a screenshot of something in the game looking wrong. Defines when a visual bug counts as fixed (a rendered capture from the reported spot that you have Read), how to triage a screenshot, and how to drive capture_shot.ps1 / capture_set.ps1.
---

# Visual bugs: done means seen

> Commands below run from the repo root. Sessions usually start in `C:/Users/Jack/Documents/AI Test`,
> so `cd C:/Users/Jack/Documents/BioshockHavok` first (or the worktree you are testing).


A visual bug is done only when a rendered capture from the spot the user reported shows it fixed,
and you have opened that PNG with the Read tool (the before and the after, whenever a before exists).
Nothing else counts:

- A headless `-run=pythonscript ... -nullrhi` PASS never counts. The Null RHI draws no pixels; a level
  whose every wall painted one flat colour passed fourteen of those checks.
- A blank frame (stddev < 1) or near-black frame (mean < 3) is a failed capture, not evidence.
  capture_shot.ps1 exits 2 on blank; capture_report.py flags both.
- A frame that is not blank is still not proof. Look at it and say what you see.
- "changed" in a capture report means a human must look at the pair. It is not pass or fail.

## Screenshot triage (user sends a picture of something wrong)

1. Locate the spot: landmarks, posters, room shape, which way the camera faces. Match them against
   the level manifest `C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/1-Medical.ue5-level.json`
   (`actors[].location` is already UE world cm; `instances[].transform[12..14]` and
   `lights[].location` need Y negated: UE = (x, -y, z)). If you cannot place it, ask the user once,
   with your best guess, rather than guessing silently.
2. Confirm the offending actor is in the playable slice `/Game/BioShockSlice/1-Medical`, not the raw
   import `/Game/BioShockLevel/1-Medical`. PIE runs the slice; fixing the other map changes nothing.
3. Reproduce it with a capture from that spot BEFORE changing any code. Read the PNG. If the capture
   does not show the bug, you have the wrong spot or the wrong theory; do not start fixing.
4. Add the spot to `tools/ue5/viewpoints/<level>.json` (name, abs, look, why, validated: true once a
   capture shows the right view) so every later change re-checks it.
5. Fix, recapture the same viewpoint, Read before and after side by side.
6. Record it in `docs/STATUS.md` under "Landed but not yet PIE-confirmed by the user". It moves to
   done only when the user confirms it in PIE.

## Taking captures

One shot (renders on D3D12, about 1-2 minutes each; only one Unreal process may run at a time, so
never launch a capture while another Unreal, a capture, or a plugin rebuild is running):

```powershell
& tools/ue5/capture_shot.ps1 -Out C:\Users\Jack\Documents\BioShockUE5\Captures\scratch\x.png `
  -SettleTicks 24 -Extra @('-bioshockshotabs=-17250,1280,7740', '-bioshockshotlook=-17250,3000,7740')
```

Switches most used in `-Extra` (parsed in ShockGameMode.cpp / ShockPlayer.cpp):

| switch | effect |
|---|---|
| `-bioshockshotabs=X,Y,Z` | camera at an absolute UE world position (cm) |
| `-bioshockshotlook=X,Y,Z` | aim the camera at a world point |
| `-bioshockshotyaw=D` / `-bioshockshotpitch=D` | degrees added to the current aim (after look) |
| `-bioshockshotmove=F,R,U` | walk the camera from the PlayerStart along its view axes |
| `-bioshockshotev=S` | brighten the capture only by S stops (dark Medical exposure) |
| `-bioshockshothud` | also write `<name>_hud.png`; the scene capture never includes UMG |
| `-bioshockstartslot=N` | equip weapon slot 0-7 (Wrench, Pistol, TommyGun, Shotgun, GL, Chem, Crossbow, Camera) |
| `-bioshockvmrot=P,Y,R` / `-bioshockvmoffset=X,Y,Z` | viewmodel rotation / offset A/B without a rebuild |

`-SettleTicks` below 24 risks a cold DDC showing default materials, which looks exactly like a material
bug. `capture_shot.ps1 -FireAtWall` fires through the last ticks (pair with `-bioshockstartslot=2`).

A whole set, with contact sheet and baseline diff:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/capture_set.ps1 -Set medical
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/capture_set.ps1 -Set medical -Only "lobby-red-wash,arrival-porthole-steinman"
powershell -NoProfile -ExecutionPolicy Bypass -File tools/ue5/capture_set.ps1 -Set medical -DryRun
```

It writes `C:/Users/Jack/Documents/BioShockUE5/Captures/<set>/<stamp>/` with one PNG and log per
viewpoint, `contact_sheet.png`, `report.md` / `report.json`. Read the contact sheet, then Read the
full-size PNG of every viewpoint your change could touch. Exit 1 means a shot was blank, near-black,
missing or skipped as busy.

## Bash vs PowerShell (arrays)

- From PowerShell, call `capture_shot.ps1` in-process with `&` and a real array: `-Extra @('a','b')`.
- From Git Bash, `powershell -File capture_shot.ps1 -Extra a,b` arrives as ONE string "a,b" (or is
  rejected), so the camera switches silently vanish and you photograph the PlayerStart. From Bash,
  either use capture_set.ps1 (put the spot in a viewpoint JSON; `-Only` takes one comma string), or
  `powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'tools/ue5/capture_shot.ps1' -Out '...' -Extra @('-bioshockshotabs=...','-bioshockshotlook=...'); exit \$LASTEXITCODE"`
  (escape `$` so Bash leaves it alone; without the `exit` the blank-frame exit code 2 is lost).
- Git Bash rewrites arguments that start with `/` (e.g. `/Game/...` becomes `C:/Program Files/Git/Game/...`).
  Prefix with `MSYS_NO_PATHCONV=1` when passing `-Map /Game/...` from Bash.
- Check the log for `BIOSHOCK_SHOT_ABS` / `BIOSHOCK_SHOT_LOOK` lines to confirm the camera switches arrived.

## Baselines

Captures are copyrighted game imagery. Baselines live in the local UE repo at
`C:/Users/Jack/Documents/BioShockUE5/Captures/baseline/<set>/` (git LFS there), never in the public
BioshockHavok repo; capture_set.ps1 refuses an output or baseline folder inside it. Refresh with
`capture_set.ps1 -Set medical -UpdateBaseline` only after you have Read the new shots and they look
right; a baseline is a picture someone approved, not whatever the last run produced.

## Reporting

When you report a visual fix, name the viewpoint(s), the before/after PNG paths, and one sentence on
what each shows. If no rendered capture was possible (Unreal busy, crash), say so plainly and leave
the item open: "landed, not visually verified".
