---
worker: cursor
base: main
verify: powershell -ExecutionPolicy Bypass -File tools/ue5/rebuild_runtime_fast.ps1
lane: tools/ue5/BioShockRuntime/**, tools/ue5/*.py
---

# Weapon mesh doesn't visually react to the reload animation

User report (in-editor, 5 Sept 2026), clarified after an initial ambiguous phrasing:
"the gun doesn't respond to the reload animation" — this is about the **weapon's own
mesh** (magazine ejecting/inserting, bolt/slide moving, whatever moving parts the
weapon model has) not visually animating during `Reload()`, not an input-lockout bug.

## Important prior context — do not re-litigate without new evidence

Earlier the same night, a near-identical-sounding report ("pistol reload animation is
working but the animation for the pistol to react to the hand animation isnt working
either") was investigated with a REAL headless test, not a guess:
`h10-real-movement-and-weapon-tracking-tests`' `BeginVerifyWeaponTrack`/
`TickVerifyWeaponTrackSample`/`FinishVerifyWeaponTrack` (`ShockGameMode.cpp`) equips the
Pistol, calls `Reload()`, and samples the weapon's world transform every 0.1s against
`FastReloadPistol`'s own `GetPlayLength()`. That test showed the weapon's transform DOES
follow/update throughout the reload (socket-follow is live) — the conclusion at the time
was "not a bug, `FrameViewmodel`'s deliberate screen-pinning just makes it read as
static," not a genuine defect.

This task must determine whether tonight's report is:
(a) the SAME thing being seen again, now that the user can actually test properly (movement
    was broken until a few hours before this report, so this may be the first real look), meaning the
    earlier "not a bug" conclusion needs revisiting with fresh eyes — screen-pinning a weapon that's
    also supposed to show a magazine popping out is a real design tension worth double-checking, or
(b) a genuinely different gap: the weapon's own skeletal mesh has moving parts (magazine,
    bolt, slide) that have NO animation asset/montage driving them at all during reload,
    separate from whatever h10 measured (h10 measured the weapon's overall world
    TRANSFORM, i.e. does it move/follow the hand socket — it did NOT necessarily confirm
    the weapon mesh's own SKELETON plays a reload animation on its own bones), or
(c) specific to a weapon h10 never tested (h10 only checked Pistol) — confirm whether
    Tommy Gun / Crossbow / Shotgun weapon meshes even have reload animation assets
    imported for their own skeletons, vs. only the ViewHands arms having one (h8's table
    only covers ViewHands/NEWPlayerHands clips — check separately whether
    WP_TommyGun/WP_Pistol/etc. skeletal meshes have their OWN reload animation sequences
    at all, or whether the weapon mesh is a static rigid attachment with no bones that
    move independently of the hands).

Do not assume screen-pinning is still the explanation without checking (b) and (c)
directly — confirm whether each weapon's own mesh has a reload animation asset it could
even play, and whether anything calls `PlayAnimation` on the weapon's own skeletal mesh
component (as opposed to only on `ViewHands`) during `Reload()`.

## Tests / verify

If a genuine gap is found (weapon mesh has moving parts / a reload anim asset that
exists but is never played, or doesn't exist and should), verify by driving `Reload()`
headlessly and asserting the weapon mesh's own skeletal mesh component's active
animation matches the expected reload clip for that weapon (not just its world
transform, which h10 already covers). If the conclusion is instead "this is the known
screen-pinning behavior, not a new bug," say so explicitly and point back to h10's
result rather than re-implementing anything.

## Constraints

- `tools/ue5/BioShockRuntime/**` and `tools/ue5/*.py` only.
- No live UE session in this worktree — headless assertions are the evidence; note that
  a human should confirm the actual visual read in-editor afterward regardless of which
  explanation this task lands on.
- Do not commit or push. Update `tools/ue5/README.md` with a dated entry once verified.
