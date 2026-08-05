#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Specification viewer: terminal queries and a self-contained HTML site.

Standard library only, compatible with Python 3.9. Read-only by
construction: it never rewrites specs/90-traceability.md and never acts
as a gate. The matrix stays the committed, byte-compared artifact; this
is a projection of the same data for people to read.

    srs_view.py                    summary: status counts and every requirement
    srs_view.py FR-CORE-020        one requirement in full
    srs_view.py --list [filters]   filtered list (see --help)
    srs_view.py --code src/a.py    which requirements describe this file
    srs_view.py --tree FR-CORE-010 what derives from it (--up for ancestors)
    srs_view.py --coverage         gaps: no tests, code outside the spec, …
    srs_view.py --diff spec/v0.1.0 working tree against a baseline revision
    srs_view.py --html [PATH]      self-contained page, default .srs-site/
    srs_view.py --json [PATH]      the model as JSON, for your own scripts

The parser lives in srs_check.py — one parser for the whole framework.
A broken specification is still worth reading, so parse errors and
duplicate identifiers are reported as a banner rather than a failure;
judging the specification remains the checker's job.
"""

import sys

# An import writes __pycache__ next to the imported module — inside the
# *target* repository, which has no reason to gitignore it. This line
# must stay above the srs_check import; moving it below is what makes
# the mess reappear.
sys.dont_write_bytecode = True

import argparse                                            # noqa: E402
import difflib                                             # noqa: E402
import html                                                # noqa: E402
import json                                                # noqa: E402
import os                                                  # noqa: E402
import re                                                  # noqa: E402
import subprocess                                          # noqa: E402

from urllib.parse import quote                              # noqa: E402

import srs_check                                           # noqa: E402

if not hasattr(srs_check, "parse_text"):
    sys.stderr.write("tools/srs_check.py predates this viewer — refresh "
                     "the tooling (re-run tools/srs_init.py from a "
                     "framework clone).\n")
    sys.exit(2)

ROOT = srs_check.ROOT
SPECS = srs_check.SPECS
DEFAULT_SITE = os.path.join(ROOT, ".srs-site")

LINK_FIELDS = srs_check.LINK_FIELDS
STATUSES = srs_check.STATUSES

# How an incoming link reads from the target's side.
INCOMING_LABEL = {
    "derives_from": "derived by",
    "refines": "refined by",
    "depends_on": "required by",
    "conflicts_with": "conflicted by",
    "superseded_by": "supersedes",
}

# Service files the parser skips (see srs_check.SKIP_FILES) but a
# reviewer still wants at hand.
DOCUMENT_FILES = ("README.md", "00-glossary.md", "constitution.md",
                  "90-traceability.md", "91-open-issues.md",
                  "92-baselines.md")

# Beyond this the layered graph stops being readable; what is dropped is
# always stated on the page rather than silently cut.
GRAPH_NODE_LIMIT = 150


# --------------------------------------------------------------------
# Model
# --------------------------------------------------------------------

def read_repo_url():
    """The blob-URL prefix used for links to code, e.g.
    https://gitlab.com/acme/app/-/blob/main — copied out of a browser,
    so no per-host URL shapes are guessed here.

    Viewer-only key: srs_check.load_config() iterates its own defaults
    and ignores anything else, so the checker never sees it.
    """
    try:
        with open(srs_check.CONFIG, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return ""
    value = data.get("repo_url", "") if isinstance(data, dict) else ""
    return value.rstrip("/") if isinstance(value, str) else ""


def _as_list(value):
    """Metadata shapes are validated by the checker, not here: a field
    that should be a list but is not simply reads as empty."""
    return [str(item) for item in value] if isinstance(value, list) else []


def _as_scalar(value):
    if isinstance(value, list):
        return str(value[0]) if value else ""
    return str(value) if value else ""


def _requirement_dict(req):
    parts = req.id.split("-")
    entry = {
        "id": req.id,
        "type": parts[0] if len(parts) > 2 else "",
        "area": parts[1] if len(parts) > 2 else "",
        "title": req.title,
        "path": req.path.replace(os.sep, "/"),
        "line": req.line,
        "status": _as_scalar(req.meta.get("status")),
        "verification": _as_scalar(req.meta.get("verification")),
        "statement": req.statement,
        "rationale": getattr(req, "rationale", ""),
        "superseded_by": _as_scalar(req.meta.get("superseded_by")),
    }
    for field in srs_check.LIST_FIELDS:
        entry[field] = _as_list(req.meta.get(field))
    return entry


def build_model(requirements, problems, with_code_scan=True):
    """Projects parsed requirements into the one structure the terminal
    renderers, the HTML generator and --json all consume."""
    entries = [_requirement_dict(req) for req in requirements]
    entries.sort(key=lambda e: (e["id"], e["path"], e["line"]))

    seen = {}
    for entry in entries:
        seen[entry["id"]] = seen.get(entry["id"], 0) + 1
    for rid in sorted(k for k, n in seen.items() if n > 1):
        problems.append("duplicate identifier %s — the checker treats "
                        "this as an error" % rid)

    incoming = {}
    for entry in entries:
        for field in LINK_FIELDS:
            for target in entry[field]:
                incoming.setdefault(target, []).append([field, entry["id"]])
        if entry["superseded_by"]:
            incoming.setdefault(entry["superseded_by"], []).append(
                ["superseded_by", entry["id"]])
    for refs in incoming.values():
        refs.sort(key=lambda pair: (pair[1], pair[0]))

    covered = set()
    for entry in entries:
        covered.update(entry["code"])
    all_code = srs_check.collect_code_files() if with_code_scan else set()

    return {
        "checker_version": srs_check.__version__,
        "repo_url": read_repo_url(),
        "areas": list(srs_check.AREAS),
        "types": list(srs_check.TYPES),
        "statuses": list(STATUSES),
        "requirements": entries,
        "incoming": incoming,
        "orphan_code": sorted(all_code - covered),
        "code_total": len(all_code),
        "documents": collect_documents(),
        "problems": problems,
    }


def collect_documents():
    """Service files and ADRs: invisible to the parser, wanted by a
    reviewer — requirements cite ART-* articles in their rationales."""
    result = []
    for name in DOCUMENT_FILES:
        if os.path.exists(os.path.join(SPECS, name)):
            result.append("specs/%s" % name)
    adr = os.path.join(SPECS, "adr")
    if os.path.isdir(adr):
        for name in sorted(os.listdir(adr)):
            if name.endswith(".md"):
                result.append("specs/adr/%s" % name)
    return result


def load_current():
    problems = []
    requirements = []
    for full, rel in srs_check.collect_spec_files():
        # A file that is not readable UTF-8, or vanished between the
        # listing and the read, is one more problem to report — not a
        # reason to refuse to show the other 400 requirements.
        try:
            requirements.extend(srs_check.parse_file(full, rel, problems))
        except (OSError, UnicodeDecodeError) as exc:
            problems.append("%s — cannot read: %s" % (rel, exc))
    return build_model(requirements, problems)


def by_id(model):
    return dict((entry["id"], entry) for entry in model["requirements"])


# --------------------------------------------------------------------
# Selection
# --------------------------------------------------------------------

def _matches_path(candidate, wanted):
    return candidate == wanted or candidate.startswith(wanted + "/")


def requirements_for_path(model, path):
    """Which requirements describe a file — the `code`/`tests` fields
    plus any implements:/verifies: annotation carried by the file
    itself. A directory prefix matches everything under it."""
    wanted = path.replace(os.sep, "/").strip()
    while wanted.startswith("./"):
        wanted = wanted[2:]
    wanted = wanted.rstrip("/")
    # Spec fields are relative to the repository root; a path typed from
    # somewhere else in the tree is translated rather than missed.
    if not os.path.exists(os.path.join(ROOT, wanted)) and os.path.exists(path):
        wanted = _repo_relative(path) or wanted
    found = set()
    for entry in model["requirements"]:
        for listed in entry["code"] + entry["tests"]:
            if _matches_path(listed, wanted):
                found.add(entry["id"])
    full = os.path.join(ROOT, wanted)
    if os.path.isfile(full):
        with open(full, "r", encoding="utf-8", errors="replace") as handle:
            for line in handle:
                if "srs-ignore" in line:
                    continue
                for match in srs_check.RE_ANNOTATION.finditer(line):
                    for rid in match.group(2).split(","):
                        found.add(rid.strip())
    return found


def select(model, args):
    entries = model["requirements"]
    if args.status:
        entries = [e for e in entries if e["status"] == args.status]
    if args.area:
        entries = [e for e in entries if e["area"] == args.area.upper()]
    if args.type:
        entries = [e for e in entries if e["type"] == args.type.upper()]
    if args.verification:
        entries = [e for e in entries
                   if e["verification"] == args.verification.upper()]
    if args.grep:
        needle = args.grep.lower()
        entries = [e for e in entries
                   if needle in e["id"].lower()
                   or needle in e["title"].lower()
                   or needle in e["statement"].lower()
                   or needle in e["rationale"].lower()]
    if args.code:
        wanted = requirements_for_path(model, args.code)
        entries = [e for e in entries if e["id"] in wanted]
    return entries


# --------------------------------------------------------------------
# Terminal output
# --------------------------------------------------------------------

class Style(object):
    """Colour only on a terminal that asked for it."""

    def __init__(self, stream):
        enabled = (hasattr(stream, "isatty") and stream.isatty()
                   and not os.environ.get("NO_COLOR"))
        self.bold = "\033[1m" if enabled else ""
        self.dim = "\033[2m" if enabled else ""
        self.off = "\033[0m" if enabled else ""

    def b(self, text):
        return "%s%s%s" % (self.bold, text, self.off)

    def d(self, text):
        return "%s%s%s" % (self.dim, text, self.off)


def out(text=""):
    sys.stdout.write(text + "\n")


def print_problems(model, style):
    if not model["problems"]:
        return
    out(style.b("%d problem(s) in the specification — run "
                "tools/srs_check.py for the full report:"
                % len(model["problems"])))
    for text in model["problems"][:10]:
        out("  %s" % text)
    if len(model["problems"]) > 10:
        out("  … %d more" % (len(model["problems"]) - 10))
    out()


def print_counts(model, style):
    counts = {}
    for entry in model["requirements"]:
        counts[entry["status"]] = counts.get(entry["status"], 0) + 1
    parts = ["%s %d" % (status, counts.get(status, 0)) for status in STATUSES]
    unknown = sorted(set(counts) - set(STATUSES))
    parts.extend("%s %d" % (status or "?", counts[status])
                 for status in unknown)
    total = len(model["requirements"])
    out("%s %s   %s" % (style.b(str(total)),
                        "requirement" if total == 1 else "requirements",
                        style.d(" · ".join(parts))))


def print_line(entry, style):
    out("%s  %-12s %s" % (style.b("%-14s" % entry["id"]),
                          entry["status"] or "?", entry["title"]))


def print_list(entries, style):
    if not entries:
        out(style.d("nothing matches"))
        return
    for entry in entries:
        print_line(entry, style)


def wrap(text, width=76, indent="  "):
    lines = []
    for paragraph in text.split("\n"):
        paragraph = paragraph.strip()
        if not paragraph:
            lines.append("")
            continue
        current = indent
        for word in paragraph.split():
            if len(current) + len(word) + 1 > width and current.strip():
                lines.append(current.rstrip())
                current = indent
            current += word + " "
        lines.append(current.rstrip())
    return "\n".join(lines).strip("\n")


def emphasize(text, style):
    """**bold** as the terminal's bold — and as plain text with the
    asterisks kept when there is no terminal to bold for."""
    if not style.bold:
        return text
    pieces = text.split("**")
    if len(pieces) < 3:
        return text
    return "".join(piece if index % 2 == 0 else style.b(piece)
                   for index, piece in enumerate(pieces))


def print_card(entry, model, style):
    known = by_id(model)
    out("%s — %s" % (style.b(entry["id"]), entry["title"]))
    out("  status %s   verification %s   %s"
        % (entry["status"] or "?", entry["verification"] or "?",
           style.d("%s:%d" % (entry["path"], entry["line"]))))
    if entry["statement"]:
        out()
        out(emphasize(wrap(entry["statement"]), style))
    if entry["rationale"]:
        out()
        out(emphasize(wrap(entry["rationale"]), style))
    out()
    for field in LINK_FIELDS:
        for target in entry[field]:
            other = known.get(target)
            out("  %-14s -> %-14s %s"
                % (field, target,
                   style.d("(%s)" % other["status"]) if other
                   else style.d("(unknown)")))
    if entry["superseded_by"]:
        other = known.get(entry["superseded_by"])
        out("  %-14s -> %-14s %s"
            % ("superseded_by", entry["superseded_by"],
               style.d("(%s)" % other["status"]) if other
               else style.d("(unknown)")))
    for field, source in model["incoming"].get(entry["id"], []):
        other = known.get(source)
        out("  %-14s <- %-14s %s"
            % (INCOMING_LABEL.get(field, field), source,
               style.d("(%s)" % other["status"]) if other
               else style.d("(unknown)")))
    for field in ("code", "tests"):
        for path in entry[field]:
            out("  %-14s    %s" % (field, path))


def children_of(model, rid):
    """Down the tree is *incoming* derives_from/refines: those links
    point from the specific requirement up to the general one."""
    result = []
    for field, source in model["incoming"].get(rid, []):
        if field in ("derives_from", "refines"):
            result.append((source, field))
    return result


def parents_of(entry):
    result = []
    for field in ("derives_from", "refines"):
        for target in entry[field]:
            result.append((target, field))
    return result


def print_tree(model, rid, upwards, style):
    known = by_id(model)

    def walk(node, prefix, seen):
        if upwards:
            entry = known.get(node)
            edges = parents_of(entry) if entry else []
        else:
            edges = children_of(model, node)
        edges.sort()
        for index, (other, field) in enumerate(edges):
            last = index == len(edges) - 1
            branch = "└── " if last else "├── "
            entry = known.get(other)
            status = entry["status"] if entry else "unknown"
            title = entry["title"] if entry else ""
            out("%s%s%s  %-12s %s %s"
                % (prefix, branch, style.b("%-14s" % other), status,
                   title, style.d("(%s)" % field)))
            if other in seen:
                out("%s%s%s" % (prefix, "    " if last else "│   ",
                                style.d("… already shown (link cycle)")))
                continue
            walk(other, prefix + ("    " if last else "│   "),
                 seen | {other})

    root = known.get(rid)
    if root is None:
        return False
    out("%s  %-12s %s" % (style.b(rid), root["status"], root["title"]))
    walk(rid, "", {rid})
    return True


def print_coverage(model, style):
    known = by_id(model)
    print_counts(model, style)
    out()

    untested = [e for e in model["requirements"]
                if e["status"] in ("implemented", "partial") and not e["tests"]]
    out(style.b("Realized without listed tests: %d" % len(untested)))
    for entry in untested:
        out("  %-14s %-12s method %s  %s"
            % (entry["id"], entry["status"], entry["verification"] or "?",
               entry["title"]))

    ahead = [e for e in model["requirements"]
             if e["status"] == "draft" and e["code"]]
    out()
    out(style.b("Draft with code — implementation ahead of approval: %d"
                % len(ahead)))
    for entry in ahead:
        out("  %-14s %s" % (entry["id"], entry["title"]))

    resting = []
    for entry in model["requirements"]:
        if entry["status"] not in ("implemented", "partial"):
            continue
        for field in ("derives_from", "depends_on", "refines"):
            for target in entry[field]:
                other = known.get(target)
                if other and other["status"] == "draft":
                    resting.append((entry["id"], field, target))
    out()
    out(style.b("Realized but resting on a draft: %d" % len(resting)))
    for rid, field, target in resting:
        out("  %-14s %s %s" % (rid, field, target))

    out()
    out(style.b("Code files no requirement references: %d of %d"
                % (len(model["orphan_code"]), model["code_total"])))
    for path in model["orphan_code"]:
        out("  %s" % path)


# --------------------------------------------------------------------
# Diff against a baseline revision
# --------------------------------------------------------------------

class ViewError(Exception):
    """Something the user can fix; reported plainly with exit code 2."""


def git(args, cwd=ROOT):
    return subprocess.check_output(["git"] + args, cwd=cwd,
                                   stderr=subprocess.PIPE)


def load_revision(rev):
    """Parses the specification as of `rev`. Paths come from git, i.e.
    relative to the git root, which is not necessarily this script's
    ROOT — nested repositories exist."""
    try:
        top = git(["rev-parse", "--show-toplevel"]).decode("utf-8").strip()
    except (OSError, subprocess.CalledProcessError):
        raise ViewError("git is unavailable or this is not a git "
                        "repository — --diff needs both")
    # realpath on both sides: git reports the physical path, while ROOT
    # comes from __file__ and keeps whatever symlinks led here (/tmp on
    # macOS). A mismatched prefix would walk out of the repository.
    prefix = os.path.relpath(os.path.realpath(ROOT),
                             os.path.realpath(top)).replace(os.sep, "/")
    prefix = "" if prefix == "." else prefix + "/"
    # From here on git runs at the top of the repository: an ls-tree
    # pathspec is resolved against the current directory, so running it
    # from a nested ROOT would look for <prefix>/<prefix>/specs and
    # quietly report every requirement as new.
    #
    # -z, because a path outside ASCII comes back C-quoted otherwise
    # ("specs/10-\321\204.md") — and a specification in any language is
    # the point of this framework.
    try:
        listing = git(["ls-tree", "-r", "-z", "--name-only", rev, "--",
                       prefix + "specs"], cwd=top).decode("utf-8", "replace")
    except subprocess.CalledProcessError as exc:
        detail = exc.stderr.decode("utf-8", "replace").strip()
        raise ViewError("cannot read revision %s: %s" % (rev, detail))

    problems = []
    requirements = []
    for git_path in sorted(filter(None, listing.split("\0"))):
        rel = git_path[len(prefix):] if prefix else git_path
        name = os.path.basename(rel)
        parts = rel.split("/")
        if not name.endswith(".md") or name in srs_check.SKIP_FILES:
            continue
        if any(part in srs_check.SKIP_DIRS for part in parts):
            continue
        blob = git(["show", "%s:%s" % (rev, git_path)], cwd=top)
        requirements.extend(srs_check.parse_text(
            blob.decode("utf-8", "replace"), rel, problems))
    return build_model(requirements, problems, with_code_scan=False)


DIFF_FIELDS = ("status", "verification", "title", "superseded_by",
               "code", "tests") + LINK_FIELDS


def compute_diff(old_model, new_model):
    """Working tree against the revision — not HEAD against it."""
    old = by_id(old_model)
    new = by_id(new_model)
    added = [new[rid] for rid in sorted(set(new) - set(old))]
    removed = [old[rid] for rid in sorted(set(old) - set(new))]
    changed = []
    for rid in sorted(set(old) & set(new)):
        fields = []
        for field in DIFF_FIELDS:
            if old[rid][field] != new[rid][field]:
                fields.append((field, old[rid][field], new[rid][field]))
        statement = []
        if old[rid]["statement"] != new[rid]["statement"]:
            statement = list(difflib.unified_diff(
                old[rid]["statement"].split("\n"),
                new[rid]["statement"].split("\n"),
                lineterm="", n=1))[2:]
        if fields or statement:
            changed.append({"entry": new[rid], "fields": fields,
                            "statement": statement})
    return {"rev": None, "added": added, "removed": removed,
            "changed": changed}


def _format_value(value):
    if isinstance(value, list):
        return "[%s]" % ", ".join(value) if value else "[]"
    return value or "—"


def _repo_relative(path):
    """A path as the specification would write it, or None when it
    points outside the repository."""
    inside = os.path.relpath(os.path.realpath(path),
                             os.path.realpath(ROOT)).replace(os.sep, "/")
    return None if inside.startswith("..") else inside


def print_diff(diff, style):
    out("%s  %s" % (style.b("Changes since %s" % diff["rev"]),
                    style.d("(working tree against the revision)")))
    out()
    out(style.b("added (%d)" % len(diff["added"])))
    for entry in diff["added"]:
        out("  + %-14s %-12s %s"
            % (entry["id"], entry["status"], entry["title"]))
    out()
    out(style.b("removed (%d)" % len(diff["removed"])))
    for entry in diff["removed"]:
        out("  - %-14s %-12s %s"
            % (entry["id"], entry["status"], entry["title"]))
    out()
    out(style.b("changed (%d)" % len(diff["changed"])))
    for item in diff["changed"]:
        out("  ~ %-14s %s" % (item["entry"]["id"], item["entry"]["title"]))
        for field, before, after in item["fields"]:
            out("      %-14s %s -> %s"
                % (field, _format_value(before), _format_value(after)))
        for line in item["statement"]:
            out("      %s" % line)


# --------------------------------------------------------------------
# HTML
# --------------------------------------------------------------------

CSS = """
:root {
  --bg: #ffffff; --fg: #1a1d21; --muted: #6b7280; --line: #e2e5e9;
  --panel: #f7f8fa; --accent: #2c5fd0; --mark: #fff3b0;
  --draft: #b45309; --deferred: #6d28d9; --partial: #0e7490;
  --implemented: #15803d; --superseded: #6b7280;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #14171a; --fg: #e6e8ea; --muted: #9aa3ad; --line: #2a2f36;
    --panel: #1b1f24; --accent: #7aa2f7; --mark: #4a3f14;
    --draft: #f59e0b; --deferred: #a78bfa; --partial: #22d3ee;
    --implemented: #4ade80; --superseded: #9aa3ad;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0; background: var(--bg); color: var(--fg);
  font: 15px/1.55 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
        Helvetica, Arial, sans-serif;
}
code, pre { font-family: ui-monospace, SFMono-Regular, Menlo,
  Consolas, monospace; font-size: 0.9em; }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
