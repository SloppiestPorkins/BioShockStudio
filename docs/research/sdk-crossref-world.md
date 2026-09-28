# SDK cross-reference — world / mapping / assets (chs. 06–19, 33–36)

Cross-check of the BioShock SDK user guide (chapters listed below) against this worktree’s
extractor, UE5 importers, and runtime. Guide text was read in full; only facts (fields, numbers,
class relationships, behaviours) are recorded here — no guide prose. Already-fixed session items
and the known-open list from the task brief are not re-reported.

**Counts:** **BUG 7** · **GAP 18** · **OK 14** · **UNKNOWN 5** · **N/A (editor how-to only) 6**

Verdict: the largest player-visible mismatches are lighting shape/falloff (we discard spotlight
and animation data and leave UE5’s steep default falloff), player capsule height vs the kit
module, and cascading water (decoded `WaterMesh1` unused; script action invents a material
toggle the guide reports as a no-op). Materials/BSP/doors/water-overlap for Electro Bolt mostly
match at the presence level; zone ambient, caustics, FXClass emitters, and UCC tooling are
absent by design of this port.

Guide chapters: 06 Mapping Guidelines · 07 BSP · 08 Zones/Portals · 09 Actors · 10 Static Meshes ·
11 Skeletal Meshes · 12 Doors (stub) · 13 Materials · 14 Lighting · 15 Water · 16 Sound (stub) ·
17 VFX · 18 Build/Bake · 19 Retail Maps · 33 UCC Packages · 34 UCC Import · 35 Commandlets ·
36 Troubleshooting.

---

## BUG

