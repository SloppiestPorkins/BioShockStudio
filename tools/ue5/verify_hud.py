"""Headless verify: player HUD widget shows live health + weapon ammo, updates on damage."""

import json
import os

import unreal


def _log(message):
    unreal.log("[bioshock-hud] %s" % message)


def main(out):
    report = {"failures": []}
    failures = report["failures"]

    hud_cls = unreal.load_class(None, "/Script/BioShockRuntime.ShockHudWidget")
    if not hud_cls:
        failures.append("ShockHudWidget class missing")
        _write(out, report)
        raise RuntimeError("hud:\n- " + "\n- ".join(failures))

    world = unreal.EditorLevelLibrary.get_editor_world()
    ok = bool(unreal.ShockHudWidget.run_headless_hud_verify(world))
    err = str(unreal.ShockHudWidget.get_last_hud_verify_error())
    report["verify"] = {"ok": ok, "error": err}
    if not ok:
        failures.append("RunHeadlessHudVerify: %s" % (err or "failed"))

    report["hud"] = "ok" if not failures else "fail"
    _write(out, report)
    if failures:
        raise RuntimeError("hud:\n- " + "\n- ".join(failures))
    _log("PASS hud")
    return report


def _write(out, report):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)


if __name__ == "__main__":
    main(
        os.environ.get(
            "BIOSHOCK_ACTION_OUT",
            os.path.join(os.environ.get("TEMP", "."), "hud_report.json"),
        )
    )
