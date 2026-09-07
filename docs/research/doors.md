# BioShock doors

Confidence labels in this note are:

- **CONFIRMED_BYTES** — decoded package properties, manifest records, or animation tracks.
- **CONFIRMED_RUNTIME** — observed in UE5 or covered by a headless runtime check.
- **INFERRED** — the evidence agrees, but the original native implementation was not observed.
- **UNKNOWN** — evidence is insufficient.

## Two visual architectures

### `Door` / `MedicalDoors`: animation proxy plus rigid leaves

**CONFIRMED_BYTES.** The ordinary Medical doors do not render their `Mesh` as the door.
`Med_DoorAnim` is a 26-vertex, 16-triangle skeletal animation proxy. Its sole section has a null
material reference. The class-default `Attachments[]` instead names two `Med_DoorRight` static
meshes, attached at `LeftDoor` and `rIGHTdOOR`. `Med_DoorRight` is the visible 1,824-vertex,
2,292-triangle leaf and has resolved medical-door and reinforced-glass shaders. See
`door-and-import-materials.md` for the byte audit.

This pattern also explains why drawing the bare proxy produced grey or shard-like geometry:
there is no missing shader to recover for the proxy. The correct representation is an invisible
skeletal component playing the source clip, with movable static-mesh components attached to the
source bones/sockets.

**CONFIRMED_RUNTIME.** `AShockDoor::AddDoorLeaf` implements that representation. The slice import
places 62 attachment leaves and skips four unresolved attachments. Leaves have no individual
collision; one explicit blocker represents the doorway.

### `LoadRoomDoor`: genuinely skinned door

**CONFIRMED_BYTES.** `LoadRoomDoor2` has no `Attachments[]` leaf set. Its class-default mesh is
`LoadRoomDoorMESH`, a 2,707-vertex / 2,796-triangle skeletal mesh with one resolved opaque
`LoadRoom_door` shader (diffuse, normal, and specular maps). Its rig has seven bones, including
`SOCKET_LeverBlocking` and `SOCKET_blocking`. Therefore it is not another empty Medical-door
proxy.

The five decoded clips share its skeleton:

| Clip | Purpose |
|---|---|
| `LoadRoomDoor_OPEN` | six-second transition; lever motion plus panel travel |
| `LoadRoomDoor_OPENED` | opened hold |
| `LoadRoomDoor_CLOSE` | closing transition |
| `LoadRoomDoor_CLOSED` | closed hold |
| `LoadRoomDoor_SPINNING` | lever/wheel loop |

**CONFIRMED_BYTES.** The open track moves `Bone06` approximately +199 Unreal units in Y and rotates
`Bone03` approximately 180 degrees. That is the source of the sliding panel and lever motion; a
yaw-swing approximation is incorrect.

The exported FBX retains vertex weights and uses the same skeleton for mesh and clips. UE5.7 still
reports that the FBX pose's mesh-relative matrices do not match and recreates the bind pose.
`use_t0_as_ref_pose` is enabled specifically for `LoadRoomDoorAnim`. A clean reimport must delete
the old `Animations` directory in a separate editor process before replacing the Skeleton:
AnimSequences retain hard references to the deleted Skeleton, and loading those orphan packages
can assert in `AsyncLoading2`. `run_reimport_load_room_door.py` encodes that two-run recovery.

The missing `LoadRoomDoorAnim_PhysicsAsset` warning is unrelated to rendering. The import
deliberately does not create a physics asset.

## Runtime state and collision

`AShockDoor` owns:

- a root transform;
- a non-colliding static fallback;
- a non-colliding skeletal component;
- zero or more non-colliding rigid attachment leaves;
- one `DoorBlocker` box for passage;
- one overlap trigger for interaction/proximity opening.

**CONFIRMED_RUNTIME.** Script and proximity requests use the same state machine. Opening is refused
when `bLocked` or `bBroken` is set. A forced close can override the stay-open state. The blocker is
enabled while closed and disabled once the opening transition reaches its terminal state, so visual
mesh or missing physics assets cannot leave invisible collision in the doorway.

For the load-room door, the source `_OPEN` and `_OPENED` clips drive the skinned mesh. Before the
level-entry script's 0.5-second delay, the runtime starts `_CLOSED` rather than exposing the FBX
reference pose.

## Locked, broken, switches, and keypads

**CONFIRMED_BYTES.** Source `Door` data includes `bLocked`, `bInitiallyOpen`,
`OpenAnimationName`, `OpenAnimationRate`, `Attachments[]`, and `DoorPortal`. `DoorSwitch`,
`DoorButtonControl`, `DoorAccessControl`, `DoorKeypadControl`, and `ThreeStateDoor` are separate
control/state variants rather than different mesh import formats.

**CONFIRMED_RUNTIME.** Imported locked/broken flags are respected by direct, scripted, and
proximity open requests. Message-trigger relays and script actions address doors by source label.

**UNKNOWN / deferred.** Full keypad UI, access-code validation, chained-door portal visibility,
and every source-specific `BROKEN`/`STUCK` transition are not reproduced by this slice. Their state
must not be inferred merely from a mesh or clip name.

## Slice replacement rule

The door import removes only the static actor carrying the exact
`instance:<LoadRoomDoor actor key>:<LoadRoomDoor asset key>` tag. Other actors are not hidden by
name substring. Ordinary source door proxy instances are replaced by their exact imported door
actors and attachment leaves. This prevents both z-fighting and the earlier over-broad operation
that hid unrelated meshes.
