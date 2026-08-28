"""Pure level-import policy helpers — no Unreal dependency, safe to unit-test outside the editor."""

# BioShock corpse actors carry a skeletal mesh in a ragdoll pose (`PoseRagdollState=1` on
# DeadBodyContainer). They must not fall back to the bind-pose static mesh the level also exports.
DEAD_BODY_ACTOR_CLASSES = (
    "DeadBodyContainer",
    "KeyframedDeadBodyContainer",
    "CorpseMaleBooty",
)

# Loot/booty actors that display a corpse mesh but are not ragdolled physics props.
_CORPSE_BOOTY_SUFFIX = "Booty"


def is_dead_body_actor(class_name):
    if not class_name:
        return False
    return any(
        class_name == name or class_name.endswith(name)
        for name in DEAD_BODY_ACTOR_CLASSES
    )


def uses_corpse_physics(class_name):
    """Whether a placed corpse should simulate physics (ragdoll containers, not loot booties)."""
    if not class_name or class_name.endswith(_CORPSE_BOOTY_SUFFIX):
        return False
    return any(
        class_name == name or class_name.endswith(name)
        for name in ("DeadBodyContainer", "KeyframedDeadBodyContainer")
    )


def requires_skeletal_rig(actor_class, asset_name):
    """Whether an instance must be a SkeletalMeshActor, never a bind-pose static mesh."""
    if asset_name and asset_name.startswith("Corpse"):
        return True
    return is_dead_body_actor(actor_class)


def dead_body_mesh_names(manifest):
    """Skeletal mesh object names every placed corpse needs a rig import for."""
    names = set()
    assets = {entry["key"]: entry for entry in manifest.get("assets") or []}
    for actor in manifest.get("actors") or []:
        class_name = actor.get("className") or ""
        mesh = actor.get("skeletalMesh")
        if mesh and (is_dead_body_actor(class_name) or uses_corpse_physics(class_name)):
            names.add(mesh)
    for instance in manifest.get("instances") or []:
        asset = assets.get(instance.get("asset"), {})
        name = asset.get("name") or ""
        actor_class = next(
            (a.get("className") or "" for a in manifest.get("actors") or []
             if a.get("key") == instance.get("actorKey")), "")
        if requires_skeletal_rig(actor_class, name):
            names.add(name)
    for asset in manifest.get("assets") or []:
        name = asset.get("name") or ""
        if name.startswith("Corpse"):
            names.add(name)
    return names


def effective_rig_names(manifest, rig_names):
    """Union explicit rig filter with every corpse mesh the level places."""
    required = dead_body_mesh_names(manifest)
    if not required:
        return rig_names
    if rig_names is None:
        return None
    return set(rig_names) | required
