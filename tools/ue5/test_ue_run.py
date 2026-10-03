"""Unit tests for tools/ue5/ue_run.py and ue_guard.py -- runnable without Unreal.

    python tools/ue5/test_ue_run.py

The generated shim is plain Python, so it is executed here for real against throwaway scripts
(pass, fail, sys.exit, sibling import) and its output fed back through the verdict parser. The
log excerpts below are trimmed from real UE 5.7 -run=pythonscript logs (2 Oct 2026); the full logs
are also read when the session scratchpad that holds them still exists.
"""

import io
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import ue_guard  # noqa: E402
import ue_run  # noqa: E402

SCRATCH = Path(r"C:\Users\Jack\AppData\Local\Temp\claude\C--Users-Jack-Documents-AI-Test"
               r"\9ae00176-5148-4c8e-9fe9-dc9e9d9c6c6f\scratchpad")
SAMPLE_LOGS = {name: SCRATCH / name for name in
               ("probe_beams.log", "repair_beams2.log", "verify_beams3.log")}

TS = "[2026.10.02-21.10.33:149][  0]"

# Trimmed from repair_beams2.log: AttributeError traceback, then UE's closing summary repeating it.
REPAIR_EXCERPT = "\n".join(TS + line for line in [
    "LogPythonScriptCommandlet: Display: Running Python script: C:/Users/Jack/Documents/BioshockHavok/tools/ue5/repair_light_beams.py",
    "MapCheck: Map check complete: 0 Error(s), 0 Warning(s), took 0.636ms to complete.",
    "LogPython: Error: Traceback (most recent call last):",
    'LogPython: Error:   File "C:/Users/Jack/Documents/BioshockHavok/tools/ue5/repair_light_beams.py", line 257, in <module>',
    "LogPython: Error:     main()",
    'LogPython: Error:   File "C:/Users/Jack/Documents/BioshockHavok/tools/ue5/repair_light_beams.py", line 130, in _author_master',
    "LogPython: Error:     near = _create_expression(edit, material, unreal.MaterialExpressionCameraDepthFade, 410, 230)",
    "LogPython: Error: AttributeError: module 'unreal' has no attribute 'MaterialExpressionCameraDepthFade'",
    "LogPythonScriptCommandlet: Error: Python script executed with errors",
    "LogCore: Engine exit requested (reason: Commandlet PythonScriptCommandlet_0 finished execution (result -1))",
    "LogInit: Display: Warning/Error Summary (Unique only)",
    "LogInit: Display: LogPython: Error: Traceback (most recent call last):",
    "LogInit: Display: LogPython: Error: AttributeError: module 'unreal' has no attribute 'MaterialExpressionCameraDepthFade'",
    "LogInit: Display: LogPythonScriptCommandlet: Error: Python script executed with errors",
    "LogExit: Exiting.",
]) + "\nLog file closed, 10/02/26 22:10:33\n"

# Trimmed from probe_beams.log / verify_beams3.log: a clean run with no markers.
PASS_EXCERPT = "\n".join(TS + line for line in [
    "LogPythonScriptCommandlet: Display: Running Python script: C:/Users/Jack/Documents/BioshockHavok/tools/ue5/verify_light_beams.py",
    'Cmd: MAP LOAD FILE="C:/Users/Jack/Documents/BioShockUE5/Content/BioShockSlice/1-Medical.umap" TEMPLATE=0 SHOWPROGRESS=1 FEATURELEVEL=4',
    "LogPython: [probe-beams] wrote C:\\Users\\Jack\\AppData\\Local\\Temp\\probe_beams.json",
    "LogPythonScriptCommandlet: Display: Python script executed successfully",
    "LogInit: Display: Success - 0 error(s), 0 warning(s)",
    "LogExit: Exiting.",
]) + "\nLog file closed, 10/02/26 22:06:07\n"


def marker(kind, payload):
    return "%sLogPython: UE_RUN_%s %s" % (TS, kind, json.dumps(payload))


def synthetic_log(body_lines, closed=True, commandlet_ok=True):
    head = [TS + "LogPythonScriptCommandlet: Display: Running Python script: "
            "C:/Users/Jack/Documents/BioShockUE5/Saved/ue_run/x_shim.py"]
    tail = []
    if commandlet_ok is not None:
        tail.append(TS + "LogPythonScriptCommandlet: Display: Python script executed successfully")
    if closed:
        tail += [TS + "LogExit: Exiting.", "Log file closed, 10/02/26 22:06:07"]
    return "\n".join(head + body_lines + tail) + "\n"


