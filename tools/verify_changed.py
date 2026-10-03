#!/usr/bin/env python3
"""Run the right tests before a C# commit: build, the whole Fast tier, plus changed test classes.

On 29 Sept a change was verified by running only the one test class it touched; it broke two
Fast-tier tests in other classes and nobody saw until 2 Oct. The rule in CLAUDE.md is "Fast tier
always, plus the Sweep classes your diff touches" - this makes that one command instead of a
judgement call:

  1. Work out what changed. Default: staged + unstaged + untracked files vs HEAD. With
     --base REF (e.g. origin/main): everything since the merge-base with REF, committed or not,
     plus untracked.
  2. Nothing under src/ or tests/ changed -> say so, exit 0.
  3. dotnet build BioShockStudio.sln
  4. dotnet test tests/BioShockStudio.Tests --no-build --filter Tier=Fast
  5. separately, any test class declared in a changed tests/*.cs file that the Fast tier does
     not already cover (Sweep, or no tier at all), via FullyQualifiedName~<Namespace>.<Class>.
     Tiers are read from the [Trait(Tiers.Name, Tiers.X)] attributes in the source, across
     partial-class files. --related also adds the non-Fast classes whose source mentions a
     changed src/ file's type name (the file stem); without it they are only listed.
  6. Parse each run's "Passed!/Failed!" summary and the "Failed <test>" lines, print a one-line
     verdict, exit 0 on success, 1 on test failures, 2 when the build or a run itself broke.

Skipped counts are reported, never folded into "passed": [RequiresGameFact] tests skip when the
game install is missing, and a Fast tier that skipped everything has verified nothing.

    python tools/verify_changed.py [--base REF] [--dry-run] [--related] [--quiet]

--dry-run prints the changed files and the exact commands, and runs nothing. The Fast tier
takes ~2.5 minutes. Close BioShockStudio.App first: a running instance locks the DLLs and the
build fails to copy them.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SOLUTION = "BioShockStudio.sln"
TEST_PROJECT = "tests/BioShockStudio.Tests"
WATCHED_ROOTS = ("src/", "tests/")
FAST = "Fast"
CLASSES_PER_RUN = 40

SUMMARY = re.compile(
    r"^\s*(?P<verdict>Passed|Failed)!\s+-\s+Failed:\s*(?P<failed>\d+),\s*Passed:\s*(?P<passed>\d+),"
    r"\s*Skipped:\s*(?P<skipped>\d+),\s*Total:\s*(?P<total>\d+)")
FAILED_TEST = re.compile(r"^\s+Failed\s+(?P<name>\S.*?)\s+\[(?:< )?\d[^\]]*\]\s*$")
NO_MATCH = re.compile(r"No test matches the given testcase filter", re.IGNORECASE)
BUILD_ERROR = re.compile(r"(?:^\s*|:\s+)error\s+[A-Z]+\d+:")
LOCKED = re.compile(r"MSB302[17]|being used by another process", re.IGNORECASE)

NAMESPACE = re.compile(r"^\s*namespace\s+([\w.]+)", re.MULTILINE)
CLASS_DECL = re.compile(
    r"^\s*(?:(?:public|internal|private|protected|sealed|static|abstract|partial|file)\s+)*"
    r"class\s+(\w+)")
TIER_TRAIT = re.compile(r"Trait\s*\(\s*(?:Tiers\.Name|\"Tier\")\s*,\s*(?:Tiers\.(\w+)|\"(\w+)\")")
TEST_ATTRIBUTE = re.compile(r"^\s*\[\s*\w*(?:Fact|Theory)\b", re.MULTILINE)


# --- what changed ------------------------------------------------------------------------------

def git(*args: str) -> str:
    result = subprocess.run(["git", "-c", "core.quotepath=off", *args], cwd=REPO,
                            capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        raise RuntimeError("git %s failed: %s" % (" ".join(args), result.stderr.strip()))
    return result.stdout


def changed_files(base: str | None) -> list[str]:
    if base:
        merge_base = git("merge-base", base, "HEAD").strip()
        tracked = git("diff", "--name-only", "-z", merge_base)
    else:
        tracked = git("diff", "--name-only", "-z", "HEAD")
    untracked = git("ls-files", "--others", "--exclude-standard", "-z")
    names = {n for n in (tracked + untracked).split("\0") if n}
    return sorted(n.replace("\\", "/") for n in names)


def is_watched(path: str) -> bool:
    return path.startswith(WATCHED_ROOTS) and "/obj/" not in path and "/bin/" not in path


# --- test classes and tiers --------------------------------------------------------------------

@dataclass
class TestClass:
    name: str
    namespace: str
    tier: str | None = None
    has_tests: bool = False
    files: set = field(default_factory=set)

    @property
    def filter(self) -> str:
        # Trailing dot so FooTests does not also select FooTestsExtra.
        return "FullyQualifiedName~%s.%s." % (self.namespace, self.name)


def scan_classes(text: str) -> list[tuple[str, str | None, bool]]:
    """(class, tier, holds tests) for each class declared in one C# file."""
    lines = text.splitlines()
    decls = []
    pending = []
    for number, line in enumerate(lines):
        stripped = line.strip()
        match = CLASS_DECL.match(line)
        if match:
            decls.append((number, match.group(1), " ".join(pending + [stripped])))
            pending = []
        elif stripped.startswith("["):
            pending.append(stripped)
        elif stripped and not stripped.startswith("//"):
            pending = []
    out = []
    for i, (start, name, attributes) in enumerate(decls):
        end = decls[i + 1][0] if i + 1 < len(decls) else len(lines)
        tier_match = TIER_TRAIT.search(attributes)
        tier = (tier_match.group(1) or tier_match.group(2)) if tier_match else None
        body = "\n".join(lines[start:end])
        out.append((name, tier, bool(TEST_ATTRIBUTE.search(body))))
    return out


