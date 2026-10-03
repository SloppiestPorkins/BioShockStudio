"""Tests for tools/git/ship.py and the bioshock_repo_guard.py Claude Code hook.

Everything runs against throwaway git repos (plus a bare "origin") created under SHIP_TEST_ROOT
(default: %TEMP%/ship-tests), never the real BioshockHavok or BioShockUE5 repos. Global and
system git config are isolated so a developer's own settings can't change the results.

    python -m unittest tools/tests_tooling/test_ship.py -v

The hook script is not part of this repo; it is looked up via BIOSHOCK_GUARD_SCRIPT, then
~/.claude/hooks/bioshock_repo_guard.py, and its tests are skipped when neither exists.
"""

import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

SHIP = Path(__file__).resolve().parents[1] / "git" / "ship.py"
TRAILER = "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
TEST_ROOT = Path(os.environ.get("SHIP_TEST_ROOT") or Path(tempfile.gettempdir()) / "ship-tests")


def guard_script():
    explicit = os.environ.get("BIOSHOCK_GUARD_SCRIPT")
    if explicit:
        return Path(explicit)
    return Path.home() / ".claude" / "hooks" / "bioshock_repo_guard.py"


def remove_tree(path):
    def make_writable(func, target, _exc):
        os.chmod(target, stat.S_IWRITE)
        func(target)
    if sys.version_info >= (3, 12):
        shutil.rmtree(path, onexc=make_writable)
    else:
        shutil.rmtree(path, onerror=make_writable)


class TempRepos(unittest.TestCase):
    """Creates a fresh sandbox with helper methods for building git repos inside it."""

    def setUp(self):
        TEST_ROOT.mkdir(parents=True, exist_ok=True)
        self.sandbox = Path(tempfile.mkdtemp(prefix="case-", dir=TEST_ROOT))
        empty_config = self.sandbox / "empty.gitconfig"
        empty_config.write_text("", encoding="utf-8")
        self.env = dict(os.environ)
        for key in ("BIOSHOCK_REPO", "BIOSHOCK_UE_REPO", "BIOSHOCK_AGENTS_DIR",
                    "SHIP_ASSUME_UNREAL", "GIT_DIR", "GIT_WORK_TREE"):
            self.env.pop(key, None)
        self.env["GIT_CONFIG_GLOBAL"] = str(empty_config)
        self.env["GIT_CONFIG_NOSYSTEM"] = "1"
        self.env["MSYS_NO_PATHCONV"] = "1"

    def tearDown(self):
        remove_tree(self.sandbox)

    def git(self, repo, *args, env=None):
        proc = subprocess.run(
            ["git", "-c", "user.name=Test", "-c", "user.email=test@example.invalid", *args],
            cwd=str(repo), env=env or self.env, capture_output=True, text=True,
            encoding="utf-8", errors="replace")
        if proc.returncode != 0:
            raise AssertionError("git %s failed: %s" % (" ".join(args), proc.stderr))
        return proc.stdout

    def write(self, repo, rel, text="content\n"):
        path = repo / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def make_repo(self, name, with_origin=False):
        repo = self.sandbox / name
        repo.mkdir()
        self.git(repo, "init", "-q", "-b", "main")
        self.write(repo, "README.md", "readme\n")
        self.write(repo, ".gitignore", "bin/\nscratch/\n*.log\n")
        self.git(repo, "add", "README.md", ".gitignore")
        self.git(repo, "commit", "-q", "-m", "initial")
        if with_origin:
            origin = self.sandbox / (name + "-origin.git")
            self.git(self.sandbox, "init", "-q", "--bare", "-b", "main", str(origin))
            self.git(repo, "remote", "add", "origin", str(origin))
            self.git(repo, "push", "-q", "-u", "origin", "main")
        return repo

    def head(self, repo, ref="HEAD"):
        return self.git(repo, "rev-parse", ref).strip()


