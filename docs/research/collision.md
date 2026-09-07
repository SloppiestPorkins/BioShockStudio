# Playable-slice collision policy

Status: **VERIFIED** for the source-manifest classification and the UE collision constraints;
runtime application must be re-measured after running the repair scripts.

## Exterior identification

`1-Medical.ue5-level.json` does not expose a trustworthy exterior flag. `Region.zoneNumber` is
visibility topology, not semantic ownership, and imported instance labels are generally
`StaticMeshActor<N>`. Spatial tests such as "outside every BlockingVolume" are unsafe because the
source map also uses volumes for gameplay partitions, not as a complete interior envelope.

The repair therefore uses an anchored, case-insensitive asset-name vocabulary:
`skybox`, `_Outside`, `exterior`, `cityscape`, `seabed`, `ocean`, `distant`, `kelp`, and `_ext_`.
Tokens must start/end at `_` or the asset boundary. This includes the measured Medical backdrop
families (`skybox_city`, both `Gen_Counter_90_*_Outside` variants, and the kelp assets) without
matching the interior `Gen_Counter_90`. This is a semantic rule, not an actor hand-list.

`fix_exterior_collision.py` sets matched components to `NO_COLLISION`; it does not alter their mesh
assets or mobility. This removes them from player, weapon, and AI traces while preserving rendering.

## Prop policy

Chaos only supports `CTF_USE_COMPLEX_AS_SIMPLE` as a usable simulation shape on Static components.
The slice intentionally keeps ordinary props Movable because it has no baked UE lightmaps; changing
all props to Static would make runtime lighting regress. The compiled `Model<N>_<N>` world shell is
the existing exception and is explicitly excluded from this pass.

Auto Convex was tested through UE5.7's commandlet API on `Long_Couch_4114` and the other measured
hollow classes. The API returned failure and produced zero replacement hulls both with CPU access
enabled and with `-AllowCommandletRendering`; it cannot be used as a reproducible headless setup
step for these Interchange-imported assets. The script therefore uses the h19-safe dual-mesh route
for classes where one hull is known to be materially wrong:

1. Backdrop, pickup, and flat surface-effect visuals (puddles, splats, carpets): `NO_COLLISION`.
2. Room-scale walk-through architecture and named hollow/concave families (cabinet, shelving,
   couch, sink, pipe, fridge, casket, wall-hole, and rubble-pile): keep the render actor Movable,
   disable its collision, and place an invisible Static complex-as-simple proxy at the same
   transform.
3. Props below 80 uu, meshes with at most 24 triangles, and semantically simple debris/containers:
   retain cheap simple collision.
4. Existing multi-convex assets are retained. Unclassified props retain their imported simple
   collision rather than being guessed into an expensive class.

This pays per-triangle query cost only for the bounded high-risk semantic families, not all 3,625
single-hull assets. The render component remains dynamically lit; the hidden proxy is the only
Static component. Proxy tags make creation and transform updates idempotent.

`verify_collision.py` checks this same boundary: every exterior/pickup component must be
non-colliding, each high-risk render actor must have a Static complex-as-simple proxy, and the
compiled-world shell retains its existing policy. Intentionally simple and unclassified props do
not create false alarms.

Confidence: **HIGH** for the Chaos/mobility constraint and manifest names; **MEDIUM** for the
semantic-family performance boundary until the generated Medical proxies are captured and walked
in interactive PIE.

## Encounter spawn correction

`AShockGameMode::PostLogin` previously created the three `SliceEnemy<N>` verification actors and
their test pickups for every player. They are now gated to `-bioshockverifypossess` or
`-bioshockverifyencounter`. The verify-only spawn traces down 3,200 uu, rejects slopes whose normal
Z is below 0.70, and uses a nearby Recast projection when one exists before creating the AI. A
missing walkable floor skips the spawn instead of using `AlwaysSpawn`; collision adjustment can
also reject an occupied result. Medical's runtime Recast request currently completes without a
projectable polygon at these offsets, so the verified fallback is the traced walkable floor rather
than reverting to the old unchecked airborne location.

The source manifest does contain 19 `AggressorSpawner` and 5 `TurretSpawner` actor records. The
current UE importer has an explicit `_import_turret_spawners` path but no corresponding
`AggressorSpawner` / `AISpawnPoint` placement path. Wiring those real script-driven spawns is a
follow-up; this pass only removes the accidental debug encounter from normal play.