def test_sources() -> list[Path]:
    root = REPO / "tests"
    return [p for p in sorted(root.rglob("*.cs"))
            if "obj" not in p.relative_to(root).parts and "bin" not in p.relative_to(root).parts]


def load_test_classes() -> dict[str, TestClass]:
    classes: dict[str, TestClass] = {}
    for path in test_sources():
        text = path.read_text(encoding="utf-8", errors="replace")
        ns_match = NAMESPACE.search(text)
        namespace = ns_match.group(1) if ns_match else ""
        rel = path.relative_to(REPO).as_posix()
        for name, tier, has_tests in scan_classes(text):
            entry = classes.setdefault(name, TestClass(name, namespace))
            entry.tier = entry.tier or tier
            entry.has_tests = entry.has_tests or has_tests
            entry.files.add(rel)
    return classes


def uncovered_classes(changed: list[str], classes: dict[str, TestClass]) -> list[TestClass]:
    changed_set = set(changed)
    return sorted((c for c in classes.values()
                   if c.files & changed_set and c.has_tests and c.tier != FAST),
                  key=lambda c: c.name)


def related_classes(changed: list[str], classes: dict[str, TestClass],
                    exclude: list[TestClass]) -> list[TestClass]:
    stems = {Path(p).stem for p in changed
             if p.startswith("src/") and p.endswith(".cs") and (REPO / p).is_file()}
    if not stems:
        return []
    pattern = re.compile(r"\b(?:%s)\b" % "|".join(re.escape(s) for s in sorted(stems)))
    skip = {c.name for c in exclude}
    found = []
    for test_class in classes.values():
        if test_class.name in skip or not test_class.has_tests or test_class.tier == FAST:
            continue
        for rel in test_class.files:
            if pattern.search((REPO / rel).read_text(encoding="utf-8", errors="replace")):
                found.append(test_class)
                break
    return sorted(found, key=lambda c: c.name)


# --- running and parsing -----------------------------------------------------------------------

@dataclass
class RunResult:
    label: str
    exit_code: int
    summaries: list = field(default_factory=list)
    failed_tests: list = field(default_factory=list)
    errors: list = field(default_factory=list)
    no_match: bool = False
    locked: bool = False

    def totals(self) -> dict:
        keys = ("failed", "passed", "skipped", "total")
        return {k: sum(int(s[k]) for s in self.summaries) for k in keys}


def parse_test_output(label: str, exit_code: int, lines: list[str]) -> RunResult:
    result = RunResult(label, exit_code)
    for line in lines:
        summary = SUMMARY.match(line)
        if summary:
            result.summaries.append(summary.groupdict())
            continue
        failed = FAILED_TEST.match(line)
        if failed and failed.group("name") not in result.failed_tests:
            result.failed_tests.append(failed.group("name"))
        if NO_MATCH.search(line):
            result.no_match = True
        if BUILD_ERROR.search(line) and line.strip() not in result.errors:
            result.errors.append(line.strip())
        if LOCKED.search(line):
            result.locked = True
    return result


def run_streaming(command: list[str], quiet: bool) -> tuple[int, list[str]]:
    env = dict(os.environ, DOTNET_CLI_UI_LANGUAGE="en", DOTNET_NOLOGO="1",
               MSBUILDTERMINALLOGGER="off")
    print("$ " + " ".join(('"%s"' % c) if " " in c or "|" in c else c for c in command),
          flush=True)
    try:
        process = subprocess.Popen(command, cwd=REPO, env=env, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, text=True, encoding="utf-8",
                                   errors="replace")
    except FileNotFoundError:
        return 127, ["%s: not found on PATH" % command[0]]
    lines = []
    assert process.stdout is not None
    for line in process.stdout:
        line = line.rstrip("\r\n")
        lines.append(line)
        if not quiet:
            print(line, flush=True)
    return process.wait(), lines


