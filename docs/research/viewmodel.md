# First-person viewmodel architecture

**Status:** researched + runtime rebuilt to match. Captures under `runs/v1-viewmodel-match-bioshock/`.
**Lane:** UE5 runtime (`tools/ue5/BioShockRuntime/**`) + this note. Decode/export readers untouched.

This note is the design authority for how BioShock 1 places and animates first-person weapons,
what our imported assets already contain, why the previous UE5 framing loop failed, and what the
runtime now does instead.

Confidence labels follow `docs/ENGINEERING_RULES.md` §27 / Process.

---

## 1. What BioShock 1 actually does

### 1.1 Hands sit at a fixed camera / eye transform

`CONFIRMED_BYTES` — `tmp/uc_shockgame/Hands.uc` `UpdateLocation` plus `Weapons.ini` `[ShockGame.Hands]`:

```
PlayerViewOffset=(X=0.0,Y=0.0,Z=0.0)
PlayerViewOffsetWidescreen=(X=0.0,Y=0.0,Z=0.0)
WeaponBobDamping=0.5   (class default; not overridden in the dumped Hands section)
```

Each tick the `Hands` actor is placed at the pawn eye (`EyeHeight`) with the view rotation, plus
`PlayerViewOffset` rotated into view space. With the config at zero that is **exactly the eye
point** — no per-weapon fudge, no per-frame socket pinning.

`PLAUSIBLE` — the mesh origin of `NEWPlayerHands` is that eye attachment. `Bip01_Spine` sits ~74 cm
behind the origin in every sampled idle (`FidgetPistol` spine local ≈ `(1.7, 5.0, −73.9)`), so the
authored arm reach puts the gun in the classic low-right FPS diagonal once the mesh origin is on
the camera.

### 1.2 Two animation handles, same timing

`CONFIRMED_EXTERNAL` — `Hands.uc` states `WeaponEquipping` / `WeaponIdling` / `WeaponFiring` /
`WeaponReloading`:

- `HandsAnimationHandle = PlayAnimationOnChannel(…, Get*HandsAnim(), …)` on channel 0
- `WeaponAnimationHandle = CurrentHoldable.PlayAnimationOnChannel(…, Get*Anim(), …)` on the weapon

Equip, idle, fire and reload all start **both** clips and `FinishAnimation` both handles. Hand-bob
is a **separate additive channel** (`kHandBobAnimationChannel = 2`) and asserts
`IsAnimationAdditive` — sway is not baked into the idle.

`CONFIRMED_BYTES` — duration pairing (already recorded in `docs/HANDOFF.md` / `context.md`): e.g.
hands `FireShotgun` and weapon `Fire` are both 1.50 s / 46 frames @ 30 fps; hands
`FireSinglePistol` and weapon `FireSingle` are both 0.23 s / 8 frames.

### 1.3 Attachment bone is per-weapon, always on `R_Grip`

`CONFIRMED_BYTES` — script defaults + `Weapons.ini`:

| Weapon | `AttachBone` | Hands idle | Weapon idle / fire leaf |
|---|---|---|---|
| Wrench | `Wrench` | `FidgetWrench` | static mesh (no weapon rig) |
| Pistol | `Pistol` | `FidgetPistol` | *(no idle clip)* / `FireSingle` |
| MachineGun | `TommyGun` | `FidgetTommygun` | *(no idle)* / `Fire` |
| Shotgun | `Launcher` | `FidgetShotgun` | `SingleFrame` / `Fire` |
| GrenadeLauncher | `Launcher` | `FidgetLauncher` | *(no idle)* / `Fire` |
| ChemicalThrower | `Chem` | `FidgetChem` | `Fidget` / `FireStart`… |
| Crossbow | `Crossbow` | `FidgetCrossbow` | *(no idle)* / `Fire` |

`CONFIRMED_BYTES` — skeletalmesh socket table: every weapon socket (`Wrench`, `Pistol`, `TommyGun`,
`Launcher`, `Chem`, `Crossbow`, …) binds to bone `R_Grip`. There is **no** `Shotgun` socket; the
shotgun uses `AttachBone=Launcher` (`CONFIRMED_BYTES` in both `.uc` and ini).

