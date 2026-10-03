"""Generate the ue-run skill's reference pages from this checkout's own source.

    python tools/ue5/gen_ue_reference.py OUTDIR [--logs PATH ...]

Writes two Markdown files into OUTDIR:

  bioshock-switches.md   every TEXT("bioshock...") command-line switch the BioShockRuntime plugin
                         reads through FParse::Param / FParse::Value (directly or via a small
                         parse helper), with file:line and the source line for context.

  unreal-api-in-use.md   every unreal.<Class>, unreal.<Class>.<member> and unreal.<function> used
                         in tools/ue5/*.py, with a use count and one example file:line, plus the
                         editor property names passed to get/set_editor_property.

Why: 41 headless runs died on AttributeError from guessing at UE 5.7's Python API. A name already
used by a script in this repo is strong evidence it exists; a new probe should reuse those calls.
Usage is not proof, so names that an Unreal log recorded as missing (AttributeError / "Failed to
find property") are flagged. Logs are read from BioShockUE5/Saved/ue_run and Saved/Logs, plus any
--logs files or directories.
"""

import argparse
import datetime
import io
import re
import sys
import tokenize
from collections import defaultdict
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent.parent
PLUGIN_SOURCE = TOOLS / "BioShockRuntime" / "Source"
DEFAULT_LOG_DIRS = [Path(r"C:\Users\Jack\Documents\BioShockUE5\Saved\ue_run"),
                    Path(r"C:\Users\Jack\Documents\BioShockUE5\Saved\Logs")]

SWITCH_RE = re.compile(r'TEXT\("(bioshock[a-z0-9_]*=?)"\)')
FPARSE_RE = re.compile(r"FParse::(Param|Value|Bool)\s*\(")
# A helper that forwards its key to FParse: `bool ParseMovementVector(const TCHAR* Key, ...)` or
# `const auto ParseTriple = [](const TCHAR* Key, ...)`.
HELPER_DEF_RE = re.compile(
    r"(?:\b(\w+)\s*\(\s*const\s+TCHAR\s*\*\s*\w+|\b(\w+)\s*=\s*\[[^\]]*\]\s*\(\s*const\s+TCHAR\s*\*)")

MISSING_PATTERNS = [
    (re.compile(r"module 'unreal' has no attribute '(\w+)'"), lambda m: "unreal.%s" % m.group(1)),
    (re.compile(r"type object '(\w+)' has no attribute '(\w+)'"),
     lambda m: "unreal.%s.%s" % (m.group(1), m.group(2))),
    # Only capitalised non-builtin type names: "'NoneType' object has no attribute" is a script bug
    # (a lookup returned None), not a missing UE API, and dict/str/list are lowercase.
    (re.compile(r"'(?!NoneType')([A-Z]\w*)' object has no attribute '(\w+)'"),
     lambda m: "unreal.%s.%s" % (m.group(1), m.group(2))),
    (re.compile(r"Failed to find property '(\w+)' for attribute '\w+' on '(\w+)'"),
     lambda m: "property %s on %s" % (m.group(1), m.group(2))),
]


def rel(path):
    try:
        return Path(path).resolve().relative_to(REPO).as_posix()
    except ValueError:
        return Path(path).as_posix()


def md_escape(text):
    return text.replace("|", "\\|").replace("`", "'")


# ---------------------------------------------------------------- switches


def find_helpers(sources):
    """Names of functions/lambdas taking a `const TCHAR* Key` whose body calls FParse."""
    helpers = set()
    for text in sources.values():
        lines = text.splitlines()
        for index, line in enumerate(lines):
            match = HELPER_DEF_RE.search(line)
            if not match:
                continue
            body = "\n".join(lines[index:index + 12])
            if FPARSE_RE.search(body):
                helpers.add(match.group(1) or match.group(2))
    helpers.discard("if")
    return helpers


def collect_switches(source_root=PLUGIN_SOURCE):
    files = sorted(list(source_root.rglob("*.cpp")) + list(source_root.rglob("*.h")))
    sources = {path: path.read_text(encoding="utf-8", errors="replace") for path in files}
    helpers = find_helpers(sources)
    switches = defaultdict(list)
    for path, text in sources.items():
        lines = text.splitlines()
        for index, line in enumerate(lines):
            for match in SWITCH_RE.finditer(line):
                # The call may open a line or two above the literal (multi-line FParse::Value), but
                # never reach back past the end of the previous statement.
                start = index
                while start > max(0, index - 3) and not lines[start - 1].rstrip().endswith((";", "{", "}")):
                    start -= 1
                window = "\n".join(lines[start:index + 1])
                kinds = FPARSE_RE.findall(window)
                via = None
                if kinds:
                    how = "FParse::" + kinds[-1]
                else:
                    called = [h for h in helpers if re.search(r"\b%s\s*\(" % re.escape(h), window)]
                    if not called:
                        continue  # a lowercase literal that is not a parsed switch
                    via = called[0]
                    how = "FParse::Value via %s()" % via
                switches[match.group(1)].append({
                    "file": path.relative_to(source_root).as_posix(), "line": index + 1, "how": how,
                    "context": line.strip()[:160],
                })
    return switches