def build_command() -> list[str]:
    return ["dotnet", "build", SOLUTION, "-nologo", "-v:minimal"]


def test_command(test_filter: str) -> list[str]:
    return ["dotnet", "test", TEST_PROJECT, "--no-build", "--nologo", "--filter", test_filter]


def describe(result: RunResult) -> tuple[bool, str]:
    """(ok, one-phrase description) for one test run."""
    totals = result.totals()
    if result.no_match and not result.summaries:
        return False, "%s: no test matched the filter" % result.label
    if not result.summaries:
        return False, "%s: no summary line (exit %d) - run aborted?" % (result.label,
                                                                        result.exit_code)
    text = "%s %d passed, %d failed, %d skipped" % (result.label, totals["passed"],
                                                   totals["failed"], totals["skipped"])
    if totals["failed"] or result.failed_tests:
        names = result.failed_tests[:5]
        more = len(result.failed_tests) - len(names)
        text += " (%s%s)" % (", ".join(names), ", +%d more" % more if more > 0 else "")
        return False, text
    if result.exit_code != 0:
        return False, text + " but exit %d" % result.exit_code
    if totals["passed"] == 0:
        return False, text + " - nothing actually ran"
    return True, text


# --- main --------------------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--base",
                        help="diff against the merge-base with this ref (e.g. origin/main)")
    parser.add_argument("--dry-run", action="store_true", help="print the plan, run nothing")
    parser.add_argument("--related", action="store_true",
                        help="also run non-Fast classes that mention a changed src/ type")
    parser.add_argument("--quiet", action="store_true", help="hide build/test output, keep verdict")
    args = parser.parse_args(argv)

    try:
        changed = changed_files(args.base)
    except (RuntimeError, OSError) as exc:
        print("verify_changed: cannot list changes: %s" % exc, file=sys.stderr)
        return 2
    watched = [p for p in changed if is_watched(p)]
    scope = "since merge-base with %s" % args.base if args.base else "vs HEAD (incl. untracked)"
    if not watched:
        print("verify_changed: nothing under src/ or tests/ changed %s (%d other file(s)) - "
              "no C# tests to run" % (scope, len(changed)))
        return 0

    classes = load_test_classes()
    extra = uncovered_classes(watched, classes)
    related = related_classes(watched, classes, extra)
    if args.related:
        extra = sorted(extra + related, key=lambda c: c.name)

    print("changed %s: %d under src/ or tests/" % (scope, len(watched)))
    for path in watched[:40]:
        print("  " + path)
    if len(watched) > 40:
        print("  ... %d more" % (len(watched) - 40))
    plan = [("build", build_command()), ("Fast tier", test_command("Tier=%s" % FAST))]
    if extra:
        # Batches keep each command line well under Windows' 32k limit when --related is large.
        batches = [extra[i:i + CLASSES_PER_RUN] for i in range(0, len(extra), CLASSES_PER_RUN)]
        for number, batch in enumerate(batches, 1):
            label = "changed classes" + (" %d/%d" % (number, len(batches))
                                         if len(batches) > 1 else "")
            plan.append((label, test_command("|".join(c.filter for c in batch))))
        print("non-Fast classes to run separately: %s"
              % ", ".join("%s (%s)" % (c.name, c.tier or "no tier") for c in extra))
    if related and not args.related:
        names = [c.name for c in related]
        print("not run (use --related): %d non-Fast classes mention a changed src/ type: %s%s"
              % (len(names), ", ".join(names[:10]), ", ..." if len(names) > 10 else ""))

    if args.dry_run:
        print("plan (dry run, nothing executed):")
        for label, command in plan:
            shown = " ".join(('"%s"' % c) if "|" in c else c for c in command)
            print("  %-16s %s" % (label, shown))
        return 0

    code, lines = run_streaming(build_command(), args.quiet)
    if code != 0:
        build = parse_test_output("build", code, lines)
        for error in build.errors[:15]:
            print(error)
        hint = " - a running BioShockStudio.App locks the DLLs, close it" if build.locked else ""
        print("verify_changed: FAIL - dotnet build exit %d, %d error line(s)%s; no tests run"
              % (code, len(build.errors), hint))
        return 2

    results = []
    for label, command in plan[1:]:
        code, lines = run_streaming(command, args.quiet)
        results.append(parse_test_output(label, code, lines))

    verdicts = [describe(r) for r in results]
    ok = all(v[0] for v in verdicts)
    for result in results:
        for name in result.failed_tests:
            print("FAILED %s  [%s]" % (name, result.label))
    print("verify_changed: %s - build ok; %s" % ("PASS" if ok else "FAIL",
                                                "; ".join(v[1] for v in verdicts)))
    if ok:
        return 0
    broken_run = any(not r.summaries for r in results)
    return 2 if broken_run else 1


if __name__ == "__main__":
    sys.exit(main())
