"""Lint: every tools/ue5 fix_*.py / repair_*.py must be part of the pipeline, or say why not.

A repair that is only ever run by hand is undone by the next reimport, and nobody notices until
it shows up live. That has happened 6+ times; on 30 Sept import_bioshock re-parented
MI_Light_Beam_01 back onto the generic additive master and undid repair_light_beams, which put a
white sheet across the view at Medical's arrival porthole. So a repair either runs every time
the slice is rebuilt, or it carries an explicit statement that it does not need to.

A script counts as REGISTERED when:
  - setup_playable_slice.py's STEPS list names it as a step module (read with `ast`, never
    imported - that file needs `unreal`), or a local step callable in STEPS imports it; or
  - another tools/ue5 script invokes it in code: `import X`, `from X import ...`, or a string
    literal that is exactly "X" / "X.py" / a path ending in X.py (the __import__ /
    import_module / script-path forms). Mentions in comments and docstrings do NOT count:
    import_bioshock.py *mentions* repair_light_beams in a comment and that is exactly the
    situation that lost the beam fix.
    References from run_*.py wrappers do not count (a wrapper is a hand-launched entry point,
    which is the problem being linted), nor do verify_* / probe_* / audit_* scripts
    (diagnostics, not the build). A reference from another fix_/repair_ script counts only if
    that script is itself registered, so a chain hanging off an unregistered driver is flagged.

A script may opt out with a line in its module docstring:

    Pipeline: one-off    a migration/cleanup that has done its job and must not re-run on every
                         rebuild (e.g. it deletes or renames assets once)
    Pipeline: retired    superseded; kept for the record (say by what in the same docstring)
    Pipeline: entry-point  a top-level driver in its own right (e.g. the batch repair for the
                         other story maps), not a step the 1-Medical slice rebuild should run

Exit 0 when nothing is unregistered, 1 when something is (they are printed), 2 when STEPS
cannot be read. Standalone Python (no Unreal):

    python tools/ue5/check_repairs_registered.py [--json] [--ue5-dir DIR]
"""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from pathlib import Path

UE5_DIR = Path(__file__).resolve().parent
PIPELINE_FILE = "setup_playable_slice.py"
CANDIDATE_GLOBS = ("fix_*.py", "repair_*.py")
# Referrers that never make a script part of the rebuild (see the docstring).
NON_PIPELINE_PREFIXES = ("run_", "verify_", "probe_", "audit_")
OPT_OUT = re.compile(r"^\s*Pipeline:\s*(one-off|retired|entry-point)\b", re.IGNORECASE | re.MULTILINE)


def parse(path: Path):
    source = path.read_text(encoding="utf-8", errors="replace")
    try:
        return ast.parse(source, filename=str(path))
    except SyntaxError:
        return None


def docstring_nodes(tree) -> set[int]:
    """ids of the Constant nodes that are module/class/function docstrings."""
    ids = set()
    for node in ast.walk(tree):
        if isinstance(node, (ast.Module, ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)):
            body = getattr(node, "body", [])
            if (body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant)
                    and isinstance(body[0].value.value, str)):
                ids.add(id(body[0].value))
    return ids


def string_names_module(text: str, modules: set[str]) -> str | None:
    text = text.strip()
    if text in modules:
        return text
    base = re.split(r"[\\/]", text)[-1]
    if base.endswith(".py") and base[:-3] in modules:
        return base[:-3]
    return None


def code_references(tree, modules: set[str], node=None) -> set[str]:
    """Modules from `modules` that this tree (or one node of it) imports or names in a string."""
    found = set()
    skip = docstring_nodes(tree)
    for child in ast.walk(node if node is not None else tree):
        if isinstance(child, ast.Import):
            for alias in child.names:
                head = alias.name.split(".")[0]
                if head in modules:
                    found.add(head)
        elif isinstance(child, ast.ImportFrom):
            head = (child.module or "").split(".")[0]
            if head in modules:
                found.add(head)
        elif (isinstance(child, ast.Constant) and isinstance(child.value, str)
              and id(child) not in skip):
            name = string_names_module(child.value, modules)
            if name:
                found.add(name)
    return found


def read_steps(pipeline_path: Path, modules: set[str]) -> dict[str, str]:
    """{module: how STEPS registers it}. Raises ValueError if STEPS is missing or unreadable."""
    tree = parse(pipeline_path)
    if tree is None:
        raise ValueError("%s does not parse" % pipeline_path)
    steps = None
    functions = {}
    for node in tree.body:
        if isinstance(node, ast.FunctionDef):
            functions[node.name] = node
        targets = []
        if isinstance(node, ast.Assign):
            targets = node.targets
        elif isinstance(node, ast.AnnAssign) and node.value is not None:
            targets = [node.target]
        if any(isinstance(t, ast.Name) and t.id == "STEPS" for t in targets):
            steps = node.value
    if not isinstance(steps, (ast.List, ast.Tuple)):
        raise ValueError("no STEPS = [...] list in %s" % pipeline_path)
    registered = {}
    for entry in steps.elts:
        if not isinstance(entry, ast.Tuple) or len(entry.elts) < 3:
            continue
        label, module, func = entry.elts[0], entry.elts[1], entry.elts[2]
        label_text = label.value if isinstance(label, ast.Constant) else "?"
        if isinstance(module, ast.Constant) and isinstance(module.value, str):
            registered.setdefault(module.value, "STEPS (%s)" % label_text)
        elif isinstance(func, ast.Name) and func.id in functions:
            for name in code_references(tree, modules, functions[func.id]):
                registered.setdefault(name, "STEPS via %s()" % func.id)
    if not registered and steps.elts:
        raise ValueError("STEPS in %s has entries but none could be read" % pipeline_path)
    return registered


