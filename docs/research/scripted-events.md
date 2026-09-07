# Scripted events in the playable slice

How MessageTrigger, scripts, and doors connect so the Medical load-room door (and plain
scripted doors) open in `/Game/BioShockSlice/1-Medical`.

## Pipeline

```
TriggerBox overlap (UE2 TriggerVolume)
  → UShockTriggerRelayComponent
  → UShockScriptSubsystem::DispatchMessage("MessageTrigger", <volume label>)
  → UShockScriptRegistry fans to every UShockScriptRunner whose TriggeredBy matches
  → AShockScript::Tick → TickExecution → ShockAction*::ApplyInWorld
  → ActionOpenDoor / PlayAnimation(*OPEN*) → AShockDoor::OpenDoor
```

Level-entry scripts (TriggeredBy = `1-Medical`, `All`, `all`) do not wait for a volume.
`UShockScriptSubsystem::OnWorldBeginPlay` defers one tick, then dispatches those labels.

## Registry home

`UShockScriptSubsystem` (`UWorldSubsystem`) owns the single `UShockScriptRegistry` for the
world. `AShockScript::EnsureRegistry` and `import_scripts.py` both prefer
`ShockScriptSubsystem.GetRegistryForWorld`. A per-actor registry is only a fallback when no
world subsystem exists — that old path is why messages never reached sibling scripts.

## Trigger relay

`import_level._import_region_volumes` attaches `UShockTriggerRelayComponent` on every
`TriggerVolume` → `TriggerBox`. `setup_playable_slice` also runs
`import_slice_doors._wire_existing_trigger_relays` so an already-built slice map gets relays
without a full re-import. One-shot is the default when `triggerOnlyOnce` is absent; disabled
volumes stay quiet. Overlaps require `AShockPlayer` by default.

## Doors in the slice

`import_level._import_door_attachments` places `MedicalDoors` / `MedicalDoors_Solid` / … as
`AShockDoor` (labels from the export). The slice setup step `import_slice_doors` calls that
plus places `LoadRoomDoor` (`MedicalLoadRoomDoor`) — that class has no `door` attachments key
in the export, so the full level importer used to skip it.

`AShockDoor::bEnableProximityOpen` can be turned off to prove a script-only open path.

## Where import_scripts sits

`setup_playable_slice.STEPS` ends with:

1. `import_slice_doors` — ShockDoors + trigger relays on `/Game/BioShockSlice/1-Medical`
2. `import_slice_scripts` — loads that map, then `import_scripts.import_scripts` against
   `Exports/slice/1-Medical/1-Medical.ue5-level.json` and the `.script-actions.json` sidecar
   (DoorLabel overlays for ActionOpenDoor / Lock / Unlock / Close)

## Load-room door (CONFIRMED from export)

Script `LoadRoomDoor`, TriggeredBy `1-Medical` (start-driven, not a nearby volume):

1. `ActionWait` 0.5s
2. `ActionPlayAnimation` TargetLabel=`MedicalLoadRoomDoor` Animation=`LoadRoomDoor_OPEN`
3. `ActionPlayAnimation` … `LoadRoomDoor_OPENED`

Until skeletal door clips are wired, `UShockActionPlayAnimation` treats `*OPEN*` clips aimed
at a placed `AShockDoor` as `OpenDoor(StayOpen)`. Proximity open is separate and can be
disabled for verification.

`OpenMedicalHallwayDoor` (TriggeredBy `MedicalHallwaySwitch`, a DoorSwitch — out of scope for
plain MessageTrigger) is the later hallway unlock; not required for the load-room beat.

## Headless checks

- `verify_import_scripts` — decode + Medical import + shared registry dispatch sample
- `verify_script_doors` — Request* records, plus MessageTrigger / relay → ActionOpenDoor →
  placed `AShockDoor` with proximity open disabled
