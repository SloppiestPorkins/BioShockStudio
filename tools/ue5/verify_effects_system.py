"""Headless verify for R3.1/3.2 — UShockEffectsSubsystem + ActionPlayEffect/StopEffect/
SetEffectsSystemContext actually spawning something instead of recording-and-doing-nothing.

Spawns one throwaway actor and drives the 4 effect actions directly against it (no script graph
needed, same pattern as verify_reflection_actions.py / verify_action_property_test.py). Checks:
  (a) ActionPlayEffect with a keyword-matching event ("SteamHiss") resolves the Steam bundle and
      spawns a visible AShockPlasmidFx (not the Generic fallback);
  (b) an unrecognised event name falls back to the Generic bundle, not silence;
  (c) ActionStopEffect tears the spawned instance down (active-effect count drops);
  (d) ActionSetEffectsSystemContext pushes/removes a context on the subsystem's stack;
  (e) ActionPlayEffectAndWaitForStart resolves its ActorLabel and spawns too.
"""
import json
import os

import unreal

OUT = os.environ.get(
    "BIOSHOCK_ACTION_OUT",
    os.path.join(os.environ.get("TEMP", "."), "effects_system_report.json"))

TEST_LOCATION = unreal.Vector(-17320.0, 1272.0, 9000.0)


def _cls(name):
    c = unreal.load_class(None, "/Script/BioShockRuntime.%s" % name)
    if c is None:
        raise RuntimeError("effects_system: class missing - %s" % name)
    return c


def main(out=OUT):
    report = {"failures": [], "checks": {}}
    failures = report["failures"]

    def check(name, ok, detail=None):
        report["checks"][name] = bool(ok)
        if not ok:
            failures.append("%s failed%s" % (name, (" (%r)" % (detail,)) if detail is not None else ""))

    lvl = unreal.get_editor_subsystem(unreal.LevelEditorSubsystem)
    if not lvl.load_level("/Game/BioShockSlice/1-Medical"):
        failures.append("could not load slice")
        raise RuntimeError("effects_system:\n- " + "\n- ".join(failures))

    world = unreal.EditorLevelLibrary.get_editor_world()
    actors = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    actor = unreal.EditorLevelLibrary.spawn_actor_from_class(
        unreal.StaticMeshActor.static_class(), TEST_LOCATION)
    if actor is None:
        failures.append("could not spawn test actor")
        raise RuntimeError("effects_system:\n- " + "\n- ".join(failures))
    actor.set_actor_label("EffectsTestActor")
    label = unreal.Name("EffectsTestActor")

    fx = unreal.ShockEffectsSubsystem.get_for_world(actor)
    if fx is None:
        failures.append("UShockEffectsSubsystem not available for this world")
        raise RuntimeError("effects_system:\n- " + "\n- ".join(failures))

    try:
        # (a) keyword match -> Steam bundle, not Generic.
        play_cls = _cls("ShockActionPlayEffect")
        play = unreal.new_object(play_cls)
        play.configure(unreal.Name("SteamHiss"), unreal.Name(), label)
        before = fx.get_active_effect_count_for_verify()
        ok_a = play.fire_on_actor(actor)
        after = fx.get_active_effect_count_for_verify()
        resolved = str(fx.get_last_resolved_bundle_key_for_verify())
        check("play_effect_keyword_match", ok_a and after > before and resolved == "Steam", resolved)

        # (b) unrecognised event -> Generic fallback, still spawns something.
        play2 = unreal.new_object(play_cls)
        play2.configure(unreal.Name("Zzz_TotallyUnknownEventName"), unreal.Name(), label)
        before2 = fx.get_active_effect_count_for_verify()
        ok_b = play2.fire_on_actor(actor)
        after2 = fx.get_active_effect_count_for_verify()
        resolved2 = str(fx.get_last_resolved_bundle_key_for_verify())
        check("play_effect_generic_fallback", ok_b and after2 > before2 and resolved2 == "Generic", resolved2)

        # (c) StopEffect tears an instance down.
        stop_cls = _cls("ShockActionStopEffect")
        stop = unreal.new_object(stop_cls)
        stop.configure(unreal.Name("SteamHiss"), unreal.Name(), label)
        before3 = fx.get_active_effect_count_for_verify()
        ok_c = stop.stop_on_actor(actor)
        after3 = fx.get_active_effect_count_for_verify()
        check("stop_effect_tears_down", ok_c and after3 < before3, (before3, after3))

        # (d) SetEffectsSystemContext push/remove, through the action's own ApplyInWorld(World).
        ctx_cls = _cls("ShockActionSetEffectsSystemContext")
        push = unreal.new_object(ctx_cls)
        push.configure(unreal.Name("Underwater"), 0, False, False)
        push_ok = push.apply_in_world(world)
        current = str(fx.get_current_context())
        remove = unreal.new_object(ctx_cls)
        remove.configure(unreal.Name("Underwater"), 0, True, False)
        remove_ok = remove.apply_in_world(world)
        after_remove = str(fx.get_current_context())
        check("effects_context_push_remove",
              push_ok and remove_ok and current == "Underwater" and after_remove != "Underwater",
              (current, after_remove))

        # (e) PlayEffectAndWaitForStart resolves ActorLabel and spawns, through its own
        # ApplyInWorld(World).
        wait_cls = _cls("ShockActionPlayEffectAndWaitForStart")
        wait_action = unreal.new_object(wait_cls)
        wait_action.configure(unreal.Name("ElectricArc"), unreal.Name(), 5.0, label, False, False)
        before4 = fx.get_active_effect_count_for_verify()
        ok_e = wait_action.apply_in_world(world)
        after4 = fx.get_active_effect_count_for_verify()
        check("play_effect_and_wait_spawns", ok_e and after4 > before4, (before4, after4))
    finally:
        actors.destroy_actor(actor)

    report["effects_system"] = "ok" if not failures else "fail"
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
    if failures:
        raise RuntimeError("effects_system:\n- " + "\n- ".join(failures))
    unreal.log("Success - %d/%d checks passed" % (len(report["checks"]), len(report["checks"])))
    return report


if __name__ == "__main__":
    main()