def opt_out_reason(tree) -> str | None:
    doc = ast.get_docstring(tree) if tree is not None else None
    match = OPT_OUT.search(doc or "")
    return match.group(1).lower() if match else None


def check(ue5_dir: Path) -> dict:
    candidates = sorted({p for pattern in CANDIDATE_GLOBS for p in ue5_dir.glob(pattern)})
    modules = {p.stem for p in candidates}
    steps = read_steps(ue5_dir / PIPELINE_FILE, modules | {p.stem for p in ue5_dir.glob("*.py")})

    trees = {p.stem: parse(p) for p in sorted(ue5_dir.glob("*.py"))}
    referrers: dict[str, set[str]] = {m: set() for m in modules}
    wrappers: dict[str, set[str]] = {m: set() for m in modules}
    mentions: dict[str, set[str]] = {m: set() for m in modules}
    for name, tree in trees.items():
        if tree is None or name == Path(__file__).stem:
            continue
        refs = code_references(tree, modules) - {name}
        for module in refs:
            if name.startswith(NON_PIPELINE_PREFIXES):
                wrappers[module].add(name)
            else:
                referrers[module].add(name)
        text = (ue5_dir / (name + ".py")).read_text(encoding="utf-8", errors="replace")
        for module in modules - refs - {name}:
            if re.search(r"\b%s\b" % re.escape(module), text):
                mentions[module].add(name)

    # Registered means reachable from STEPS over the code-reference graph of every tools/ue5 script.
    # Being imported by some other script is not enough: a hand-run tool (reimport_*.py, author_*.py)
    # that calls a repair is exactly the hand-run case this lint exists to catch.
    all_modules = set(trees)
    graph = {name: code_references(tree, all_modules) - {name}
             for name, tree in trees.items()
             if tree is not None and not name.startswith(NON_PIPELINE_PREFIXES)}
    reach: dict[str, str] = dict(steps)
    queue = sorted(steps)
    while queue:
        current = queue.pop()
        for callee in sorted(graph.get(current, ())):
            if callee not in reach:
                reach[callee] = "via %s" % current
                queue.append(callee)

    status: dict[str, str] = {}
    for module in modules:
        reason = opt_out_reason(trees.get(module))
        if module in reach:
            status[module] = reach[module]
        elif reason:
            status[module] = "opted out (%s)" % reason

    results = []
    for module in sorted(modules):
        state = status.get(module)
        notes = []
        if state is None:
            pending = sorted(r for r in referrers[module] if r in modules)
            if pending:
                notes.append("called only by unregistered %s" % ", ".join(pending))
        if wrappers[module]:
            notes.append("also invoked outside the pipeline by %s"
                         % ", ".join(sorted(wrappers[module])))
        if state is None and mentions[module]:
            notes.append("mentioned (not invoked) in %s" % ", ".join(sorted(mentions[module])))
        results.append({"script": module + ".py", "registered": state is not None,
                        "status": state or "UNREGISTERED", "notes": notes})
    return {"ue5Dir": str(ue5_dir), "pipelineFile": PIPELINE_FILE, "results": results,
            "unregistered": [r["script"] for r in results if not r["registered"]]}


def main(argv: list[str] | None = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--json", action="store_true", help="machine-readable report")
    parser.add_argument("--ue5-dir", default=str(UE5_DIR), help="tools/ue5 directory to lint")
    args = parser.parse_args(argv)

    try:
        report = check(Path(args.ue5_dir))
    except (OSError, ValueError) as exc:
        print("check_repairs_registered: cannot read the pipeline: %s" % exc, file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(report, indent=2))
    else:
        width = max(len(r["script"]) for r in report["results"]) if report["results"] else 10
        for r in report["results"]:
            line = "%-*s  %s" % (width, r["script"], r["status"])
            if r["notes"]:
                line += "  [%s]" % "; ".join(r["notes"])
            print(line)
        total = len(report["results"])
        bad = report["unregistered"]
        print()
        if bad:
            print("%d of %d fix_/repair_ scripts are not in the pipeline and not opted out:"
                  % (len(bad), total))
            for name in bad:
                print("  " + name)
            print("Register each in %s STEPS (or call it from a registered script), or add "
                  "'Pipeline: one-off' / 'retired' / 'entry-point' to its docstring." % PIPELINE_FILE)
        else:
            print("all %d fix_/repair_ scripts are registered or opted out" % total)
    return 1 if report["unregistered"] else 0


if __name__ == "__main__":
    sys.exit(main())
