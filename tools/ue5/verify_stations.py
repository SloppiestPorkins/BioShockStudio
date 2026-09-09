"""Headless verify: station UIs (Phase U5).

Requires Station textures under /Game/BioShockUI/Station.
Headless only — no visual likeness claim.
"""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-stations] %s" % message)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    classes = {
        "ShockStationMenu": unreal.load_class(None, "/Script/BioShockRuntime.ShockStationMenu"),
        "ShockVendingMenu": unreal.load_class(None, "/Script/BioShockRuntime.ShockVendingMenu"),
        "ShockGeneBankMenu": unreal.load_class(None, "/Script/BioShockRuntime.ShockGeneBankMenu"),
        "ShockUInventMenu": unreal.load_class(None, "/Script/BioShockRuntime.ShockUInventMenu"),
        "ShockGathererGardenMenu": unreal.load_class(
            None, "/Script/BioShockRuntime.ShockGathererGardenMenu"
        ),
        "ShockComboLockMenu": unreal.load_class(
            None, "/Script/BioShockRuntime.ShockComboLockMenu"
        ),
        "ShockStationBase": unreal.load_class(None, "/Script/BioShockRuntime.ShockStationBase"),
    }
    for name, cls in classes.items():
        if not cls:
            failures.append("%s class missing" % name)
    if failures:
        _write(out, report)
        raise RuntimeError("stations:\n- " + "\n- ".join(failures))

    required = {
        "/Game/BioShockUI/Station/T_Station_DecoFrame": "deco frame",
        "/Game/BioShockUI/Station/T_Station_Vend_Face": "vend face",
        "/Game/BioShockUI/Station/T_Station_Gene_Panel": "gene panel",
        "/Game/BioShockUI/Station/T_Station_Invent_Face": "invent face",
        "/Game/BioShockUI/Station/T_Station_Garden_Banner": "garden banner",
        "/Game/BioShockUI/Station/T_Station_Combo_Dial": "combo dial",
    }
    textures_on_disk = {}
    for path, role in required.items():
        present = bool(unreal.EditorAssetLibrary.does_asset_exist(path))
        textures_on_disk[path] = present
        if not present:
            failures.append(
                "%s texture missing %s — run import_bioshock_ui.py" % (role, path)
            )
    report["texturesOnDisk"] = textures_on_disk

    world = unreal.EditorLevelLibrary.get_editor_world()
    ok = bool(unreal.ShockStationMenu.run_headless_stations_verify(world))
    err = str(unreal.ShockStationMenu.get_last_stations_verify_error())
    report["stationsVerify"] = {"ok": ok, "error": err}
    if not ok:
        failures.append("RunHeadlessStationsVerify: %s" % (err or "failed"))

    # Health Station (w11): heal-for-money, no menu.
    sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    hs = sub.spawn_actor_from_class(
        classes["ShockStationBase"], unreal.Vector(0, 6000, 100), unreal.Rotator(0, 0, 0))
    hp = sub.spawn_actor_from_class(player_cls, unreal.Vector(80, 6000, 100), unreal.Rotator(0, 0, 0))
    if hs and hp:
        hs.set_editor_property("station_kind", unreal.ShockStationKind.HEALTH_STATION)
        hp.ensure_health_initialized()
        hp.set_current_health_for_verify(20.0)
        hp.add_money(50)
        m0 = hp.get_money()
        healed = hs.try_interact(hp)
        report["healthStation"] = {
            "healed": bool(healed),
            "health": float(hp.get_current_health()),
            "spent": m0 - hp.get_money(),
        }
        if not (healed and hp.get_current_health() >= hp.get_max_health() - 0.5 and hp.get_money() < m0):
            failures.append("health_station heal-for-money failed: %s" % report["healthStation"])
        # already-full -> no charge
        m1 = hp.get_money()
        hs.try_interact(hp)
        if hp.get_money() != m1:
            failures.append("health_station charged at full health")
    for a in (hs, hp):
        if a:
            try:
                sub.destroy_actor(a)
            except Exception:
                pass

    report["stations"] = "ok" if not failures else "fail"
    report["visual"] = (
        "headless cannot judge BioShock likeness — confirm via "
        "capture_shot.ps1 -Map /Game/BioShockSlice/1-Medical -Extra "
        "'-bioshockshothud','-bioshockshotvend' (also genebank/invent/garden/combo); "
        "human still confirms PIE feel"
    )
    report["gaps"] = {
        "geneTonics": "no tonic system — Gene Bank is plasmids only",
        "craftComponents": "no crafting-component bag — U-Invent uses inventory stacks",
        "levelPlacement": "full vending placement is level-import; slice uses "
        "bEnableSliceStations",
    }
    _write(out, report)
    if failures:
        raise RuntimeError("stations:\n- " + "\n- ".join(failures))
    _log("PASS stations")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "stations_report.json"),
        )
    )
