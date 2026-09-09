---
worker: chatgpt
base: main
verify: dotnet test tests/BioShockStudio.Tests/BioShockStudio.Tests.csproj --filter Tier=Fast
lane: src/**, tests/**, tools/ue5/**, docs/research/**, tmp/**
---

# Shotgun viewmodel — the hands don't wrap the gun

`docs/AUDIT_2026-09-06.md` open gap #5 (and `docs/research/viewmodel.md`): the shotgun's screen
placement is fixed (bore-axis solve, `4046dee`) and acceptable, but the `FidgetShotgun` hand
clip poses the fingers around **where the gun was authored in BioShock's space**, not where the
solve now puts it — so the hands float slightly off the grip / forestock.

`ENGINEERING_RULES.md` §60 names the proper fix: **carry `MeshSocket.Transform` through the FBX
manifest** so the UE import knows the authored socket transforms, and place the shotgun on its
real attach socket (`Shotgun.uc AttachBone`) at the authored offset — the same way every other
weapon aligns to `R_grip` — instead of the from-posed-hands solve that only exists because the
socket data was missing.

## What to build

1. **C# — `MeshSocket.Transform` through the manifest.** `ResolveMesh` /
   `AnimationSceneExporter` already read `MeshSocket` (name + bone); also serialise the socket's
   local transform (translation + rotation) into the FBX `ue5_manifest.json` per socket. This
   is the general fix — it helps every rig, not just the shotgun. Additive; keep Fast tests
   green; add a test that a known socket's transform round-trips.
2. **UE import** — `import_bioshock` / `import_level` skeletal path: create UE `SkeletalMeshSocket`s
   from the manifest transforms (currently sockets are name+bone only).
3. **`AShockPlayer` shotgun path** — once the shotgun has a real socket, drop
   `AlignShotgunToHandPose` and align the shotgun root to its authored socket like the other
   weapons (`AlignEquippedWeaponRootToGripSocket`). Keep the bore-axis check as a sanity assert.
4. Re-tune the `FidgetShotgun` playback / hand IK only if a residual gap remains.

## Deliverable

- `docs/research/viewmodel.md` + `g3-socket-transform-through-manifest` notes updated.
- C# socket-transform serialisation + test; UE socket creation; shotgun alignment on the real
  socket.
- `-game` shotgun captures (`capture_shot.ps1 -Extra @('-bioshockstartslot=3')`, a few settle
  values) — hands wrapping the grip and forestock.
- Fast tests green; `verify_viewmodel_anims` / `run_weapon_mesh_anims` still pass.

## Constraints

- `src/**` additive only, Fast tests green. `tools/ue5/**` for import + player alignment.
- Editor CLOSED for headless. MSYS forward-slash + `MSYS_NO_PATHCONV=1`.
- Do NOT commit. Diff for review; human confirms the grip visually.