header {
  border-bottom: 1px solid var(--line); padding: 14px 20px;
  display: flex; flex-wrap: wrap; gap: 14px; align-items: baseline;
}
header h1 { font-size: 17px; margin: 0; }
header .counts { color: var(--muted); font-size: 13px; }
nav { margin-left: auto; display: flex; gap: 6px; }
nav button {
  font: inherit; font-size: 13px; padding: 4px 12px; cursor: pointer;
  background: var(--panel); color: var(--fg);
  border: 1px solid var(--line); border-radius: 6px;
}
nav button[aria-selected="true"] { background: var(--accent); color: #fff;
  border-color: var(--accent); }
.layout { display: flex; align-items: flex-start; }
aside {
  width: 250px; flex: none; padding: 16px; border-right: 1px solid var(--line);
  position: sticky; top: 0; max-height: 100vh; overflow-y: auto;
}
main { flex: 1; padding: 16px 20px; min-width: 0; }
#search {
  width: 100%; font: inherit; padding: 6px 8px; border-radius: 6px;
  border: 1px solid var(--line); background: var(--bg); color: var(--fg);
}
aside h2 {
  font-size: 11px; text-transform: uppercase; letter-spacing: .07em;
  color: var(--muted); margin: 18px 0 6px;
}
.chip {
  display: inline-block; font-size: 12px; padding: 2px 8px; margin: 2px 2px 2px 0;
  border: 1px solid var(--line); border-radius: 999px; cursor: pointer;
  background: var(--panel); color: var(--fg); user-select: none;
}
.chip[aria-pressed="true"] { background: var(--accent); color: #fff;
  border-color: var(--accent); }
