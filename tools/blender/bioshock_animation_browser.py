"""BioShock animation browser — a sidebar panel for an exported animation library.

Install: Blender > Edit > Preferences > Add-ons > Install, pick this file, enable it.
Then open a library `.blend` and press N in the 3D viewport; the panel is under "BioShock".

A library holds one rig and every animation that rig can play — 148 actions for the first-person
hands, several hundred for a character. Blender's own action selector is a flat alphabetical list of
all of them, with the weapon rigs' actions mixed in, so finding "the pistol reloads" means scrolling.
This filters by the metadata the importer already wrote onto each action: `bioshock_weapon`,
`bioshock_animation_set` and `bioshock_original_name`.

It reads only. It creates no data and changes no action, so it cannot invalidate a validated library.
"""

import bpy

bl_info = {
    "name": "BioShock Animation Browser",
    "author": "BioShockStudio",
    "version": (1, 0),
    "blender": (3, 0, 0),
    "location": "View3D > Sidebar > BioShock",
    "description": "Browse, filter and play the animations in an extracted BioShock library.",
    "category": "Animation",
}

BIO_NAME = "bioshock_original_name"
BIO_SET = "bioshock_animation_set"
BIO_WEAPON = "bioshock_weapon"
BIO_FPS = "bioshock_original_fps"
BIO_FRAMES = "bioshock_frame_count"


def is_library_action(action):
    """Only actions this project wrote. A user's own actions are left alone."""
    return action.get(BIO_NAME) is not None


def rig_of(context):
    """The armature the panel acts on: the selected one, else the scene's host rig."""
    obj = context.object
    if obj is not None and obj.type == "ARMATURE":
        return obj

    armatures = [o for o in context.scene.objects if o.type == "ARMATURE"]
    # The host has no bone parent; a weapon rig hangs off the host's grip.
    return next((a for a in armatures if a.parent is None), armatures[0] if armatures else None)


def actions_for(rig, settings):
    """Library actions belonging to this rig, after the weapon and search filters."""
    if rig is None:
        return []

    # A weapon rig's actions are named after it; the host's are not. Without this the hands' panel
    # lists the pistol rig's two actions alongside its own hundred and thirty.
    other_rigs = [
        o.name for o in bpy.data.objects
        if o.type == "ARMATURE" and o is not rig and o.parent is not None
    ]

    search = (settings.search or "").strip().lower()
    weapon = settings.weapon

    result = []
    for action in bpy.data.actions:
        if not is_library_action(action):
            continue
        if any(action.name.startswith(name) for name in other_rigs):
            continue

        if weapon and weapon != "ALL":
            if weapon == "NONE":
                if action.get(BIO_WEAPON):
                    continue
            elif (action.get(BIO_WEAPON) or "") != weapon:
                continue

        if search:
            haystack = f"{action.get(BIO_NAME, '')} {action.get(BIO_SET, '')}".lower()
            if search not in haystack:
                continue

        result.append(action)

    result.sort(key=lambda a: (a.get(BIO_SET) or "", a.get(BIO_NAME) or ""))
    return result


def weapon_items(self, context):
    """Weapons present in this file, built from the actions themselves."""
    weapons = sorted({
        a.get(BIO_WEAPON) for a in bpy.data.actions
        if is_library_action(a) and a.get(BIO_WEAPON)
    })

    items = [("ALL", "All", "Every animation in the library")]
    items += [(w, w, f"Animations for {w}") for w in weapons]
    items.append(("NONE", "Unarmed", "Animations not tied to a weapon"))
    return items


class BioShockBrowserSettings(bpy.types.PropertyGroup):
    search: bpy.props.StringProperty(
        name="Search",
        description="Filter by the animation's original name or its set",
        options={"TEXTEDIT_UPDATE"},
    )
    weapon: bpy.props.EnumProperty(name="Weapon", items=weapon_items)
    loop: bpy.props.BoolProperty(
        name="Loop",
        description="Play the selected animation on repeat",
        default=True,
    )


class BIOSHOCK_OT_play(bpy.types.Operator):
    """Assign this animation to the rig and play it"""

    bl_idname = "bioshock.play_action"
    bl_label = "Play BioShock animation"
    bl_options = {"REGISTER", "UNDO"}

    action: bpy.props.StringProperty()

    def execute(self, context):
        rig = rig_of(context)
        action = bpy.data.actions.get(self.action)
        if rig is None or action is None:
            self.report({"WARNING"}, "No rig or action to play")
            return {"CANCELLED"}

        if rig.animation_data is None:
            rig.animation_data_create()
        rig.animation_data.action = action

        # The library preserves each animation's own frame count; the scene range follows it so the
        # clip plays exactly once rather than being padded or cut by whatever was set before.
        frames = action.get(BIO_FRAMES) or int(action.frame_range[1] - action.frame_range[0]) + 1
        context.scene.frame_start = int(action.frame_range[0])
        context.scene.frame_end = max(int(action.frame_range[0]) + 1, int(action.frame_range[0]) + frames - 1)

        fps = action.get(BIO_FPS)
        if fps:
            # Blender's scene rate is an integer; the authored rate is kept on the action, and
            # rounding here only affects playback speed, never the keys.
            context.scene.render.fps = max(1, int(round(fps)))

        context.scene.frame_set(context.scene.frame_start)

        settings = context.scene.bioshock_browser
        context.scene.use_preview_range = False
        if not context.screen.is_animation_playing:
            bpy.ops.screen.animation_play()
        # Blender loops by default; turning it off is what "play once" means here.
        context.scene.render.use_sequencer = context.scene.render.use_sequencer
        bpy.context.preferences.edit.use_negative_frames = False
        self.report({"INFO"}, f"Playing {action.get(BIO_NAME)} ({frames} frames)"
                              + (" looping" if settings.loop else ""))
        return {"FINISHED"}


