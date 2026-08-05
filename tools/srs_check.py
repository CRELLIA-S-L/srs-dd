#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Specification integrity checker and traceability matrix generator.

Standard library only, compatible with Python 3.9. The specification
markup rules are described in specs/README.md — that file is the single
normative document; this script only enforces it.

    python3 tools/srs_check.py             check and rewrite 90-traceability.md
    python3 tools/srs_check.py --no-write  check only

Project-specific settings (requirement areas, code roots, source file
extensions) live in specs/srs-config.json. The defaults below apply when
that file is absent.
"""

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPECS = os.path.join(ROOT, "specs")
TRACE = os.path.join(SPECS, "90-traceability.md")
CONFIG = os.path.join(SPECS, "srs-config.json")

# Files in specs/ that do not contain requirements.
SKIP_FILES = {"README.md", "00-glossary.md", "constitution.md",
              "90-traceability.md", "91-open-issues.md"}
SKIP_DIRS = {"archive", "adr"}

# Fallbacks used when specs/srs-config.json is missing. Edit the config,
# not these constants.
DEFAULT_AREAS = ["CORE", "UI", "API", "DATA", "SEC"]
DEFAULT_CODE_ROOTS = ["src"]
DEFAULT_CODE_EXTENSIONS = [".py", ".ts", ".tsx", ".js", ".swift", ".kt",
                           ".go", ".rs", ".java", ".c", ".cpp", ".h", ".m"]


def load_config():
    if not os.path.exists(CONFIG):
        return DEFAULT_AREAS, DEFAULT_CODE_ROOTS, DEFAULT_CODE_EXTENSIONS
    with open(CONFIG, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    return (data.get("areas", DEFAULT_AREAS),
            data.get("code_roots", DEFAULT_CODE_ROOTS),
            data.get("code_extensions", DEFAULT_CODE_EXTENSIONS))


AREAS, CODE_ROOTS, CODE_EXTENSIONS = load_config()

TYPES = ("FR", "NFR", "IF", "INV", "CON")

STATUSES = ("implemented", "partial", "deferred", "superseded")
VERIFICATIONS = ("T", "D", "I", "A")

LINK_FIELDS = ("derives_from", "refines", "depends_on", "conflicts_with")
LIST_FIELDS = LINK_FIELDS + ("code", "tests")
SCALAR_FIELDS = ("status", "verification", "superseded_by")
KNOWN_FIELDS = set(LIST_FIELDS) | set(SCALAR_FIELDS)

RE_ID = re.compile(r"^(%s)-(%s)-(\d{3})$" % ("|".join(TYPES), "|".join(AREAS)))
RE_HEADING = re.compile(r"^###\s+([A-Za-z]+-[A-Za-z]+-\d+)\s*(?:[—–-]\s*)?(.*)$")
RE_ANY_HEADING = re.compile(r"^#{1,6}\s")
RE_FENCE_OPEN = re.compile(r"^\s*```+\s*yaml\s*$")
RE_FENCE_CLOSE = re.compile(r"^\s*```+\s*$")
RE_RATIONALE = re.compile(r"^\s*\*\*Rationale\.?\*\*")
# Exactly one bolded modal verb per requirement statement:
# shall / must (binding), should (recommendation), may (permission).
RE_MODAL = re.compile(r"\*\*(?:shall|must|should|may)(?:\s+not)?\*\*",
                      re.IGNORECASE)


class Requirement(object):
    def __init__(self, rid, title, path, line):
        self.id = rid
        self.title = title
        self.path = path          # path relative to the repository root
        self.line = line          # 1-based line number of the heading
        self.meta = {}
        self.statement = ""

    def links(self, field):
        return self.meta.get(field, [])

    @property
    def where(self):
        return "%s:%d" % (self.path, self.line)


def parse_metadata(lines, path, line_no, errors):
    """Parses a restricted YAML subset: flat keys, scalars, bracketed lists."""
    meta = {}
    for offset, raw in enumerate(lines):
        text = raw.strip()
        if not text or text.startswith("#"):
            continue
        if ":" not in text:
            errors.append("%s:%d — metadata line without a colon: %r"
                          % (path, line_no + offset, text))
            continue
        key, _, value = text.partition(":")
        key = key.strip()
        value = value.strip()
        if key in meta:
            errors.append("%s:%d — duplicate key %r" % (path, line_no + offset, key))
        if value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            meta[key] = [v.strip() for v in inner.split(",") if v.strip()] if inner else []
        else:
            meta[key] = value
    return meta


def parse_file(path, rel, errors):
    with open(path, "r", encoding="utf-8") as handle:
        lines = handle.read().split("\n")

    requirements = []
    index = 0
    total = len(lines)

    while index < total:
        match = RE_HEADING.match(lines[index])
        if not match:
            index += 1
            continue

        req = Requirement(match.group(1), match.group(2).strip(), rel, index + 1)
        index += 1

        # Metadata block: the first ```yaml fence before the next heading.
        meta_lines = []
        found_fence = False
        while index < total:
            if RE_ANY_HEADING.match(lines[index]):
                break
            if RE_FENCE_OPEN.match(lines[index]):
                found_fence = True
                index += 1
                start = index + 1
                while index < total and not RE_FENCE_CLOSE.match(lines[index]):
                    meta_lines.append(lines[index])
                    index += 1
                index += 1  # closing fence
                req.meta = parse_metadata(meta_lines, rel, start, errors)
                break
            index += 1

        if not found_fence:
            errors.append("%s — no metadata block" % req.where)
            requirements.append(req)
            continue

        # Statement: up to the rationale or the next heading.
        statement = []
        while index < total:
            if RE_ANY_HEADING.match(lines[index]) or RE_RATIONALE.match(lines[index]):
                break
            statement.append(lines[index])
            index += 1
        req.statement = "\n".join(statement).strip()

        requirements.append(req)

    return requirements


def collect_spec_files():
    result = []
    for current, dirs, files in os.walk(SPECS):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in sorted(files):
            if not name.endswith(".md") or name in SKIP_FILES:
                continue
            full = os.path.join(current, name)
            result.append((full, os.path.relpath(full, ROOT)))
    return sorted(result, key=lambda pair: pair[1])


def find_cycles(requirements, field):
    """Finds loops over a single link kind. Returns a list of cycle paths."""
    graph = dict((r.id, [t for t in r.links(field)]) for r in requirements)
    cycles = []
    state = {}   # 0 untouched, 1 in progress, 2 done
    stack = []

    def walk(node):
        state[node] = 1
        stack.append(node)
        for nxt in graph.get(node, []):
            if nxt not in graph:
                continue
            if state.get(nxt, 0) == 0:
                walk(nxt)
            elif state.get(nxt) == 1:
                start = stack.index(nxt)
                cycles.append(stack[start:] + [nxt])
        stack.pop()
        state[node] = 2

    for rid in graph:
        if state.get(rid, 0) == 0:
            walk(rid)
    return cycles


def validate(requirements):
    errors = []
    warnings = []

    by_id = {}
    for req in requirements:
        if req.id in by_id:
            errors.append("%s — identifier %s is already used at %s"
                          % (req.where, req.id, by_id[req.id].where))
        else:
            by_id[req.id] = req

        if not RE_ID.match(req.id):
            errors.append("%s — identifier does not match <TYPE>-<AREA>-<NNN>"
                          % req.where)
        if not req.title:
            errors.append("%s — requirement has no title" % req.where)

        for key in req.meta:
            if key not in KNOWN_FIELDS:
                warnings.append("%s — unknown field %r" % (req.where, key))

        status = req.meta.get("status", "")
        if status not in STATUSES:
            errors.append("%s — status %r is not one of %s"
                          % (req.where, status, "/".join(STATUSES)))

        verification = req.meta.get("verification", "")
        if verification not in VERIFICATIONS:
            errors.append("%s — verification method %r is not one of %s"
                          % (req.where, verification, "/".join(VERIFICATIONS)))

        # Statement and its binding force.
        if not req.statement:
            errors.append("%s — no statement" % req.where)
        else:
            found = len(RE_MODAL.findall(req.statement))
            if found == 0:
                errors.append("%s — no bolded modal verb "
                              "(shall / must / should / may)" % req.where)
            elif found > 1:
                errors.append("%s — %d modal verbs, expected one: "
                              "this is two requirements, split them"
                              % (req.where, found))

        # Status implemented obliges the code field.
        code = req.meta.get("code", [])
        if status == "implemented" and not code:
            errors.append("%s — status implemented but the code field is empty"
                          % req.where)

        for field in ("code", "tests"):
            for rel in req.meta.get(field, []):
                if not os.path.exists(os.path.join(ROOT, rel)):
                    errors.append("%s — %s points to a nonexistent path %s"
                                  % (req.where, field, rel))

        # Replacement for superseded requirements.
        replacement = req.meta.get("superseded_by", "")
        if status == "superseded" and not replacement:
            errors.append("%s — status superseded without superseded_by"
                          % req.where)
        if replacement and status != "superseded":
            errors.append("%s — superseded_by present but status is %r"
                          % (req.where, status))

    # Dangling links.
    for req in requirements:
        targets = list(req.links("derives_from")) + list(req.links("refines")) \
            + list(req.links("depends_on")) + list(req.links("conflicts_with"))
        replacement = req.meta.get("superseded_by", "")
        if replacement:
            targets.append(replacement)
        for target in targets:
            if target not in by_id:
                errors.append("%s — link to nonexistent requirement %s"
                              % (req.where, target))
            elif target == req.id:
                errors.append("%s — requirement links to itself" % req.where)

    for field in ("derives_from", "refines"):
        for cycle in find_cycles(requirements, field):
            errors.append("cycle in %s links: %s" % (field, " → ".join(cycle)))

    return errors, warnings


def collect_code_files():
    result = set()
    extensions = tuple(CODE_EXTENSIONS)
    for root in CODE_ROOTS:
        base = os.path.join(ROOT, root)
        if not os.path.isdir(base):
            continue
        for current, dirs, files in os.walk(base):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for name in files:
                if name.endswith(extensions):
                    full = os.path.join(current, name)
                    result.add(os.path.relpath(full, ROOT))
    return result


def build_traceability(requirements):
    by_id = dict((r.id, r) for r in requirements)

    incoming = {}
    for req in requirements:
        for field in LINK_FIELDS:
            for target in req.links(field):
                if target in by_id:
                    incoming.setdefault(target, []).append((field, req.id))

    lines = []
    lines.append("# Traceability matrix")
    lines.append("")
    lines.append("**Generated by `tools/srs_check.py`. Do not edit by hand —")
    lines.append("the next run will overwrite it.**")
    lines.append("")
    lines.append("Total requirements: %d." % len(requirements))
    lines.append("")

    by_status = {}
    for req in requirements:
        by_status.setdefault(req.meta.get("status", "?"), []).append(req)
    lines.append("| Status | Requirements |")
    lines.append("|---|---|")
    for status in STATUSES:
        lines.append("| `%s` | %d |" % (status, len(by_status.get(status, []))))
    lines.append("")

    lines.append("## Requirement → code → verification")
    lines.append("")
    lines.append("| Requirement | Status | Method | Code | Tests |")
    lines.append("|---|---|---|---|---|")
    for req in sorted(requirements, key=lambda r: r.id):
        code = "<br>".join("`%s`" % p for p in req.meta.get("code", [])) or "—"
        tests = "<br>".join("`%s`" % p for p in req.meta.get("tests", [])) or "—"
        lines.append("| **%s** %s | `%s` | %s | %s | %s |"
                     % (req.id, req.title, req.meta.get("status", "?"),
                        req.meta.get("verification", "?"), code, tests))
    lines.append("")

    lines.append("## Incoming links")
    lines.append("")
    lines.append("Who links to each requirement. Computed; not stored in the "
                 "requirements themselves.")
    lines.append("")
    referenced = sorted(incoming.keys())
    if referenced:
        lines.append("| Requirement | Referenced by |")
        lines.append("|---|---|")
        for rid in referenced:
            refs = ", ".join("%s (%s)" % (src, field)
                             for field, src in sorted(incoming[rid], key=lambda p: p[1]))
            lines.append("| **%s** | %s |" % (rid, refs))
    else:
        lines.append("No links yet.")
    lines.append("")

    lines.append("## Requirements without listed tests")
    lines.append("")
    untested = [r for r in sorted(requirements, key=lambda r: r.id)
                if not r.meta.get("tests") and r.meta.get("status") in ("implemented", "partial")]
    if untested:
        lines.append("Verified by means other than testing — or the check has "
                     "not been set up yet.")
        lines.append("")
        for req in untested:
            lines.append("- **%s** (`%s`, method `%s`) — %s"
                         % (req.id, req.meta.get("status", "?"),
                            req.meta.get("verification", "?"), req.title))
    else:
        lines.append("None.")
    lines.append("")

    lines.append("## Code files outside the specification")
    lines.append("")
    covered = set()
    for req in requirements:
        for path in req.meta.get("code", []):
            covered.add(path)
    all_code = collect_code_files()
    orphans = sorted(all_code - covered)
    lines.append("No requirement references them: %d of %d."
                 % (len(orphans), len(all_code)))
    lines.append("")
    for path in orphans:
        lines.append("- `%s`" % path)
    lines.append("")

    return "\n".join(lines) + "\n"


def main():
    write = "--no-write" not in sys.argv[1:]

    if not os.path.isdir(SPECS):
        sys.stderr.write("specs/ directory not found: %s\n" % SPECS)
        return 2

    parse_errors = []
    requirements = []
    files = collect_spec_files()
    for full, rel in files:
        requirements.extend(parse_file(full, rel, parse_errors))

    errors, warnings = validate(requirements)
    errors = parse_errors + errors

    for text in warnings:
        sys.stdout.write("warning: %s\n" % text)

    if errors:
        sys.stdout.write("\n")
        for text in errors:
            sys.stdout.write("error: %s\n" % text)
        sys.stdout.write("\nFiles scanned: %d. Requirements: %d. Errors: %d.\n"
                         % (len(files), len(requirements), len(errors)))
        return 1

    sys.stdout.write("Files scanned: %d. Requirements: %d. No errors.\n"
                     % (len(files), len(requirements)))

    if write:
        with open(TRACE, "w", encoding="utf-8") as handle:
            handle.write(build_traceability(requirements))
        sys.stdout.write("Traceability matrix rewritten: %s\n"
                         % os.path.relpath(TRACE, ROOT))

    return 0


if __name__ == "__main__":
    sys.exit(main())
