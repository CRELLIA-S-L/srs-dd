#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Specification integrity checker and traceability matrix generator.

Standard library only, compatible with Python 3.9. The specification
markup rules are described in specs/README.md — that file is the single
normative document; this script only enforces it.

    python3 tools/srs_check.py             check and rewrite 90-traceability.md
    python3 tools/srs_check.py --no-write  check only
    python3 tools/srs_check.py --strict    treat warnings as errors (CI)

Project-specific settings (requirement areas, code roots, source file
extensions, statement lexicon) live in specs/srs-config.json. The
defaults below apply for any key absent from that file. The script knows
no natural language: the modal verbs, negation words, and rationale
markers it matches all come from the lexicon in the config.
"""

import json
import os
import re
import sys

__version__ = "0.1.0"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPECS = os.path.join(ROOT, "specs")
TRACE = os.path.join(SPECS, "90-traceability.md")
CONFIG = os.path.join(SPECS, "srs-config.json")

# Files in specs/ that do not contain requirements.
SKIP_FILES = {"README.md", "00-glossary.md", "constitution.md",
              "90-traceability.md", "91-open-issues.md", "92-baselines.md"}
SKIP_DIRS = {"archive", "adr"}

# Fallbacks used for keys absent from specs/srs-config.json. Edit the
# config, not these constants.
DEFAULTS = {
    "areas": ["CORE", "UI", "API", "DATA", "SEC"],
    "code_roots": ["src"],
    "test_roots": ["tests"],
    "code_extensions": [".py", ".ts", ".tsx", ".js", ".swift", ".kt",
                        ".go", ".rs", ".java", ".c", ".cpp", ".h", ".m"],
    "modal_verbs": ["shall", "must", "should", "may"],
    "negation_words": ["not"],
    "rationale_markers": ["Rationale"],
}

# Uppercase, matching the annotation grammar and the installer's rule.
RE_AREA_NAME = re.compile(r"^[A-Z][A-Z0-9]*$")


def _config_fail(message):
    sys.stderr.write("specs/srs-config.json: %s\n" % message)
    sys.exit(2)


def load_config():
    """Loads and validates the config; fails with a friendly message
    rather than letting a bad value crash regex compilation later."""
    data = {}
    if os.path.exists(CONFIG):
        try:
            with open(CONFIG, "r", encoding="utf-8") as handle:
                data = json.load(handle)
        except ValueError as exc:
            _config_fail("invalid JSON — %s" % exc)
        except OSError as exc:
            _config_fail("cannot read — %s" % exc)
        if not isinstance(data, dict):
            _config_fail("the top level must be a JSON object")
    cfg = {}
    for key, fallback in DEFAULTS.items():
        value = data.get(key, fallback)
        if not isinstance(value, list) \
                or not all(isinstance(v, str) and v for v in value):
            _config_fail("%s must be a list of non-empty strings" % key)
        cfg[key] = value
    for key in ("areas", "modal_verbs", "rationale_markers"):
        if not cfg[key]:
            _config_fail("%s must not be empty" % key)
    for area in cfg["areas"]:
        if not RE_AREA_NAME.match(area):
            _config_fail("area %r must match [A-Z][A-Z0-9]*" % area)
    return cfg


CFG = load_config()
AREAS = CFG["areas"]
CODE_ROOTS = CFG["code_roots"]
TEST_ROOTS = CFG["test_roots"]
CODE_EXTENSIONS = CFG["code_extensions"]

TYPES = ("FR", "NFR", "IF", "INV", "CON")

# Lifecycle order; also the row order of the status table in the matrix.
STATUSES = ("draft", "deferred", "partial", "implemented", "superseded")
VERIFICATIONS = ("T", "D", "I", "A")

LINK_FIELDS = ("derives_from", "refines", "depends_on", "conflicts_with")
LIST_FIELDS = LINK_FIELDS + ("code", "tests")
SCALAR_FIELDS = ("status", "verification", "superseded_by")
KNOWN_FIELDS = set(LIST_FIELDS) | set(SCALAR_FIELDS)


def _alternation(words):
    return "|".join(re.escape(w) for w in words)


RE_ID = re.compile(r"^(%s)-(%s)-(\d{3})$" % ("|".join(TYPES), "|".join(AREAS)))
# A deliberately broad net: anything ID-shaped is captured (including
# junk like FR-CORE-010-B) and then judged loudly by RE_ID — a malformed
# identifier must never be skipped silently.
RE_HEADING = re.compile(
    r"^###\s+([A-Za-z][A-Za-z0-9]*-[A-Za-z][A-Za-z0-9]*-\d+"
    r"(?:-[A-Za-z0-9]+)*)\s*(?:[—–-]\s*)?(.*)$")
RE_ANY_HEADING = re.compile(r"^#{1,6}\s")
RE_FENCE = re.compile(r"^\s*(`{3,})")
RE_FENCE_OPEN = re.compile(r"^\s*```+\s*yaml\s*$")
RE_FENCE_CLOSE = re.compile(r"^\s*```+\s*$")


def _fence_len(line):
    match = RE_FENCE.match(line)
    return len(match.group(1)) if match else 0


RE_FENCE_BARE = re.compile(r"^\s*(`{3,})\s*$")


def _closer_len(line):
    """Length of a bare closing fence; 0 for anything else. Per
    CommonMark a closer carries no info string, so ```python can open a
    block but never close one."""
    match = RE_FENCE_BARE.match(line)
    return len(match.group(1)) if match else 0


# The statement lexicon comes from the config; the patterns are
# language-neutral. Exactly one bolded modal verb per statement; the
# negation word may precede or follow the verb inside the bold markers
# ("**shall not**", "**не должна**"). The bold markers themselves are
# the word boundary, so no \b is needed.
def _modal_pattern(verbs, negations):
    verb_alt = _alternation(verbs)
    if not negations:
        return r"\*\*(?:%s)\*\*" % verb_alt
    neg_alt = _alternation(negations)
    return (r"\*\*(?:(?:%s)\s+)?(?:%s)(?:\s+(?:%s))?\*\*"
            % (neg_alt, verb_alt, neg_alt))


RE_MODAL = re.compile(
    _modal_pattern(CFG["modal_verbs"], CFG["negation_words"]),
    re.IGNORECASE)
RE_RATIONALE = re.compile(
    r"^\s*\*\*(?:%s)\.?\*\*" % _alternation(CFG["rationale_markers"]))

# Optional traceability annotations in source and test files:
#   implements: FR-CORE-010            (maps to the requirement's `code`)
#   verifies: FR-CORE-010, FR-UI-020   (maps to the requirement's `tests`)
# A line containing "srs-ignore" is exempt from annotation checking.
_ANNOT_ID = r"[A-Z]+-[A-Z0-9]+-\d{3}(?!\d)"
RE_ANNOTATION = re.compile(
    r"\b(implements|verifies):\s*(%s(?:\s*,\s*%s)*)" % (_ANNOT_ID, _ANNOT_ID))


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


def _skip_fence(lines, index):
    """`index` points at a fence opener; returns the index just past the
    matching closing fence (or EOF). Per CommonMark, the closer is a
    backtick run at least as long as the opener."""
    opener = _fence_len(lines[index])
    index += 1
    total = len(lines)
    while index < total and _closer_len(lines[index]) < opener:
        index += 1
    return index + 1


def parse_file(path, rel, errors):
    with open(path, "r", encoding="utf-8") as handle:
        lines = handle.read().split("\n")

    requirements = []
    index = 0
    total = len(lines)

    while index < total:
        # Fenced code blocks may contain example headings and example
        # statements; they never contribute requirements.
        if RE_FENCE.match(lines[index]):
            index = _skip_fence(lines, index)
            continue

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
                opener = _fence_len(lines[index])
                index += 1
                start = index + 1
                while index < total \
                        and not (RE_FENCE_CLOSE.match(lines[index])
                                 and _fence_len(lines[index]) >= opener) \
                        and not RE_HEADING.match(lines[index]):
                    meta_lines.append(lines[index])
                    index += 1
                if index < total and RE_FENCE_CLOSE.match(lines[index]) \
                        and _fence_len(lines[index]) >= opener:
                    index += 1  # closing fence
                else:
                    errors.append("%s — unterminated metadata fence"
                                  % req.where)
                req.meta = parse_metadata(meta_lines, rel, start, errors)
                break
            if RE_FENCE.match(lines[index]):
                # Some other fenced block before the metadata — skip it.
                index = _skip_fence(lines, index)
                continue
            index += 1

        if not found_fence:
            errors.append("%s — no metadata block" % req.where)
            requirements.append(req)
            continue

        # Statement: prose up to the rationale or the next heading.
        # Fenced blocks are skipped — modal verbs are counted in prose only.
        statement = []
        while index < total:
            if RE_FENCE.match(lines[index]):
                index = _skip_fence(lines, index)
                continue
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


def normalize_meta(req, errors):
    """List fields must be bracketed lists; scalar fields single values.
    Coerces wrong shapes so later checks do not iterate a string
    character by character or crash on a list."""
    for field in LIST_FIELDS:
        value = req.meta.get(field)
        if value is not None and not isinstance(value, list):
            example = ("[src/app.py]" if field in ("code", "tests")
                       else "[FR-CORE-010]")
            errors.append("%s — %s must be a bracketed list, e.g. %s"
                          % (req.where, field, example))
            req.meta[field] = []
    for field in SCALAR_FIELDS:
        value = req.meta.get(field)
        if isinstance(value, list):
            errors.append("%s — %s must be a single value, not a list"
                          % (req.where, field))
            req.meta[field] = value[0] if value else ""


def validate(requirements):
    errors = []
    warnings = []

    by_id = {}
    for req in requirements:
        normalize_meta(req, errors)

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
                errors.append("%s — no bolded modal verb from the lexicon (%s)"
                              % (req.where, " / ".join(CFG["modal_verbs"])))
            elif found > 1:
                errors.append("%s — %d modal verbs, expected one: "
                              "this is two requirements, split them"
                              % (req.where, found))

        # Status implemented obliges the code field.
        code = req.meta.get("code", [])
        if status == "implemented" and not code:
            errors.append("%s — status implemented but the code field is empty"
                          % req.where)

        # Implementation ahead of approval.
        if status == "draft" and code:
            warnings.append("%s — status draft but the code field is not "
                            "empty: implementation ahead of approval"
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

    # Dangling links; approved-or-better requirements resting on drafts.
    for req in requirements:
        status = req.meta.get("status", "")
        for field in LINK_FIELDS:
            for target in req.links(field):
                if target not in by_id:
                    errors.append("%s — link to nonexistent requirement %s"
                                  % (req.where, target))
                elif target == req.id:
                    errors.append("%s — requirement links to itself" % req.where)
                elif (status in ("implemented", "partial")
                        and field in ("derives_from", "depends_on", "refines")
                        and by_id[target].meta.get("status") == "draft"):
                    warnings.append("%s — %s requirement rests on draft %s "
                                    "(%s): approve or revisit it"
                                    % (req.where, status, target, field))
        replacement = req.meta.get("superseded_by", "")
        if replacement:
            if replacement not in by_id:
                errors.append("%s — link to nonexistent requirement %s"
                              % (req.where, replacement))
            elif replacement == req.id:
                errors.append("%s — requirement links to itself" % req.where)

    for field in ("derives_from", "refines"):
        for cycle in find_cycles(requirements, field):
            errors.append("cycle in %s links: %s" % (field, " → ".join(cycle)))

    return by_id, errors, warnings


def iter_source_files():
    """Yields repo-relative paths of source files under code and test roots,
    deduplicated when roots nest."""
    seen = set()
    extensions = tuple(CODE_EXTENSIONS)
    for root in list(CODE_ROOTS) + list(TEST_ROOTS):
        base = os.path.join(ROOT, root)
        if not os.path.isdir(base):
            continue
        for current, dirs, files in os.walk(base):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for name in sorted(files):
                if not name.endswith(extensions):
                    continue
                # Spec fields use forward slashes; normalize for comparison.
                rel = os.path.relpath(os.path.join(current, name),
                                      ROOT).replace(os.sep, "/")
                if rel in seen:
                    continue
                seen.add(rel)
                yield rel


def scan_annotations(by_id, errors, warnings):
    """Cross-checks implements:/verifies: annotations against the spec.

    The code/tests fields remain the source of truth; annotations are an
    optional cross-check, so absence of annotations is never reported.
    """
    field_by_keyword = {"implements": "code", "verifies": "tests"}
    for rel in iter_source_files():
        full = os.path.join(ROOT, rel)
        with open(full, "r", encoding="utf-8", errors="replace") as handle:
            for lineno, line in enumerate(handle, 1):
                if "srs-ignore" in line:
                    continue
                for match in RE_ANNOTATION.finditer(line):
                    keyword = match.group(1)
                    ids = [t.strip() for t in match.group(2).split(",")]
                    for rid in ids:
                        where = "%s:%d" % (rel, lineno)
                        req = by_id.get(rid)
                        if req is None:
                            parts = rid.split("-")
                            known_shape = (len(parts) == 3
                                           and parts[0] in TYPES
                                           and parts[1] in AREAS)
                            if known_shape:
                                errors.append(
                                    "%s — annotation references unknown "
                                    "requirement %s" % (where, rid))
                            else:
                                warnings.append(
                                    "%s — annotation references %s with an "
                                    "unknown type or area (an example? add "
                                    "srs-ignore to the line if intended)"
                                    % (where, rid))
                            continue
                        if req.meta.get("status") == "superseded":
                            warnings.append(
                                "%s — annotation points at superseded "
                                "requirement %s" % (where, rid))
                            continue
                        field = field_by_keyword[keyword]
                        if rel not in req.meta.get(field, []):
                            warnings.append(
                                "%s — file carries `%s: %s` but is not "
                                "listed in that requirement's %s field"
                                % (where, keyword, rid, field))


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
                    result.add(os.path.relpath(full, ROOT)
                               .replace(os.sep, "/"))
    return result


def _cell(text):
    """Escapes pipes so a title cannot break the markdown table."""
    return text.replace("|", "\\|")


def build_traceability(requirements):
    # The matrix is compared byte-for-byte by the CI freshness gate.
    # Everything here must stay deterministic: files and IDs are sorted,
    # link fields iterate in the fixed LINK_FIELDS order.
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
                     % (req.id, _cell(req.title), req.meta.get("status", "?"),
                        req.meta.get("verification", "?"), _cell(code),
                        _cell(tests)))
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
    args = sys.argv[1:]
    unknown = [a for a in args if a not in ("--no-write", "--strict")]
    if unknown:
        sys.stderr.write("unknown flag(s): %s\nusage: srs_check.py "
                         "[--no-write] [--strict]\n" % ", ".join(unknown))
        return 2
    write = "--no-write" not in args
    strict = "--strict" in args

    if not os.path.isdir(SPECS):
        sys.stderr.write("specs/ directory not found: %s\n" % SPECS)
        return 2

    parse_errors = []
    requirements = []
    files = collect_spec_files()
    for full, rel in files:
        requirements.extend(parse_file(full, rel, parse_errors))

    by_id, errors, warnings = validate(requirements)
    scan_annotations(by_id, errors, warnings)
    errors = parse_errors + errors

    for text in warnings:
        sys.stdout.write("warning: %s\n" % text)

    if errors:
        sys.stdout.write("\n")
        for text in errors:
            sys.stdout.write("error: %s\n" % text)
        sys.stdout.write("\nFiles scanned: %d. Requirements: %d. Errors: %d. "
                         "(srs_check %s)\n"
                         % (len(files), len(requirements), len(errors),
                            __version__))
        return 1

    if strict and warnings:
        sys.stdout.write("\nstrict mode: %d warning(s) treated as errors. "
                         "(srs_check %s)\n" % (len(warnings), __version__))
        return 1

    sys.stdout.write("Files scanned: %d. Requirements: %d. No errors. "
                     "(srs_check %s)\n"
                     % (len(files), len(requirements), __version__))

    if write:
        with open(TRACE, "w", encoding="utf-8") as handle:
            handle.write(build_traceability(requirements))
        sys.stdout.write("Traceability matrix rewritten: %s\n"
                         % os.path.relpath(TRACE, ROOT))

    return 0


if __name__ == "__main__":
    sys.exit(main())