# ---------------------------------------------------------------- arguments + MSYS


class ArgumentTests(unittest.TestCase):
    def quiet(self, argv):
        return ue_run.parse_args(argv, warn=lambda *_: None)

    def test_defaults(self):
        args = self.quiet(["verify_water"])
        self.assertEqual(args.scripts, ["verify_water"])
        self.assertEqual(args.timeout, 1800)
        self.assertEqual(args.wait, 0)
        self.assertFalse(args.render)
        self.assertFalse(args.dry_run)
        self.assertEqual(args.env_pairs, {})
        self.assertEqual(args.uproject, ue_run.DEFAULT_UPROJECT)

    def test_all_flags(self):
        args = self.quiet(["a", "b.py", "--suite", "medical-core", "--render", "--env", "X=1",
                           "--env", "Y=a=b", "--log", "C:/l.log", "--timeout", "60",
                           "--wait", "30", "--dry-run", "--uproject", "C:/p.uproject",
                           "--engine", "D:/UE"])
        self.assertEqual(args.scripts, ["a", "b.py"])
        self.assertEqual(args.suite, "medical-core")
        self.assertTrue(args.render and args.dry_run)
        self.assertEqual(args.env_pairs, {"X": "1", "Y": "a=b"})
        self.assertEqual((args.timeout, args.wait), (60, 30))

    def test_needs_script_or_suite(self):
        with self.assertRaises(SystemExit), _silence_stderr():
            self.quiet([])

    def test_bad_env(self):
        with self.assertRaises(SystemExit), _silence_stderr():
            self.quiet(["a", "--env", "NOEQUALS"])

    def test_mangled_env_repaired_with_warning(self):
        warnings = []
        args = ue_run.parse_args(
            ["verify_water", "--env", "BIOSHOCK_WATER_MAP=C:/Program Files/Git/Game/BioShockSlice/1-Medical"],
            warn=warnings.append)
        self.assertEqual(args.env_pairs["BIOSHOCK_WATER_MAP"], "/Game/BioShockSlice/1-Medical")
        self.assertEqual(len(warnings), 1)
        self.assertIn("MSYS", warnings[0])


class MsysRepairTests(unittest.TestCase):
    P = ["C:/Program Files/Git"]

    def fix(self, value, prefixes=None):
        return ue_run.repair_msys(value, self.P if prefixes is None else prefixes)

    def test_default_install(self):
        self.assertEqual(self.fix("C:/Program Files/Git/Game/BioShockSlice/1-Medical"),
                         ("/Game/BioShockSlice/1-Medical", True))

    def test_key_value_and_script_path(self):
        self.assertEqual(
            self.fix("game=C:/Program Files/Git/Script/BioShockRuntime.ShockGameMode")[0],
            "game=/Script/BioShockRuntime.ShockGameMode")

    def test_lists_and_case(self):
        self.assertEqual(
            self.fix("c:/program files/git/Game/A,C:/Program Files/Git/Game/B")[0], "/Game/A,/Game/B")

    def test_backslash_form(self):
        self.assertEqual(self.fix("C:\\Program Files\\Git\\Game\\A\\B")[0], "/Game/A/B")

    def test_other_install_found_by_git_dir(self):
        self.assertEqual(self.fix("D:/Tools/Git/Game/X", prefixes=[])[0], "/Game/X")

    def test_explicit_odd_prefix(self):
        self.assertEqual(
            self.fix("C:/Users/Jack/scoop/apps/git/current/Engine/BasicShapes/Cube",
                     prefixes=["C:/Users/Jack/scoop/apps/git/current"])[0],
            "/Engine/BasicShapes/Cube")

    def test_leaves_real_paths_alone(self):
        for value in ("/Game/BioShockSlice/1-Medical", "C:/Users/Jack/Documents/x.py",
                      "G:/Games/UE_5.7/Engine/Binaries/Win64/UnrealEditor-Cmd.exe",
                      "C:/Program Files/Git/usr/bin/bash.exe", "verify_water", "", "X=1"):
            self.assertEqual(self.fix(value), (value, False), value)

    def test_real_prefix_discovery_includes_default(self):
        prefixes = [p.lower() for p in ue_run._git_prefixes()]
        self.assertIn("c:/program files/git", prefixes)