class ShipTests(TempRepos):

    def setUp(self):
        super().setUp()
        self.repo = self.make_repo("havok", with_origin=True)
        self.origin = self.sandbox / "havok-origin.git"
        self.ue = self.make_repo("ue")
        self.env["BIOSHOCK_REPO"] = str(self.repo)
        self.env["BIOSHOCK_UE_REPO"] = str(self.ue)

    def ship(self, *args, extra_env=None):
        env = dict(self.env)
        env.update(extra_env or {})
        return subprocess.run([sys.executable, str(SHIP), *args], cwd=str(self.repo), env=env,
                              capture_output=True, text=True, encoding="utf-8", errors="replace")

    def origin_head(self):
        return self.git(self.origin, "rev-parse", "main").strip()

    def last_message(self, repo):
        # %B prints the raw message plus a newline of its own.
        return self.git(repo, "log", "-1", "--format=%B")[:-1]

    def assert_refused(self, proc, fragment):
        self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
        self.assertIn("REFUSED", proc.stderr)
        self.assertIn(fragment, proc.stderr)

    def test_refuses_blanket_and_bad_paths(self):
        self.write(self.repo, "a.txt")
        self.write(self.repo, "dir/b.txt")
        before = self.head(self.repo)
        cases = [
            (["--files", "."], "blanket staging"),
            (["--files", "-A"], "blanket staging is not allowed (-A)"),
            (["--files", "--all"], "blanket staging is not allowed (--all)"),
            (["--files", "a.txt", "-A"], "blanket staging is not allowed (-A)"),
            (["--files", "*.txt"], "globs are not allowed"),
            (["--files", "dir"], "is a directory"),
            (["--files", "missing.txt"], "does not exist"),
            (["--files", "../outside.txt"], "outside"),
        ]
        for args, fragment in cases:
            with self.subTest(args=args):
                self.assert_refused(self.ship("-m", "subject", "--no-push", *args), fragment)
        self.assertEqual(self.head(self.repo), before)
        self.assertEqual(self.git(self.repo, "diff", "--cached", "--name-only"), "")

    def test_refuses_gitignored_file_and_unchanged_files(self):
        self.write(self.repo, "scratch/keep.cpp")
        self.assert_refused(self.ship("-m", "s", "--no-push", "--files", "scratch/keep.cpp"),
                            "is gitignored")
        self.assert_refused(self.ship("-m", "s", "--no-push", "--files", "README.md"),
                            "has changes to commit")

    def test_commit_message_identity_and_only_listed_files(self):
        self.write(self.repo, "a.txt")
        self.write(self.repo, "other.txt")
        self.git(self.repo, "add", "other.txt")  # someone else's staged work
        body = self.write(self.sandbox, "body.txt", "Why this change.\n\n- detail #1\n")
        before_origin = self.origin_head()
        proc = self.ship("-m", "Add a.txt", "-b", str(body), "--files", "a.txt", "--no-push")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertEqual(self.last_message(self.repo),
                         "Add a.txt\n\nWhy this change.\n\n- detail #1\n\n" + TRAILER + "\n")
        author = self.git(self.repo, "log", "-1", "--format=%an <%ae>|%cn <%ce>").strip()
        self.assertEqual(author, "Jack <jackwickens6@googlemail.com>|Jack <jackwickens6@googlemail.com>")
        committed = self.git(self.repo, "show", "--name-only", "--format=", "HEAD").split()
        self.assertEqual(committed, ["a.txt"])
        self.assertEqual(self.git(self.repo, "diff", "--cached", "--name-only").split(), ["other.txt"])
        self.assertIn("other.txt is already staged but not listed", proc.stdout)
        self.assertIn(self.head(self.repo), proc.stdout)
        self.assertEqual(self.origin_head(), before_origin, "--no-push must not push")
        self.assertIn("--no-push given", proc.stdout)

    def test_trailer_not_duplicated(self):
        self.write(self.repo, "a.txt")
        body = self.write(self.sandbox, "body.txt", "Body.\n\n" + TRAILER + "\n")
        proc = self.ship("-m", "Subject", "-b", str(body), "--files", "a.txt", "--no-push")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(self.last_message(self.repo).count("Co-Authored-By"), 1)

    def test_tracked_deletion_and_absolute_path(self):
        (self.repo / "README.md").unlink()
        self.write(self.repo, "new file.txt")
        proc = self.ship("-m", "Delete readme", "--no-push",
                         "--files", "README.md", str(self.repo / "new file.txt"))
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        changes = self.git(self.repo, "show", "--name-status", "--format=", "HEAD").splitlines()
        self.assertEqual(sorted(changes), ["A\tnew file.txt", "D\tREADME.md"])

    def test_ignored_source_warning(self):
        self.write(self.repo, "scratch/FmodFsbDecoder.cpp")   # ignored, not a known generated dir
        self.write(self.repo, "scratch/notes.bin")           # ignored but not source-like
        self.write(self.repo, "scratch/bin/Generated.cs")    # inside a generated dir
        self.write(self.repo, "src/App/bin/Debug/App.cs")    # generated at any depth
        self.write(self.repo, "run.log")                     # not source-like
        self.write(self.repo, "a.txt")
        proc = self.ship("-m", "s", "--files", "a.txt", "--dry-run")
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("WARNING: 1 gitignored source-like file", proc.stdout)
        self.assertIn("scratch/FmodFsbDecoder.cpp", proc.stdout)
        self.assertNotIn("Generated.cs", proc.stdout)
        self.assertNotIn("App.cs", proc.stdout)

    def test_dry_run_changes_nothing(self):
        self.write(self.repo, "a.txt")
        self.write(self.ue, "Content/Map.umap", "map\n")
        before, before_ue, before_origin = self.head(self.repo), self.head(self.ue), self.origin_head()
        proc = self.ship("-m", "s", "--files", "a.txt", "--ue-files", "Content/Map.umap", "--dry-run",
                         extra_env={"SHIP_ASSUME_UNREAL": "stopped"})
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertIn("DRY RUN", proc.stdout)
        self.assertIn("git add -- a.txt", proc.stdout)
        self.assertIn("git push origin main", proc.stdout)
        self.assertIn("Paired with BioshockHavok <sha>.", proc.stdout)
        self.assertEqual((self.head(self.repo), self.head(self.ue), self.origin_head()),
                         (before, before_ue, before_origin))
        self.assertEqual(self.git(self.repo, "diff", "--cached", "--name-only"), "")
        self.assertEqual(self.git(self.ue, "diff", "--cached", "--name-only"), "")

    def test_pushes_by_default(self):
        self.write(self.repo, "a.txt")
        proc = self.ship("-m", "Push me", "--files", "a.txt")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertEqual(self.origin_head(), self.head(self.repo))
        self.assertIn("pushed", proc.stdout)

    def test_ue_files_paired_commit(self):
        self.write(self.repo, "a.txt")
        self.write(self.ue, "Content/Map.umap", "map\n")
        proc = self.ship("-m", "Fix the map", "--files", "a.txt", "--ue-files", "Content/Map.umap",
                         "--no-push", extra_env={"SHIP_ASSUME_UNREAL": "stopped"})
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        sha = self.head(self.repo)
        self.assertEqual(self.last_message(self.ue), "Fix the map\n\nPaired with BioshockHavok %s.\n" % sha)
        self.assertEqual(self.git(self.ue, "log", "-1", "--format=%an <%ae>").strip(),
                         "Jack <jackwickens6@googlemail.com>")
        self.assertIn(self.head(self.ue), proc.stdout)

    def test_ue_files_refused_while_unreal_runs(self):
        self.write(self.repo, "a.txt")
        self.write(self.ue, "Content/Map.umap", "map\n")
        before, before_ue = self.head(self.repo), self.head(self.ue)
        proc = self.ship("-m", "s", "--files", "a.txt", "--ue-files", "Content/Map.umap", "--no-push",
                         extra_env={"SHIP_ASSUME_UNREAL": "running"})
        self.assert_refused(proc, "Unreal is running")
        self.assertEqual((self.head(self.repo), self.head(self.ue)), (before, before_ue))

    def test_src_change_runs_verify_changed(self):
        self.write(self.repo, "src/Core/Thing.cs", "class Thing {}\n")
        self.write(self.repo, "tools/verify_changed.py", "import sys\nprint('fast tier FAILED')\nsys.exit(1)\n")
        self.git(self.repo, "add", "tools/verify_changed.py")
        self.git(self.repo, "commit", "-q", "-m", "verifier")
        before = self.head(self.repo)
        proc = self.ship("-m", "s", "--files", "src/Core/Thing.cs", "--no-push")
        self.assert_refused(proc, "verify_changed.py failed")
        self.assertEqual(self.head(self.repo), before)
        proc = self.ship("-m", "s", "--files", "src/Core/Thing.cs", "--no-push", "--skip-tests")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertNotEqual(self.head(self.repo), before)

    def test_unlisted_src_change_refuses_before_testing(self):
        # The tests would see B.cs, the commit would not: refuse instead of pushing a broken main.
        self.write(self.repo, "src/Core/A.cs", "class A { B b; }\n")
        self.write(self.repo, "src/Core/B.cs", "class B {}\n")
        self.write(self.repo, "tools/verify_changed.py", "import sys\nsys.exit(0)\n")
        self.git(self.repo, "add", "tools/verify_changed.py")
        self.git(self.repo, "commit", "-q", "-m", "verifier")
        before = self.head(self.repo)
        proc = self.ship("-m", "s", "--files", "src/Core/A.cs", "--no-push")
        self.assert_refused(proc, "src/Core/B.cs")
        self.assertEqual(self.head(self.repo), before)
        proc = self.ship("-m", "s", "--files", "src/Core/A.cs", "src/Core/B.cs", "--no-push")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)

    def test_src_change_without_verifier_warns(self):
        self.write(self.repo, "tests/ThingTests.cs", "class ThingTests {}\n")
        proc = self.ship("-m", "s", "--files", "tests/ThingTests.cs", "--no-push")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertIn("verify_changed.py not found", proc.stdout)