.chip .n { color: var(--muted); }
.chip[aria-pressed="true"] .n { color: #dbe4f7; }
aside ul { list-style: none; margin: 0; padding: 0; }
aside li { font-size: 13px; margin: 3px 0; word-break: break-all; }
article {
  border: 1px solid var(--line); border-radius: 8px; padding: 12px 14px;
  margin-bottom: 12px; background: var(--panel);
}
article.superseded { opacity: .6; }
article h3 { margin: 0 0 6px; font-size: 15px; }
article h3 .id { font-family: ui-monospace, monospace; }
.badge {
  font-size: 11px; padding: 1px 7px; border-radius: 999px; margin-left: 6px;
  border: 1px solid currentColor; white-space: nowrap;
}
.st-draft { color: var(--draft); }
.st-deferred { color: var(--deferred); }
.st-partial { color: var(--partial); }
.st-implemented { color: var(--implemented); }
.st-superseded { color: var(--superseded); }
.badge.new { background: var(--implemented); color: #fff; border-color: transparent; }
.badge.changed { background: var(--draft); color: #fff; border-color: transparent; }
.where { color: var(--muted); font-size: 12px; }
.statement { margin: 8px 0; }
.statement .modal { background: var(--mark); padding: 0 3px; border-radius: 3px; }
.rationale { color: var(--muted); font-size: 14px; margin: 8px 0; }
.links { display: grid; grid-template-columns: auto auto 1fr; gap: 2px 10px;
  font-size: 13px; margin-top: 8px; }
.links .rel { color: var(--muted); }
.banner {
  border: 1px solid var(--draft); color: var(--draft); border-radius: 8px;
  padding: 10px 14px; margin-bottom: 14px; font-size: 14px;
}
table { border-collapse: collapse; font-size: 14px; }
th, td { text-align: left; padding: 4px 14px 4px 0; }
th { color: var(--muted); font-weight: 600; font-size: 12px;
  text-transform: uppercase; letter-spacing: .05em; }
section h2 { font-size: 15px; margin: 22px 0 8px; }
.scroll { overflow-x: auto; max-width: 100%; }
.graph text { font-family: ui-monospace, monospace; font-size: 11px;
  fill: var(--fg); }
.graph .node rect { fill: var(--panel); stroke: var(--line); }
.graph .node.dim { opacity: .2; }
.graph .edge { stroke: var(--muted); fill: none; }
.graph .edge.refines { stroke-dasharray: 5 3; }
.graph .edge.back { stroke-dasharray: 1 3; }
footer { border-top: 1px solid var(--line); margin-top: 24px; padding: 12px 20px;
  color: var(--muted); font-size: 12px; }
[hidden] { display: none !important; }
@media print {
  aside, nav, .banner { display: none; }
  body { font-size: 11pt; }
  article { break-inside: avoid; border-color: #ccc; background: none; }
  #view-dash, #view-graph { display: block !important; }
}
"""

JS = """
(function () {
  var cards = Array.prototype.slice.call(
    document.querySelectorAll('article[data-id]'));
  var search = document.getElementById('search');
  var chips = Array.prototype.slice.call(document.querySelectorAll('.chip'));
  var shown = document.getElementById('shown');
  var active = {};

  function passes(card) {
    for (var key in active) {
      if (!active[key].size) continue;
      if (!active[key].has(card.dataset[key])) return false;
    }
    var q = search.value.trim().toLowerCase();
    return !q || card.dataset.search.indexOf(q) !== -1;
  }

  function apply() {
    var visible = 0, live = {};
    cards.forEach(function (card) {
      var ok = passes(card);
      card.hidden = !ok;
      if (ok) { visible++; live[card.dataset.id] = true; }
    });
    if (shown) shown.textContent = visible;
    document.querySelectorAll('.graph .node').forEach(function (node) {
      node.classList.toggle('dim', !live[node.dataset.id]);
    });
  }

  chips.forEach(function (chip) {
    var key = chip.dataset.key;
    active[key] = active[key] || new Set();
    chip.addEventListener('click', function () {
      var on = chip.getAttribute('aria-pressed') === 'true';
      chip.setAttribute('aria-pressed', on ? 'false' : 'true');
      if (on) active[key].delete(chip.dataset.value);
      else active[key].add(chip.dataset.value);
      apply();
    });
    chip.addEventListener('keydown', function (event) {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        chip.click();
      }
    });
  });
  search.addEventListener('input', apply);

  // A link to a requirement the current filter hides would otherwise do
  // nothing — and following links in both directions is the point of
  // this page. Clear the filters and go there.
  function jump() {
    var id = location.hash.replace(/^#/, '');
    if (!id) return;
    var card = cards.filter(function (c) { return c.dataset.id === id; })[0];
    if (!card || !card.hidden) return;
    search.value = '';
    chips.forEach(function (chip) {
      chip.setAttribute('aria-pressed', 'false');
      active[chip.dataset.key].delete(chip.dataset.value);
    });
    apply();
    if (card.scrollIntoView) card.scrollIntoView();
  }
  window.addEventListener('hashchange', jump);

  var tabs = Array.prototype.slice.call(document.querySelectorAll('nav button'));
  tabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      tabs.forEach(function (other) {
        var on = other === tab;
        other.setAttribute('aria-selected', on ? 'true' : 'false');
        document.getElementById(other.dataset.view).hidden = !on;
      });
    });
  });

  document.querySelectorAll('.graph .node').forEach(function (node) {
    node.addEventListener('click', function () {
      tabs[0].click();
      location.hash = node.dataset.id;
      jump();          // hashchange stays silent when the hash repeats
    });
  });

  apply();
  jump();
})();
"""


def esc(text):
    return html.escape(text or "", quote=True)


def render_inline(text, modal_pattern):
    """A deliberately partial Markdown renderer: escaping, the modal
    verb, **strong**, *em*, `code`, paragraphs. A full parser without
    dependencies is not worth its weight here; anything else in a
    statement shows up literally.

    The modal verb is substituted first — srs_check.RE_MODAL matches the
    asterisks along with the word, so after **strong** became <strong>
    it would never match again.
    """
    text = esc(text)
    if modal_pattern is not None:
        text = modal_pattern.sub(
            lambda m: '<strong class="modal">%s</strong>'
                      % m.group(0).strip("*"), text)
    text = "".join(
        part if index % 2 == 0 else "<code>%s</code>" % part
        for index, part in enumerate(text.split("`")))
    text = _pair(text, "**", "strong")
    text = _pair(text, "*", "em")
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    return "".join("<p>%s</p>" % p.replace("\n", " ") for p in paragraphs)


def _pair(text, marker, tag):
    pieces = text.split(marker)
    if len(pieces) < 3:
        return text
    result = []
    for index, piece in enumerate(pieces):
        if index % 2 == 1 and index != len(pieces) - 1:
            result.append("<%s>%s</%s>" % (tag, piece, tag))
        else:
            result.append(piece)
    return "".join(result)


class Links(object):
    """Paths become links twice over: relative ones so the page works
    from file://, and repository ones when repo_url is configured.

    A page written outside the repository gets absolute file:// URLs
    instead — a relative path out of, say, /tmp is correct only for as
    long as nobody moves the page.
    """

    def __init__(self, model, out_dir):
        self.repo_url = model["repo_url"]
        # One resolved pair for both the decision and the path: mixing
        # resolved and unresolved sides is how a symlinked root produces
        # links that walk out of the repository.
        root, here = os.path.realpath(ROOT), os.path.realpath(out_dir)
        if os.path.relpath(here, root).startswith(".."):
            self.prefix = "file://" + quote(root)
        else:
            self.prefix = os.path.relpath(root, here).replace(os.sep, "/")

    def local(self, path):
        return "%s/%s" % (self.prefix, quote(path))

    def href(self, path, line=None):
        if self.repo_url:
            anchor = "#L%d" % line if line else ""
            return "%s/%s%s" % (self.repo_url, quote(path), anchor)
        return self.local(path)


def render_card(entry, model, known, links, diff_state):
    classes = ["superseded"] if entry["status"] == "superseded" else []
    badge = ""
    state = diff_state.get(entry["id"])
    if state:
        badge = '<span class="badge %s">%s</span>' % (state, state)
    rows = []
    for field in LINK_FIELDS:
        for target in entry[field]:
            rows.append((field, target, "→"))
    if entry["superseded_by"]:
        rows.append(("superseded_by", entry["superseded_by"], "→"))
    for field, source in model["incoming"].get(entry["id"], []):
        rows.append((INCOMING_LABEL.get(field, field), source, "←"))

    link_html = []
    for label, other, arrow in rows:
        target = known.get(other)
        status = target["status"] if target else "unknown"
        link_html.append(
            '<span class="rel">%s</span><span>%s</span>'
            '<span><a href="#%s">%s</a> <span class="rel">(%s)</span></span>'
            % (esc(label), arrow, esc(other), esc(other), esc(status)))
    for field in ("code", "tests"):
        for path in entry[field]:
            link_html.append(
                '<span class="rel">%s</span><span></span>'
                '<span><a href="%s"><code>%s</code></a></span>'
                % (field, esc(links.href(path)), esc(path)))

    parts = ['<article id="%s" data-id="%s" data-status="%s" data-type="%s" '
             'data-area="%s" data-file="%s" data-search="%s"%s>'
             % (esc(entry["id"]), esc(entry["id"]), esc(entry["status"]),
                esc(entry["type"]), esc(entry["area"]),
                esc(os.path.basename(entry["path"])),
                esc(" ".join([entry["id"], entry["title"], entry["statement"],
                              entry["rationale"]]).lower()),
                ' class="%s"' % " ".join(classes) if classes else "")]
    parts.append('<h3><span class="id">%s</span> — %s'
                 '<span class="badge st-%s">%s</span>'
                 '<span class="badge">%s</span>%s</h3>'
                 % (esc(entry["id"]), esc(entry["title"]),
                    esc(entry["status"] or "unknown"),
                    esc(entry["status"] or "unknown"),
                    esc(entry["verification"] or "?"), badge))
    parts.append('<div class="where"><a href="%s">%s:%d</a></div>'
                 % (esc(links.href(entry["path"], entry["line"])),
                    esc(entry["path"]), entry["line"]))
    parts.append('<div class="statement">%s</div>'
                 % render_inline(entry["statement"], srs_check.RE_MODAL))
    if entry["rationale"]:
        parts.append('<div class="rationale">%s</div>'
                     % render_inline(entry["rationale"], None))
    if link_html:
        parts.append('<div class="links">%s</div>' % "".join(link_html))
    parts.append("</article>")
    return "".join(parts)


def render_chips(key, values, counts):
    chips = []
    for value in values:
        if not counts.get(value):
            continue
        chips.append('<span class="chip" role="button" tabindex="0" '
                     'aria-pressed="false" data-key="%s" data-value="%s">%s '
                     '<span class="n">%d</span></span>'
                     % (key, esc(value), esc(value), counts[value]))
    return "".join(chips)


def render_dashboard(model, links):
    known = by_id(model)
    counts = {}
    for entry in model["requirements"]:
        counts[entry["status"]] = counts.get(entry["status"], 0) + 1
    rows = "".join("<tr><td><span class=\"badge st-%s\">%s</span></td>"
                   "<td>%d</td></tr>" % (esc(status), esc(status),
                                         counts.get(status, 0))
                   for status in STATUSES)

    def listing(entries, note):
        if not entries:
            return "<p>None.</p>"
        items = "".join('<li><a href="#%s">%s</a> %s</li>'
                        % (esc(e["id"]), esc(e["id"]), esc(e["title"]))
                        for e in entries)
        return "<p>%s</p><ul>%s</ul>" % (esc(note), items)

    untested = [e for e in model["requirements"]
                if e["status"] in ("implemented", "partial") and not e["tests"]]
    ahead = [e for e in model["requirements"]
             if e["status"] == "draft" and e["code"]]
    resting, seen_resting = [], set()
    for entry in model["requirements"]:
        if entry["status"] not in ("implemented", "partial"):
            continue
        for field in ("derives_from", "depends_on", "refines"):
            for target in entry[field]:
                other = known.get(target)
                if (other and other["status"] == "draft"
                        and entry["id"] not in seen_resting):
                    seen_resting.add(entry["id"])
                    resting.append(entry)
    orphans = "".join('<li><a href="%s"><code>%s</code></a></li>'
                      % (esc(links.href(path)), esc(path))
                      for path in model["orphan_code"])
    return ("<h2>Status</h2><table><tr><th>Status</th><th>Requirements</th>"
            "</tr>%s</table>"
            "<h2>Realized without listed tests</h2>%s"
            "<h2>Draft with code — implementation ahead of approval</h2>%s"
            "<h2>Realized but resting on a draft</h2>%s"
            "<h2>Code files no requirement references (%d of %d)</h2>"
            "<ul>%s</ul>"
            % (rows,
               listing(untested, "Verified by other means, or not yet set up."),
               listing(ahead, "Code exists before approval (ART-020)."),
               listing(resting, "Approve the parent or revisit the child."),
               len(model["orphan_code"]), model["code_total"],
               orphans or "<li>None.</li>"))


def render_diff_section(diff):
    def block(title, entries, sign):
        if not entries:
            return "<h2>%s (0)</h2><p>None.</p>" % title
        items = "".join('<li>%s <a href="#%s">%s</a> %s</li>'
                        % (sign, esc(e["id"]), esc(e["id"]), esc(e["title"]))
                        for e in entries)
        return "<h2>%s (%d)</h2><ul>%s</ul>" % (title, len(entries), items)

    changed = []
    for item in diff["changed"]:
        rows = "".join("<li><code>%s</code>: %s → %s</li>"
                       % (esc(field), esc(_format_value(before)),
                          esc(_format_value(after)))
                       for field, before, after in item["fields"])
        statement = ""
        if item["statement"]:
            statement = "<pre class=\"scroll\">%s</pre>" % esc(
                "\n".join(item["statement"]))
        changed.append('<li><a href="#%s">%s</a> %s<ul>%s</ul>%s</li>'
                       % (esc(item["entry"]["id"]), esc(item["entry"]["id"]),
                          esc(item["entry"]["title"]), rows, statement))
    return ("<h2>Changes since %s</h2>"
            "<p>The working tree against the revision.</p>%s%s"
            "<h2>Changed (%d)</h2>%s"
            % (esc(diff["rev"]),
               block("Added", diff["added"], "+"),
               block("Removed", diff["removed"], "−"),
               len(diff["changed"]),
               ("<ul>%s</ul>" % "".join(changed)) if changed
               else "<p>None.</p>"))


# --------------------------------------------------------------------
# Graph
# --------------------------------------------------------------------

NODE_W, NODE_H, GAP_X, GAP_Y = 118, 28, 18, 46
ROW_LIMIT = 10          # boxes per row before a layer wraps


def svg_escape(text):
    """SVG is XML: an unescaped & in a title breaks the whole document,
    and the HTML text escaper is not the same thing."""
    return (text.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace('"', "&quot;"))


def build_graph(model):
    """Layered layout over derives_from/refines.

    The checker looks for cycles in each field separately, so the union
    of the two can still contain one (A derives_from B, B refines A).
    The depth walk therefore carries a stack and treats a re-entry as
    depth 0 instead of recursing forever; such edges are drawn dashed
    and take no part in the layout.
    """
    known = by_id(model)
    edges = []
    for entry in model["requirements"]:
        for field in ("derives_from", "refines"):
            for target in entry[field]:
                if target in known:
                    edges.append((entry["id"], target, field))
    nodes = sorted({rid for edge in edges for rid in edge[:2]})
    dropped = 0
    if len(nodes) > GRAPH_NODE_LIMIT:
        dropped = len(nodes) - GRAPH_NODE_LIMIT
        nodes = nodes[:GRAPH_NODE_LIMIT]
        keep = set(nodes)
        edges = [e for e in edges if e[0] in keep and e[1] in keep]

    parents = {}
    for child, parent, _field in edges:
        parents.setdefault(child, []).append(parent)
    depth = {}

    def resolve(node, stack):
        if node in depth:
            return depth[node]
        if node in stack:
            return 0                       # back edge: break the walk
        stack.add(node)
        value = 0
        for parent in parents.get(node, []):
            value = max(value, resolve(parent, stack) + 1)
        stack.discard(node)
        depth[node] = value
        return value

    for node in nodes:
        resolve(node, set())

    layers = {}
    for node in nodes:
        layers.setdefault(depth.get(node, 0), []).append(node)
    # A wide layer wraps into several rows within its own band: forty
    # boxes on one line would push the page sideways, and a page that
    # scrolls horizontally is a page nobody reads.
    position = {}
    top = 1
    for level in sorted(layers):
        members = sorted(layers[level])
        rows = 0
        for index, node in enumerate(members):
            row, column = divmod(index, ROW_LIMIT)
            rows = max(rows, row + 1)
            position[node] = (1 + column * (NODE_W + GAP_X),
                              top + row * (NODE_H + 10))
        top += rows * (NODE_H + 10) + GAP_Y
    if not position:
        return "", 0
    width = max(x for x, _y in position.values()) + NODE_W + 2
    height = max(y for _x, y in position.values()) + NODE_H + 2

    parts = ['<div class="scroll"><svg class="graph" viewBox="0 0 %d %d" '
             'width="%d" height="%d" xmlns="http://www.w3.org/2000/svg">'
             % (width, height, width, height)]
    parts.append('<defs><marker id="a" viewBox="0 0 8 8" refX="7" refY="4" '
                 'markerWidth="6" markerHeight="6" orient="auto-start-reverse">'
                 '<path d="M0 0 L8 4 L0 8 z" fill="currentColor"/>'
                 '</marker></defs>')
    for child, parent, field in edges:
        if child not in position or parent not in position:
            continue
        cx, cy = position[child]
        px, py = position[parent]
        back = depth.get(parent, 0) >= depth.get(child, 0)
        klass = "edge back" if back else "edge %s" % field
        parts.append('<path class="%s" d="M %d %d L %d %d" '
                     'marker-end="url(#a)"/>'
                     % (klass, cx + NODE_W / 2, cy,
                        px + NODE_W / 2, py + NODE_H))
    for node in nodes:
        x, y = position[node]
        entry = known.get(node, {})
        parts.append('<g class="node st-%s" data-id="%s"><title>%s</title>'
                     '<rect x="%d" y="%d" width="%d" height="%d" rx="5" '
                     'stroke="currentColor"/>'
                     '<text x="%d" y="%d" text-anchor="middle">%s</text></g>'
                     % (svg_escape(entry.get("status", "")), svg_escape(node),
                        svg_escape("%s — %s" % (node, entry.get("title", ""))),
                        x, y, NODE_W, NODE_H,
                        x + NODE_W / 2, y + NODE_H / 2 + 4, svg_escape(node)))
    parts.append("</svg></div>")
    return "".join(parts), dropped


# --------------------------------------------------------------------
# Page
# --------------------------------------------------------------------

PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<style>__CSS__</style>
</head>
<body>
<header>
  <h1>__TITLE__</h1>
  <div class="counts"><span id="shown">__COUNT__</span> of __COUNT__ \
requirements</div>
  <nav>
    <button data-view="view-reqs" aria-selected="true">Requirements</button>
    <button data-view="view-dash" aria-selected="false">Dashboard</button>
    <button data-view="view-graph" aria-selected="false">Graph</button>
  </nav>
</header>
<div class="layout">
<aside>
  <input id="search" type="search" placeholder="search" autocomplete="off">
  __FILTERS__
  <h2>Documents</h2>
  <ul>__DOCUMENTS__</ul>
</aside>
<main>
  __BANNER__
  <section id="view-reqs">__DIFF____CARDS__</section>
  <section id="view-dash" hidden>__DASHBOARD__</section>
  <section id="view-graph" hidden>__GRAPH__</section>
</main>
</div>
<footer>__FOOTER__</footer>
<script>__JS__</script>
</body>
</html>
"""


