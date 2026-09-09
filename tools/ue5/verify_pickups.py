"""Headless verify: world pickups + lootable containers grant the right thing."""

import json
import os

import unreal


def _log(msg):
    unreal.log("[bioshock-pickups] %s" % msg)


def _spawn(sub, cls, label, loc):
    a = sub.spawn_actor_from_class(cls, loc, unreal.Rotator(0, 0, 0))
    if a:
        a.set_actor_label(label)
    return a


# EShockPickupKind
K_FIRST_AID, K_EVE, K_MONEY, K_AMMO, K_ADAM, K_ITEM, K_WEAPON, K_PLASMID, K_DIARY = range(9)


def main(out):
    report = {"failures": [], "results": []}
    failures = report["failures"]
    sub = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    player_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockPlayer")
    pickup_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockConsumablePickup")
    container_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockSearchableContainer")
    if not all([player_cls, pickup_cls, container_cls]):
        failures.append("runtime classes missing")
        raise RuntimeError("pickups:\n- " + "\n- ".join(failures))

    spawned = []

    def check(name, ok, detail=None):
        report["results"].append({"name": name, "ok": bool(ok), "detail": detail})
        if not ok:
            failures.append("%s: %s" % (name, detail))

    player = _spawn(sub, player_cls, "PickupPlayer", unreal.Vector(0, 0, 100))
    spawned.append(player)
    player.ensure_health_initialized()

    # money
    p = _spawn(sub, pickup_cls, "P_Money", unreal.Vector(50, 0, 100))
    spawned.append(p)
    p.configure_pickup(K_MONEY, 35, unreal.Name(), unreal.Name(), unreal.Name(), unreal.Name(), False)
    m0 = player.get_money()
    check("money_grant", p.try_collect(player) and player.get_money() == m0 + 35, player.get_money())

    # adam
    p = _spawn(sub, pickup_cls, "P_Adam", unreal.Vector(60, 0, 100))
    spawned.append(p)
    p.configure_pickup(K_ADAM, 10, unreal.Name(), unreal.Name(), unreal.Name(), unreal.Name(), False)
    a0 = player.get_adam()
    check("adam_grant", p.try_collect(player) and player.get_adam() == a0 + 10, player.get_adam())

    # first aid -> inventory
    p = _spawn(sub, pickup_cls, "P_Aid", unreal.Vector(70, 0, 100))
    spawned.append(p)
    p.configure_pickup(K_FIRST_AID, 1, unreal.Name(), unreal.Name(), unreal.Name(), unreal.Name(), False)
    f0 = player.get_inventory_stack(unreal.Name("FirstAidKit"))
    check("firstaid_grant",
          p.try_collect(player) and player.get_inventory_stack(unreal.Name("FirstAidKit")) == f0 + 1,
          player.get_inventory_stack(unreal.Name("FirstAidKit")))

    # item (auto-hack)
    p = _spawn(sub, pickup_cls, "P_Hack", unreal.Vector(80, 0, 100))
    spawned.append(p)
    p.configure_pickup(K_ITEM, 1, unreal.Name(), unreal.Name("AutoHackTool"), unreal.Name(), unreal.Name(), False)
    check("item_grant",
          p.try_collect(player) and player.get_inventory_stack(unreal.Name("AutoHackTool")) >= 1, None)

    # weapon (keypress — try_collect still works when called directly)
    p = _spawn(sub, pickup_cls, "P_Pistol", unreal.Vector(90, 0, 100))
    spawned.append(p)
    p.configure_pickup(K_WEAPON, 20, unreal.Name("Pistol"), unreal.Name(), unreal.Name(), unreal.Name(), True)
    got = p.try_collect(player)
    has_pistol = any(
        player.get_weapon_in_slot(s) and player.get_weapon_in_slot(s).get_weapon_def_name() == unreal.Name("Pistol")
        for s in range(8)
    )
    check("weapon_grant", got and has_pistol, None)

    # plasmid
    p = _spawn(sub, pickup_cls, "P_Plasmid", unreal.Vector(100, 0, 100))
    spawned.append(p)
    p.configure_pickup(K_PLASMID, 1, unreal.Name(), unreal.Name(), unreal.Name("ElectroBolt"), unreal.Name(), True)
    check("plasmid_grant", bool(p.try_collect(player)), None)

    # diary
    p = _spawn(sub, pickup_cls, "P_Diary", unreal.Vector(110, 0, 100))
    spawned.append(p)
    p.configure_pickup(K_DIARY, 1, unreal.Name(), unreal.Name(), unreal.Name(), unreal.Name("medical_01"), True)
    check("diary_grant",
          p.try_collect(player) and player.get_inventory_stack(unreal.Name("AudioDiary_medical_01")) >= 1, None)

    # container search
    c = _spawn(sub, container_cls, "C_Corpse", unreal.Vector(200, 0, 100))
    spawned.append(c)
    c.configure_container(unreal.Name("TestCorpse"), 10, 20, unreal.Name("FirstAidKit"), 1)
    mm0 = player.get_money()
    searched = c.search(player)
    check("container_search",
          searched and c.was_searched_for_verify() and player.get_money() >= mm0 + 10, player.get_money())
    check("container_search_once", not c.search(player), None)

    for a in spawned:
        try:
            sub.destroy_actor(a)
        except Exception:
            pass

    report["pickups"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("pickups:\n- " + "\n- ".join(failures))
    _log("Success - %d checks" % len(report["results"]))
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT",
                        os.path.join(os.environ.get("TEMP", "."), "pickups_report.json")))
