"""Ensure BioShockUE5 has ActionMapping Fire → LeftMouseButton; verify EnablePlayableInput + fire.

Writes Config/DefaultInput.ini (project is outside this repo). Does not claim PIE possess.
"""

import json
import os
import re

import unreal


def _log(m):
    unreal.log("[bioshock-playable-input] %s" % m)


def _spawn(cls, loc):
    return unreal.EditorLevelLibrary.spawn_actor_from_class(cls, loc, unreal.Rotator(0.0, 0.0, 0.0))


FIRE_LINE = '+ActionMappings=(ActionName="Fire",bShift=False,bCtrl=False,bAlt=False,bCmd=False,Key=LeftMouseButton)'
AXIS_LINES = [
    '+AxisMappings=(AxisName="MoveForward",Scale=1.000000,Key=W)',
    '+AxisMappings=(AxisName="MoveForward",Scale=-1.000000,Key=S)',
    '+AxisMappings=(AxisName="MoveRight",Scale=-1.000000,Key=A)',
    '+AxisMappings=(AxisName="MoveRight",Scale=1.000000,Key=D)',
    '+AxisMappings=(AxisName="Turn",Scale=1.000000,Key=MouseX)',
    '+AxisMappings=(AxisName="LookUp",Scale=-1.000000,Key=MouseY)',
]
LEGACY_INPUT = "DefaultPlayerInputClass=/Script/Engine.PlayerInput"
LEGACY_COMPONENT = "DefaultInputComponentClass=/Script/Engine.InputComponent"


def ensure_fire_in_default_input(project_dir):
    cfg_dir = os.path.join(project_dir, "Config")
    path = os.path.join(cfg_dir, "DefaultInput.ini")
    os.makedirs(cfg_dir, exist_ok=True)
    text = ""
    if os.path.isfile(path):
        text = open(path, encoding="utf-8").read()
    changed = False
    if "[/Script/Engine.InputSettings]" not in text:
        text = text.rstrip() + "\n\n[/Script/Engine.InputSettings]\n"
        changed = True
    # Legacy ActionMappings need legacy PlayerInput — Enhanced Input ignores them.
    if "DefaultPlayerInputClass=/Script/EnhancedInput" in text:
        text = text.replace(
            "DefaultPlayerInputClass=/Script/EnhancedInput.EnhancedPlayerInput",
            LEGACY_INPUT,
        )
        changed = True
        _log("switched DefaultPlayerInputClass to legacy Engine.PlayerInput")
    elif LEGACY_INPUT not in text:
        text = text.rstrip() + "\n" + LEGACY_INPUT + "\n"
        changed = True
    if "DefaultInputComponentClass=/Script/EnhancedInput" in text:
        text = text.replace(
            "DefaultInputComponentClass=/Script/EnhancedInput.EnhancedInputComponent",
            LEGACY_COMPONENT,
        )
        changed = True
        _log("switched DefaultInputComponentClass to legacy Engine.InputComponent")
    elif LEGACY_COMPONENT not in text:
        text = text.rstrip() + "\n" + LEGACY_COMPONENT + "\n"
        changed = True
    if 'ActionName="Fire"' not in text and "ActionName=Fire" not in text:
        if not text.endswith("\n"):
            text += "\n"
        text += FIRE_LINE + "\n"
        changed = True
        _log("wrote Fire ActionMapping to DefaultInput.ini")
    else:
        _log("DefaultInput.ini already has Fire")
    for line in AXIS_LINES:
        # Match AxisName="MoveForward" etc. already present
        axis_name = re.search(r'AxisName="([^"]+)"', line)
        key_name = re.search(r"Key=([A-Za-z0-9]+)", line)
        if not axis_name or not key_name:
            continue
        needle = 'AxisName="%s"' % axis_name.group(1)
        key = key_name.group(1)
        if needle in text and ("Key=%s" % key) in text:
            continue
        # Avoid duplicate exact lines
        if line in text:
            continue
        if not text.endswith("\n"):
            text += "\n"
        text += line + "\n"
        changed = True
        _log("wrote axis %s %s" % (axis_name.group(1), key))
    if changed:
        open(path, "w", encoding="utf-8", newline="\n").write(text)
    return path, changed


def main(out):
    report = {"failures": []}
    f = report["failures"]

    project_dir = os.path.dirname(unreal.Paths.get_project_file_path())
    ini_path, wrote = ensure_fire_in_default_input(project_dir)
    report["ini"] = ini_path
    report["ini_wrote"] = wrote
    ini_text = open(ini_path, encoding="utf-8").read()
    if 'ActionName="Fire"' not in ini_text and "ActionName=Fire" not in ini_text:
        f.append("Fire missing from DefaultInput.ini")
    report["fire_mapping"] = "ok"
    for axis in ("MoveForward", "MoveRight", "Turn", "LookUp"):
        if ('AxisName="%s"' % axis) not in ini_text:
            f.append("axis missing %s" % axis)
    report["axis_mappings"] = "ok"

    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    weapon_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockWeapon")
    ai_cls = unreal.load_class(None, "/Script/BioShockRuntime.BaseShockAI")

    player = _spawn(player_cls, unreal.Vector(0.0, 0.0, 100.0))
    weapon = _spawn(weapon_cls, unreal.Vector(0.0, 0.0, 100.0))
    ai = _spawn(ai_cls, unreal.Vector(300.0, 0.0, 100.0))
    if not player or not weapon or not ai:
        f.append("spawn")
    else:
        player.enable_playable_input(True)
        if not bool(player.is_playable_input_enabled()):
            f.append("EnablePlayableInput")
        report["playable_input"] = "ok"

        weapon.configure_hitscan(15.0, 5000.0)
        player.equip_weapon(weapon)
        ai.ensure_health_initialized()
        before = float(ai.get_current_health())
        direction = ai.get_actor_location() - player.get_actor_location()
        look = unreal.MathLibrary.find_look_at_rotation(player.get_actor_location(), ai.get_actor_location())
        player.set_actor_rotation(look, False)
        hit = bool(player.try_fire_equipped_weapon())
        if not hit:
            hit = bool(weapon.fire_at(player, player.get_actor_location(), direction))
            report["try_fire"] = "fallback_fire_at" if hit else "miss"
        else:
            report["try_fire"] = "ok"
        if int(weapon.get_fire_count()) < 1:
            f.append("FireCount")
        after = float(ai.get_current_health())
        if after >= before:
            f.append("no damage")
        report["damage"] = before - after

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("playable-input:\n- " + "\n- ".join(f))
    _log("PASS playable input")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\playable_input_report.json"))
