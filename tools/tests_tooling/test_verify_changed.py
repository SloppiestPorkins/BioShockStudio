"""Tests for tools/verify_changed.py: class/tier scanning, output parsing, verdicts. No dotnet.

    python -m unittest discover -s tools/tests_tooling
"""

from __future__ import annotations

import contextlib
import io
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_changed as vc  # noqa: E402

SOURCE = '''using Xunit;

namespace BioShockStudio.Tests;

/// <summary>Docs between the attributes and the class must not lose the tier.</summary>
[Collection(GameCollection.Name)]
[Trait(Tiers.Name, Tiers.Sweep)]
/// <remarks>more docs</remarks>
public sealed partial class SweepThingTests(GameFixture game)
{
    [RequiresGameFact]
    public void A() { }
}

internal sealed class Helper
{
    public int X;
}

[Trait("Tier", "Fast")]
public class FastThingTests
{
    [AvaloniaFact]
    public void B() { }
}
'''

PASS_OUTPUT = """\
Test run for C:\\repo\\tests\\BioShockStudio.Tests\\bin\\Debug\\net8.0\\BioShockStudio.Tests.dll (.NETCoreApp,Version=v8.0)
Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:   412, Skipped:     3, Total:   415, Duration: 2 m 31 s - BioShockStudio.Tests.dll (net8.0)
"""

FAIL_OUTPUT = """\
Starting test execution, please wait...
  Failed BioShockStudio.Tests.CubemapTests.MedicalCubemapsDecode [41 ms]
  Error Message:
   Assert.Equal() Failure
  Stack Trace:
     at BioShockStudio.Tests.CubemapTests.MedicalCubemapsDecode() in C:\\x.cs:line 9
  Failed BioShockStudio.Tests.MaterialAnimatorTests.Pans(name: "a b") [3 ms]
  Error Message:
   boom

Failed!  - Failed:     2, Passed:   410, Skipped:     3, Total:   415, Duration: 2 m 29 s - BioShockStudio.Tests.dll (net8.0)
"""

NO_MATCH_OUTPUT = """\
No test matches the given testcase filter `FullyQualifiedName~X.` in C:\\repo\\BioShockStudio.Tests.dll
"""

BUILD_FAIL_OUTPUT = """\
C:\\repo\\src\\A.cs(10,5): error CS1002: ; expected [C:\\repo\\src\\A.csproj]
C:\\repo\\src\\A.cs(10,5): error CS1002: ; expected [C:\\repo\\src\\A.csproj]
warning MSB3026: Could not copy "obj\\A.dll". The process cannot access the file because it is being used by another process.
error MSB3027: Could not copy "obj\\A.dll" to "bin\\A.dll". Exceeded retry count of 10.
"""


class ScanTests(unittest.TestCase):
    def test_scan_classes_reads_tiers_and_test_presence(self):
        found = {name: (tier, has) for name, tier, has in vc.scan_classes(SOURCE)}
        self.assertEqual(found["SweepThingTests"], ("Sweep", True))
        self.assertEqual(found["Helper"], (None, False))
        self.assertEqual(found["FastThingTests"], ("Fast", True))

    def test_filter_has_trailing_dot(self):
        c = vc.TestClass("FooTests", "BioShockStudio.Tests")
        self.assertEqual(c.filter, "FullyQualifiedName~BioShockStudio.Tests.FooTests.")

    def test_uncovered_classes_skips_fast_and_helpers(self):
        classes = {
            "SweepThingTests": vc.TestClass("SweepThingTests", "N", "Sweep", True, {"tests/a.cs"}),
            "FastThingTests": vc.TestClass("FastThingTests", "N", "Fast", True, {"tests/a.cs"}),
            "Helper": vc.TestClass("Helper", "N", None, False, {"tests/a.cs"}),
            "Untiered": vc.TestClass("Untiered", "N", None, True, {"tests/a.cs"}),
            "Other": vc.TestClass("Other", "N", "Sweep", True, {"tests/b.cs"}),
        }
        names = [c.name for c in vc.uncovered_classes(["tests/a.cs"], classes)]
        self.assertEqual(names, ["SweepThingTests", "Untiered"])

    def test_is_watched(self):
        self.assertTrue(vc.is_watched("src/BioShockStudio.Core/A.cs"))
        self.assertTrue(vc.is_watched("tests/BioShockStudio.Tests/A.cs"))
        self.assertFalse(vc.is_watched("tools/ue5/a.py"))
        self.assertFalse(vc.is_watched("tests/BioShockStudio.Tests/obj/Debug/x.cs"))


