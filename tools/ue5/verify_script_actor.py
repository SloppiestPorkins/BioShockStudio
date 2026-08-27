"""Level-placed AShockScript: spawn, TriggeredBy dispatch, TickScript with authored time."""

import json
import os

import unreal


def _log(m):
    unreal.log("[bioshock-script-actor] %s" % m)


def _spawn(cls, loc):
    return unreal.EditorLevelLibrary.spawn_actor_from_class(cls, loc, unreal.Rotator(0.0, 0.0, 0.0))


def _assign(name, value):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableAssignOverwrite")
    a = unreal.new_object(cls)
    a.configure(name, value)
    return a


def _wait(seconds):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionWait")
    a = unreal.new_object(cls)
    a.configure(seconds)
    return a


def _inc(name):
    cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockActionVariableIncrement")
    a = unreal.new_object(cls)
    a.configure(name)
    return a


def main(out):
    report = {"failures": []}
    f = report["failures"]

    script_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockScript")
    if not script_cls:
        f.append("load ShockScript")
        raise RuntimeError("no ShockScript")

    door = _spawn(script_cls, unreal.Vector(10.0, 0.0, 20.0))
    if not door:
        f.append("spawn door script")
        raise RuntimeError("spawn failed")

    door.configure("DoorScript", "DoorA")
    registry = door.ensure_registry()
    if not registry:
        f.append("EnsureRegistry")
    runner = door.get_runner()
    if not runner:
        f.append("GetRunner")
    runner.add_action(_assign("Hit", "1"))

    other = _spawn(script_cls, unreal.Vector(30.0, 0.0, 20.0))
    other.configure("CrateScript", "Crate")
    other.set_registry(registry)
    other.get_runner().add_action(_assign("Hit", "crate"))

    if int(registry.dispatch_message("Touch", "Nope")) != 0:
        f.append("Nope")
    if int(registry.dispatch_message("Touch", "DoorA")) != 1:
        f.append("DoorA dispatch")
    door.tick_script(0.0)
    if str(runner.ensure_variables().get_value_or_empty("Hit")) != "1":
        f.append("Hit=%s" % runner.ensure_variables().get_value_or_empty("Hit"))
    report["door"] = "ok"

    # Wait + MessageQueue on placed actor
    busy = _spawn(script_cls, unreal.Vector(50.0, 0.0, 20.0))
    busy.configure("BusyScript", "BusySrc")
    busy.set_registry(registry)
    busy.get_runner().add_action(_wait(0.5))
    busy.get_runner().add_action(_inc("N"))
    if int(registry.dispatch_message("T", "BusySrc")) != 1:
        f.append("busy start")
    if int(registry.dispatch_message("T", "BusySrc")) != 1:
        f.append("busy queue")
    if int(busy.get_runner().get_message_queue_num()) != 1:
        f.append("queue")
    busy.tick_script(0.0)
    if not bool(busy.get_runner().is_executing):
        f.append("should wait")
    busy.tick_script(0.5)
    busy.tick_script(1.0)
    if str(busy.get_runner().ensure_variables().get_value_or_empty("N")) != "2":
        f.append("N=%s" % busy.get_runner().ensure_variables().get_value_or_empty("N"))
    report["queue"] = "ok"

    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if f:
        raise RuntimeError("script-actor:\n- " + "\n- ".join(f))
    _log("PASS script actor")
    return report


if __name__ == "__main__":
    main(os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\script_actor_report.json"))