`OnEquippingStarted` calls `AttachToBone(theHoldable, theHoldable.GetAttachBone(…))` once. The
holdable then rides the animated bone.

### 1.4 FOV

`CONFIRMED_EXTERNAL` — zoom paths fade `DesiredFOV` ↔ `DefaultFOV` and a separate
`ForegroundFovAngle` / `DefaultForegroundFOV` (viewmodel FOV). Exact numeric defaults are **not**
in the baked `Weapons.ini` / `DefUser.ini` sections dumped here (`UNKNOWN` for the shipped default
degree value). UE runtime keeps `CameraFieldOfView = 75` from commit `baaaaa0` as a
`PLAUSIBLE` match to the classic BioShock look; refine from a live `DefaultFOV` read if one is
found later. Separate foreground FOV is **not** wired in UE5 yet (`UNKNOWN` / deferred).

---

## 2. What our exported / imported data contains

### 2.1 Hands: `R_grip` is a rigid child; the arm drives the socket

`CONFIRMED_BYTES` — sampled `FidgetPistol` and `FidgetShotgun` tracks (export JSON under
`%TEMP%/bioshock_viewmodel_probe/`):

- `R_grip` **local** translation is constant (`≈ (3.969, 2.022, −0.148)`).
- `R_grip` **local** rotation is constant (quat self-dot ≈ 1 across the clip).
- Parent chain **does** move: `Bip01_R_UpperArm` quat first→mid dot ≈ 0.47 on `FidgetShotgun`;
  `Bip01_L_Hand` ≈ 0.19.

So the hand clip **does** move the grip in component / world space — through the arm, not by
keying `R_grip` itself. A weapon snapped to the `Pistol` / `Launcher` / … socket therefore sways
with the fingers **if and only if** the hands mesh is left free to animate.

### 2.2 Weapon rigs are separate performances

`CONFIRMED_BYTES` — `ShockGame.U` wrappers:

| Wrapper | Root bone | Idle-ish | Fire | Reload |
|---|---|---|---|---|
| `UAPW_WP_Pistol` | `R_grip` | — | `FireSingle` | `FastReload` |
| `UAPW_WP_TommyGun` | `R_grip` (6 tracks) | — | `Fire` | `Reload` (+ `Equip`) |
| `UAPW_WP_Shotgun` | `SG_Body` | `SingleFrame` | `Fire` | `Reload` / `Reload_Loop` |
| `UAPW_WP_Crossbow` | (15 bones) | — | `Fire` | `Reload` |
| `UAPW_WP_GrenadeLauncher` | (8 bones) | — | `Fire` / `FireLast` | `Reload` (+ `Equip`) |
| `UAPW_WP_ChemicalThrower` | (8 bones) | `Fidget` | `FireStart`/`FireLoop`/`FireEnd` | `Reload` |

Shotgun root `SG_Body` (children `SG_Pump`, `SG_Shell`) is **not** a grip bone
(`CONFIRMED_BYTES`). Attachment still goes to hands socket `Launcher` on `R_Grip`
(`CONFIRMED_BYTES`). BioShock's `AttachToBone` places the weapon actor (mesh root = `SG_Body`) on
that socket; the authored bind + `SingleFrame` pose are what make the hands meet the wood and
receiver — not a second "grip bone" align.

### 2.3 Socket transforms

`CONFIRMED_BYTES` — origins are zero for the weapon sockets; rotations are not all identity
(Wrench ≈ 180° about Z; Launcher / TommyGun carry small quats; Pistol / Chem identity). See
`FirstPersonWeaponOrientationTests` and the probe dump of `Launcher_FirstPerson.json` sockets.