class GuardTests(TempRepos):

    def setUp(self):
        super().setUp()
        self.script = guard_script()
        if not self.script.is_file():
            self.skipTest("hook script not found: %s" % self.script)
        self.repo = self.make_repo("havok", with_origin=True)
        self.ue = self.make_repo("ue")
        self.agents = self.sandbox / "agents"
        self.agents.mkdir()
        self.env["BIOSHOCK_REPO"] = str(self.repo)
        self.env["BIOSHOCK_UE_REPO"] = str(self.ue)
        self.env["BIOSHOCK_AGENTS_DIR"] = str(self.agents)

    def guard(self, mode):
        start = time.monotonic()
        proc = subprocess.run([sys.executable, str(self.script), "--mode", mode], env=self.env,
                              capture_output=True, text=True, encoding="utf-8", errors="replace",
                              stdin=subprocess.DEVNULL)
        return proc, time.monotonic() - start

    def test_clean_is_silent(self):
        live = self.agents / "live-worktree"
        live.mkdir()
        (live / ".git").write_text("gitdir: %s\n" % (self.repo / ".git").as_posix(), encoding="utf-8")
        for mode in ("sessionstart", "stop"):
            with self.subTest(mode=mode):
                proc, elapsed = self.guard(mode)
                self.assertEqual(proc.returncode, 0)
                self.assertEqual(proc.stdout, "")
                self.assertLess(elapsed, 5.0)

    def test_reports_drift(self):
        self.write(self.repo, "a.txt")
        self.git(self.repo, "add", "a.txt")
        old = int(time.time()) - 5 * 3600 - 60
        env = dict(self.env, GIT_COMMITTER_DATE="@%d +0000" % old, GIT_AUTHOR_DATE="@%d +0000" % old)
        self.git(self.repo, "commit", "-q", "-m", "unpushed", env=env)
        self.write(self.repo, "README.md", "edited\n")
        self.write(self.ue, "README.md", "edited\n")
        self.write(self.ue, ".gitignore", "changed\n")
        self.write(self.ue, "untracked.txt")  # untracked files are not counted
        orphan = self.agents / "w99-gone"
        orphan.mkdir()
        (orphan / ".git").write_text("gitdir: %s\n" % (self.sandbox / "nope" / "worktrees" / "w99").as_posix(),
                                     encoding="utf-8")
        (self.agents / "not-a-worktree").mkdir()

        proc, elapsed = self.guard("sessionstart")
        self.assertEqual(proc.returncode, 0)
        self.assertEqual(proc.stdout.strip(),
                         "BioShock repos: 1 unpushed commit (oldest 5h) in havok; 1 uncommitted file in havok; "
                         "2 uncommitted files in ue; 1 orphan worktree dir in agents (gitdir gone)")
        self.assertLess(elapsed, 5.0)

        proc, _ = self.guard("stop")
        self.assertEqual(proc.returncode, 0)
        payload = json.loads(proc.stdout)
        self.assertEqual(list(payload), ["systemMessage"])
        self.assertIn("1 unpushed commit (oldest 5h) in havok", payload["systemMessage"])

    def test_missing_repos_and_bad_mode_are_silent(self):
        self.env["BIOSHOCK_REPO"] = str(self.sandbox / "missing")
        self.env["BIOSHOCK_UE_REPO"] = str(self.sandbox / "missing-ue")
        self.env["BIOSHOCK_AGENTS_DIR"] = str(self.sandbox / "missing-agents")
        for mode in ("sessionstart", "stop", "bogus"):
            with self.subTest(mode=mode):
                proc, _ = self.guard(mode)
                self.assertEqual((proc.returncode, proc.stdout), (0, ""))
        proc = subprocess.run([sys.executable, str(self.script)], env=self.env, capture_output=True, text=True)
        self.assertEqual((proc.returncode, proc.stdout), (0, ""))


if __name__ == "__main__":
    unittest.main()
