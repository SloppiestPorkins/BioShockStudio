# Animated props — fans, ScriptableMovers, turrets

Foundation for script-driven kinematic props in the UE5 slice. Runtime actors live under
`tools/ue5/BioShockRuntime`; level import places them from `*.ue5-level.json`.

**Status (7 Sept 2026).** `AShockAnimatedProp` implements continuous spin and keyframe
actor-transform motion (swept). `UShockActionPlayAnimation` / `UShockActionChangeAnimationRate`
drive those props while still recording `Last*` for headless verifies. Medical-slice import
places ScriptableMovers + fan meshes + TurretSpawners. Motion is **transform-driven** — no
skeletal animation data invented.

**Headless stamp.** `verify_animated_props` PASS (16 checks, `animated_props: ok`) via
`run_animated_props.py` / `-run=pythonscript` / NullRHI — fan `AccumulatedSpinDegrees` +360°
at 1 rps, `ChangeAnimationRate` → scale 2.5, `PlayOnActor` starts keyframe move (z 50→150),
turret yaw tracks player, barrel mesh present. Re-run after touching these files.

## 1. Medical slice census (`1-Medical.ue5-level.json`)

| Class / shape | Count | Notes |
|---|---:|---|
| `ScriptableMover` | **8** | Typed `mover` record + raw `KeyPos`/`KeyRot`/`MoveTime` in `properties` |
| `Fan` class | **0** | Absent in Medical; task estimate (~6) does not match this package |
| Fan meshes (`fanv2` on `StaticMeshActor`) | **4** | Treated as continuous-spin props |
| `Turret` placed actors | **0** | |
| `TurretSpawner` | **5** | One carries `ForScriptedSpawn` (TargetPoint only); four get `AShockTurret` |
| `AggressorSpawner` | **19** | Unchanged this task |
| `Elevator_Switch*` / `Elevator_Button*` | **0** | Not in Medical |

Sample mover (`MeatLockerDoor` / `ScriptableMover5`): `InitialState=TriggerToggle`,
`TriggeredBy="MeatLockerDoorScript, MeatLockerOn"`, `KeyRot[1]=KeyRot[2]=(0,-90°,0)` (Unreal
rotator units decoded), mesh `decor_fridgedoorsmall`. Sample translating mover
(`TurretTrapTop`): `MoveTime=0.3`, `KeyPos[1]=(-4,144,-6)`, `KeyPos[2]=(-96,0,-8)`.

`KeyPos`/`KeyRot` are **not** typed in the C# `MoverActorData` (see
`docs/research/interaction.md` §3). Import decodes them from property `valueHex` in Python —
layout `CONFIRMED_BYTES` (float32×3 / int32×3); semantic path **APPROXIMATED** until a
`-game` capture confirms direction and basis.

## 2. `AShockAnimatedProp`

Movable static-mesh actor (`PropMesh` root, `BlockAll`, no physics sim).

| Mode | Behaviour |
|---|---|
| `ContinuousSpin` | Actor rotation about axis; rev/sec from BeginPlay; toggleable; `SpinRateScale` from scripts |
| `KeyframeMove` | Interpolates actor location/rotation across keys (rest + KeyPos/KeyRot offsets); swept `SetActorLocationAndRotation`; one-shot / ping-pong / loop |

Label: `PropLabel` (+ editor actor label). `FindByLabel` matches either.

Fan default when export has no rate: **0.75 rev/s** about local +X
(`_DEFAULT_FAN_REVOLUTIONS_PER_SECOND` in `import_level.py`). Documented APPROXIMATION —
Medical fan actors carry no `RotationRate` in the sidecar.

## 3. Action stubs → real motion

| Action | Still records | New effect |
|---|---|---|
| `ShockActionPlayAnimation` | `LastPlayedAnimation`, `LastPlayedActorName` | On `AShockAnimatedProp`: `PlayScriptedMotion` (start/toggle keyframe, or enable spin); `PlayOnActor` returns that result. Non-prop targets unchanged (record only → true). |
| `ShockActionChangeAnimationRate` | `LastTargetLabel`, `LastAppliedRate` | `ApplyRateInWorld` sets `SpinRateScale` + `MotionRateScale` on matching props. |

`EndBehavior=Loop` maps to ping-pong on movers. `TriggerToggle` movers import as one-shot;
a second `PlayAnimation` reverses.

## 4. Import wiring (`import_level.py`)

- Mesh instances for `ScriptableMover` / `Fan` / `*fan*` assets are deferred (not placed as
  plain `StaticMeshActor`).
- `_import_animated_props` spawns `AShockAnimatedProp`, assigns mesh, configures spin or
  keyframes from `mover` + raw `KeyPos`/`KeyRot`/`MoveTime`.
- `_import_turret_spawners` places hostile `AShockTurret` at each `TurretSpawner` unless
  `ForScriptedSpawn` is present (those stay TargetPoints for `ActionSpawnTurret`).

## 5. Turrets

`AShockTurret` already tracks opposing `AShockPawn`s (`FindBestTarget` → `UpdateAimToward`)
with transform pan/tilt (**APPROXIMATION** — no skeletal barrel rig). Visual stand-in: cube
root + cylinder barrel (`/Engine/BasicShapes`). Hostile by default; `ActionHackTurret` /
security shutdown remain the hack path. `ActionSpawnTurret` already spawns a real
`AShockTurret` at the labeled marker (header comment corrected).

## 6. Headless verification

```text
verify_animated_props.py / run_animated_props.py
```

Checks: fan mesh rotates; `ChangeAnimationRate` sets scale 2.5; `PlayAnimation` on a
keyframe prop moves it on Z; turret yaw turns toward a spawned player. Also keep
`verify_script_movement` (unchanged contract) and existing `verify_action_play_anim` /
batch22 record checks.

`-game` / capture evidence (fan spin, script-fired gate, turret facing) is owed when the
editor is free and E1's script pipeline is live for the gate path.

## 7. What this does not claim

- Skeletal `PlayAnimationOnChannel` on characters / doors — still record-only outside
  `AShockAnimatedProp`.
- `KeyPos`/`KeyRot` basis and key-0 semantics — APPROXIMATED; see interaction.md §3.
- Elevator call buttons — absent from Medical; not wired.
- AggressorSpawner placement — out of scope here.