def render_switches(switches):
    out = io.StringIO()
    out.write("# BioShockRuntime command-line switches\n\n")
    out.write("Generated %s by `python tools/ue5/gen_ue_reference.py <outdir>` from "
              "`tools/ue5/BioShockRuntime/Source` (paths below are relative to it). "
              "Do not edit by hand.\n\n"
              % datetime.date.today().isoformat())
    out.write("%d switches. Pass them on the game/editor command line with a leading dash "
              "(`-bioshockscreenshot`, `-bioshockshotpath=C:/x.png`). A switch ending in `=` takes "
              "a value; `FParse::Param` switches are bare flags. capture_shot.ps1 forwards extras "
              "with `-Extra '-bioshockvmoffset=28,10,-24'`.\n\n" % len(switches))
    out.write("| switch | parsed by | where | context |\n|---|---|---|---|\n")
    for name in sorted(switches):
        uses = switches[name]
        first = uses[0]
        where = ", ".join("%s:%d" % (u["file"], u["line"]) for u in uses[:4])
        if len(uses) > 4:
            where += " (+%d)" % (len(uses) - 4)
        how = " / ".join(sorted({u["how"] for u in uses}))
        out.write("| `-%s` | %s | %s | `%s` |\n" % (name, how, where, md_escape(first["context"])))
    return out.getvalue()


# ---------------------------------------------------------------- unreal API


def scan_python(path):
    """Yield (dotted_name, line) for unreal.X / unreal.X.y in code (not strings or comments),
    plus ("@prop:" + name, line) for get/set_editor_property("name") calls and
    ("@guard:" + name, line) for hasattr/getattr(unreal, "Name")."""
    text = path.read_text(encoding="utf-8", errors="replace")
    try:
        tokens = [t for t in tokenize.generate_tokens(io.StringIO(text).readline)
                  if t.type not in (tokenize.NL, tokenize.NEWLINE, tokenize.COMMENT,
                                    tokenize.INDENT, tokenize.DEDENT)]
    except (tokenize.TokenError, SyntaxError, IndentationError):
        return
    count = len(tokens)
    for i, tok in enumerate(tokens):
        if tok.type != tokenize.NAME:
            continue
        nxt = tokens[i + 1] if i + 1 < count else None
        prev = tokens[i - 1] if i > 0 else None
        if tok.string == "unreal" and nxt and nxt.string == "." and not (prev and prev.string == "."):
            if i + 2 < count and tokens[i + 2].type == tokenize.NAME:
                first = tokens[i + 2].string
                name = "unreal." + first
                if (i + 4 < count and tokens[i + 3].string == "."
                        and tokens[i + 4].type == tokenize.NAME and first[:1].isupper()):
                    name += "." + tokens[i + 4].string
                yield name, tok.start[0]
        elif tok.string in ("get_editor_property", "set_editor_property") and nxt and nxt.string == "(":
            arg = tokens[i + 2] if i + 2 < count else None
            if arg is not None and arg.type == tokenize.STRING:
                literal = arg.string.strip("rbuRBU")
                if literal[:1] in "'\"":
                    yield "@prop:" + literal.strip("'\""), tok.start[0]
        elif tok.string in ("hasattr", "getattr") and nxt and nxt.string == "(":
            if (i + 4 < count and tokens[i + 2].string == "unreal" and tokens[i + 3].string == ","
                    and tokens[i + 4].type == tokenize.STRING):
                yield "@guard:unreal." + tokens[i + 4].string.strip("'\""), tok.start[0]


def collect_api(files):
    uses = defaultdict(lambda: {"count": 0, "example": None, "files": set()})
    props = defaultdict(lambda: {"count": 0, "example": None})
    guarded = {}
    for path in files:
        for name, line in scan_python(path):
            where = "%s:%d" % (rel(path), line)
            if name.startswith("@prop:"):
                entry = props[name[6:]]
                entry["count"] += 1
                entry["example"] = entry["example"] or where
            elif name.startswith("@guard:"):
                guarded.setdefault(name[7:], where)
            else:
                entry = uses[name]
                entry["count"] += 1
                entry["example"] = entry["example"] or where
                entry["files"].add(rel(path))
    return uses, props, guarded


def collect_missing(log_paths):
    missing = {}
    for path in log_paths:
        try:
            with open(path, encoding="utf-8", errors="replace") as handle:
                for line in handle:
                    if "attribute" not in line and "property" not in line:
                        continue
                    for pattern, render in MISSING_PATTERNS:
                        for match in pattern.finditer(line):
                            missing.setdefault(render(match), Path(path).name)
        except OSError:
            continue
    return missing