| id | what the guide says (own words) | guide ref | our code | what we do instead | proposed fix | effort |
| --- | --- | --- | --- | --- | --- | --- |
| W-BUG-01 | Light shape is selected by `LightEffect` (`LE_Pointlight` / `LE_Spotlight` / `LE_Sunlight` / `LE_Directionallight`). Spotlights use actor rotation and `LightCone`; cone half-angle satisfies `cos(θ)=1−LightCone/255`. | ch.14 Lighting category / Light effects / Spot cone | **FIXED (importer + export schema).** `import_level._import_lights` branches on `_UE2_LIGHT_EFFECT_TO_SHAPE`; spots get `SpotLight` + `OuterConeAngle` from the guide cosine formula; sun/directional get `DirectionalLight` (no attenuation). `LevelLight` / `LevelLightDocument` now carry the actor's raw UE2 `rotation` triple (same shape as `LevelActorDocument.Rotation`). Re-export of Medical still needed for `lights[].rotation` on disk; importer falls back to `actors[]` by key until then. | Was: every light → omnidirectional `PointLight`. | — | M |
| W-BUG-02 | Point/spot/directional falloff is `(1−saturate(d²/R²))²` (half strength near mid-radius). | ch.14 Falloff | `import_level.py:191–197` disables inverse-square and does **not** set `light_falloff_exponent`. UE5 default exponent is **8**. `repair_level_lighting.py:34–42,108` later forces exponent **2** and multiplies intensity — still `pow(1−d/R,e)`, not the guide’s squared-distance curve. | Raw import: hot bulbs, black walls. After optional repair: softer but still not BioShock’s curve; brightness also scaled by invented factors. | Set falloff at import to match guide curve (custom attenuation or calibrated exponent+docs); stop relying on a separate brightness-multiply repair. | L |
| W-BUG-03 | Animated `LightType` (`LT_Flicker`, `LT_SubtlePulse`, `LT_Pulse`, …) scales live colour; bake is unchanged. `LightPeriod` / `LightPhase` set the cycle. | ch.14 Light types | Fields decoded (`LevelLight.cs:57–80`) and exported (`LevelSceneExporter.cs:560–563`); `import_level.py` never applies type/period to the UE5 component. | Flicker/neon/damaged fixtures stay steady. | Drive intensity (or a material) from type+period+phase at runtime; keep bake/static path separate. | M |
| W-BUG-04 | Player collision cylinder is **136** tall, **68** wide; crouch **80** tall. (`CollisionHeight` is half-height → 68 / 40.) | ch.06 The vertical module | `ShockPlayer.cpp:135–141,154`: radius **34** (matches half of 68), crouch half-height **40** (matches), standing half-height deliberately set to **88** (176 tall) with a comment rejecting 68. Schema still documents VPawn `CollisionHeight=68` (`ShockPawn.h:11–12`). | Player stands taller than kit door/module sizes; snags and eye height vs retail proportions differ. | Restore half-height 68 from schema/defaults; retune eye height / step if needed — do not invent UE mannequin height. | S |
| W-BUG-05 | Falling water needs mesh + puddle + splash emitter + `CascadingWaterVolume` with `WaterMesh_1` and `WaterSplashEffect`. The script action that enables/disables a cascading volume **appears to have no effect** in the game. | ch.15 Place falling water / CascadingWaterVolume properties; note on enable/disable action | `WaterMesh1` decoded (`LevelAnalyzer.cs:808–837`) and exported (`LevelSceneExporter.cs:266–267`). Import only flips `bCascading` for a stand-in material (`import_level.py:795–801`, `ShockWaterVolume.cpp:83–115`). `ShockActionEnableOrDisableCascadingWaterVolume.cpp:28–37` sets `bCascading` and refreshes the surface MI. | Cascades look like flat top-plane water; splash/mesh links ignored. Scripts that “enable cascading” change our MI — behaviour the guide says the original action does not have. | Wire `WaterMesh` / splash refs; spawn or link emitters; make the action a no-op (or match real engine once verified), not a material toggle. | L |
| W-BUG-06 | `MaskMaterial` has `Material` + `Channel` (`MC_A` / `MC_R` / `MC_G` / `MC_B`). Specular/gloss often share one packed map via different channels. Cutouts use Opacity + `MC_A` with `Masked`. | ch.13 Mask properties / Blending | `MaskChannel` is read (`MaterialReader.cs:21–27,827–835`) but material export still treats channel selection as unsafe / unused (`MaterialExporter.cs:190–228`). Importer hard-wires OpacityMask to **R** (`import_bioshock.py:678–697`) and translucent Opacity to **A** (`:576,788`). | Wrong channel → wrong cutouts/spec; packed maps mis-sampled. Opaque panels previously broken by treating packed Opacity as R-cutout (partially mitigated by filtering, not by honouring Channel). | Export `maskChannel`; sample the selected channel in masters; only then widen Opacity export. | M |
| W-BUG-07 | Zone ambient is a two-colour gradient (`NormalPressureAmbientColorHigh` × multiplier, often **40**, contrast power **2**, XGroundRatio **0.15`). It is the fill light; bake has no bounce. Missing ZoneInfo ⇒ black ambient. | ch.08 ZoneLight ambient; ch.06 Ambient and fog presets; ch.14 Ambient light | Analyzer reads ambient fields (`LevelAnalyzer.cs:33–40,567–568,721–723`). UE5 path uses global SkyLight / slice `ExponentialHeightFog` + post (`repair_level_lighting.py`, `repair_slice_look.py`) — not per-zone two-colour ambient ×40. | Rooms that retail fills with teal ambient stay dark or get a uniform invented sky ambient; district fog presets are not applied per zone. | Author per-zone ambient (or a ShockZoneInfo proxy) from exported ZoneLight; apply high/low blend in materials or a world subsystem. | L |

---

## GAP

| id | what the guide says (own words) | guide ref | our code | proposed fix | effort |
| --- | --- | --- | --- | --- | --- |
| W-GAP-01 | `NeverCollide` on the mesh asset forces no collision regardless of actor Collision flags (beams, blood, glass dust, water spews, etc.). | ch.10 NeverCollide | Property exists on shipped meshes (`StaticMeshPropertyTests.cs:83`); not decoded into export/import. Decals use name heuristics (`verify_decal_collision.py:34–47`). | Decode `NeverCollide` on StaticMesh; force NoCollision on instances. | S |
| W-GAP-02 | Actor `Skins[]` overrides mesh section materials. | ch.09 Display; ch.10 / ch.13 Apply materials to static mesh | No Skins export/import found under `LevelSceneExporter` / `import_level`. | Export Skins; apply as material overrides on instances. | M |
| W-GAP-03 | `MaxLightsStatic` (default 3) and `SpecialLitChannel` gate which baked lights hit a mesh; BSP Special Lit flag differs. | ch.14 MaxLightsStatic / Special lit channels | Not carried into UE5 lighting (dynamic PointLights, no channel filter). | Either approximate with lighting channels / per-actor max, or document permanent divergence from Lightmass. | L |
| W-GAP-04 | CubemapProbe bake: 64×64 faces, leaf→probe assignment via zone portals; materials need specular cubemap thresholds. | ch.13 Cubemaps | Faces imported as loose Texture2D; no TextureCube assembly (`import_level.py:206–267`). | Assemble cubes; assign reflections; or keep UNKNOWN and skip. | L |
| W-GAP-05 | Caustic_Projector defaults (`Gen_Water.CausticCheap_Shader`, MaxTraceDistance 250, DrawScale 2, Tile 3,3). | ch.15 Caustics | No caustic projector import/runtime. | Projector or deferred decal stand-in from FXClass placements. | M |
| W-GAP-06 | FluidVolume wave / friction / entry-exit sounds and effects; buoyancy and shocked-water defaults. | ch.15 FluidVolume properties | `ShockWaterVolume` = overlap + plane (`ShockWaterVolume.h`); no Wave/FluidFriction/EntrySound. Electro Bolt water chain uses overlap only (`ShockElectroBoltPlasmid.cpp:73+`). | Port needed PhysicsVolume fields; keep EB chain. | M |
| W-GAP-07 | Retail FXClass emitters (BubblesA, BrineOmni, MistLow, Fire_*, Sparks*, decal projectors Grime/Gore, …). | ch.17 Which effect to place / Decals | Effects subsystem for gameplay events exists; map-placed Emitter classes from FXClass are not a first-class import path (see also `docs/research/effects.md`). | Place/proxy high-count classes from manifest. | L |
| W-GAP-08 | Zone distance fog (`bDistanceFog`, DistanceFogStart/End/Color) and pressure fog sets; sky Fake Backdrop. | ch.08 Fog; ch.06 Ambient and fog presets | Fog fields read in analyzer; UE5 uses one ExponentialHeightFog (`repair_slice_look.py`). FakeBackdrop surfaces flagged in BSP (`BspWorld.cs:26`) but not wired as sky pass. | Per-zone fog volumes; skybox from SkyZoneInfo. | L |
| W-GAP-09 | Pressure-system ambient/light High/Low sets and DramaticLightingScale. | ch.08 ZoneLightPressure; ch.14 Pressure category | Pressure regions decoded; no zone ambient swap from pressure for lighting look. | Hook pressure change to ambient/fog. | M |
| W-GAP-10 | FluidShader / FluidSurfaceShader / PondScumFluidShader / LightBeamShader / WindowShader / CausticShader specialised inputs. | ch.13 material class tree; ch.15 Water materials | Generic Shader→MI path + authored `M_ShockWater` stand-in (`docs/research/water.md`). | Class-specific masters where fidelity demands. | L |
| W-GAP-11 | God-ray / neon recipes (Light_Beams NeverCollide, Neon_System Skins + flicker light). | ch.06 Lighting conventions / Using the kit | Beam repair scripts exist as look stand-ins; not full NeverCollide+Skins+LT_Flicker recipe. | Combine W-BUG-01/03 + W-GAP-01/02. | M |
| W-GAP-12 | BlockingVolume / PathBlockingVolume / PhysicsVolume damage & class blockers. | ch.08 Volumes | Import maps many volumes; PathBlocking / class-limited blockers not fully featured. | Audit volume class matrix vs runtime. | M |
| W-GAP-13 | Sound: AmbientSound Tag→sound, zone ReverbType; music/voice not in editor. | ch.16 stub + note | Ambient audio import path exists (`import_audio.py`); zone reverb / Tag semantics incomplete vs guide note. | Finish ambient Tag + zone reverb; leave music to game tests. | M |
| W-GAP-14 | Door chapter still stub; gameplay door/keypad/power systems. | ch.12 entire | `AShockDoor` + script Open/Close/Lock (`ShockDoor.h`) — slice approximation, not full Doors.pkg matrix. | Expand when ch.12 exists; track power/keypad separately. | L |
| W-GAP-15 | Static lighting bake model (no radiosity; 8-bit reach; sunlight vs Fake Backdrop; movers unshadowed). | ch.14 The static bake / Visibility | UE5 movable lights + Lightmass — different model by construction. | Accept as engine divergence; use dynamic approximation checklist. | — |
| W-GAP-16 | Retail bake/deploy, bulk catalog level-name rule, Play Map, UCC make/`#exec`, commandlets, SDK Manager. | ch.18–19, 33–36 | We extract from cooked `.bsm` + BulkContent; we do not run BioShock editor/UCC. | N/A for this port; keep for anyone using the SDK side-by-side. | — |
| W-GAP-17 | CollisionHeight meaning (half-height) and kit module sizes for new maps. | ch.06; ch.09 Collision | Documented in schema comments; UE5 player ctor disagrees (W-BUG-04). | Fix bug; document kit sizes for props. | S |
| W-GAP-18 | Light beam / cutout materials must not block baked light. | ch.10 Lighting on static meshes; ch.14 Visibility | No `LightBeamShader` / Opacity→shadow caster rule in import. | Disable shadow cast on those material classes. | S |

---

## OK

- Light brightness/radius/colour types are floats + RGB (not stock UE2 bytes) — matches guide’s BioShock lighting fields; carried in `LevelLight` / import intensity+attenuation (`import_level.py:188–203`). Guide: ch.14 LightBrightness / LightRadius.
- Player capsule **radius 34** and crouch half-height **40** match 68-wide / 80-tall crouch. Guide: ch.06 vertical module. Code: `ShockPlayer.cpp:140,154`.
- BSP FakeBackdrop / Portal / Invisible flags decoded (`BspWorld.cs`). Guide: ch.07 Flags tab; ch.08 sky.
- ZoneInfo / SkyZoneInfo / FluidVolume / CascadingWaterVolume actors identified and water volumes become overlap volumes. Guide: ch.08–15. Code: `import_level.py` water class set + `ShockWaterVolume`.
- Electro Bolt respects water overlap via `IsActorInWater`. Guide: ch.15 body of water needs FluidVolume. Code: `ShockElectroBoltPlasmid.cpp`.
- Cascading volume exports `WaterMesh1` / Axis (data present even if unwired). Guide: ch.15. Code: `LevelAnalyzer` RegionActor.
- Shader slots Diffuse/NormalMap/Specular/Opacity/Emissive/OutputBlending/TwoSided/Masked read. Guide: ch.13 Shader properties. Code: `MaterialReader` / `materials.md`.
- MaterialVisualType enum values used for footstep/impact routing. Guide: ch.13 Material base properties. Code: audio/impact paths.
- Static mesh section materials and DrawScale × DrawScale3D applied on place (`import_level.py:126–128`). Guide: ch.09–10 scale fields.
- Door actors import to `AShockDoor` with lock/open/close. Guide: ch.12 points at classes; ch.09 Door package note.
- Cubemap face pixels recoverable from packages. Guide: ch.13 cubemap storage size. Code: face import path.
- Lightmaps / LightMapScale present on BSP surfaces. Guide: ch.07 Light map scale. Code: `BspWorld` / polys.
- Havok / simple collision intent properties exist on meshes (census). Guide: ch.10 Collision in the game. Code: `StaticMeshPropertyTests`.
- Troubleshooting symptoms (blank bulk textures, missing collision proxy crash, MaxLightsStatic black mesh, level-name texture miss) match issues we have hit in fidelity notes — causes align even though we are not the SDK editor. Guide: ch.36.

---

## UNKNOWN

| id | question | what would resolve it |
| --- | --- | --- |
| W-UNK-01 | Exact BioShock `LightEffect` ordinal ↔ shape names in `Engine.u` (importer uses a PLAUSIBLE map from Medical census + guide declaration order: absent/0/1=point, 2=spot, 3=sun, 4=directional). | Observe enum in BioShock editor or `Engine.u` export; confirm or correct `_UE2_LIGHT_EFFECT_TO_SHAPE`. |
| W-UNK-02 | Whether wall-sheet / spew mesh collision drives wet-screen (guide marks unverified). | In-game test with collision on/off. |
| W-UNK-03 | Whether ZoneFog read-only fields must be mirrored from ZoneLight for retail fog (guide note). | Compare ZoneInfo bytes vs in-game fog. |
| W-UNK-04 | Imported normal-map expected format (guide: not verified). | A/B in editor/game with one material. |
| W-UNK-05 | Full door/keypad/power behaviour (ch.12 unwritten; caution on custom maps). | Wait for ch.12 or decompile door classes + play tests. |

---

## Status (28 Sept)

| id | status | notes |
| --- | --- | --- |
| W-BUG-03 | FIXED | `import_level._apply_light_effect` maps the authored `type`/`period` onto y8's `UShockLightEffectComponent` (Pulse/Blink/Flicker/Strobe/SubtlePulse). Ordinal table taken from the community SDK's declared light-type order, which the census (0,2,3,4,5,7,9 seen in `1-Medical`) is consistent with. Explicit `LT_None` (type 0) now zeroes intensity — the guide's table calls that ordinal "off", not merely unanimated, so it was previously lighting rooms it shouldn't. `LT_BackdropLight`/both `TexturePalette*`/`LT_FadeOut` have no decoded waveform to drive and stay steady rather than guessed. `LightPhase` is still not exported — every animated light starts its cycle at 0. Verified against the real `1-Medical` census (`verify_light_import.py` via `run_light_look.py`), not synthetic data. |
| W-BUG-01 | FIXED (PLAUSIBLE ordinals; awaiting Medical re-export + headless verify) | Medical `lights[].effect` census: absent=514, `2`=175, `3`=6 (of 695); `cone` set on 232 (148 of the effect=2 set, 82 with effect absent, 2 of effect=3). Mapped `2→spot`, `3→sun`, absent/`0`/`1→point`, `4→directional` (not seen in Medical). Cone → `OuterConeAngle` via `cos(θ)=1−cone/255`. Rotation exported on `LevelLightDocument`; importer also joins `actors[].rotation` by key until Claude re-runs `export-level`. Verify: `tools/ue5/verify_light_shape.py` (Claude runs headless). W-UNK-01 still open for Engine.u confirmation. |
| W-BUG-02, W-BUG-05, W-BUG-06, W-BUG-07 | OPEN | Each needs either a level re-import + visual capture pass (mask channel) or new runtime systems (per-zone ambient, cascading water) — bigger than a self-contained fix; not attempted this pass. |
| W-BUG-04 | OPEN — deliberately not touched | Current 88uu (176cm) half-height has a reasoned comment (movement/weapon/viewmodel tuning all happened at this height); the schema's 68 is the shipped default but flipping it would invalidate a lot of already capture-verified work (melee reach, viewmodel offsets, camera FOV) without a human PIE pass to re-tune against. Needs the user's call, not a blind revert. |



## N/A (editor / SDK-tooling how-to; no runtime mismatch to score)

- **ch.07** brush builders, CSG UI, 2D shape editor, vertex clip modes — we consume cooked BSP, we do not author brushes.
- **ch.09** Actor Class browser, gizmo/Ctrl-drag, Group browser — editor UX only.
- **ch.18** Build menu, Bake dialog, Play Map, deploy to `Content\Maps` — SDK workflow; our pipeline is extract→UE5.
- **ch.19** opening/re-baking retail maps in BioShock editor — same.
- **ch.33–35** `ucc make`, `#exec` imports, BioDecookLibrary / BioFxExtract — SDK Manager territory; not this repo’s runtime.
- **ch.12 / ch.16** documents are stubs (pointers only).

---

## RESULT

Wrote `docs/research/sdk-crossref-world.md` only. No code, builds, Unreal, or commits.

Highest-impact follow-ups: **W-BUG-01/02/03** (light shape + falloff + flicker), **W-BUG-04** (player height 136), **W-BUG-05** (cascading water data + action semantics), **W-BUG-06** (mask Channel), **W-BUG-07** (zone ambient ×40).