`CONFIRMED_BYTES` (import path, commit `d534944` era) — applying those rotations onto grip-weapon
sockets **and** running `AlignEquippedWeaponRootToGripSocket` (which cancels the weapon's
`R_grip` root component transform) double-rotates Pistol / TommyGun / GL / Crossbow. Current
`import_bioshock._restore_manifest_sockets` therefore keeps a decoded transform for **`Wrench`
only** and restores other sockets as name+bone at identity. That remains correct under the new
runtime design for `R_grip`-rooted guns.

`PLAUSIBLE` — Shotgun on `Launcher` may want the decoded Launcher rotation without a matching
`R_grip` cancel. Deferred unless captures still show a systematic twist after the architecture fix;
do not re-introduce double-rotation for the grip-rooted set.

### 2.4 Re-import

`CONFIRMED_BYTES` — hand clips for all seven weapons and weapon clips listed above are already on
disk under `/Game/BioShockWeapons/…` (72 hand anims; per-weapon `WP_* / Animations`). **No
re-export/re-import is required** for the architecture fix. If a leaf is missing at runtime the
weapon mesh simply stays in bind / last pose and the log warns — same as today's reload path.

---

## 3. Why the previous UE5 code failed

Hypotheses from the task brief, verified:

| # | Claim | Verdict |
|---|---|---|
| 1 | `ViewHands` on camera at rel (0,0,0), clips via `PlayAnimation` | `CONFIRMED_BYTES` (code) — keep |
| 2 | `FrameViewmodel` every Tick pins the animated grip socket to `ViewmodelOffset`, cancelling hand motion on the gun | `CONFIRMED_BYTES` (code + §2.1) — **root cause of "hands don't line up with the gun"** |
| 3 | Weapon mesh often static; BioShock plays a matching weapon clip | `CONFIRMED_BYTES` — reload already played weapon clips; idle/fire/equip did not |
| 4 | `AlignEquippedWeaponRootToGripSocket` on Shotgun (`SG_Body`) + camera pin = "huge blob" | `CONFIRMED_BYTES` (code) — `PinShotgunToCamera` fought socket attach; Align for `SG_Body` is actually what `AttachToBone` means and is kept; the pin is removed |
| 5 | FOV 90 vs ~75 | `PLAUSIBLE` — keep 75 |
| 6 | Stash `AnchorViewHandsToGrip` (ref-pose socket → `ViewmodelOffset`) | `CONFIRMED_BYTES` (stash patch) — right idea (stop per-frame re-pin) but still **subtracts the socket from the mesh origin**, which with `ViewmodelOffset≈(68,17,−28)` and the wrench's forward ref-pose socket shoves the arms through the camera. Wrong because BioShock's offset is **(0,0,0)** at the eye, not "put socket at a screen fudge" |

Nudging `ViewmodelOffset` / per-weapon shotgun pins could never converge: every weapon's idle moves
`R_Grip` differently, and freezing that point makes each clip need a different lie.

---

## 4. Design implemented

1. **Fixed camera-relative hands transform.** `ViewHands` relative location/rotation set **once**
   from `ViewmodelOffset` / `ViewmodelRotation` (defaults **`(0,0,0)` / identity**, matching
   `PlayerViewOffset`). Command-line `-bioshockvmoffset=` / `-bioshockvmrot=` still override for
   capture A/B. **No per-frame socket re-pin. No `PinShotgunToCamera`.**

2. **Attach weapon to the script `AttachBone` socket** (`ResolveGripSocketForWeapon`, including
   Shotgun → `Launcher`). `SnapToTarget` + `AlignEquippedWeaponRootToGripSocket` for skeletal
   weapons (including Shotgun) so FBX root drift is cancelled and the mesh root lands on the
   socket — BioShock `AttachToBone` semantics.

3. **Two-rig playback.** When ViewHands plays equip / fidget / fire / reload, the equipped
   `AShockWeapon` plays the matching mesh leaf at the same time (loop flag shared). Leaves:

   | Def | Idle | Fire | Reload | Equip |
   |---|---|---|---|---|
   | Pistol | — | `FireSingle` | `FastReload` | — |
   | TommyGun | — | `Fire` | `Reload` | `Equip` |
   | Shotgun | `SingleFrame` | `Fire` | `Reload` | — |
   | Crossbow | — | `Fire` | `Reload` | — |
   | GrenadeLauncher | — | `Fire` | `Reload` | `Equip` |
   | ChemicalThrower | `Fidget` | `FireStart` | `Reload` | — |
   | Wrench | — (static) | — | — | — |

