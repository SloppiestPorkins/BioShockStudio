"""Import real BioShock HUD + Radial + Status + Pause + Station tag-512 art into /Game/BioShockUI.

Phase U2: HUDPC crops → /Game/BioShockUI/HUD.
Phase U3: HUDRadial ring + digits → /Game/BioShockUI/Radial.
Phase U4: mapsPC/ingamemanual/HUDPC help → /Game/BioShockUI/Status;
          pausePC logo/chevrons → /Game/BioShockUI/Pause.
Phase U5: pausePC Deco/vend faces + GeneBankPC / craftingStationPC /
          PlasmidEquipStation / ComboLockPC → /Game/BioShockUI/Station.
PNGs stay outside git.

Prepare (no Unreal):
  py -3 tools/ue5/import_bioshock_ui.py --prepare

Import (UnrealEditor-Cmd -run=pythonscript):
  run_import_bioshock_ui.py
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

CONTENT_FOLDER = "/Game/BioShockUI/HUD"
RADIAL_CONTENT_FOLDER = "/Game/BioShockUI/Radial"
STATUS_CONTENT_FOLDER = "/Game/BioShockUI/Status"
PAUSE_CONTENT_FOLDER = "/Game/BioShockUI/Pause"
STATION_CONTENT_FOLDER = "/Game/BioShockUI/Station"
DEFAULT_EXPORT = os.path.join(os.environ.get("TEMP", "."), "bioshock-ui")
DEFAULT_STAGING = os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-hud-staging")
DEFAULT_RADIAL_STAGING = os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-radial-staging")
DEFAULT_STATUS_STAGING = os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-status-staging")
DEFAULT_PAUSE_STAGING = os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-pause-staging")
DEFAULT_STATION_STAGING = os.path.join(os.environ.get("TEMP", "."), "bioshock-ui-station-staging")
# Optional partial export of station SWFs (orchestrator / manual export-swf-images).
DEFAULT_STATION_EXPORT = os.path.join(os.environ.get("TEMP", "."), "ui_u5")

# Status tab icons (mapsPC): compass N / ! / tape / ?
STATUS_TAB_IDS = {
    "T_Status_Tab_Map": ("mapsPC", 1804),
    "T_Status_Tab_Goals": ("mapsPC", 1796),
    "T_Status_Tab_Messages": ("mapsPC", 1900),
    "T_Status_Tab_Help": ("mapsPC", 1798),
}
STATUS_PANEL_IDS = {
    "T_Status_Panel_Main": ("mapsPC", 1793),
    "T_Status_Panel_Wide": ("mapsPC", 1790),
    "T_Status_Panel_Ornate": ("mapsPC", 1811),
    "T_Status_Panel_Corner": ("mapsPC", 1840),
    "T_Status_Panel_Inset": ("mapsPC", 1845),
}
STATUS_NAMEPLATE_IDS = {
    "T_Status_Nameplate_Main": ("mapsPC", 1801),
    "T_Status_Nameplate_Thin": ("mapsPC", 1773),
    "T_Status_Nameplate_Wide": ("mapsPC", 1860),
}
# HUDPC poster illustrations: research / electro / medical / EVE
STATUS_HELP_IDS = {
    "T_Status_Help_Research": ("HUDPC", 552),
    "T_Status_Help_Electro": ("HUDPC", 560),
    "T_Status_Help_Medical": ("HUDPC", 592),
    "T_Status_Help_Eve": ("HUDPC", 599),
}
PAUSE_ART_IDS = {
    "T_Pause_Logo": ("pausePC", 1248),
    "T_Pause_ChevronUp": ("pausePC", 223),
    "T_Pause_ChevronDown": ("pausePC", 228),
}
# U5 station chrome — pause Deco frame + vend faces; per-SWF panels for the other four.
STATION_ART_IDS = {
    "T_Station_DecoFrame": ("pausePC", 1405),
    "T_Station_Vend_Face": ("pausePC", 62),
    "T_Station_Vend_Alt": ("pausePC", 740),
    "T_Station_Gene_Panel": ("GeneBankPC", 53),
    "T_Station_Gene_Banner": ("GeneBankPC", 204),
    "T_Station_Invent_Face": ("craftingStationPC", 334),
    "T_Station_Invent_Icon": ("craftingStationPC", 325),
    "T_Station_Garden_Banner": ("PlasmidEquipStation", 87),
    "T_Station_Garden_Icon": ("PlasmidEquipStation", 59),
    "T_Station_Combo_Dial": ("ComboLockPC", 1),
    "T_Station_Combo_Banner": ("ComboLockPC", 15),
}

# Atlas 86 (neutral tint): long pill frame object bbox measured 5 Sept 2026.
ATLAS_ID = 86
METER_FRAME_BOX = (414, 20, 1075, 157)  # left, top, right, bottom (exclusive right/bottom via +1)
# 9-slice margins in source pixels (hand-measured on the 661x137 crop).
METER_SLICE_LEFT = 68
METER_SLICE_TOP = 22
METER_SLICE_RIGHT = 68
METER_SLICE_BOTTOM = 22
# Inner fill cavity inset on the same crop (hand-measured; punch uses a hair tighter).
METER_FILL_LEFT = 32
METER_FILL_TOP = 28
METER_FILL_RIGHT = 32
METER_FILL_BOTTOM = 28
# Transparent punch / white-on-black mask — inset further so the rim always covers the fill edge.
METER_PUNCH_LEFT = 36
METER_PUNCH_TOP = 30
METER_PUNCH_RIGHT = 36
METER_PUNCH_BOTTOM = 30

# HUDRadial digit glyphs: ids run 9..0 then a highlight set. Normal set only for U2.
DIGIT_IDS_9_TO_0 = [239, 241, 243, 245, 247, 249, 251, 253, 255, 257]
# Highlight set (same 9→0 order) for radial hover readout.
DIGIT_HI_IDS_9_TO_0 = [260, 262, 264, 266, 268, 270, 272, 274, 276, 278]
# HUDRadial tag-512 brass ring (wheel body is DefineSprite/Shape — not used; see prepare_radial).
RADIAL_RING_ID = 14

STALE_ASSETS = (
    "T_Hud_HealthArc",
    "T_Hud_EveArc",
    "T_Hud_MeterUnderlay",
)


def _tools_dir():
    return os.path.dirname(os.path.abspath(__file__))


def _repo_root():
    return os.path.abspath(os.path.join(_tools_dir(), "..", ".."))


def _log(message):
    try:
        import unreal

        unreal.log("[bioshock-ui-import] %s" % message)
    except Exception:  # noqa: BLE001
        print("[bioshock-ui-import] %s" % message, flush=True)


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


def _ensure_export(export_root, force=False):
    """Run export_all_ui_images.py when HUD/Radial/Status/Pause source PNGs are missing."""
    probes = (
        os.path.join(export_root, "HUDPC", "86.png"),
        os.path.join(export_root, "HUDRadial", "239.png"),
        os.path.join(export_root, "mapsPC", "1804.png"),
        os.path.join(export_root, "pausePC", "1248.png"),
        os.path.join(export_root, "HUDPC", "552.png"),
    )
    if not force and all(os.path.isfile(p) for p in probes):
        _log("reusing export at %s" % export_root)
        return
    env = os.environ.copy()
    env["BIOSHOCK_UI_EXPORT"] = export_root
    script = os.path.join(_tools_dir(), "export_all_ui_images.py")
    _log("shelling export_all_ui_images.py -> %s" % export_root)
    subprocess.check_call([sys.executable, script, "--out", export_root], cwd=_repo_root(), env=env)


def _resolve_station_png(export_root, movie, image_id, station_export=None):
    """Find a station bitmap under bioshock-ui or the optional ui_u5 partial export."""
    candidates = [
        os.path.join(export_root, movie, "%d.png" % image_id),
    ]
    station_export = station_export or os.environ.get(
        "BIOSHOCK_UI_STATION_EXPORT", DEFAULT_STATION_EXPORT
    )
    if station_export:
        candidates.append(os.path.join(station_export, movie, "%d.png" % image_id))
    for path in candidates:
        if os.path.isfile(path):
            return path
    return None


def prepare_station_staging(export_root=None, staging_dir=None, force_export=False):
    """Stage pause Deco/vend + GeneBank/craft/garden/combo art for /Game/BioShockUI/Station."""
    from PIL import Image

    export_root = export_root or os.environ.get("BIOSHOCK_UI_EXPORT", DEFAULT_EXPORT)
    staging_dir = staging_dir or os.environ.get(
        "BIOSHOCK_UI_STATION_STAGING", DEFAULT_STATION_STAGING
    )
    station_export = os.environ.get("BIOSHOCK_UI_STATION_EXPORT", DEFAULT_STATION_EXPORT)
    os.makedirs(staging_dir, exist_ok=True)
    _ensure_export(export_root, force=force_export)

    textures = []
    gaps = []
    for asset_name, (movie, image_id) in STATION_ART_IDS.items():
        src = _resolve_station_png(export_root, movie, image_id, station_export)
        if not src:
            gaps.append("missing %s/%d.png for %s" % (movie, image_id, asset_name))
            continue
        dst_file = asset_name + ".png"
        Image.open(src).convert("RGBA").save(os.path.join(staging_dir, dst_file))
        textures.append(
            {
                "name": asset_name,
                "file": dst_file,
                "role": asset_name,
                "source": "%s/%d.png" % (movie, image_id),
            }
        )

    gaps.append(
        "Gene Bank: no gene-tonic system in BioShockRuntime — menu is plasmids only"
    )
    gaps.append(
        "U-Invent: no dedicated crafting-component inventory — recipes use AShockPlayer "
        "inventory stacks (Glue/Rubber/Screws/Oil)"
    )
    gaps.append(
        "Gatherer's Garden face art is PlasmidEquipStation banner/icon only "
        "(SWF has no large machine face); Deco frame = pausePC 1405"
    )

    manifest = {
        "stagingDir": staging_dir,
        "exportRoot": export_root,
        "stationExport": station_export,
        "textures": textures,
        "gaps": gaps,
        "contentFolder": STATION_CONTENT_FOLDER,
    }
    man_path = os.path.join(staging_dir, "station_import_manifest.json")
    with open(man_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    _log("staged %d station textures -> %s" % (len(textures), staging_dir))
    return manifest


def _draw_cross_icon(size=64):
    """Medical cross — thicker arms so it does not read as a bare '+' glyph at HUD scale."""
    from PIL import Image, ImageDraw

    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    cx = cy = size // 2
    arm = size * 18 // 64
    thick = size * 14 // 64
    outline = (20, 20, 20, 180)
    color = (240, 245, 240, 255)
    for offset, fill in ((2, outline), (0, color)):
        draw.rectangle(
            [cx - thick // 2 - offset, cy - arm - offset, cx + thick // 2 + offset, cy + arm + offset],
            fill=fill,
        )
        draw.rectangle(
            [cx - arm - offset, cy - thick // 2 - offset, cx + arm + offset, cy + thick // 2 + offset],
            fill=fill,
        )
    return im


def _draw_hypo_icon(size=64):
    """EVE hypo syringe — body + plunger + needle (not a lone '|')."""
    from PIL import Image, ImageDraw

    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)
    color = (200, 230, 255, 255)
    draw.rounded_rectangle([22, 14, 38, 48], radius=3, fill=color)
    draw.rectangle([25, 22, 35, 40], fill=(120, 180, 220, 200))
    draw.rectangle([18, 12, 42, 16], fill=color)
    draw.rectangle([26, 4, 34, 12], fill=color)
    draw.rectangle([22, 2, 38, 5], fill=color)
    draw.line([(30, 48), (30, 60)], fill=color, width=2)
    draw.ellipse([28, 58, 32, 62], fill=color)
    return im


def _draw_white_fill():
    from PIL import Image

    return Image.new("RGBA", (8, 8), (255, 255, 255, 255))


def _punch_meter_cavity(frame):
    """Zero alpha in the inner liquid channel so a fill drawn under the frame is shaped by the rim."""
    from PIL import Image, ImageChops, ImageDraw, ImageFilter

    w, h = frame.size
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    x0 = METER_PUNCH_LEFT
    y0 = METER_PUNCH_TOP
    x1 = w - METER_PUNCH_RIGHT - 1
    y1 = h - METER_PUNCH_BOTTOM - 1
    radius = max(1, (y1 - y0) // 2)
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=255)
    for _ in range(1):
        mask = mask.filter(ImageFilter.MinFilter(3))

    punched = frame.convert("RGBA")
    # Keep RGB; multiply alpha by (1 - mask) so the cavity is fully transparent.
    r, g, b, a = punched.split()
    inv = mask.point(lambda p: 255 - p)
    a = ImageChops.multiply(a, inv)
    return Image.merge("RGBA", (r, g, b, a)), mask


def _fill_mask_from_l_mask(mask):
    """White RGB + mask alpha — UImage brush tinted red/blue for the liquid."""
    from PIL import Image

    w, h = mask.size
    rgb = Image.new("RGB", (w, h), (255, 255, 255))
    return Image.merge("RGBA", (*rgb.split(), mask))


def prepare_staging(export_root=None, staging_dir=None, force_export=False):
    """Crop/stage HUD PNGs into staging_dir. Uses Pillow. Returns manifest dict."""
    from PIL import Image

    export_root = export_root or os.environ.get("BIOSHOCK_UI_EXPORT", DEFAULT_EXPORT)
    staging_dir = staging_dir or os.environ.get("BIOSHOCK_UI_HUD_STAGING", DEFAULT_STAGING)
    os.makedirs(staging_dir, exist_ok=True)

    _ensure_export(export_root, force=force_export)

    textures = []
    gaps = []

    atlas_path = os.path.join(export_root, "HUDPC", "%d.png" % ATLAS_ID)
    if not os.path.isfile(atlas_path):
        raise RuntimeError("missing atlas %s — run export_all_ui_images.py" % atlas_path)
    atlas = Image.open(atlas_path).convert("RGBA")
    x0, y0, x1, y1 = METER_FRAME_BOX
    frame_raw = atlas.crop((x0, y0, x1, y1))
    frame, cavity_mask = _punch_meter_cavity(frame_raw)
    frame_name = "T_Hud_MeterFrame.png"
    frame.save(os.path.join(staging_dir, frame_name))
    textures.append(
        {
            "name": "T_Hud_MeterFrame",
            "file": frame_name,
            "role": "meterFrame",
            "source": "HUDPC/%d.png crop %s (cavity alpha punched)" % (ATLAS_ID, METER_FRAME_BOX),
            "sliceMarginPx": {
                "left": METER_SLICE_LEFT,
                "top": METER_SLICE_TOP,
                "right": METER_SLICE_RIGHT,
                "bottom": METER_SLICE_BOTTOM,
            },
            "fillInsetPx": {
                "left": METER_FILL_LEFT,
                "top": METER_FILL_TOP,
                "right": METER_FILL_RIGHT,
                "bottom": METER_FILL_BOTTOM,
            },
            "punchInsetPx": {
                "left": METER_PUNCH_LEFT,
                "top": METER_PUNCH_TOP,
                "right": METER_PUNCH_RIGHT,
                "bottom": METER_PUNCH_BOTTOM,
            },
            "sourceSize": [frame.size[0], frame.size[1]],
        }
    )

    fill_mask = _fill_mask_from_l_mask(cavity_mask)
    fill_mask_name = "T_Hud_FillMask.png"
    fill_mask.save(os.path.join(staging_dir, fill_mask_name))
    textures.append(
        {
            "name": "T_Hud_FillMask",
            "file": fill_mask_name,
            "role": "fillMask",
            "source": "derived from meter-frame cavity punch",
            "sourceSize": [fill_mask.size[0], fill_mask.size[1]],
        }
    )

    def copy_named(movie, image_id, asset_name, role):
        src = os.path.join(export_root, movie, "%d.png" % image_id)
        if not os.path.isfile(src):
            gaps.append("missing %s/%d.png for %s" % (movie, image_id, asset_name))
            return
        dst_file = asset_name + ".png"
        Image.open(src).convert("RGBA").save(os.path.join(staging_dir, dst_file))
        textures.append(
            {
                "name": asset_name,
                "file": dst_file,
                "role": role,
                "source": "%s/%d.png" % (movie, image_id),
            }
        )

    copy_named("HUDPC", 8, "T_Hud_BrassRing", "brassRing")
    copy_named("HUDPC", 177, "T_Hud_Vignette", "vignette")
    copy_named("HUDPC", 370, "T_Hud_ReadoutPlate", "readoutPlate")

    # Digits: source order is 9..0.
    for digit_value, image_id in zip(range(9, -1, -1), DIGIT_IDS_9_TO_0):
        copy_named("HUDRadial", image_id, "T_Hud_Digit_%d" % digit_value, "digit")

    # Authored cap icons — standalone medical/hypo bitmaps not found in tag-512 exports.
    gaps.append(
        "medical-cross / EVE-hypo cap icons: not found as standalone tag-512 bitmaps in "
        "HUDPC/sharedlibrary/pausePC; using authored glyphs T_Hud_Icon_Cross / T_Hud_Icon_Hypo"
    )
    _draw_cross_icon().save(os.path.join(staging_dir, "T_Hud_Icon_Cross.png"))
    textures.append(
        {
            "name": "T_Hud_Icon_Cross",
            "file": "T_Hud_Icon_Cross.png",
            "role": "authoredCross",
            "source": "authored",
        }
    )
    _draw_hypo_icon().save(os.path.join(staging_dir, "T_Hud_Icon_Hypo.png"))
    textures.append(
        {
            "name": "T_Hud_Icon_Hypo",
            "file": "T_Hud_Icon_Hypo.png",
            "role": "authoredHypo",
            "source": "authored",
        }
    )
    _draw_white_fill().save(os.path.join(staging_dir, "T_Hud_FillWhite.png"))
    textures.append(
        {
            "name": "T_Hud_FillWhite",
            "file": "T_Hud_FillWhite.png",
            "role": "fill",
            "source": "authored",
        }
    )

    gaps.append(
        "per-weapon / per-plasmid icons: HUD_Ret_* and weapon art are vector/ImportAssets in "
        "sharedlibrary, not tag-512 bitmaps in these SWFs — U2 uses brass ring + weapon/plasmid "
        "name text; real icons deferred"
    )

    manifest = {
        "stagingDir": staging_dir,
        "exportRoot": export_root,
        "textures": textures,
        "gaps": gaps,
        "contentFolder": CONTENT_FOLDER,
    }
    man_path = os.path.join(staging_dir, "hud_import_manifest.json")
    with open(man_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    _log("staged %d textures -> %s" % (len(textures), staging_dir))
    return manifest


def prepare_radial_staging(export_root=None, staging_dir=None, force_export=False):
    """Stage HUDRadial ring + digit sets for /Game/BioShockUI/Radial. Returns manifest dict."""
    from PIL import Image

    export_root = export_root or os.environ.get("BIOSHOCK_UI_EXPORT", DEFAULT_EXPORT)
    staging_dir = staging_dir or os.environ.get(
        "BIOSHOCK_UI_RADIAL_STAGING", DEFAULT_RADIAL_STAGING
    )
    os.makedirs(staging_dir, exist_ok=True)
    _ensure_export(export_root, force=force_export)

    textures = []
    gaps = []

    def copy_named(movie, image_id, asset_name, role):
        src = os.path.join(export_root, movie, "%d.png" % image_id)
        if not os.path.isfile(src):
            gaps.append("missing %s/%d.png for %s" % (movie, image_id, asset_name))
            return
        dst_file = asset_name + ".png"
        Image.open(src).convert("RGBA").save(os.path.join(staging_dir, dst_file))
        textures.append(
            {
                "name": asset_name,
                "file": dst_file,
                "role": role,
                "source": "%s/%d.png" % (movie, image_id),
            }
        )

    copy_named("HUDRadial", RADIAL_RING_ID, "T_Radial_BrassRing", "brassRing")

    for digit_value, image_id in zip(range(9, -1, -1), DIGIT_IDS_9_TO_0):
        copy_named("HUDRadial", image_id, "T_Radial_Digit_%d" % digit_value, "digit")
    for digit_value, image_id in zip(range(9, -1, -1), DIGIT_HI_IDS_9_TO_0):
        copy_named("HUDRadial", image_id, "T_Radial_DigitHi_%d" % digit_value, "digitHi")

    gaps.append(
        "HUDRadial wheel body: no named ExportAssets for wheel/radial/ring/selector; "
        "wheel is DefineSprite/DefineShape vector (258 sprites). U3 builds the wheel from "
        "tag-512 brass ring id 14 + UMG segment labels (compromise)."
    )
    gaps.append(
        "per-weapon / per-plasmid icons: sharedlibrary HUD_Ret_* are crosshair reticles "
        "(vector shapes, e.g. id 988 Pistol / 982 Wrench), not inventory icons; "
        "PCWeaponSelection *Reticle exports are the same family. U3 uses brass ring + name "
        "text per segment — do not author fake icons."
    )

    manifest = {
        "stagingDir": staging_dir,
        "exportRoot": export_root,
        "textures": textures,
        "gaps": gaps,
        "contentFolder": RADIAL_CONTENT_FOLDER,
    }
    man_path = os.path.join(staging_dir, "radial_import_manifest.json")
    with open(man_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    _log("staged %d radial textures -> %s" % (len(textures), staging_dir))
    return manifest


def _stage_named_copies(export_root, staging_dir, mapping, textures, gaps):
    """Copy (movie, id) → staging asset PNG entries."""
    from PIL import Image

    for asset_name, (movie, image_id) in mapping.items():
        src = os.path.join(export_root, movie, "%d.png" % image_id)
        if not os.path.isfile(src):
            gaps.append("missing %s/%d.png for %s" % (movie, image_id, asset_name))
            continue
        dst_file = asset_name + ".png"
        Image.open(src).convert("RGBA").save(os.path.join(staging_dir, dst_file))
        textures.append(
            {
                "name": asset_name,
                "file": dst_file,
                "role": asset_name,
                "source": "%s/%d.png" % (movie, image_id),
            }
        )


def prepare_status_staging(export_root=None, staging_dir=None, force_export=False):
    """Stage mapsPC / HUDPC help art for /Game/BioShockUI/Status."""
    export_root = export_root or os.environ.get("BIOSHOCK_UI_EXPORT", DEFAULT_EXPORT)
    staging_dir = staging_dir or os.environ.get(
        "BIOSHOCK_UI_STATUS_STAGING", DEFAULT_STATUS_STAGING
    )
    os.makedirs(staging_dir, exist_ok=True)
    _ensure_export(export_root, force=force_export)

    textures = []
    gaps = []
    _stage_named_copies(export_root, staging_dir, STATUS_TAB_IDS, textures, gaps)
    _stage_named_copies(export_root, staging_dir, STATUS_PANEL_IDS, textures, gaps)
    _stage_named_copies(export_root, staging_dir, STATUS_NAMEPLATE_IDS, textures, gaps)
    _stage_named_copies(export_root, staging_dir, STATUS_HELP_IDS, textures, gaps)
    gaps.append(
        "Map tab: level-plan rendering deferred — U4 shows placeholder text + player coords"
    )
    gaps.append(
        "Messages tab: audio-diary collection not wired yet — empty panel until inventory "
        "diaries exist"
    )
    # Task brief said "face = Messages"; shipped mapsPC art is a reel-to-reel tape (id 1900).
    gaps.append(
        "Messages tab icon: task brief said face; mapsPC id 1900 is reel-to-reel tape "
        "(audio-diary glyph) — used as-is"
    )

    manifest = {
        "stagingDir": staging_dir,
        "exportRoot": export_root,
        "textures": textures,
        "gaps": gaps,
        "contentFolder": STATUS_CONTENT_FOLDER,
    }
    man_path = os.path.join(staging_dir, "status_import_manifest.json")
    with open(man_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    _log("staged %d status textures -> %s" % (len(textures), staging_dir))
    return manifest


def prepare_pause_staging(export_root=None, staging_dir=None, force_export=False):
    """Stage pausePC logo + chevrons for /Game/BioShockUI/Pause."""
    export_root = export_root or os.environ.get("BIOSHOCK_UI_EXPORT", DEFAULT_EXPORT)
    staging_dir = staging_dir or os.environ.get(
        "BIOSHOCK_UI_PAUSE_STAGING", DEFAULT_PAUSE_STAGING
    )
    os.makedirs(staging_dir, exist_ok=True)
    _ensure_export(export_root, force=force_export)

    textures = []
    gaps = []
    _stage_named_copies(export_root, staging_dir, PAUSE_ART_IDS, textures, gaps)
    gaps.append(
        "Little Sister count: no AShockLittleSister class yet — pause menu counts actors "
        "whose class name contains Gatherer/LittleSister, else 0"
    )

    manifest = {
        "stagingDir": staging_dir,
        "exportRoot": export_root,
        "textures": textures,
        "gaps": gaps,
        "contentFolder": PAUSE_CONTENT_FOLDER,
    }
    man_path = os.path.join(staging_dir, "pause_import_manifest.json")
    with open(man_path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2)
    _log("staged %d pause textures -> %s" % (len(textures), staging_dir))
    return manifest


def _disable_interchange():
    import unreal

    for flag in ("PNG", "Texture", "FBX", "OBJ"):
        unreal.SystemLibrary.execute_console_command(
            None, "Interchange.FeatureFlags.Import.%s 0" % flag
        )


def _ensure_dir(path):
    import unreal

    if unreal.EditorAssetLibrary.does_directory_exist(path):
        return
    if not unreal.EditorAssetLibrary.make_directory(path):
        raise RuntimeError("could not create folder %s" % path)


def _configure_ui_texture(texture):
    """UI group, sRGB, no mips, UI compression."""
    import unreal

    texture.set_editor_property("srgb", True)
    try:
        texture.set_editor_property("lod_group", unreal.TextureGroup.TEXTUREGROUP_UI)
    except Exception:  # noqa: BLE001
        pass
    try:
        texture.set_editor_property(
            "mip_gen_settings", unreal.TextureMipGenSettings.TMGS_NO_MIPMAPS
        )
    except Exception:  # noqa: BLE001
        try:
            texture.set_editor_property(
                "mip_gen_settings", unreal.TextureMipGenSettings.TMGS_NoMipmaps
            )
        except Exception:  # noqa: BLE001
            pass
    try:
        texture.set_editor_property("never_stream", True)
    except Exception:  # noqa: BLE001
        pass

    compression = None
    for name in ("TC_EDITOR_ICON", "TC_USERINTERFACE2D", "TC_EditorIcon", "TC_UserInterface2D"):
        compression = getattr(unreal.TextureCompressionSettings, name, None)
        if compression is not None:
            break
    if compression is None:
        compression = unreal.TextureCompressionSettings.TC_DEFAULT
    texture.set_editor_property("compression_settings", compression)
    unreal.EditorAssetLibrary.save_loaded_asset(texture)


def _import_png(source, destination_path, asset_name):
    import unreal

    if not os.path.isfile(source):
        return None

    task = unreal.AssetImportTask()
    task.set_editor_property("filename", source)
    task.set_editor_property("destination_path", destination_path)
    task.set_editor_property("destination_name", asset_name)
    task.set_editor_property("automated", True)
    task.set_editor_property("replace_existing", True)
    task.set_editor_property("save", False)
    try:
        task.set_editor_property("factory", unreal.TextureFactory())
    except Exception as exc:  # noqa: BLE001
        _log("could not pin TextureFactory (%s); Interchange may assert" % exc)

    unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    objects = list(task.get_objects())
    texture = next((o for o in objects if isinstance(o, unreal.Texture2D)), None)
    if texture is None:
        texture = unreal.EditorAssetLibrary.load_asset("%s/%s" % (destination_path, asset_name))
        if texture is not None and not isinstance(texture, unreal.Texture2D):
            texture = None
    if texture is None:
        return None
    _configure_ui_texture(texture)
    return texture


def _delete_stale():
    import unreal

    deleted = []
    for name in STALE_ASSETS:
        path = "%s/%s" % (CONTENT_FOLDER, name)
        if unreal.EditorAssetLibrary.does_asset_exist(path):
            if unreal.EditorAssetLibrary.delete_asset(path):
                deleted.append(path)
                _log("deleted stale %s" % path)
            else:
                _log("failed to delete stale %s" % path)
    return deleted


def _import_manifest(staging_dir, man_name, content_folder, report):
    """Import one staging manifest into content_folder; appends to report."""
    failures = report["failures"]
    man_path = os.path.join(staging_dir, man_name)
    if not os.path.isfile(man_path):
        failures.append("missing staging manifest: %s (run --prepare)" % man_path)
        return
    with open(man_path, encoding="utf-8") as handle:
        manifest = json.load(handle)
    report["gaps"].extend(list(manifest.get("gaps") or []))
    _ensure_dir(content_folder)
    for entry in list(manifest.get("textures") or []):
        name = entry["name"]
        source = os.path.join(staging_dir, entry["file"].replace("/", os.sep))
        if not os.path.isfile(source):
            failures.append("missing PNG: %s" % source)
            continue
        texture = _import_png(source, content_folder, name)
        if texture is None:
            failures.append("import failed: %s" % name)
            continue
        path = "%s/%s" % (content_folder, name)
        report["imported"][name] = path
        _log("imported %s" % path)


def main(
    staging_dir=None,
    radial_staging_dir=None,
    status_staging_dir=None,
    pause_staging_dir=None,
    station_staging_dir=None,
    out=None,
    content_folder=CONTENT_FOLDER,
    prepare_if_needed=True,
):
    import unreal

    staging_dir = staging_dir or os.environ.get("BIOSHOCK_UI_HUD_STAGING", DEFAULT_STAGING)
    radial_staging_dir = radial_staging_dir or os.environ.get(
        "BIOSHOCK_UI_RADIAL_STAGING", DEFAULT_RADIAL_STAGING
    )
    status_staging_dir = status_staging_dir or os.environ.get(
        "BIOSHOCK_UI_STATUS_STAGING", DEFAULT_STATUS_STAGING
    )
    pause_staging_dir = pause_staging_dir or os.environ.get(
        "BIOSHOCK_UI_PAUSE_STAGING", DEFAULT_PAUSE_STAGING
    )
    station_staging_dir = station_staging_dir or os.environ.get(
        "BIOSHOCK_UI_STATION_STAGING", DEFAULT_STATION_STAGING
    )
    out = out or os.environ.get(
        "BIOSHOCK_UI_IMPORT_OUT",
        os.path.join(os.environ.get("TEMP", "."), "bioshock_ui_import_report.json"),
    )
    export_root = os.environ.get("BIOSHOCK_UI_EXPORT", DEFAULT_EXPORT)

    report = {
        "stagingDir": staging_dir,
        "radialStagingDir": radial_staging_dir,
        "statusStagingDir": status_staging_dir,
        "pauseStagingDir": pause_staging_dir,
        "stationStagingDir": station_staging_dir,
        "contentFolder": content_folder,
        "radialContentFolder": RADIAL_CONTENT_FOLDER,
        "statusContentFolder": STATUS_CONTENT_FOLDER,
        "pauseContentFolder": PAUSE_CONTENT_FOLDER,
        "stationContentFolder": STATION_CONTENT_FOLDER,
        "imported": {},
        "deleted": [],
        "failures": [],
        "gaps": [],
    }
    failures = report["failures"]

    man_path = os.path.join(staging_dir, "hud_import_manifest.json")
    radial_man = os.path.join(radial_staging_dir, "radial_import_manifest.json")
    status_man = os.path.join(status_staging_dir, "status_import_manifest.json")
    pause_man = os.path.join(pause_staging_dir, "pause_import_manifest.json")
    station_man = os.path.join(station_staging_dir, "station_import_manifest.json")
    need_prepare = (
        not os.path.isfile(man_path)
        or not os.path.isfile(radial_man)
        or not os.path.isfile(status_man)
        or not os.path.isfile(pause_man)
        or not os.path.isfile(station_man)
    )
    if prepare_if_needed and need_prepare:
        # Unreal's Python often lacks Pillow — prepare via system py.
        prep = subprocess.run(
            [
                "py",
                "-3",
                os.path.join(_tools_dir(), "import_bioshock_ui.py"),
                "--prepare",
                "--export",
                export_root,
                "--staging",
                staging_dir,
                "--radial-staging",
                radial_staging_dir,
                "--status-staging",
                status_staging_dir,
                "--pause-staging",
                pause_staging_dir,
                "--station-staging",
                station_staging_dir,
            ],
            cwd=_repo_root(),
            capture_output=True,
            text=True,
        )
        if prep.returncode != 0:
            failures.append("prepare failed: %s" % (prep.stderr or prep.stdout or prep.returncode))
            report["ok"] = False
            _write(out, report)
            raise RuntimeError("bioshock-ui-import:\n- " + "\n- ".join(failures))

    _disable_interchange()
    _ensure_dir("/Game/BioShockUI")
    report["deleted"] = _delete_stale()
    _import_manifest(staging_dir, "hud_import_manifest.json", content_folder, report)
    _import_manifest(
        radial_staging_dir, "radial_import_manifest.json", RADIAL_CONTENT_FOLDER, report
    )
    _import_manifest(
        status_staging_dir, "status_import_manifest.json", STATUS_CONTENT_FOLDER, report
    )
    _import_manifest(
        pause_staging_dir, "pause_import_manifest.json", PAUSE_CONTENT_FOLDER, report
    )
    _import_manifest(
        station_staging_dir, "station_import_manifest.json", STATION_CONTENT_FOLDER, report
    )

    report["ok"] = not failures
    _write(out, report)
    if failures:
        raise RuntimeError("bioshock-ui-import:\n- " + "\n- ".join(failures))
    _log("PASS bioshock-ui-import (%d textures)" % len(report["imported"]))
    return report


def _cli(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prepare", action="store_true", help="Stage crops only (no Unreal)")
    parser.add_argument("--export", default=None, help="export_all_ui_images root")
    parser.add_argument("--staging", default=None, help="staging directory for HUD PNGs")
    parser.add_argument(
        "--radial-staging", default=None, help="staging directory for Radial PNGs"
    )
    parser.add_argument(
        "--status-staging", default=None, help="staging directory for Status PNGs"
    )
    parser.add_argument(
        "--pause-staging", default=None, help="staging directory for Pause PNGs"
    )
    parser.add_argument(
        "--station-staging", default=None, help="staging directory for Station PNGs"
    )
    parser.add_argument("--force-export", action="store_true")
    args = parser.parse_args(argv)
    if args.prepare:
        prepare_staging(args.export, args.staging, force_export=args.force_export)
        prepare_radial_staging(
            args.export, args.radial_staging, force_export=args.force_export
        )
        prepare_status_staging(
            args.export, args.status_staging, force_export=args.force_export
        )
        prepare_pause_staging(
            args.export, args.pause_staging, force_export=args.force_export
        )
        prepare_station_staging(
            args.export, args.station_staging, force_export=args.force_export
        )
        return 0
    # Running under Unreal as __main__ is unusual; prefer run_import_bioshock_ui.py
    main(
        staging_dir=args.staging,
        radial_staging_dir=args.radial_staging,
        status_staging_dir=args.status_staging,
        pause_staging_dir=args.pause_staging,
        station_staging_dir=args.station_staging,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(_cli())