# ---------------------------------------------------------------- resolution


class ResolutionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.repo = root / "checkout"
        self.tools = self.repo / "tools" / "ue5"
        (self.tools / "suites").mkdir(parents=True)
        (self.tools / "ue_run.py").write_text("# marker\n")
        (self.tools / "verify_water.py").write_text("pass\n")
        (self.tools / "verify_door.py").write_text("pass\n")
        (self.tools / "suites" / "mini.txt").write_text(
            "# header\n\nverify_water   # trailing comment\n  verify_door.py\n")
        self.elsewhere = root / "elsewhere"
        self.elsewhere.mkdir()
        (self.elsewhere / "probe.py").write_text("pass\n")

    def tearDown(self):
        self.tmp.cleanup()

    def test_bare_name_and_file_name(self):
        want = (self.tools / "verify_water.py").resolve()
        self.assertEqual(ue_run.resolve_script("verify_water", self.tools, self.elsewhere), want)
        self.assertEqual(ue_run.resolve_script("verify_water.py", self.tools, self.elsewhere), want)

    def test_paths(self):
        probe = (self.elsewhere / "probe.py").resolve()
        self.assertEqual(ue_run.resolve_script(str(probe), self.tools), probe)
        self.assertEqual(ue_run.resolve_script("./probe.py", self.tools, self.elsewhere), probe)
        self.assertEqual(ue_run.resolve_script(str(probe).replace("\\", "/"), self.tools), probe)

    def test_missing_suggests(self):
        with self.assertRaises(ue_run.ResolveError) as ctx:
            ue_run.resolve_script("verify_watr", self.tools, self.elsewhere)
        self.assertIn("verify_water", str(ctx.exception))

    def test_checkout_from_cwd_wins(self):
        inner = self.repo / "src" / "deep"
        inner.mkdir(parents=True)
        self.assertEqual(ue_run.checkout_tools_dir(cwd=inner, here=HERE), self.tools)
        self.assertEqual(ue_run.checkout_tools_dir(cwd=self.tools, here=HERE), self.tools)
        self.assertEqual(ue_run.checkout_tools_dir(cwd=self.elsewhere, here=HERE), HERE)

    def test_suite_file(self):
        tokens, path = ue_run.read_suite("mini", self.tools)
        self.assertEqual(tokens, ["verify_water", "verify_door.py"])
        self.assertEqual(ue_run.read_suite(str(path), self.tools)[0], tokens)
        with self.assertRaises(ue_run.ResolveError):
            ue_run.read_suite("nope", self.tools)

    def test_real_medical_core_suite_resolves(self):
        tokens, _ = ue_run.read_suite("medical-core", HERE)
        self.assertEqual(tokens, ["verify_gameplay_fidelity", "verify_scripting_movers",
                                  "verify_vita_chamber", "verify_import_scripts", "verify_water"])
        for token in tokens:
            path = ue_run.resolve_script(token, HERE)
            source = path.read_text(encoding="utf-8")
            self.assertIn('if __name__ == "__main__":', source, token)

    def test_engine_resolution(self):
        exe = Path("D:/x/UnrealEditor-Cmd.exe")
        self.assertEqual(ue_run.resolve_engine(str(exe)), exe)
        self.assertEqual(ue_run.resolve_engine("Z:/NoEngine").name, "UnrealEditor-Cmd.exe")


# ---------------------------------------------------------------- shim + command


class ShimTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        d = Path(self.tmp.name) / "scripts dir"
        d.mkdir()
        (d / "helper_mod.py").write_text("VALUE = 42\n")
        scripts = {
            "ok.py": 'import helper_mod\nif __name__ == "__main__":\n    assert helper_mod.VALUE == 42\n',
            "boom.py": 'def main():\n    raise RuntimeError("water:\\n- no surface\\n- bad pan")\n'
                       'if __name__ == "__main__":\n    main()\n',
            "exit0.py": "import sys\nsys.exit(0)\n",
            "exit3.py": "import sys\nsys.exit(3)\n",
            "notmain.py": 'if __name__ != "__main__":\n    raise SystemExit("not run as __main__")\n',
        }
        self.paths = []
        for name, body in scripts.items():
            (d / name).write_text(body)
            self.paths.append(d / name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_shim_compiles_and_lists_scripts(self):
        shim = ue_run.generate_shim(self.paths)
        compile(shim, "shim.py", "exec")
        for path in self.paths:
            self.assertIn(str(path).replace("\\", "/"), shim)

    def test_shim_runs_and_verdict_reads_it(self):
        shim_path = Path(self.tmp.name) / "shim.py"
        shim_path.write_text(ue_run.generate_shim(self.paths), encoding="utf-8")
        done = subprocess.run([sys.executable, str(shim_path)], capture_output=True, text=True,
                              timeout=60, cwd=self.tmp.name)
        self.assertEqual(done.returncode, 0, done.stderr)
        parsed = ue_run.parse_log(done.stdout)
        self.assertTrue(parsed["done"])
        status = {r["script"]: r for r in parsed["results"]}
        self.assertEqual(status["ok.py"]["status"], "pass")  # sibling import worked
        self.assertEqual(status["exit0.py"]["status"], "pass")
        self.assertEqual(status["notmain.py"]["status"], "pass")
        self.assertEqual(status["exit3.py"]["status"], "fail")
        self.assertEqual(status["exit3.py"]["error"], "SystemExit: 3")
        self.assertEqual(status["boom.py"]["status"], "fail")
        self.assertEqual(status["boom.py"]["error"], "RuntimeError: water: | - no surface | - bad pan")
        self.assertIn("Traceback", done.stderr)  # inside UE this lands as LogPython: Error lines
        code, lines = ue_run.verdict(parsed, self.paths, "x.log")
        self.assertEqual(code, 1)
        self.assertTrue(lines[-1].startswith("UE_RUN FAIL 3/5  log=x.log"))

    def test_command(self):
        cmd = ue_run.build_command(Path(r"G:\UE\UnrealEditor-Cmd.exe"),
                                   Path(r"C:\P\P.uproject"), Path(r"C:\P\Saved\ue_run\s.py"),
                                   Path(r"C:\P\Saved\ue_run\s.log"))
        self.assertEqual(cmd[1:], ["C:/P/P.uproject", "-run=pythonscript",
                                   "-script=C:/P/Saved/ue_run/s.py", "-unattended", "-nopause",
                                   "-nosplash", "-nullrhi", "-abslog=C:/P/Saved/ue_run/s.log"])
        rendered = ue_run.build_command("e.exe", "p", "s", "l", render=True)
        self.assertNotIn("-nullrhi", rendered)

    def test_label_is_plain(self):
        class A:
            suite = None
        self.assertEqual(ue_run._label(A(), ["x/verify_water.py", "y/verify_door.py"]),
                         "verify_water_plus1")

    def test_child_environment_repairs_and_overrides(self):
        os.environ["UE_RUN_TEST_MANGLED"] = "C:/Program Files/Git/Game/A"
        try:
            env = ue_run.child_environment({"EXTRA": "1"}, warn=lambda *_: None)
        finally:
            del os.environ["UE_RUN_TEST_MANGLED"]
        self.assertEqual(env["UE_RUN_TEST_MANGLED"], "/Game/A")
        self.assertEqual(env["EXTRA"], "1")


# ---------------------------------------------------------------- verdict parsing


class VerdictTests(unittest.TestCase):
    def test_excerpt_pass_without_markers_is_infra(self):
        parsed = ue_run.parse_log(PASS_EXCERPT)
        self.assertEqual((parsed["done"], parsed["commandlet"], parsed["closed"]),
                         (False, "success", True))
        self.assertEqual(parsed["relevant"], [])
        code, lines = ue_run.verdict(parsed, ["verify_light_beams.py"], "l.log")
        self.assertEqual(code, 2)
        self.assertIn("[infra]", lines[-1])

    def test_excerpt_traceback(self):
        parsed = ue_run.parse_log(REPAIR_EXCERPT)
        self.assertEqual(parsed["commandlet"], "errors")
        attr = [l for l in parsed["relevant"] if "AttributeError" in l]
        self.assertEqual(len(attr), 1, "summary repeat must be dropped")
        code, lines = ue_run.verdict(parsed, ["repair_light_beams.py"], "l.log")
        self.assertEqual(code, 2)
        self.assertTrue(any("MaterialExpressionCameraDepthFade" in l for l in lines))
        self.assertFalse(any(l.lstrip().startswith("[2026") for l in lines),
                         "timestamps stripped from evidence")

    @unittest.skipUnless(all(p.is_file() for p in SAMPLE_LOGS.values()), "sample logs not present")
    def test_full_sample_logs(self):
        read = lambda n: SAMPLE_LOGS[n].read_text(encoding="utf-8", errors="replace")  # noqa: E731
        probe = ue_run.parse_log(read("probe_beams.log"))
        verify = ue_run.parse_log(read("verify_beams3.log"))
        repair = ue_run.parse_log(read("repair_beams2.log"))
        self.assertEqual([probe["commandlet"], verify["commandlet"], repair["commandlet"]],
                         ["success", "success", "errors"])
        self.assertTrue(probe["closed"] and verify["closed"] and repair["closed"])
        self.assertFalse(any(p["done"] or p["results"] for p in (probe, verify, repair)))
        self.assertEqual(probe["relevant"], [])
        self.assertEqual(verify["relevant"], [])
        self.assertEqual(sum("AttributeError" in l for l in repair["relevant"]), 1)
        self.assertTrue(repair["relevant"][-1].endswith("Python script executed with errors"))

    def test_synthetic_pass(self):
        log = synthetic_log([
            marker("START", {"script": "verify_water.py"}),
            marker("RESULT", {"script": "verify_water.py", "status": "pass", "seconds": 12.3, "error": ""}),
            marker("START", {"script": "verify_door.py"}),
            marker("RESULT", {"script": "verify_door.py", "status": "pass", "seconds": 4, "error": ""}),
            marker("DONE", {"passed": 2, "total": 2}),
        ])
        code, lines = ue_run.verdict(ue_run.parse_log(log), ["a/verify_water.py", "b/verify_door.py"],
                                     "C:\\S\\x.log")
        self.assertEqual(code, 0)
        self.assertTrue(lines[0].startswith("PASS  verify_water.py"))
        self.assertIn("12.3s", lines[0])
        self.assertTrue(lines[-1].startswith("UE_RUN PASS 2/2  log=C:/S/x.log"))
        self.assertTrue(lines[-1].endswith(ue_run.NULLRHI_NOTE))
        code, lines = ue_run.verdict(ue_run.parse_log(log), ["verify_water.py", "verify_door.py"],
                                     "x.log", nullrhi=False)
        self.assertNotIn("nullrhi", lines[-1])

    def test_synthetic_fail(self):
        log = synthetic_log([
            marker("START", {"script": "verify_water.py"}),
            TS + "LogPython: Error: Traceback (most recent call last):",
            TS + "LogPython: Error: RuntimeError: water: | - no surface",
            marker("RESULT", {"script": "verify_water.py", "status": "fail", "seconds": 3.0,
                              "error": "RuntimeError: water: | - no surface"}),
            marker("START", {"script": "verify_door.py"}),
            marker("RESULT", {"script": "verify_door.py", "status": "pass", "seconds": 1.0, "error": ""}),
            marker("DONE", {"passed": 1, "total": 2}),
        ])
        code, lines = ue_run.verdict(ue_run.parse_log(log), ["verify_water.py", "verify_door.py"], "x.log")
        self.assertEqual(code, 1)
        self.assertTrue(lines[0].startswith("FAIL  verify_water.py"))
        self.assertIn("RuntimeError: water: | - no surface", lines[0])
        self.assertTrue(lines[-1].startswith("UE_RUN FAIL 1/2"))
        self.assertNotIn("INFRA", "\n".join(lines))

    def test_synthetic_crash_without_done(self):
        log = synthetic_log([
            marker("START", {"script": "verify_water.py"}),
            marker("RESULT", {"script": "verify_water.py", "status": "pass", "seconds": 2.0, "error": ""}),
            marker("START", {"script": "verify_vita_chamber.py"}),
            TS + "LogWindows: Error: === Critical error: ===",
            TS + "LogWindows: Error: Fatal error: [File:D:/build/Engine/Source/Runtime/Core/Private/X.cpp] [Line: 10]",
            TS + "LogWindows: Error: Assertion failed: IsValid(Player)",
            TS + 'LogPython: Error:     print("UE_RUN_DONE " + json.dumps(x))',  # quoted source is not a marker
        ], closed=False, commandlet_ok=None)
        expected = ["verify_water.py", "verify_vita_chamber.py", "verify_door.py"]
        code, lines = ue_run.verdict(ue_run.parse_log(log), expected, "x.log")
        text = "\n".join(lines)
        self.assertEqual(code, 2)
        self.assertIn("PASS  verify_water.py", text)
        self.assertIn("verify_vita_chamber.py", text)
        self.assertIn("started, never finished", text)
        self.assertIn("not reached", text)
        self.assertIn("INFRA FAILURE", text)
        self.assertIn("Assertion failed: IsValid(Player)", text)
        self.assertTrue(lines[-1].startswith("UE_RUN FAIL 1/3"))
        self.assertIn("[infra]", lines[-1])

    def test_timeout_is_infra_even_with_markers(self):
        log = synthetic_log([marker("DONE", {"passed": 0, "total": 0})])
        code, lines = ue_run.verdict(ue_run.parse_log(log), [], "x.log",
                                     infra_cause="timeout after 5s - killed our UnrealEditor-Cmd (pid 1)")
        self.assertEqual(code, 2)
        self.assertIn("timeout after 5s", "\n".join(lines))

    def test_missing_result_with_done_is_fail(self):
        log = synthetic_log([marker("DONE", {"passed": 0, "total": 1})])
        code, lines = ue_run.verdict(ue_run.parse_log(log), ["verify_water.py"], "x.log")
        self.assertEqual(code, 1)
        self.assertIn("not reached", lines[0])


# ---------------------------------------------------------------- guard


class GuardTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.lock = Path(self.tmp.name) / "Saved" / "ue_run.lock"
        self.sleeper = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(120)"])

    def tearDown(self):
        self.sleeper.kill()
        self.sleeper.wait()
        self.tmp.cleanup()

    def guard(self, task, owner, **kw):
        return ue_guard.UnrealGuard(task, owner_pid=owner, path=self.lock, out=io.StringIO(),
                                    check_processes=False, **kw)

    def test_tasklist_parse_and_classify(self):
        text = ('"System","4","Services","0","15,632 K"\n'
                '"UnrealEditor.exe","1234","Console","1","4,000,000 K"\n'
                '"UnrealEditor-Cmd.exe","2345","Console","1","2,000 K"\n'
                '"dotnet.exe","3456","Console","1","90 K"\n'
                '"dotnet.exe","4567","Console","1","90 K"\n'
                '"UnrealBuildTool.exe","5678","Console","1","90 K"\n')
        rows = ue_guard.parse_tasklist_csv(text)
        self.assertEqual(rows[1], ("UnrealEditor.exe", 1234))
        cmd = {3456: r'"G:\UE\dotnet.exe" "G:\UE\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.dll" UnrealEditor',
               4567: r'"C:\Program Files\dotnet\dotnet.exe" test BioShockStudio.Tests'}
        found = ue_guard.classify_processes(rows, cmd)
        self.assertEqual([(p["pid"], p["kind"]) for p in found],
                         [(1234, "editor"), (2345, "editor"), (3456, "build"), (5678, "build")])
        self.assertEqual(len(ue_guard.classify_processes(rows, None)), 3)

    def test_reasons(self):
        editor = [{"pid": 1234, "name": "UnrealEditor.exe", "kind": "editor"}]
        rebuild = ue_guard.process_reason("rebuild", editor)
        self.assertIn("1234", rebuild)
        self.assertIn("DLL", rebuild)
        self.assertIn("never kill", ue_guard.process_reason("run", editor))
        self.assertIsNone(ue_guard.process_reason("run", []))
        self.assertIsNone(ue_guard.busy_reason("run", path=self.lock, procs=[]))

    def test_pid_alive(self):
        self.assertTrue(ue_guard.pid_alive(os.getpid()))
        self.assertTrue(ue_guard.pid_alive(self.sleeper.pid))
        created = ue_guard._process_created(self.sleeper.pid)
        self.assertTrue(ue_guard.pid_alive(self.sleeper.pid, created))
        self.assertFalse(ue_guard.pid_alive(self.sleeper.pid, created + 1), "pid reuse detected")
        dead = subprocess.Popen([sys.executable, "-c", "pass"])
        dead.wait()
        self.assertFalse(ue_guard.pid_alive(dead.pid))

    def test_acquire_busy_release(self):
        holder = self.guard("ue_run verify_water", self.sleeper.pid)
        holder.acquire()
        data = ue_guard.read_lock(self.lock)
        self.assertEqual(data["pid"], self.sleeper.pid)
        self.assertEqual(data["task"], "ue_run verify_water")
        self.assertIn("started", data)
        self.assertIn("cwd", data)
        with self.assertRaises(ue_guard.GuardBusy) as ctx:
            self.guard("capture", os.getpid()).acquire()
        self.assertIn(str(self.sleeper.pid), ctx.exception.reason)
        self.assertIn("ue_run verify_water", ctx.exception.reason)
        self.assertIn("held by", ue_guard.busy_reason("capture", path=self.lock, procs=[]))
        self.assertFalse(ue_guard.release(os.getpid(), path=self.lock), "only the owner releases")
        self.assertTrue(holder.release())
        self.assertIsNone(ue_guard.read_lock(self.lock))

    def test_wait_then_busy(self):
        self.guard("a", self.sleeper.pid).acquire()
        started = time.time()
        with self.assertRaises(ue_guard.GuardBusy):
            self.guard("b", os.getpid(), wait_seconds=1).acquire()
        self.assertGreaterEqual(time.time() - started, 0.9)

    def test_stale_lock_taken_over_with_note(self):
        dead = subprocess.Popen([sys.executable, "-c", "pass"])
        dead.wait()
        self.guard("crashed capture", dead.pid).acquire()
        taker = self.guard("ue_run x", os.getpid())
        taker.acquire()
        self.assertIn("stale", taker.out.getvalue())
        self.assertEqual(ue_guard.read_lock(self.lock)["pid"], os.getpid())
        taker.release()

    def test_corrupt_lock_is_stale(self):
        self.lock.parent.mkdir(parents=True, exist_ok=True)
        self.lock.write_text("{not json")
        with self.guard("x", os.getpid()) as held:
            self.assertTrue(held.held)
        self.assertIsNone(ue_guard.read_lock(self.lock))

    def test_adopt_hands_lock_to_child(self):
        self.guard("capture_shot", os.getpid()).acquire()
        self.assertTrue(ue_guard.adopt(os.getpid(), self.sleeper.pid, path=self.lock))
        self.assertEqual(ue_guard.read_lock(self.lock)["pid"], self.sleeper.pid)
        self.assertTrue(ue_guard.lock_is_live(ue_guard.read_lock(self.lock)))
        self.sleeper.kill()
        self.sleeper.wait()
        self.assertFalse(ue_guard.lock_is_live(ue_guard.read_lock(self.lock)),
                         "lock dies with the adopted process")
        self.assertFalse(ue_guard.adopt(12345678, 1, path=self.lock))

    def test_cli_release_force_and_acquire(self):
        old = os.environ.get("UE_GUARD_LOCK")
        os.environ["UE_GUARD_LOCK"] = str(self.lock)
        try:
            self.guard("x", self.sleeper.pid).acquire()
            with _silence_stdout():
                self.assertEqual(ue_guard.main(["release", "--force"]), 0)
            self.assertIsNone(ue_guard.read_lock(self.lock))
        finally:
            if old is None:
                del os.environ["UE_GUARD_LOCK"]
            else:
                os.environ["UE_GUARD_LOCK"] = old


class ReferenceGeneratorTests(unittest.TestCase):
    def setUp(self):
        import gen_ue_reference
        self.gen = gen_ue_reference
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_switches_direct_multiline_and_helper(self):
        src = self.root / "Source" / "Private"
        src.mkdir(parents=True)
        (src / "A.cpp").write_text(textwrap_dedent('''
            bool ParseVec(const TCHAR* Key, FVector& Out)
            {
                FString Value;
                if (!FParse::Value(FCommandLine::Get(), Key, Value, false)) { return false; }
                return true;
            }
            void F()
            {
                if (FParse::Param(FCommandLine::Get(), TEXT("bioshockflag"))) {}
                FParse::Value(
                    FCommandLine::Get(),
                    TEXT("bioshockdelay="),
                    Delay);
                ParseVec(TEXT("bioshockstart="), Start);
                UE_LOG(LogTemp, Display, TEXT("bioshock_not_a_switch"));
                UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_AI state"));
            }
            '''))
        found = self.gen.collect_switches(self.root / "Source")
        self.assertEqual(sorted(found), ["bioshockdelay=", "bioshockflag", "bioshockstart="])
        self.assertEqual(found["bioshockflag"][0]["how"], "FParse::Param")
        self.assertEqual(found["bioshockdelay="][0]["how"], "FParse::Value")
        self.assertEqual(found["bioshockstart="][0]["how"], "FParse::Value via ParseVec()")
        self.assertEqual(found["bioshockflag"][0]["file"], "Private/A.cpp")

    def test_api_scan_skips_strings_and_comments(self):
        script = self.root / "probe.py"
        script.write_text(textwrap_dedent('''
            import unreal
            # unreal.NotReal in a comment
            text = "unreal.AlsoNotReal in a string"
            lib = unreal.EditorAssetLibrary.load_asset("/Game/X")
            rot = unreal.Rotator(pitch=0.0, yaw=90.0, roll=0.0)
            unreal.log("hi")
            comp.set_editor_property("relative_scale3d", unreal.Vector(1, 1, 1))
            if hasattr(unreal, "MaybeThing"):
                pass
            '''))
        uses, props, guarded = self.gen.collect_api([script])
        self.assertEqual(sorted(uses), ["unreal.EditorAssetLibrary.load_asset", "unreal.Rotator",
                                        "unreal.Vector", "unreal.log"])
        self.assertIn("relative_scale3d", props)
        self.assertIn("unreal.MaybeThing", guarded)

    def test_missing_from_logs(self):
        log = self.root / "x.log"
        log.write_text(REPAIR_EXCERPT + TS + "LogPython: Error: Exception: StaticMeshComponent: "
                       "Failed to find property 'bogus' for attribute 'bogus' on 'StaticMeshComponent'\n")
        missing = self.gen.collect_missing([log])
        self.assertIn("unreal.MaterialExpressionCameraDepthFade", missing)
        self.assertIn("property bogus on StaticMeshComponent", missing)

    def test_end_to_end_writes_both_pages(self):
        out = self.root / "refs"
        with _silence_stdout():
            self.assertEqual(self.gen.main([str(out)]), 0)
        switches = (out / "bioshock-switches.md").read_text(encoding="utf-8")
        api = (out / "unreal-api-in-use.md").read_text(encoding="utf-8")
        self.assertIn("`-bioshockscreenshot`", switches)
        self.assertIn("`unreal.EditorAssetLibrary`", api)


def textwrap_dedent(text):
    import textwrap
    return textwrap.dedent(text).lstrip("\n")


class UeRepoReportTests(unittest.TestCase):
    def test_reports_only_files_the_run_dirtied(self):
        lines = ue_run.ue_repo_report({"Content/A.uasset"}, {"Content/A.uasset", "Content/B.umap"},
                                      Path("C:/UE"))
        self.assertEqual(len(lines), 2)
        self.assertIn("changed 1 tracked file", lines[0])
        self.assertIn("Content/B.umap", lines[1])

    def test_silent_when_nothing_new_or_unknown(self):
        self.assertEqual(ue_run.ue_repo_report({"x"}, {"x"}, Path("C:/UE")), [])
        self.assertEqual(ue_run.ue_repo_report(None, {"x"}, Path("C:/UE")), [])
        self.assertEqual(ue_run.ue_repo_report(set(), None, Path("C:/UE")), [])

    def test_real_git_repo_detects_a_modified_tracked_file(self):
        with tempfile.TemporaryDirectory() as root:
            git = ["git", "-C", root, "-c", "user.name=t", "-c", "user.email=t@t"]
            subprocess.run(git[:3] + ["init", "-q"], check=True)
            Path(root, "a.txt").write_text("1")
            subprocess.run(git + ["add", "a.txt"], check=True)
            subprocess.run(git + ["commit", "-qm", "c"], check=True)
            before = ue_run.ue_repo_dirty(root)
            Path(root, "a.txt").write_text("2")
            after = ue_run.ue_repo_dirty(root)
            self.assertEqual(before, set())
            self.assertEqual(after, {"a.txt"})
        self.assertIsNone(ue_run.ue_repo_dirty(Path(tempfile.gettempdir()) / "no-such-dir-xyz"))


class _silence_stderr:
    def __enter__(self):
        self.old, sys.stderr = sys.stderr, io.StringIO()

    def __exit__(self, *exc):
        sys.stderr = self.old


class _silence_stdout:
    def __enter__(self):
        self.old, sys.stdout = sys.stdout, io.StringIO()

    def __exit__(self, *exc):
        sys.stdout = self.old


if __name__ == "__main__":
    unittest.main()