4. **Hand-bob additive channel** — not implemented (needs additive clips + move-speed weights).
   Recorded as deferred; idle fidget already carries most of the on-screen life.

5. **Socket import policy** — unchanged (Wrench transform only). Revisit Launcher-only restore only
   if shotgun captures still show a fixed twist after (1)–(3).

---

## 5. Verification / captures

Rebuild: `tools/ue5/rebuild_runtime_fast.ps1` (editor closed). Captures in
`runs/v1-viewmodel-match-bioshock/` via `capture_shot.ps1` + `-bioshockstartslot=N`.
Optional mid-anim: `-bioshockshotfire` / `-bioshockshotreload` (fire/reload a few settle-ticks
before the shot).

| File | Slot | Result (looked at) |
|---|---|---|
| `0_wrench_idle.png` | 0 | Right hand grips wrench, low-right diagonal — reads BioShock |
| `1_pistol_idle.png` | 1 | Revolver low-right diagonal, right hand on grip |
| `1_pistol_reload.png` | 1 | Reload one-shot triggered (`-bioshockshotreload`) |
| `2_tommygun_idle.png` | 2 | **Best match** — both hands on gun, vertical foregrip + pistol grip, BioShock diagonal, ~40% frame |
| `2_tommygun_fire.png` | 2 | Fire one-shot triggered |
| `3_shotgun_idle.png` | 3 | **Residual** — hands present; weapon mesh draws **flat green** (materials/textures not binding on this asset); left hand open. Architecture path correct (socket=Launcher, SingleFrame idle logged); mesh paint is a separate import fault |
| `3_shotgun_fire.png` | 3 | Fire one-shot on same green mesh |
| `4_grenadelauncher_idle.png` | 4 | Two-hand hold, low-right, large in frame |
| `5_chem_idle.png` | 5 | Chem tank gripped; mesh idle `Fidget` logged |
| `6_crossbow_idle.png` | 6 | Both hands on crossbow, BioShock diagonal |

Logs (TEMP): `%TEMP%/bioshock_viewmodel_captures/logs/`. Every equip logged
`BIOSHOCK_VIEWMODEL fixed offset=V(0) rot=R(0)` and the expected grip socket. Dual-clip idle
logged for Shotgun (`SingleFrame`) and Chem (`Fidget`); Tommy/GL logged weapon `Equip` with the
hands equip clip.

### Shotgun green mesh

`CONFIRMED_BYTES` (capture) — `WP_Shotgun` Content has `Textures/Shotgun_NoUpgrades_*` and an MI,
but the in-game draw is unlit green. Earlier CLI export of those PNGs was ~4 KB (placeholder-sized).
**Not fixed in this change** — architecture no longer pins/fudges the shotgun; restoring real
shotgun mips / material bind is a follow-up import pass (`export-fbx` / `import_bioshock` for
`WP_Shotgun` only).

---

## 6. Open / deferred

| Item | Label |
|---|---|
| Exact `DefaultFOV` / `DefaultForegroundFOV` degrees from a live controller default | `UNKNOWN` |
| Additive hand-bob channel in UE | deferred |
| Shotgun shell-by-shell reload (`_Start`/`_LOOP`/`_End` + weapon `Reload_Loop`) | deferred (trigger clip only) |
| Chem `FireLoop`/`FireEnd` while trigger held | deferred (`FireStart` on fire notify) |
| Whether Launcher socket rotation should be restored for Shotgun only | `PLAUSIBLE`, capture-gated |
| Shotgun flat-green draw (textures present on disk, not bound / empty mips) | `CONFIRMED_BYTES` capture; import follow-up |
