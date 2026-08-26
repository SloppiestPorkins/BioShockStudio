# Porting BioShock to UE5 in full — a strategy

**Written 23 Aug 2026, at the user's request: import the entire game into UE5, including game
logic and AI.**

This is a plan, not a claim of work done. Every number in it is measured from this repository or
from the shipped game; where something is a judgement call it says so.

---

## 1. The bottom line, first

**The assets are a solved problem in principle and a grind in practice. The game logic is readable
but not portable automatically. The gap between those two facts is what this plan is built around.**

One measured asymmetry decides the whole strategy:

| What decompiles | Quality | Usable as |
|---|---|---|
| Class hierarchy, names, `var` declarations | **Clean** | Machine input |
| `defaultproperties` blocks | **Clean** — `CollisionRadius=50.0`, `bPrefersRangedAttack=true` | Machine input |
| Function bodies, state machines | **Degraded** — control-flow artifacts, `__NFUN_<id>__` placeholders, occasional statement errors | Human documentation |

So: **port the data mechanically, reimplement the behaviour by hand, and use the decompiled source
as the specification while doing it.** Anything that tries to transpile UnrealScript function bodies
into C++ or Blueprint will faithfully encode the decompiler's own defects, and will be harder to
debug than a hand-written implementation read from the same source.

**Do not attempt an automatic UnrealScript-to-UE5 transpiler.** It is the obvious idea and it is the
wrong one, for the reason above.

---

## 2. Three layers, three strategies

### Layer A — Assets. Mechanical. Extend what exists.

Meshes, skeletons, animations, textures, levels. Already imports into UE5.7 today
(`tools/ue5/import_bioshock.py`, `import_level.py`). Bounded work, not research.

### Layer B — Data. Mechanical, and mostly not built yet.

Every class's schema and defaults; every placed actor's transform, zone, tags and references; every
`Script` actor's `Actions` array; every AI archetype's tuning numbers. **This is the highest-value
unbuilt piece**, because it is pure data, it decompiles cleanly, and it is what makes Layer C
tractable rather than open-ended.

### Layer C — Behaviour. Hand-written, prioritised by measured usage.

Function bodies, state machines, native calls. Reimplemented in UE5 C++ against the decompiled
source as a spec. **Bounded by data**: this project can measure which classes the shipped levels
actually use, so the work is prioritised by evidence rather than by guessing.

---

## 3. What already exists (measured, not estimated)

**Assets:** 8,668 static meshes, 967 skeletal meshes (99.9% resolving section tables), 16,031
animations (0 decode failures), 30,831 textures plus 287 cubemaps, 14,328 materials. UE5 import
works end to end: meshes, skeletons, animations, textures with correct sRGB and compression,
idempotent re-runs. **Rigs verified for real in UE5.7 across every rig category the game ships**:
first-person weapons (pistol, TommyGun, Crossbow, ChemicalThrower, GrenadeLauncher), humanoid
characters (splicer, both Big Daddy variants, Little Sister), mechanical doors/props/turrets, and
creatures (cat, crab, whale, giant squid, jellyfish, shark).

**Levels:** 21 map packages. BSP world, 118,919 placed actors across 764 classes, 1,042 zones with
connectivity, 2,386 portals with their zone pairs, 465+ lights per map, 281 cubemap probes.

**Physics:** Havok ragdolls decoded — 207 rigs, 1,426 rigid bodies with world transforms, masses,
inertia, friction, restitution; capsule shapes; the full constraint graph. **Joint limits are not
decoded and will not be** (declined on Havok licence grounds, `docs/research/havok-physics.md`).

**Game logic:** **1,445 classes decompile with 0 hard failures** across `ShockGame.U` (654),
`ShockAI.U` (540), `Scripting.U` (99) and seven smaller packages. `Engine.U` does not decompile (a
UELib version-gating bug) but is mostly stock engine classes. `ShockAI.U` alone is 64,698 lines,
3,120 functions, **103 state machines** and **66 Action classes**.

**Audio:** the chain is decoded down to sound names, but **where the sound data lives is still
UNKNOWN** and is the standing blocker (`docs/research/audio.md` section 4).

---

## 3a. Why UE5.7 initially rejected every exported file — and the fix