def render_page(model, links, diff=None):
    entries = model["requirements"]
    known = by_id(model)
    diff_state = {}
    if diff:
        for entry in diff["added"]:
            diff_state[entry["id"]] = "new"
        for item in diff["changed"]:
            diff_state[item["entry"]["id"]] = "changed"

    counts = {"status": {}, "type": {}, "area": {}, "file": {}}
    for entry in entries:
        counts["status"][entry["status"]] = \
            counts["status"].get(entry["status"], 0) + 1
        counts["type"][entry["type"]] = counts["type"].get(entry["type"], 0) + 1
        counts["area"][entry["area"]] = counts["area"].get(entry["area"], 0) + 1
        name = os.path.basename(entry["path"])
        counts["file"][name] = counts["file"].get(name, 0) + 1

    filters = []
    for key, values in (("status", list(STATUSES)),
                        ("type", list(model["types"])),
                        ("area", list(model["areas"])),
                        ("file", sorted(counts["file"]))):
        extra = [v for v in sorted(counts[key]) if v not in values]
        chips = render_chips(key, values + extra, counts[key])
        if chips:
            filters.append("<h2>%s</h2>%s" % (key, chips))

    banner = ""
    if model["problems"]:
        items = "".join("<li>%s</li>" % esc(text)
                        for text in model["problems"][:10])
        banner = ('<div class="banner"><strong>%d problem(s) in the '
                  'specification.</strong> Run <code>tools/srs_check.py</code> '
                  'for the full report.<ul>%s</ul></div>'
                  % (len(model["problems"]), items))

    graph_svg, dropped = build_graph(model)
    if not graph_svg:
        graph = "<p>No derives_from or refines links yet.</p>"
    else:
        note = ""
        if dropped:
            note = ("<p>%d node(s) beyond the first %d are not drawn — the "
                    "layout stops being readable past that.</p>"
                    % (dropped, GRAPH_NODE_LIMIT))
        graph = ("<p>Solid: <code>derives_from</code>. Dashed: "
                 "<code>refines</code>. Dotted: a link that closes a cycle "
                 "across the two, excluded from the layout. Filters dim the "
                 "nodes; the layout itself is fixed.</p>%s%s" % (note,
                                                                 graph_svg))

    documents = "".join('<li><a href="%s">%s</a></li>'
                        % (esc(links.href(path)),
                           esc(path[len("specs/"):]))
                        for path in model["documents"])

    # One pass over the template, not one pass per token: a requirement
    # whose text happens to contain __GRAPH__ (this tool's own
    # specification, for one) must not have it substituted after the
    # cards are already in place.
    filled = dict((
            ("__TITLE__", esc(project_title())),
            ("__CSS__", CSS),
            ("__JS__", JS),
            ("__COUNT__", str(len(entries))),
            ("__FILTERS__", "".join(filters)),
            ("__DOCUMENTS__", documents),
            ("__BANNER__", banner),
            ("__DIFF__", render_diff_section(diff) if diff else ""),
            ("__CARDS__", "".join(render_card(e, model, known, links,
                                              diff_state)
                                  for e in entries)),
            ("__DASHBOARD__", render_dashboard(model, links)),
            ("__GRAPH__", graph),
            # No wall-clock stamp on purpose: two runs of the generator
            # must produce byte-identical output.
            ("__FOOTER__", "Generated by tools/srs_view.py from srs_check %s. "
                           "Requirements are rendered; the glossary, the "
                           "constitution and the ADRs are linked, not "
                           "rendered." % esc(model["checker_version"]))))
    pattern = re.compile("|".join(re.escape(token) for token in filled))
    return pattern.sub(lambda match: filled[match.group(0)], PAGE)