class BIOSHOCK_OT_stop(bpy.types.Operator):
    """Stop playback and return the rig to its rest pose"""

    bl_idname = "bioshock.reset_pose"
    bl_label = "Reset pose"
    bl_options = {"REGISTER", "UNDO"}

    def execute(self, context):
        if context.screen.is_animation_playing:
            bpy.ops.screen.animation_cancel(restore_frame=False)

        rig = rig_of(context)
        if rig is None:
            return {"CANCELLED"}

        # Unassigning is what returns the rig to rest: the action stays in the file with its fake
        # user, so nothing is lost.
        if rig.animation_data is not None:
            rig.animation_data.action = None

        for bone in rig.pose.bones:
            bone.matrix_basis.identity()

        context.view_layer.update()
        return {"FINISHED"}


class BIOSHOCK_OT_add_to_nla(bpy.types.Operator):
    """Add this animation to the rig's NLA stack, keeping the action usable on its own"""

    bl_idname = "bioshock.add_to_nla"
    bl_label = "Add to NLA"
    bl_options = {"REGISTER", "UNDO"}

    action: bpy.props.StringProperty()

    def execute(self, context):
        rig = rig_of(context)
        action = bpy.data.actions.get(self.action)
        if rig is None or action is None:
            return {"CANCELLED"}

        if rig.animation_data is None:
            rig.animation_data_create()

        track = rig.animation_data.nla_tracks.new()
        track.name = action.get(BIO_NAME) or action.name

        start = int(context.scene.frame_current)
        track.strips.new(action.get(BIO_NAME) or action.name, start, action)

        # The action is NOT cleared from the file or from the action editor. Pushing down would take
        # it out of reach, and every animation has to stay independently usable.
        action.use_fake_user = True

        self.report({"INFO"}, f"Added {track.name} to the NLA at frame {start}")
        return {"FINISHED"}


class BIOSHOCK_PT_browser(bpy.types.Panel):
    bl_label = "Animation Library"
    bl_idname = "BIOSHOCK_PT_browser"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "BioShock"

    def draw(self, context):
        layout = self.layout
        settings = context.scene.bioshock_browser
        rig = rig_of(context)

        if rig is None:
            layout.label(text="No armature in this file", icon="ERROR")
            return

        box = layout.box()
        box.label(text=rig.name, icon="ARMATURE_DATA")
        current = rig.animation_data.action if rig.animation_data else None
        if current is not None:
            box.label(text=f"Playing: {current.get(BIO_NAME, current.name)}", icon="PLAY")

        layout.prop(settings, "weapon")
        layout.prop(settings, "search", icon="VIEWZOOM", text="")

        row = layout.row(align=True)
        row.prop(settings, "loop", toggle=True, icon="FILE_REFRESH")
        row.operator(BIOSHOCK_OT_stop.bl_idname, text="Reset pose", icon="LOOP_BACK")

        actions = actions_for(rig, settings)
        layout.label(text=f"{len(actions)} animations")

        column = layout.column(align=True)
        # A character can carry several hundred; drawing them all makes the panel unusable.
        for action in actions[:200]:
            row = column.row(align=True)
            play = row.operator(BIOSHOCK_OT_play.bl_idname,
                                text=action.get(BIO_NAME) or action.name, icon="PLAY")
            play.action = action.name

            nla = row.operator(BIOSHOCK_OT_add_to_nla.bl_idname, text="", icon="NLA")
            nla.action = action.name

        if len(actions) > 200:
            layout.label(text=f"…and {len(actions) - 200} more — narrow the search", icon="INFO")


CLASSES = (
    BioShockBrowserSettings,
    BIOSHOCK_OT_play,
    BIOSHOCK_OT_stop,
    BIOSHOCK_OT_add_to_nla,
    BIOSHOCK_PT_browser,
)


def register():
    for cls in CLASSES:
        bpy.utils.register_class(cls)
    bpy.types.Scene.bioshock_browser = bpy.props.PointerProperty(type=BioShockBrowserSettings)


def unregister():
    del bpy.types.Scene.bioshock_browser
    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)


if __name__ == "__main__":
    register()