The single largest investigation before this plan was written. UE5.7's legacy FBX importer rejected
every file this project's exporter produced, with `File is corrupted` / `No mesh is found or
animation track`. An exhaustive byte-level audit — header, `GlobalSettings`, `Definitions` object
counts vs. actual, the `Connections` graph, transform properties, polygon winding and end-markers,
skinning cluster data, zlib stream validity, the trailing magic footer, and a full object-schema diff
against a known-good reference file — found the exported files were **not** malformed (independently
confirmed: Blender's own FBX importer opens them cleanly). The actual fix ended up being pragmatic
rather than a root-cause fix for the SDK's rejection:

- `tools/blender/normalize_fbx_for_ue5.py` re-exports every FBX through headless Blender before
  handing it to UE5 — Blender's re-export is byte-different in ways not yet fully characterized, but
  UE5.7 accepts it.
- A `BioShockImportTools` UE5 editor plugin (`tools/ue5/BioShockImportTools/`) restores the
  `SOCKET_*` markers that round-trip drops.
- `tools/ue5/verify_bioshock_import.py` checks an imported asset set against its manifest.

**Verified for real, not just documented**: a fresh pistol export run through
`import_bioshock.main` → `verify_bioshock_import.main` in a live UE5.7 editor session imported both
rigs and all 12 animations cleanly (`Success - 0 error(s), 7 warning(s)`, warnings cosmetic — missing
smoothing groups, sockets outside the bind pose). The TommyGun slice is verified the same way per
`tools/ue5/README.md`. No app-facing "export to UE5" button exists — this is still a command-line/
editor-script bridge, deliberately; see §9's "app-facing export workflow" entry for why.

---

## 4. The insight that makes the AI tractable

BioShock's AI and scripting is **data-driven**, and both halves are already partly in hand:

- **The level side:** `Script` actors (3,942 game-wide) carry `Actions` arrays, and
  `LevelAnalyzer.ScriptActions` **already resolves them to typed class and object references**.
- **The code side:** those references name `Action*` classes — `ActionAttackTarget`,
  `ActionHackTurret`, `ActionAssignNextProtectorVent` — each a small class with typed parameters
  (`var travel name AILabel; var travel name TargetLabel; var travel bool bAttackOnSight;`).

So a level's scripted behaviour is **a graph of parameterised action nodes**, and this project can
already read the graph. What is missing is the implementations — 66 of them in `ShockAI`.

**That reframes "port the AI" from an unbounded research problem into a countable list**, and the
list can be ordered by how often each action actually appears in the shipped maps. That census does
not exist yet and is cheap to build.

The same argument applies to enemy tuning: `RangedAggressor`'s `defaultproperties` already give
collision size, locomotion flags, ranged-attack preference and a damage-resistance set name. Every
archetype has such a block, and they extract cleanly.

---

## 5. The plan

### Phase 0 — Prove the whole stack on one vertical slice (do this first)

**One level, one enemy archetype, one weapon, playable end to end.** Not the best-looking slice; the
*thinnest* one that exercises every layer. The point is to find the integration problems while they
are cheap.

**The asset half is done, 26 Aug 2026** — `1-Medical` + `Agg_BabyJane` + the TommyGun, imported in
one pass into a saved `.umap` and verified from the reloaded level; see §9's entry. *Playable* is
untouched: it needs Phase 3's runtime, and nothing here is a claim about behaviour.

This project's own history is the argument. Every UE5 item worked on so far had a defect that only
appeared when the pipeline was actually run: a manifest that did not carry texture intent, an
importer with textures switched off, a level importer that spawned 465 duplicate lights. Breadth
before a working slice multiplies that class of problem by 21 maps.

### Phase 1 — Finish Layer A (assets)

1. **Level geometry as real UE5 meshes.** Today the BSP world exports as OBJ and the level importer
   places `TargetPoint` placeholders where geometry should be. The single biggest visible gap.
2. **Materials as UE5 material instances (rig slice verified).** The manifest v2 rig path now
   generates authored-material parents and instances, binds base colour/normal textures, preserves
   raw material provenance, and assigns them to the UE LOD section's actual slot index. Visually
   verified on `WP_Pistol` in UE5.7. **Still open:** carry the same graph/instance path onto level
   geometry; this is not evidence that BSP/static-mesh materials are finished.
3. **Cubemaps as reflection captures**, using the `CubemapProbe` actors' positions (281 of them,
   each naming its `Cubemap`).
4. **Lighting.** 465+ lights per map already export with colour and brightness. **Mapped 25 Aug
   2026:** authored brightness as a scale (inverse-square off), authored radius as attenuation
   radius, missing radius dropped. Not candelas, not `* 1000`. Falloff exponent still `UNKNOWN`.

### Phase 2 — Build Layer B, the data layer (highest-value unbuilt work)

1. **A class-schema exporter.** Run the decompiler over all 1,445 classes and emit structured JSON:
   class, parent, `var` declarations with types, and the full `defaultproperties` tree. Mechanical,
   decompiles cleanly, and **nothing else in this plan is efficient without it**.
2. **An action-usage census.** For every `Action*` class, how many times it appears across the 21
   maps' `Script` actors. This orders Phase 4.
3. **Extend the level manifest** to carry the script graph, AI spawner configuration, zone
   membership (already decoded via `Actor.Region`) and archetype references.

### Phase 3 — A runtime skeleton in UE5 C++

Mirror the parts of the class tree that matter as real UE5 classes: `AShockPawn`, `AShockAI`,
`UAction` with a parameter block populated from Phase 2 data, `UActionSet`, the weapon and plasmid
bases. Populate instances from exported data rather than hand-authoring them.

**Where UE2 and UE5 genuinely differ** — these need design decisions, not translation:

- **UnrealScript states** (103 in ShockAI) have no UE5 equivalent. Map to a state-machine component
  or to StateTree / behaviour-tree nodes.
- **Latent functions** (`Sleep`, `FinishAnim`, latent `MoveTo`) are VM-level in UE2. In UE5 they
  become latent nodes or C++ coroutine-style tasks.
- **Havok to Chaos.** Bodies, masses, capsules and the constraint graph are decoded; joint limits
  are not, and are licence-blocked, so ragdoll constraints must be re-authored or approximated.

### Phase 4 — Implement the behaviour library, in measured priority order

Work the action list from Phase 2's census, most-used first. For each: read the decompiled `.uc`,
implement in C++, verify against the game.

**Budget this honestly.** `ShockAI` alone is 3,120 functions and 103 state machines; `ShockGame` is
larger again. This is the long pole by a wide margin, and no tooling removes it.

### Phase 5 — Audio (blocked, not on the critical path)

Sound names resolve; the sound data location is UNKNOWN. Ambient placement is already decoded
(`AmbientSound` actors name sounds by `Tag`, `SoundMarker` carries `ambience_*` schema names), so
the moment the data is located, placement is ready. Until then the port runs silent.

---

## 6. Risks, stated plainly

| Risk | Assessment |
|---|---|
| **Scale** | ~1,445 classes. A multi-year effort at hobby pace. The vertical slice is what keeps it honest. |
| **`__NFUN_<id>__` natives** | Only a partial ID-to-name map exists. Each unresolved native is a small research task at implementation time. |
| **`Engine.U` will not decompile** | Mostly stock classes; a real problem only if a specific base class turns out to matter. |
| **Havok joint limits** | Licence-blocked, permanently. Ragdolls need re-authored constraints. |
| **Audio data** | Genuinely unknown; may stay blocked indefinitely. |
| **Fidelity drift** | Hand-written behaviour will diverge from the original. Decide early whether the goal is *faithful* or *playable* — they are different projects. |

## 7. Constraints

This repository already forbids committing game-derived data, and that applies here: decompiled
UnrealScript, extracted assets and any UE5 project built from them are derived from a commercial
game. This plan assumes a personally-owned copy and no redistribution. Havok's licence separately
prohibits the reverse engineering that joint limits would require — already declined twice, and it
stays declined.

## 8. What to do next, concretely

In order, smallest first:

1. **The class-schema and `defaultproperties` exporter** (Phase 2.1). Mechanical, self-contained,
   and everything downstream gets cheaper once it exists.
2. **The action-usage census** (Phase 2.2). Cheap, and it turns "port the AI" into an ordered list.
3. **Level geometry as real meshes** (Phase 1.1). The biggest visible gap in what already imports.
4. **Then the vertical slice**, using the three above. **Asset half done, 26 Aug 2026** (§9); the
   playable half has a **class skeleton** plus Medical **GameMode/PlayerStart/editor-pilot**
   (same day). PIE possess not claimed; no `Action*` yet.

Items 1 and 2 are the ones to start with: small, pure data, and they convert the open-ended part of
this project into something countable.

---

## 9. Decisions and measurements taken since this plan was written

### The goal is FAITHFUL — user decision, 23 Aug 2026

Confirmed directly when asked. It also matches the standing instruction already recorded in
`docs/HANDOFF_UE5_IMPORT.md` section 1: port everything over faithfully first, modify or improve
only after the port is in place.

**What "faithful" means here, precisely, because one reading of it is not achievable:**

- **Faithful to the source, not to observed behaviour.** Verifying behavioural fidelity would need
  an oracle — a way to observe the running game's AI decisions and compare. No such instrumentation
  exists, so "faithful behaviour" is not a claim this project can verify, and it does not make
  unverifiable claims. What is achievable is implementing each action and state exactly as the
  decompiled UnrealScript reads.
- **Where the decompilation is degraded** — control-flow artifacts, `__NFUN_<id>__` placeholders —
  the implementer makes a judgement call and **records it**, the same way research notes record an
  `UNKNOWN`. Divergences then exist on the record rather than by accident.
- **Faithful semantics, native mechanism.** Use StateTree rather than reimplementing UE2's VM state
  system; use Chaos rather than emulating Havok. Preserve *which* state, *which* transition and
  *what* parameters. Porting the 2007 implementation strategy as well as its meaning is how these
  projects die.

### Phase 2.1 done — the class-schema exporter

`tools/uelib-bridge --schema <out.json> <package.U>` emits every class's hierarchy, variable
declarations and `defaultproperties` as JSON. Measured across the six real script packages:

**1,410 classes, 5,233 variables, 5,870 defaults, 0 unreadable.**

It deliberately does **not** emit function bodies — those are documentation for a human, not machine
input, and emitting them would invite exactly the transpiler approach section 1 argues against.

### Phase 2.2 done — the action-usage census, and the number that sizes the port

`ActionUsageCensusTests`, over all 21 maps: **3,932 `Script` actors, 21,752 action references, 186
distinct action classes, 0 unresolved class names.**

The distribution is a steep power law, and this is the single most useful planning number in this
document:

| Implement | Covers |
|---|---|
| top 5 actions | 41% of all scripted behaviour |
| top 10 | 57% |
| **top 20** | **73%** |
| top 30 | 81% |
| **top 50** | **90%** |
| top 75 | 96% |
| all 186 | 100% |

53 actions are used five times or fewer; 16 are used exactly once.

The head of the list is mostly control flow and scene plumbing rather than AI combat logic —
`ActionWait` (2,209), `ActionSetProperty` (1,902), `ActionIf` (1,891), `ActionPlayEffect` (1,806),
`ActionNonBlockingExecuteScript` (1,106) — which is good news: those are the cheapest to implement
and they unlock the most.

**So Phase 4 is not "implement 186 actions".** It is roughly: ~20 for a working vertical slice,
~50 for most of the game, ~75 for near-complete coverage, and a long tail that can be implemented
on demand as specific levels need it.

### Phase 1.1 done — level geometry as real UE5 meshes

Verified in UE5.7 on `0-Lighthouse`: **1,274 `StaticMeshActor`s placed from 422 imported static
meshes, 0 skipped.**

**Exported per asset, not per instance.** The existing world OBJ bakes every instance into world
space — right for opening a level in a viewer, wrong for an engine import, because it discards
instancing entirely and a brush used forty times arrives as forty copies. `LevelExportFormats
.AssetMeshes` writes one local-space OBJ per unique asset instead, and the manifest's per-instance
transforms place them. For `0-Lighthouse` that is **21 MB against the flattened world's 123 MB**,
for the same geometry.

Manifest bumped to **version 4** (assets now carry a `file`), and `validate_level_manifest.py`
follows.

The instance transform is decomposed by hand rather than through `unreal.Matrix`: the manifest
stores System.Numerics' row-vector convention, and getting that wrong yields a level that looks
plausible and is subtly inside out — a failure this project has already paid for once in the BSP
viewport.

**Still placeholders:** 1,401 actors with no geometry to attach, reported as `unsupported` exactly
as before. Materials are the next gap — the meshes import untextured.

### Phase 1.1 continued, 24 Aug 2026 — level materials, UV mapping, multi-material slots, and two
bugs that had been reported as clean

**Level materials landed and verified in a live UE5.7 run.** `LevelSceneExporter` now resolves every
distinct material a level's placed sections use (455 materials, 1,179 texture bindings, 958 PNGs on
`1-Medical`) and `import_level.py` creates/assigns real `MaterialInstanceConstant`s, reusing
`import_bioshock.py`'s rig pipeline. Two real bugs found by regression tests that check the actual
connection rather than that both sides are merely non-empty, not by inspection:

- A `MaterialSwitch` section's key named the switch; the manifest entry resolving it was keyed by
  the resolved *child* material instead — every other number looked complete (materials non-empty,
  textures on disk) while that one lookup silently failed. Fixed by keying the written entry off the
  section's own referenced identity.
- `BuildAssetObj` wrote positions and faces only — no `vt` (UV) line at all, so **every** level asset
  imported through this path had no texture mapping regardless of which material got assigned, and
  every face in one ungrouped run regardless of how many materials a mesh's sections named. Fixed:
  one `vt` per vertex (same V-flip convention as the proven FBX rig path) and one `usemtl
  BioShock_{n}` group per section. Verified live: of 792 `1-Medical` assets needing more than one
  slot, a 20-asset sample all show the imported slot count matching the manifest's section count
  exactly — confirming UE5's OBJ importer does split by `usemtl` group in file order, the one
  empirical assumption this depended on. 1,357 static meshes total got a real material assigned.

**Instance placement was wrong the whole time this phase's own text above called it "placed
correctly."** `import_level.py` never reversed `GameBasis.Convert` (the reflection this project's
whole pipeline applies because Blender/FBX/glTF are right-handed and BioShock/Unreal are natively
left-handed), so every instance landed mirrored in Y with an inverted rotation — plausible at a
glance, wrong up close. **Found by the user exploring the imported level, not by any check this
project runs.** Fixed and verified live by replaying `LevelSceneTests.
TheMedicalPavilionCeilingArchFormsOneContinuousSurface`'s own geometric check against the
actually-placed actors: combined bounding diagonal came back 2422 units, the test's own reference
value for a correctly-assembled arch (a wrong-handed one measures ~4295).

**The `unsupported` count itself was wrong since `import_level.py` was first written.**
`_import_instances` marked an actor "handled" by its geometry instance's own composite key, never
the bare actor key `_import_actors` checks — so every actor with real geometry also got a second,
overlapping `TargetPoint` placeholder, miscounted as unsupported. On `1-Medical`, reported 7,337,
true figure 2,018. This means every `unsupported` figure quoted earlier in this document and in
`docs/ROADMAP.md` predates the fix and overstates the gap — not a new regression, a standing one.

**Net effect on this plan, as of 24 Aug 2026:** Phase 1 (assets) for levels is now materially closer
to done than §5/§9 above describe — geometry, UV mapping, single- and multi-material texturing,
correct placement, and accurate reporting are all verified live. What Phase 1 still did not cover for
levels at this point: animated `SkeletalMesh`-kind instances (imported as bind-pose-only static
geometry through the same path as everything else — no skeleton, no animation, no link to the
character's actual rig), and cubemaps as reflection captures (§5 Phase 1.3, probe actors and face
PNGs landed 25 Aug 2026; live UE5.7 probe/face import the same day, see the still-open paragraph
below). See the
next entry for the skeletal case landing the following day.

### Manifest versioning, idempotency, and a per-level validation map — done, 23 Aug 2026

Both verified in UE5.7, closing out most of Gate 5's original item list (this section absorbs what
was previously tracked as `docs/ROADMAP.md`'s Gate 5 — kept here now instead of duplicated there).

- **Versioned manifests.** `ue5_manifest.json` carries `version` (`FbxExporter.ManifestVersion`); the
  level manifest already had `formatVersion`. `import_bioshock.py` **refuses** an unversioned
  manifest outright, because one predating texture intent would otherwise import rigs with no
  textures — which looks like a working import and is not one.
- **Idempotent imports.** Rig import measured first run 8 created / 0 updated, second run **0
  created / 8 updated**, asset count unchanged at 22. Level import 1,877 created then **0 created /
  1,877 updated**. Both report created/updated/skipped/unsupported per run.
- **A UE5 validation map**, `tools/ue5/build_validation_map.py`, built and verified in UE5.7 with
  `missing: []` — one instance of every supported asset class (a skeletal mesh, a point light, the
  level importer's placeholder class, textures with their intent read back from the assets). It
  states what is *not* supported too — at the time: level geometry as UE5 meshes (fixed the next
  day, see the 24 Aug entries above), UE5 material graphs, cubemaps as reflection captures. **25 Aug
  2026:** `SphereReflectionCapture` is now in `supported`. The validation map itself has not been
  re-run live; a dedicated Medical cubemap import the same day placed 29 captures (see still-open
  paragraph below). `TextureCube` assembly stays unsupported (face order UNKNOWN). The `missing` field is the one that
  matters: a class claimed supported but not instanced is a failure, reported rather than skipped.
- **First proof of concept on `1-Medical`, 24 Aug 2026.** Previously verified only on `0-Lighthouse`
  (1,877 actors). Exported and validated cleanly (`validate_level_manifest.py`, exit 0): 8,089
  actors, 1,551 unique mesh assets, 5,322 geometry instances, 692 lights. Imported into the
  `BioShockUE5` project's `Untitled` transient level: **13,411 created, 0 updated, 0 skipped, 7,337
  unsupported** (typed placeholders — scripts, markers, spawners; correctly reported rather than
  silently dropped) — **the 7,337 figure itself was wrong, see the duplicate-`TargetPoint` bug
  above; the true figure is 2,018.** The user then looked at it directly in the editor — walls,
  floor and a room's worth of geometry render at the correct scale and position, no materials
  (checkerboard, as expected — bindings exist, no graph generated yet). Confirmed against that
  session's own work: searching the Outliner for `MeatLocker` surfaces `MeatLockerDoor` as a real
  `StaticMeshActor` with `MeatLockerDoorScript`/`MeatLockerOn` — its two `ResolvedTriggers` targets
  from the same day's mover-resolution commit — placed nearby as the `TargetPoint` placeholders
  their `Script` class predicts. Not saved as a persistent level asset — a live, unsaved
  verification pass, not a checked-in result.

### Level-placed characters as real animated `SkeletalMeshActor`s — done, 25 Aug 2026

Closes the skeletal-case gap the previous entry left open. Verified in a live UE5.7 run, not just a
clean report.

Until this, every `SkeletalMesh`-kind level instance (splicers, Big Daddies, but also animated
non-character props like doors) landed as a bind-pose `StaticMeshActor`, same as any other static
geometry. `export-level` (`Program.cs`) now also writes an FBX rig — mesh, skeleton, animations — to
`Rigs/<meshName>/ue5_manifest.json` for every distinct mesh a level places, once per mesh variant
rather than per character group (a group can own several: thirteen splicer variants off one
`AggressorBabyJane`, each needing its own separate UE5 `SkeletalMesh`). `import_level.py` imports
each rig into a shared `/Game/BioShockCharacters` root — deliberately not per-level, so a character
appearing in many maps is one reused asset — and places a `SkeletalMeshActor` instead of the old
placeholder wherever a rig resolved, falling back to the bind-pose static mesh (not losing the actor
entirely) when one didn't.

**A real bug caught before it shipped**: the first working draft passed the mesh's own name as
`AnimationSceneExporter.Build`'s `owner` filter, believing it namespaced the export — it actually
filters to animations whose own recorded `OwnerName` field matches (the mechanism
`export-firstperson` uses to pick one weapon's animations out of a shared hands package). No mesh
name is ever a valid `OwnerName`, so every exported rig silently carried **zero** animations — no
exception, a clean-looking manifest, wrong content. Caught by reading the exported rig's own
animation count rather than trusting the exit code, fixed by passing no filter (a character's own
wrapper already carries only that character's animations).

**1-Medical, live UE5.7 import**: 8,092 created / 958 updated / 0 skipped / 2,018 unsupported
(matches the figure above exactly — nothing else regressed) / 1,357 materials assigned, and **130
`SkeletalMeshActor`s placed**, a sample of 15 checked directly all carrying a real mesh with a
non-zero bone count (3–21 bones). `AggressorBabyJane`'s own rig export independently carries 457
animations, matching this document's own previously-recorded figure for that rig exactly.

**Still open for Phase 1 (assets):** no `TextureCube` assembly (face order UNKNOWN). Cubemap
probes as `SphereReflectionCapture` plus face `Texture2D`s **looked at in a live UE5.7 run,
25 Aug 2026** — `1-Medical`, 29 captures at manifest locations, 174 64×64 faces, 0 cubes,
`Success - 0 error(s), 0 warning(s)`. Influence radius still the engine default. A UE5 material
*graph* for level geometry — animator, sequence, and switch-candidate values now copy onto the
level manifest (25 Aug 2026) but must not drive a panner node, timeline, or switch-selection rule
until those mappings are known; an app-facing
"export to UE5" workflow — see the next entry.

**Lighting photometric mapping, live UE5.7 25 Aug 2026.** The previous `brightness * 1000` under
inverse-square was the uncalibrated guess. BioShock's `LightBrightness` is a 0–4 scale (Medical
median 0.8) and `LightRadius` is world centimetres. UE5's own `PointLightComponent`: when
inverse-square is off, intensity *is* a brightness scale. Mapping: intensity = authored
brightness (missing → 1.0, the measured median), attenuation radius = authored radius, inverse
square off, unitless. Lights with no radius are not spawned. Verified on `1-Medical`: **664
PointLights, 28 dropped, 0 errors.** `LightFalloffExponent` remains UE5's default 8 (`UNKNOWN`
vs the game). This is not a claim that the level looks like BioShock — static look is still
lightmaps.

### Phase 0 vertical slice, asset half — done and saved to disk, 26 Aug 2026

**One level, one enemy archetype, one weapon, in one pass, into a level that still exists when the
editor closes.** `tools/ue5/verify_vertical_slice.py` (+ `run_vertical_slice.py`); recipe and full
figures in `tools/ue5/README.md`.

**The gap this closes is smaller than it sounds and worth naming exactly.** Every UE5 verification
before this — geometry, materials, characters, cubemaps, lights — ran in a live editor session and
was measured from actors held in memory by the same script that had just spawned them. Nothing had
ever been written to a `.umap` and read back, so "the pipeline produces a UE5 level" was an
inference from an import report. It now isn't: `Content/BioShockSlice/1-Medical.umap` is 14 MB on
disk, and the checks run against the level *reloaded from it*, after the editor has demonstrably
left it (asserted, not assumed — a `new_level` that quietly failed would otherwise make the reload
prove itself).

**`1-Medical`, live UE5.7, 22m03s, `Success - 0 error(s)`, commandlet exit 0.** The census is
identical before the save and after the reload — 5,312 `StaticMeshActor`, 664 `PointLight`, 29
`SphereReflectionCapture`, 12 `SkeletalMeshActor`, 2,075 `TargetPoint`, of which 8,090 carry a
`BioShockKey` tag — and the ceiling-arch handedness canary, measured off the reloaded actors,
returns **2422.0** units against `LevelSceneTests`'s own reference for an assembled arch (mirrored
is ~4295). Sampled characters reload carrying a real 97-bone mesh, so a surviving actor with a
dangling mesh reference could not pass as a placed one.

**Two real findings, both from running it rather than reading it.**

- **The rig path had no skip-on-exists.** `import_bioshock.main` re-normalized every animation
  through Blender and re-imported it on each run — it reported "updated", but did the whole job.
  `AggressorBabyJane`'s 457 animations were 20 of the 22 minutes above, and `1-Medical` places 32
  distinct rigs, which is why the first (unfiltered) attempt was still importing characters two
  hours in. `import_level.main` now takes `rig_names`; the slice defaults to the one archetype
  Phase 0 actually asks for, and the report records which rigs were requested so a narrowed run
  cannot be misread as a whole-level one. Every other skeletal asset falls back to a bind-pose
  static mesh — the existing behaviour for a rig that fails to import, not a new compromise.
  **Skip-on-exists landed the same day** (next entry): a skip that silently keeps a stale asset is
  the failure mode, so it was verified by tampering, not by timing a second run.
- **Cheap preconditions must run before expensive work.** The first narrowed run spent 24 minutes
  importing the level and then died on the weapon, because `Exports\TommyGun` predated manifest
  texture intent and `import_bioshock` refused it — correctly. The weapon is now imported first.

**What this is not.** Not playable, and not a look: there is no gameplay layer, lighting is unbuilt,
level material *graphs* and `TextureCube` assembly remain `UNKNOWN`, and 31 of 32 rigs were
deliberately not imported. It is an asset round trip that now survives the editor closing.

### Rig importer skip-on-exists — done, 26 Aug 2026

The slice's 22 minutes were 20 minutes of re-normalizing `AggressorBabyJane`'s 457 animations on a
path that already reported "updated". Skip is now a fingerprint of the *export on disk* (inventory
plus source file size+mtime) stamped on the skeletal mesh after a complete import. A later run
reuses only when that stamp matches **and** every animation and texture is still present. A missing
stamp, a mismatch, or a hole in the inventory is a full re-import. Inventory-only matching is
deliberately not used — that is how a stale mesh with the same names would be kept.

**Proven able to fail, live UE5.7, TommyGun export, `run_import_skip.py`, `Success - 0 error(s)`.**
First import 37s / 0 reused; second **0.16s / 2 reused**; breaking the stamp on one rig re-imported
that rig only (1 reused, 26s); deleting `EmptyFidgetTommygun` did the same and the animation was
restored. Unstamped assets from before this change still pay once, then stamp. `BIOSHOCK_FORCE_IMPORT=1`
turns skip off.

### Phase 3 runtime skeleton, first slice — done, 26 Aug 2026

The class tree now exists as a **runtime** plugin (`tools/ue5/BioShockRuntime`), compiled and loaded
in UE5.7: `AShockPawn`, `AShockPlayer`, `ABaseShockAI` (the UnrealScript name; the plan's "ShockAI"
is this class), `AShockWeapon` (`Weapon` in script), `UShockAction` (parameter block, no Execute),
`AShockGameMode` (default pawn is `AShockPlayer`).

Numbers come from Phase 2.1 schema JSON, not from this header file. Live verify
(`run_runtime_skeleton.py`, `Success - 0 error(s)`): `ShockPlayer` radius **34**, `GroundSpeed`
**450**, `JumpZ` **525**, `BaseEyeHeight` **60**, `Health`/`MaxHealth` **200**, matching
`ShockGame.U`. Standing `CollisionHeight` is **68**, declared on `VPawn` in
`VengeanceShared.U` (`ClassDefaultsInheritanceTests`) — not Engine.U `Pawn`'s 78, which the
same-package walk cannot see. Live UE5.7 re-verify the same day: capsule half-height **68**,
`Success - 0 error(s)`. Walk speed is the canary: UE's Character default is 600.

**What this is not.** Not a weapon that fires. Phase 4 starts at `ActionWait` (first slice done
same day — see below). The plugin is built with `RunUAT BuildPlugin` and its Binaries live in the
UE project, not this repo.

### Phase 0 Medical possess setup — done, 26 Aug 2026

Saved `1-Medical.umap` now carries `ShockGameMode` and a `PlayerStart` at MedicalStart
(`run_possess.py`, `Success - 0 error(s)`). Schema-applied `ShockPlayer` piloted in the editor
world (radius 34, half-height 68, walk 450). Editor `PlayerController.Possess` AVs headless —
not claimed; PIE possess is still a human Play check.

### Phase 4 ActionWait first slice — done, 26 Aug 2026

`UShockActionWait` mirrors Scripting.U: `Seconds` from schema (default **1**), wake check matching
decompiled `latentExecute` (`TimeSeconds + Seconds`). Live verify `run_action_wait.py`,
`Success - 0 error(s)`. Not wired into a script graph; no `Sleep` on a ticking world. Next census
item is `ActionSetProperty`.

### Phase 4 ActionSetProperty first slice — done, 26 Aug 2026

`UShockActionSetProperty`: Object/Property/NewValue params; `ApplyToActor` writes **Label** only
(editor). Unknown properties refused. Live `run_action_set_property.py`, `Success - 0 error(s)`.
Not a full `SetPropertyText` port; no actor-label lookup loop yet.

### Phase 4 ActionIf first slice — done, 26 Aug 2026

`UShockActionIf` + `UShockTruthStatement`: OR of bool tests, choose true/else branch. Live
`run_action_if.py`, `Success - 0 error(s)`. Does not yet run nested actions on a script VM. Next
census item: `ActionPlayEffect`.

### Phase 4 ActionPlayEffect first slice — done, 26 Aug 2026

`UShockActionPlayEffect`: EffectEvent default ScriptTrigger from schema; `FireOnActor` records the
TriggerEffectEvent call. Live `run_action_play_effect.py`, `Success - 0 error(s)`. No FX
configurator yet. Next census: `ActionNonBlockingExecuteScript`.

### Phase 4 ActionNonBlockingExecuteScript first slice — done, 26 Aug 2026

`UShockActionExecuteScript` + `UShockActionNonBlockingExecuteScript`: `targetScript` / `block`
(default false); `RequestExecute` records the script that would start. Live
`run_action_nonblocking_script.py`, `Success - 0 error(s)`. No Script VM / label lookup yet. Next
census: `ActionSetLightProperties`.

### Phase 4 ActionSetLightProperties first slice — done, 26 Aug 2026

`UShockActionSetLightProperties`: Object label + ChangeProperty brightness/colour; `ApplyToActor`
writes intensity (LightBrightness scale) and light colour on the first `ULightComponent`. Live
`run_action_set_light.py`, `Success - 0 error(s)`. LightType / period / phase / shadow flags still
open; decompiled `LightBrightnessProperty` lists no value field (float inferred from Engine.Light
+ level import). Next census: `ActionVariableAssignIfNotExist`.

### Phase 4 ActionVariableAssignIfNotExist first slice — done, 26 Aug 2026

`UShockVariableScope` + `UShockActionVariableAssignIfNotExist`: lhs/rhs; create-only write into an
in-memory string map (`bOnlyIfMissing`). Live `run_action_var_assign_if.py`,
`Success - 0 error(s)`. No typed VariableFloat/Bool classes, no dotted lhs, no bestVariableClass.
Next census: `ActionVariableAssign`.

### Phase 4 ActionVariableAssign first slice — done, 26 Aug 2026

`UShockActionVariableAssignOverwrite` (`ActionClassName` ActionVariableAssign): overwrite lhs in
`UShockVariableScope`. Live `run_action_var_assign.py`, `Success - 0 error(s)`. Next census:
`ActionHideOrShowActor`.

### Phase 4 ActionHideOrShowActor first slice — done, 26 Aug 2026

`UShockActionHideOrShowActor`: ActorLabel + HideActor (schema default true);
`ApplyToActor` → `SetActorHiddenInGame` (+ editor temp hide). Live `run_action_hide_show.py`,
`Success - 0 error(s)`. Label foreach still open. Next census: `ActionSpawnAI`.

### Phase 4 ActionSpawnAI first slice — done, 26 Aug 2026

`UShockActionSpawnAI` (ShockAI.U): params + `RequestSpawn` records AI type / location label.
Schema applies `bCorpseCanBeRemoved=true`. Live `run_action_spawn_ai.py`,
`Success - 0 error(s)`. No SpawningManager / pawn spawn yet. Next census: `ActionStopEffect`.

### Phase 4 ActionStopEffect first slice — done, 26 Aug 2026

`UShockActionStopEffect`: EffectEvent default ScriptTrigger; `StopOnActor` records UnTrigger
intent. Live `run_action_stop_effect.py`, `Success - 0 error(s)`. No FX tear-down. Next census:
`ActionPlayAnimation`.

### Phase 4 ActionPlayAnimation first slice — done, 26 Aug 2026

`UShockActionPlayAnimation` (ShockGame.U): TargetLabel / Animation / AnimationRate=1 /
bOnlyPlayOnAlivePawns=true from schema; `PlayOnActor` records intent. Live
`run_action_play_anim.py`, `Success - 0 error(s)`. No mesh channel playback / wait. Next:
`ActionScriptNote`.

### Phase 4 ActionScriptNote first slice — done, 26 Aug 2026

`UShockActionScriptNote`: holds `Note` string; runtime no-op (`EvaluateBool` false). Live
`run_action_script_note.py`. Next: `ActionDestroyActor`.

### Phase 4 ActionDestroyActor first slice — done, 26 Aug 2026

`UShockActionDestroyActor`: `DestroyTarget` calls `Destroy()` on a passed actor. Label foreach /
NotifyKilled open. Live `run_action_destroy.py`. Next census: `ActionAttackTarget`.

### Phase 4 ActionAttackTarget first slice — done, 26 Aug 2026

`UShockActionAttackTarget` (ShockAI.U): AILabel / TargetLabel / bAttackOnSight;
`RequestAttack` records the order. Live `run_action_attack.py`, `Success - 0 error(s)`.
No ScriptedAttackTarget / label foreach. Next: `ActionGiveItemsToPlayer`.

### Phase 4 ActionGiveItemsToPlayer first slice — done, 26 Aug 2026

`UShockActionShockInventory` + `UShockActionGiveItemsToPlayer`: ItemClass / StackSize (default 1);
`RequestGive` records the grant. Live `run_action_give_items.py`, `Success - 0 error(s)`.
No inventory / ItemStack. Next: `ActionChangeCollision`.

### Phase 4 ActionChangeCollision first slice — done, 26 Aug 2026

`UShockActionChangeCollision`: CollisionChangeType defaults DoNotChange (2);
`CollideActors` → `SetActorEnableCollision`. Live `run_action_change_collision.py`,
`Success - 0 error(s)`. Other flags held; label foreach open. Next: `ActionTweakAIVision`.

### Phase 4 ActionTweakAIVision / ActionTweakAIHearing first slices — done, 26 Aug 2026

`UShockActionTweakAIVision` / `UShockActionTweakAIHearing`: label + on/off flags;
`RequestTweak` records. Live verifies `Success - 0 error(s)`. No sense wiring. Next:
`ActionBlockingExecuteScript`.

### Phase 4 census #20–batch (Blocking / Increment / Log / Exit / Freeze / Unlock) — done, 26 Aug 2026

One-build batch, live `run_action_batch_census.py`, `Success - 0 error(s)`:
`ActionBlockingExecuteScript` (block=true), `ActionVariableIncrement`, `ActionLog`,
`ActionExitScript`, `ActionFreezeHavokActor` (SetSimulatePhysics), `ActionUnlockDoor`.
Next: `ActionPostMovementGoal`.

### Phase 4 census batch2 (MuteAI / SetTipPriority / PostMovementGoal) — done, 26 Aug 2026

Live `run_action_batch2.py`, `Success - 0 error(s)`. Goal stack / tip manager / MuteAI
native still open. Next: keep walking the census head.

### Phase 4 census batch3 (FadeView / Concept / ScriptedSequence / DealDamage) — done, 26 Aug 2026

Live `run_action_batch3.py`, `Success - 0 error(s)`. Fade / concept / sequence / damage
are request-record slices (no real camera fade, tip concepts, sequence runner, or combat).
Next: keep walking the census head.

### Phase 4 census batch4 (WaitForGoal / ChangeSkin / OpenDoor / AISpeech) — done, 26 Aug 2026

Live `run_action_batch4.py`, `Success - 0 error(s)`. Goal wait / SetSkin / door open /
speech are request-record slices. Next: keep walking the census head.

### Phase 4 census batch5 (AssertFact / Loop / Teleport / InputContext) — done, 26 Aug 2026

Live `run_action_batch5.py`, `Success - 0 error(s)`. Facts DB / loop VM / teleport /
input stack still open. Next: keep walking the census head.

### Phase 4 census batch6 (SpawnZone / Quest / Spotlight / Pressure) — done, 26 Aug 2026

Live `run_action_batch6.py`, `Success - 0 error(s)`. SpawningManager / quests /
spotlight tracking / pressure regions still open. DesiredPressure kept as uint8 until
Engine.U `EPressureLevel` is pinned. Next: keep walking the census head.

### Phase 4 census batch7 (QuestLogWait / SpotlightState / CloseDoor / ToggleReactions) — done, 26 Aug 2026

Live `run_action_batch7.py`, `Success - 0 error(s)`. Audio wait / door close /
reaction wiring still open. Next: keep walking the census head.

### Phase 4 census batch8 (Trigger / DebugMsg / Invincibility / Console) — done, 26 Aug 2026

Live `run_action_batch8.py`, `Success - 0 error(s)`. MessageTrigger / ClientMessage /
god mode / ConsoleCommand still open (console command is recorded, not executed).
Next: keep walking the census head.

### Phase 4 census batch9 (Patrol / PawnPhysics / PawnInvinc / LOD) — done, 26 Aug 2026

Live `run_action_batch9.py`, `Success - 0 error(s)`. Patrol / Physics /
pawn invincibility / LOD override still open. Next: keep walking the census head.

### Phase 4 census batch10 (Reactive / VitaChamber / LockDoor / Training) — done, 26 Aug 2026

Live `run_action_batch10.py`, `Success - 0 error(s)`. Spawn / station / lock /
training UI still open. Next: keep walking the census head.

### Phase 4 census batch11 (CompleteQuest / RemoveGoal / ToggleAttack / SetLabel) — done, 26 Aug 2026

Live `run_action_batch11.py`, `Success - 0 error(s)`. Quests / goals / attack
toggle still open; SetActorLabel applies editor SetActorLabel. Next: keep walking
the census head.

### Phase 4 census batch12 (FadeVolume / InitiateDamage / HavokForce / QuestArrow) — done, 26 Aug 2026

Live `run_action_batch12.py`, `Success - 0 error(s)`. Audio fade / damage /
Havok force / quest arrow still open. Next: keep walking the census head.

### Phase 4 census batch13 (LevelSaving / RetractFact / Vulnerability / Decrement) — done, 26 Aug 2026

Live `run_action_batch13.py`, `Success - 0 error(s)`. Save gate / facts DB /
AI vulnerability still open; VariableDecrement applies to scope. Next: keep walking
the census head.

### App-facing "export to UE5" workflow — deliberately not started

Per §5 Phase 1 and §8: only add this once the command-line import reproduces cleanly on a fresh UE5
project, not sooner. **Precondition tested 23 Aug 2026 and it is *nearly* met, with one documented
caveat.** A rig import into a genuinely fresh project succeeds for meshes, skeletons, animations and
textures, but **fails at socket restoration**: `BioShockImportTools` is a **C++** plugin, so copying
the folder in (as `tools/ue5/README.md` step 1 said) does not make `unreal.BioShockSocketLibrary`
exist. The project must either be a C++ project, or receive prebuilt binaries. README corrected.

**This item is a product decision, not a decode**, and stays unstarted pending a call on whether the
app should carry this workflow at all.