def project_title():
    """The project's name, borrowed from the agent guide's heading
    ("# Acme — agent guide"). The specification's own §1 heading would
    only ever say "Introduction", and the directory name is the last
    thing left to fall back on."""
    for name in ("AGENTS.md", "CLAUDE.md"):
        try:
            with open(os.path.join(ROOT, name), "r",
                      encoding="utf-8") as handle:
                for line in handle:
                    if not line.startswith("# "):
                        continue
                    title = line[2:].strip()
                    for dash in (" — ", " – ", " - "):
                        title = title.split(dash)[0]
                    if title and not title.startswith("<"):
                        return "%s — specification" % title
                    break
        except OSError:
            continue
    return "%s — specification" % os.path.basename(ROOT)


def ensure_parent(target):
    out_dir = os.path.dirname(os.path.abspath(target)) or ROOT
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    return out_dir


def write_site(model, target, diff=None):
    out_dir = ensure_parent(target)
    links = Links(model, out_dir)
    with open(target, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(render_page(model, links, diff))
    # Only the default directory ignores itself: writing a .gitignore
    # into a path the user named would be presumptuous.
    if os.path.realpath(out_dir) == os.path.realpath(DEFAULT_SITE):
        with open(os.path.join(out_dir, ".gitignore"), "w",
                  encoding="utf-8", newline="\n") as handle:
            handle.write("*\n")
    return os.path.abspath(target)


# --------------------------------------------------------------------
# Entry point
# --------------------------------------------------------------------

def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="srs_view.py",
        description="Read the specification: terminal queries and a "
                    "self-contained HTML page. Never writes to specs/.")
    parser.add_argument("requirement", nargs="?",
                        help="identifier to show in full, e.g. FR-CORE-020")
    parser.add_argument("--list", action="store_true",
                        help="list requirements (with the filters below)")
    parser.add_argument("--status", help="filter by status")
    parser.add_argument("--area", help="filter by area")
    parser.add_argument("--type", help="filter by type (FR, NFR, IF, …)")
    parser.add_argument("--verification", help="filter by method (T, D, I, A)")
    parser.add_argument("--grep", help="filter by text in id/title/statement")
    parser.add_argument("--code", metavar="PATH",
                        help="requirements describing this file or directory, "
                             "by code/tests fields and by the file's own "
                             "implements:/verifies: annotations")
    parser.add_argument("--tree", metavar="ID",
                        help="what derives from this requirement")
    parser.add_argument("--up", action="store_true",
                        help="with --tree: walk to the ancestors instead")
    parser.add_argument("--coverage", action="store_true",
                        help="requirements without tests, code outside the "
                             "specification, drafts with code")
    parser.add_argument("--diff", metavar="REV",
                        help="compare the working tree against a revision, "
                             "usually a spec/vX.Y.Z baseline tag")
    parser.add_argument("--html", nargs="?", const=os.path.join(
        DEFAULT_SITE, "index.html"), metavar="PATH",
        help="write a self-contained page (default .srs-site/index.html)")
    parser.add_argument("--json", nargs="?", const="-", metavar="PATH",
                        help="write the model as JSON (default stdout); with "
                             "--diff it carries the comparison too")
    parser.add_argument("--repo-url", dest="repo_url", metavar="URL",
                        help="blob-URL prefix for links to code, overriding "
                             "repo_url in specs/srs-config.json; in CI the "
                             "revision is usually known, e.g. "
                             "$CI_PROJECT_URL/-/blob/$CI_COMMIT_SHA")
    return parser.parse_args(argv)