def expand_logs(paths):
    found = []
    for path in paths:
        path = Path(path)
        if path.is_dir():
            found += sorted(path.glob("*.log"))
        elif path.is_file():
            found.append(path)
    return found


def render_api(uses, props, guarded, missing, script_count, log_count):
    out = io.StringIO()
    out.write("# unreal Python API in use (UE 5.7)\n\n")
    out.write("Generated %s by `python tools/ue5/gen_ue_reference.py <outdir>` from %d scripts in "
              "`tools/ue5/*.py` and %d Unreal logs. Do not edit by hand.\n\n"
              % (datetime.date.today().isoformat(), script_count, log_count))
    out.write("Before calling an `unreal` API in a new probe, find it here and copy the example's "
              "usage. A name used by a script that ran is strong evidence it exists in UE 5.7; a "
              "name not listed is a guess -- check it with `hasattr(unreal, \"Name\")` first and "
              "fail loudly. Rows marked MISSING raised AttributeError (or 'Failed to find "
              "property') in a real log: they do not exist, even though a script mentions them. "
              "Rows marked guarded are only touched behind hasattr/getattr.\n\n")
    out.write("Instance methods (`actor.get_actor_location()`) are not listed: the scanner cannot "
              "know an object's class. Search `tools/ue5/*.py` for the method name instead.\n\n")

    if missing:
        out.write("## Known missing (seen failing in logs)\n\n")
        for name in sorted(missing):
            out.write("- `%s` -- %s\n" % (name, missing[name]))
        out.write("\n")

    def flag(name):
        notes = []
        if name in missing:
            notes.append("MISSING")
        if name in guarded:
            notes.append("guarded")
        return (" **%s**" % ", ".join(notes)) if notes else ""

    functions = sorted(n for n in uses if n.count(".") == 1 and not n[7:8].isupper())
    out.write("## Module functions (%d)\n\n| call | uses | example |\n|---|---|---|\n" % len(functions))
    for name in functions:
        u = uses[name]
        out.write("| `%s`%s | %d | %s |\n" % (name, flag(name), u["count"], u["example"]))

    classes = sorted({".".join(n.split(".")[:2]) for n in uses if n[7:8].isupper()})
    out.write("\n## Classes, enums and their members (%d classes)\n\n" % len(classes))
    out.write("A class row counts every use of the class, members included.\n\n")
    out.write("| name | uses | example |\n|---|---|---|\n")
    for cls in classes:
        members = sorted(n for n in uses if n.startswith(cls + "."))
        total = sum(uses[n]["count"] for n in members) + (uses[cls]["count"] if cls in uses else 0)
        example = uses[cls]["example"] if cls in uses else uses[members[0]]["example"]
        out.write("| `%s`%s | %d | %s |\n" % (cls, flag(cls), total, example))
        for name in members:
            u = uses[name]
            out.write("| `%s`%s | %d | %s |\n" % (name, flag(name), u["count"], u["example"]))

    out.write("\n## Editor property names passed to get/set_editor_property (%d)\n\n" % len(props))
    out.write("Property names are per class; the example line shows which object it was used on.\n\n")
    out.write("| property | uses | example |\n|---|---|---|\n")
    for name in sorted(props):
        p = props[name]
        bad = [m for m in missing if m.startswith("property %s on " % name)]
        note = (" **MISSING on %s**" % ", ".join(m.split(" on ")[1] for m in bad)) if bad else ""
        out.write("| `%s`%s | %d | %s |\n" % (name, note, p["count"], p["example"]))
    return out.getvalue()


def main(argv=None):
    parser = argparse.ArgumentParser(description="Generate the ue-run skill reference pages.")
    parser.add_argument("outdir")
    parser.add_argument("--logs", nargs="*", default=[],
                        help="extra Unreal log files or directories to mine for AttributeErrors")
    args = parser.parse_args(argv)
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    switches = collect_switches()
    (outdir / "bioshock-switches.md").write_text(render_switches(switches), encoding="utf-8")

    scripts = sorted(TOOLS.glob("*.py"))
    uses, props, guarded = collect_api(scripts)
    logs = expand_logs(DEFAULT_LOG_DIRS + [Path(p) for p in args.logs])
    missing = collect_missing(logs)
    (outdir / "unreal-api-in-use.md").write_text(
        render_api(uses, props, guarded, missing, len(scripts), len(logs)), encoding="utf-8")

    print("bioshock-switches.md : %d switches" % len(switches))
    print("unreal-api-in-use.md : %d names, %d editor properties, %d known missing, from %d scripts"
          " / %d logs" % (len(uses), len(props), len(missing), len(scripts), len(logs)))
    print("written to %s" % outdir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