class ParseTests(unittest.TestCase):
    def test_pass(self):
        result = vc.parse_test_output("Fast tier", 0, PASS_OUTPUT.splitlines())
        self.assertEqual(result.totals(), {"failed": 0, "passed": 412, "skipped": 3, "total": 415})
        ok, text = vc.describe(result)
        self.assertTrue(ok)
        self.assertIn("412 passed, 0 failed, 3 skipped", text)

    def test_fail_lists_test_names(self):
        result = vc.parse_test_output("Fast tier", 1, FAIL_OUTPUT.splitlines())
        self.assertEqual(result.failed_tests, [
            "BioShockStudio.Tests.CubemapTests.MedicalCubemapsDecode",
            'BioShockStudio.Tests.MaterialAnimatorTests.Pans(name: "a b")'])
        ok, text = vc.describe(result)
        self.assertFalse(ok)
        self.assertIn("2 failed", text)
        self.assertIn("CubemapTests.MedicalCubemapsDecode", text)

    def test_no_match_and_missing_summary_are_failures(self):
        ok, text = vc.describe(vc.parse_test_output("x", 0, NO_MATCH_OUTPUT.splitlines()))
        self.assertFalse(ok)
        self.assertIn("no test matched", text)
        ok, text = vc.describe(vc.parse_test_output("x", 3, ["crashed"]))
        self.assertFalse(ok)
        self.assertIn("aborted", text)

    def test_all_skipped_is_not_a_pass(self):
        line = ("Passed!  - Failed:     0, Passed:     0, Skipped:    40, Total:    40, "
                "Duration: 1 s - BioShockStudio.Tests.dll (net8.0)")
        ok, text = vc.describe(vc.parse_test_output("x", 0, [line]))
        self.assertFalse(ok)
        self.assertIn("nothing actually ran", text)

    def test_build_errors_and_lock(self):
        result = vc.parse_test_output("build", 1, BUILD_FAIL_OUTPUT.splitlines())
        self.assertEqual(len(result.errors), 2)  # duplicate CS1002 collapsed, MSB3027 kept
        self.assertTrue(result.locked)


class MainTests(unittest.TestCase):
    def run_main(self, changed, *argv):
        out = io.StringIO()
        with mock.patch.object(vc, "changed_files", return_value=changed), \
                mock.patch.object(vc, "run_streaming") as run, \
                contextlib.redirect_stdout(out):
            code = vc.main(list(argv))
        return code, out.getvalue(), run

    def test_nothing_relevant_exits_zero_without_running(self):
        code, out, run = self.run_main(["tools/ue5/a.py", "docs/x.md"])
        self.assertEqual(code, 0)
        self.assertIn("nothing under src/ or tests/", out)
        run.assert_not_called()

    def test_dry_run_prints_plan_and_runs_nothing(self):
        code, out, run = self.run_main(["src/BioShockStudio.Core/Nope.cs"], "--dry-run")
        self.assertEqual(code, 0)
        self.assertIn("dotnet build BioShockStudio.sln", out)
        self.assertIn("--filter Tier=Fast", out)
        run.assert_not_called()

    def test_full_flow_verdicts(self):
        outputs = iter([(0, ["Build succeeded."]), (1, FAIL_OUTPUT.splitlines())])
        out = io.StringIO()
        with mock.patch.object(vc, "changed_files", return_value=["src/X.cs"]), \
                mock.patch.object(vc, "run_streaming", side_effect=lambda c, q: next(outputs)), \
                contextlib.redirect_stdout(out):
            code = vc.main(["--quiet"])
        self.assertEqual(code, 1)
        self.assertIn("verify_changed: FAIL", out.getvalue())
        self.assertIn("FAILED BioShockStudio.Tests.CubemapTests.MedicalCubemapsDecode", out.getvalue())

        outputs = iter([(1, BUILD_FAIL_OUTPUT.splitlines())])
        out = io.StringIO()
        with mock.patch.object(vc, "changed_files", return_value=["src/X.cs"]), \
                mock.patch.object(vc, "run_streaming", side_effect=lambda c, q: next(outputs)), \
                contextlib.redirect_stdout(out):
            code = vc.main(["--quiet"])
        self.assertEqual(code, 2)
        self.assertIn("locks the DLLs", out.getvalue())


class RealRepoTests(unittest.TestCase):
    def test_every_real_test_class_has_a_tier(self):
        # Mirrors TierCoverageTests: if the scanner disagreed with it, the plan would be wrong.
        classes = vc.load_test_classes()
        self.assertEqual(classes["TierCoverageTests"].tier, "Fast")
        self.assertEqual(classes["BspTextureOriginTests"].tier, "Sweep")
        untiered = [c.name for c in classes.values() if c.has_tests and c.tier is None]
        self.assertEqual(untiered, [])


if __name__ == "__main__":
    unittest.main()