def main(argv=None):
    if hasattr(sys.stdout, "reconfigure"):
        # A specification may be written in any language; a C locale
        # must not turn reading it into a UnicodeEncodeError.
        sys.stdout.reconfigure(errors="replace")
    args = parse_args(argv)
    style = Style(sys.stdout)

    if not os.path.isdir(SPECS):
        sys.stderr.write("specs/ directory not found: %s\n" % SPECS)
        return 2

    model = load_current()
    if args.repo_url:
        model["repo_url"] = args.repo_url.rstrip("/")
    diff = None
    if args.diff:
        try:
            diff = compute_diff(load_revision(args.diff), model)
        except ViewError as exc:
            sys.stderr.write("%s\n" % exc)
            return 2
        diff["rev"] = args.diff

    # A mistyped output path deserves a sentence, not a traceback. Both
    # outputs may be asked for at once; neither silently wins.
    try:
        if args.json is not None:
            payload = dict(model)
            if diff:
                payload["diff"] = diff
            text = json.dumps(payload, ensure_ascii=False, indent=2,
                              sort_keys=True) + "\n"
            if args.json == "-":
                sys.stdout.write(text)
            else:
                ensure_parent(args.json)
                with open(args.json, "w", encoding="utf-8",
                          newline="\n") as handle:
                    handle.write(text)
                out("JSON written: %s" % os.path.abspath(args.json))

        if args.html is not None:
            out("Page written: %s" % write_site(model, args.html, diff))

        if args.json is not None or args.html is not None:
            return 0
    except OSError as exc:
        sys.stderr.write("cannot write the output: %s\n" % exc)
        return 2

    print_problems(model, style)

    if args.requirement:
        entry = by_id(model).get(args.requirement)
        if entry is None:
            sys.stderr.write("no requirement %s\n" % args.requirement)
            return 1
        print_card(entry, model, style)
        return 0

    if args.tree:
        if not print_tree(model, args.tree, args.up, style):
            sys.stderr.write("no requirement %s\n" % args.tree)
            return 1
        return 0

    if args.coverage:
        print_coverage(model, style)
        return 0

    if diff:
        print_diff(diff, style)
        return 0

    entries = select(model, args)
    if not args.list:
        print_counts(model, style)
        out()
    print_list(entries, style)
    return 0


if __name__ == "__main__":
    sys.exit(main())
