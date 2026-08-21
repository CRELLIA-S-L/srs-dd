#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""The grounds checker: reads the register beside specs/ and reports on it.

    python3 tools/srs_grounds.py             check and rewrite 90-dashboard.md
    python3 tools/srs_grounds.py --no-write  check only
    python3 tools/srs_grounds.py --strict    treat warnings as errors
    python3 tools/srs_grounds.py --blast P…  what the requirements in these
                                             files are staked on

The register's format is described in grounds/README.md — that file is the
normative one; this script only enforces it. Standard library only,
compatible with Python 3.9.

The requirement model is read by running tools/srs_view.py as a subprocess
rather than importing the checker: an optional subsystem must not die on the
mandatory one's configuration before it can say anything of its own, and a
register whose specification is broken still has plenty to report.
"""

# implements: NFR-SPEC-010, CON-GND-030

import datetime
import json
import os
import re
import subprocess
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    import srs_parse                                        # noqa: E402
except ImportError:
    sys.stderr.write(
        "tools/srs_parse.py: missing — the grounds checker reads the record "
        "shape through it, and the two travel together. Copy it beside this "
        "file from the framework clone, or re-run tools/srs_init.py to "
        "refresh the tooling.\n")
    sys.exit(2)

__version__ = "0.14.0"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GROUNDS = os.path.join(ROOT, "grounds")
CONFIG = os.path.join(GROUNDS, "grounds-config.json")
# implements: CON-GND-010
# The only path this tool ever writes. Everything else it does is read.
DASHBOARD = os.path.join(GROUNDS, "90-dashboard.md")
VIEWER = os.path.join(ROOT, "tools", "srs_view.py")

# Files in grounds/ that hold no records.
SKIP_FILES = {"README.md", "90-dashboard.md"}

# implements: FR-GND-020
# The same broad net the specification checker uses, in this format's
# grammar: anything ID-shaped is captured and judged loudly afterwards.
RE_HEADING = re.compile(
    r"^###\s+([A-Za-z][A-Za-z0-9]*-\d+(?:-[A-Za-z0-9]+)*)"
    r"\s*(?:[—–-]\s*)?(.*)$")
RE_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
# The threshold grammar the standard declares, and the four comparisons
# it names. A threshold nothing can apply twice the same way is not one.
RE_THRESHOLD = re.compile(
    r"^(?:proportion|mean|count)\s+(?:<=|>=|<|>)\s+"
    r"\d+(?:\.\d+)?\s+at\s+n\s*>=\s*\d+$")

# implements: IF-GND-010
# The kinds the format defines, and the keys each declares. What a record
# means is the standard's business; this is the standard's shape as code.
KINDS = {"I": "ideology", "F": "frame", "H": "hypothesis",
         "B": "bet", "U": "unclaimed"}
# implements: INV-GND-010
# One number, one meaning, forever: the checker's part of that promise is
# that no two records in the register carry the same one.
RE_ID = re.compile(r"^(%s)-(\d{3})$" % "|".join(sorted(KINDS)))

# implements: FR-GND-030
REQUIRED = {
    "I": ("status", "admissible_arguments"),
    "F": ("status",),
    "H": ("status", "class", "population", "refuted_if", "expires",
          "owner", "impact"),
    "B": ("status", "requirement"),
    "U": ("status", "requirement"),
}

# implements: FR-GND-390
CLASSES = ("I", "II", "III")
GRADES = ("high", "moderate", "low", "very-low")
# `declined` carries both halves because they are useless apart: a refusal
# with no reason answers nothing next time, one with no date cannot be told
# from one that predates everything since.
RE_DECLINED = re.compile(r"^(\d{4}-\d{2}-\d{2})\s+[—–-]\s+(\S.*)$")
STATUSES = {
    "I": ("active", "dissolved"),
    "F": ("active", "retired"),
    "H": ("untested", "assumed", "supported", "refuted", "expired",
          "declined"),
    "B": ("active", "retired"),
    "U": ("active", "retired"),
}

# How much ground a hypothesis provides, weakest first. `declined` is beside
# `refuted` on purpose: the core looked at it and said no, so a requirement
# standing on it stands on something nobody agreed to carry.
STRENGTH = {"refuted": 0, "declined": 0, "expired": 1, "untested": 2,
            "assumed": 3, "supported": 4}
DEBT_STATUSES = ("refuted", "expired", "assumed")

# implements: FR-GND-110, IF-GND-030
# Published names: a name here keeps its meaning forever, and is never given
# to a different rule.
RULES = ("bet-cancelled", "hypothesis-expired", "bet-duplicated",
         "declaration-superfluous", "threshold-moved", "evidence-dropped",
         "relied-on-untested", "never-measured", "verdict-unattributed",
         "action-beyond-grade", "declined-leftover", "action-without-grade")
SEVERITIES = ("warn", "report", "off")

DEFAULTS = {"rules": {}, "grades": {}}


def _config_fail(message):
    sys.stderr.write("grounds/grounds-config.json: %s\n" % message)
    sys.exit(2)


def load_config():
    # implements: FR-GND-110
    cfg = dict(DEFAULTS)
    if not os.path.exists(CONFIG):
        return cfg
    try:
        with open(CONFIG, "r", encoding="utf-8") as handle:
            raw = json.load(handle)
    except ValueError as exc:
        _config_fail("invalid JSON: %s" % exc)
    if not isinstance(raw, dict):
        _config_fail("the top level must be a JSON object")
    rules = raw.get("rules", {})
    if not isinstance(rules, dict):
        _config_fail("rules must be an object of rule name to severity")
    for name, severity in sorted(rules.items()):
        if name not in RULES:
            _config_fail("unknown rule %r; known rules are: %s"
                         % (name, ", ".join(RULES)))
        if severity not in SEVERITIES:
            _config_fail("rule %r: severity must be one of %s"
                         % (name, ", ".join(SEVERITIES)))
    cfg["rules"] = rules
    # implements: FR-GND-170
    # What a weakly supported hypothesis may be used for is a matter of
    # appetite, so the map is the project's and the format only says it
    # exists. A grade absent from it permits anything.
    grades = raw.get("grades", {})
    if not isinstance(grades, dict):
        _config_fail("grades must be an object of grade to permitted actions")
    for grade, actions in sorted(grades.items()):
        if grade not in GRADES:
            _config_fail("unknown grade %r; the format defines: %s"
                         % (grade, ", ".join(GRADES)))
        if not isinstance(actions, list) \
                or not all(isinstance(a, str) and a for a in actions):
            _config_fail("grade %r: permitted actions must be a list of "
                         "non-empty strings" % grade)
    cfg["grades"] = grades
    return cfg


def rule_finding(warnings, reports, cfg, rule, text):
    """Files a tunable finding at the severity this project chose."""
    severity = cfg["rules"].get(rule, "warn")
    if severity == "off":
        return
    line = "%s [%s]" % (text, rule)
    (warnings if severity == "warn" else reports).append(line)


def collect_files():
    # implements: FR-GND-010
    """Every record file in the register, subdirectories included.

    The layout in the standard is flat, and a register that grows a folder
    is not thereby exempt: `every record in it` has to mean every one, or
    a file one directory down goes unread with nothing said about it.
    """
    out = []
    if not os.path.isdir(GROUNDS):
        return out
    for current, dirs, files in os.walk(GROUNDS):
        dirs.sort()
        for name in sorted(files):
            if not name.endswith(".md") or name in SKIP_FILES:
                continue
            full = os.path.join(current, name)
            out.append((full, os.path.relpath(full, ROOT)))
    return sorted(out, key=lambda pair: pair[1])


def read_records(errors):
    # implements: FR-GND-010, FR-GND-020
    records = {}
    seen = {}
    for full, rel in collect_files():
        try:
            with open(full, "r", encoding="utf-8") as handle:
                text = handle.read()
        except (OSError, UnicodeDecodeError) as exc:
            errors.append("%s — cannot read the file: %s" % (rel, exc))
            continue
        for entry in srs_parse.parse_entries(text, rel, errors, RE_HEADING):
            match = RE_ID.match(entry.id)
            if not match:
                errors.append("%s — identifier does not match <KIND>-<NNN> "
                              "with a kind the standard defines (%s)"
                              % (entry.where, ", ".join(sorted(KINDS))))
                continue
            entry.kind = match.group(1)
            if entry.id in seen:
                errors.append("%s — %s is already used at %s"
                              % (entry.where, entry.id, seen[entry.id]))
                continue
            seen[entry.id] = entry.where
            records[entry.id] = entry
    return records


def read_model():
    """The requirement model, or None with the reason it could not be read."""
    if not os.path.exists(VIEWER):
        return None, "tools/srs_view.py is not here"
    try:
        done = subprocess.run([sys.executable, VIEWER, "--json"],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError as exc:
        return None, "could not run tools/srs_view.py: %s" % exc
    if done.returncode != 0:
        detail = done.stderr.decode("utf-8", "replace").strip().split("\n")
        return None, "tools/srs_view.py exited %d: %s" % (
            done.returncode, detail[-1] if detail else "no output")
    try:
        return json.loads(done.stdout.decode("utf-8")), None
    except ValueError as exc:
        return None, "tools/srs_view.py produced unreadable JSON: %s" % exc


def history_of(paths):
    # implements: FR-GND-270
    """Past revisions of the register's record files, oldest first.

    Returns (revisions, problem). Where `problem` is a sentence the
    history could not be read, and the rules standing on it are not run
    and not passed — a history nobody can read is also a history nobody
    can audit, and a reader told nothing assumes the check ran.
    """
    def git(*args):
        return subprocess.check_output(
            ["git", "-C", ROOT] + list(args),
            stderr=subprocess.DEVNULL).decode("utf-8", "replace")

    try:
        if git("rev-parse", "--is-shallow-repository").strip() == "true":
            return [], "the clone is shallow, so earlier revisions are absent"
        listed = git("log", "--format=%H", "--", *paths).split()
    except (OSError, subprocess.CalledProcessError):
        return [], "this is not a repository, or git could not read it"

    revisions = []
    for rev in reversed(listed):                  # oldest first
        texts = {}
        for path in paths:
            try:
                texts[path] = git("show", "%s:%s" % (rev, path))
            except (OSError, subprocess.CalledProcessError):
                continue                          # not in the tree yet
        revisions.append(texts)
    return revisions, None


def hypotheses_in(text, path):
    """The hypothesis records of one file's text, by identifier."""
    out = {}
    for entry in srs_parse.parse_entries(text, path, [], RE_HEADING):
        match = RE_ID.match(entry.id)
        if match and match.group(1) == "H":
            out[entry.id] = entry
    return out


def check_history(records, cfg, warnings, reports):
    # implements: FR-GND-190, FR-GND-200, FR-GND-270
    """The two rules that read the register's history rather than its files.

    Both are replayed from one walk: the ordering of a threshold against
    the first measurement recorded under it, and the evidence rows that
    were once there.
    """
    paths = [rel for _full, rel in collect_files()]
    revisions, problem = history_of(paths)
    if problem:
        reports.append(
            "the register's history could not be read (%s); the "
            "threshold-moved and evidence-dropped rules did not run, which "
            "is not the same as passing" % problem)
        return

    threshold = {}        # id -> (value, revision index, ever changed)
    first_measured = {}   # id -> index of the revision that first showed one
    rows_ever = {}        # id -> {row: index first seen}
    for index, texts in enumerate(revisions):
        for path, text in sorted(texts.items()):
            for hid, entry in sorted(hypotheses_in(text, path).items()):
                value = entry.fields.get("refuted_if")
                if hid not in threshold:
                    threshold[hid] = (value, index, False)
                elif threshold[hid][0] != value:
                    threshold[hid] = (value, index, True)
                rows = [tuple(r) for r in table_with(entry, "verdict")]
                if rows and hid not in first_measured:
                    first_measured[hid] = index
                for row in rows:
                    rows_ever.setdefault(hid, {}).setdefault(row, index)

    # A record that is simply gone takes its measurements with it, which is
    # the easiest way to make an inconvenient one disappear and the one the
    # loop below cannot see: it walks what is here.
    for hid in sorted(rows_ever):
        if hid not in records:
            rule_finding(warnings, reports, cfg, "evidence-dropped",
                         "grounds — %s recorded %d measurement(s) and is no "
                         "longer in the register at all; an entry is "
                         "retired in a status that says so, never deleted"
                         % (hid, len(rows_ever[hid])))

    for hid in sorted(records):
        rec = records[hid]
        if rec.kind != "H":
            continue
        moved = threshold.get(hid)
        measured = first_measured.get(hid)
        # `>=` and not `>`: inside one commit there is no ordering, so a
        # threshold changed in the very commit that records the first
        # measurement is the abuse done in one step instead of two. The
        # `ever changed` flag is what keeps a hypothesis born with its
        # first measurement out of this — declaring is not moving.
        if moved and moved[2] and measured is not None and moved[1] >= measured:
            rule_finding(warnings, reports, cfg, "threshold-moved",
                         "%s — %s had its threshold changed after the first "
                         "measurement was recorded under it; a threshold "
                         "named after the result turns every outcome into an "
                         "encouraging one" % (rec.where, hid))
        now = {tuple(r) for r in table_with(rec, "verdict")}
        for row in sorted(rows_ever.get(hid, {})):
            if row not in now:
                rule_finding(warnings, reports, cfg, "evidence-dropped",
                             "%s — %s once recorded the measurement %s and "
                             "no longer does; the older one is what the "
                             "newer is a change from"
                             % (rec.where, hid, " | ".join(row)))


def statement_of(entry):
    """The record's prose, with any table below it left out."""
    lines = []
    for line in entry.body:
        if line.lstrip().startswith("|"):
            break
        lines.append(line)
    return "\n".join(lines).strip()


# implements: FR-GND-450
# The tables this format names, each by the one column only it has, and the
# heading it must then carry. A table with none of these markers is one the
# format has not named and is left alone.
NAMED_TABLES = {
    "verdict": ["date", "value", "n", "verdict", "by"],
    "what was refused": ["date", "what was refused", "who asked"],
    "what changed": ["date", "what changed", "why", "territory it opens"],
}


def tables_of(entry):
    """Every table under a record, as (heading cells, rows).

    A record can carry more than one — a frame keeps its refusals and its
    amendments — so tables are told apart by their heading and never by
    their order, which is what the standard promises a reader.
    """
    out = []
    heading, rows = None, []
    for line in entry.body:
        text = line.strip()
        cells = ([c.strip() for c in text.strip("|").split("|")]
                 if text.startswith("|") else None)
        if cells is None:
            if heading is not None:
                out.append((heading, rows))
            heading, rows = None, []
            continue
        if all(set(c) <= set("-: ") for c in cells):
            continue                      # the separator under a heading
        if heading is None:
            heading = cells
            continue
        rows.append(cells)
    if heading is not None:
        out.append((heading, rows))
    return out


def table_with(entry, column):
    """The rows of the record's table that has this column, or nothing."""
    for heading, rows in tables_of(entry):
        if column in heading:
            return rows
    return []


def as_date(value):
    """The value as a date, or None. A shape that passes and a date that
    cannot exist are the same answer here — neither can be compared."""
    if not isinstance(value, str) or not RE_DATE.match(value):
        return None
    try:
        return datetime.date.fromisoformat(value)
    except ValueError:
        return None


def as_list(value):
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def active(rec):
    return rec.fields.get("status") == "active"


def validate(records, model, model_error, cfg):
    # implements: FR-GND-030, FR-GND-040, FR-GND-050, FR-GND-060,
    # implements: FR-GND-080, FR-GND-090, FR-GND-100, FR-GND-390, FR-GND-400,
    # implements: FR-GND-410, FR-GND-420, FR-GND-430, FR-GND-160,
    # implements: FR-GND-170, FR-GND-180, FR-GND-460, FR-GND-470
    errors, warnings, reports = [], [], []
    today = datetime.date.today()

    hyps = {i: r for i, r in records.items() if r.kind == "H"}
    bets = {i: r for i, r in records.items() if r.kind == "B"}
    decls = {i: r for i, r in records.items() if r.kind == "U"}

    for rid in sorted(records):
        rec = records[rid]
        for key in REQUIRED[rec.kind]:
            if key not in rec.fields:
                errors.append("%s — %s is missing the required key %r"
                              % (rec.where, rid, key))
        status = rec.fields.get("status")
        if status is not None and status not in STATUSES[rec.kind]:
            errors.append(
                "%s — %s carries status %r, which the format does not define "
                "for a %s (%s)" % (rec.where, rid, status, KINDS[rec.kind],
                                   ", ".join(STATUSES[rec.kind])))
        kls = rec.fields.get("class")
        if rec.kind == "H" and kls is not None and kls not in CLASSES:
            errors.append(
                "%s — %s carries class %r, which the format does not define "
                "(%s)" % (rec.where, rid, kls, ", ".join(CLASSES)))
        named = rec.fields.get("requirement")
        if rec.kind in ("B", "U") and named is not None \
                and not isinstance(named, str):
            errors.append(
                "%s — %s carries requirement %r, and the format defines one "
                "requirement identifier there, not a list"
                % (rec.where, rid, named))
        expires = rec.fields.get("expires")
        if rec.kind == "H" and expires is not None and not as_date(expires):
            errors.append(
                "%s — %s carries expires %r, which is not a date the format "
                "defines (YYYY-MM-DD)" % (rec.where, rid, expires))
        for heading, rows in tables_of(rec):
            for marker, declared in sorted(NAMED_TABLES.items()):
                if marker in heading and heading != declared:
                    errors.append(
                        "%s — %s carries a table headed | %s |, and the "
                        "format declares | %s | for that one; read by "
                        "position, the difference is silent"
                        % (rec.where, rid, " | ".join(heading),
                           " | ".join(declared)))
            for row in rows:
                if len(row) != len(heading):
                    errors.append(
                        "%s — %s has a table row with %d cell(s) where its "
                        "heading declares %d: | %s |"
                        % (rec.where, rid, len(row), len(heading),
                           " | ".join(row)))
        grade = rec.fields.get("grade")
        if rec.kind == "H" and grade is not None and grade not in GRADES:
            errors.append(
                "%s — %s carries grade %r, which the format does not define "
                "(%s)" % (rec.where, rid, grade, ", ".join(GRADES)))
        declined = rec.fields.get("declined")
        if rec.kind == "H" and declined is not None \
                and not (isinstance(declined, str)
                         and RE_DECLINED.match(declined)):
            errors.append(
                "%s — %s carries declined %r, which is not the grammar the "
                "format defines (a date, a dash, and the reason)"
                % (rec.where, rid, declined))
        threshold = rec.fields.get("refuted_if")
        if rec.kind == "H" and threshold is not None \
                and not (isinstance(threshold, str)
                         and RE_THRESHOLD.match(threshold)):
            errors.append(
                "%s — %s carries refuted_if %r, which is not the grammar the "
                "format defines (proportion|mean|count, one of < <= > >=, a "
                "number, at n >= a whole number)" % (rec.where, rid, threshold))

    # implements: FR-GND-160, FR-GND-170, FR-GND-180
    for hid in sorted(hyps):
        rec = hyps[hid]

        # Forty thousand in a cohort and a dozen conversations both end in
        # the word `supported`, and only for the second is the word
        # somebody's reading.
        if rec.fields.get("class") == "III":
            for row in table_with(rec, "verdict"):
                if len(row) >= 5 and not row[4]:
                    rule_finding(warnings, reports, cfg,
                                 "verdict-unattributed",
                                 "%s — %s is class III and its measurement "
                                 "of %s gives a verdict with nobody named; "
                                 "a reading with no reader is not evidence "
                                 "anyone can weigh"
                                 % (rec.where, hid, row[0] or "no date"))

        # A grade with nothing attached is a label. The binding is what
        # makes it do work, and the map is the project's own.
        action, grade = rec.fields.get("action"), rec.fields.get("grade")
        permitted = cfg["grades"].get(grade) if grade else None
        if action and permitted is not None and action not in permitted:
            rule_finding(warnings, reports, cfg, "action-beyond-grade",
                         "%s — %s is graded %s and declares the action %r, "
                         "which that grade does not permit here (%s)"
                         % (rec.where, hid, grade, action,
                            ", ".join(permitted) or "nothing"))
        # implements: FR-GND-470
        # The quieter half: an action beyond its grade can be compared,
        # an action with no grade cannot.
        if action and not grade and cfg["grades"]:
            rule_finding(warnings, reports, cfg, "action-without-grade",
                         "%s — %s declares the action %r and no grade, so "
                         "there is nothing to say whether its evidence "
                         "carries it" % (rec.where, hid, action))

        # implements: FR-GND-460
        # One line says it was refused on a date and for a reason; the
        # status says it holds. Which is current, only the author knows.
        if "declined" in rec.fields \
                and rec.fields.get("status") != "declined":
            rule_finding(warnings, reports, cfg, "declined-leftover",
                         "%s — %s is %s and still carries a `declined` "
                         "value; a refusal left behind by a later "
                         "measurement says the opposite of the status"
                         % (rec.where, hid,
                            rec.fields.get("status") or "without a status"))

        # A refusal is recorded so the same question returning in six
        # months is answered from the record instead of argued again.
        if rec.fields.get("status") == "declined" \
                and "declined" not in rec.fields:
            errors.append("%s — %s is declined and carries no `declined` "
                          "value, so neither the reason nor the date of the "
                          "refusal is on the record" % (rec.where, hid))

    # A declaration that gives no reason is indistinguishable from a shrug.
    for rid in sorted(decls):
        rec = decls[rid]
        if not statement_of(rec):
            errors.append("%s — %s declares %s unclaimed and gives no reason"
                          % (rec.where, rid,
                             rec.fields.get("requirement", "a requirement")))

    staked = {}
    for rid in sorted(bets):
        rec = bets[rid]
        if not active(rec):
            continue
        for name in as_list(rec.fields.get("all_of")) \
                + as_list(rec.fields.get("any_of")):
            staked.setdefault(name, []).append(rid)

    def never_measured(hid):
        """Whether the more specific rule will speak for this record.

        Checked against the severity a project chose and not only against
        the facts: a project that silenced that rule has not silenced this
        one, and stepping aside for a finding nobody will see would leave
        the record unreported by either.
        """
        rec = hyps.get(hid)
        return (cfg["rules"].get("never-measured", "warn") != "off"
                and hid in staked and rec is not None
                and not table_with(rec, "verdict"))

    # A hypothesis whose term has run out. Reported, never rewritten: expiry
    # is not a verdict, and only a measurement can answer what the status is.
    for rid in sorted(hyps):
        rec = hyps[rid]
        expires = as_date(rec.fields.get("expires"))
        if expires is None:
            continue                      # already reported as a bad value
        if expires < today and not never_measured(rid):
            rule_finding(warnings, reports, cfg, "hypothesis-expired",
                         "%s — %s ran out of term on %s"
                         % (rec.where, rid, expires.isoformat()))

    # Every pointer into a model this register does not own.
    for rid in sorted(records):
        rec = records[rid]
        if rec.kind not in ("B", "U") or model is None:
            continue
        named = rec.fields.get("requirement")
        if isinstance(named, str) and named and named not in model:
            errors.append("%s — %s names requirement %s, which is not in the "
                          "requirement model" % (rec.where, rid, named))

    # Both ends of every bet.
    by_requirement = {}
    for rid in sorted(bets):
        rec = bets[rid]
        for name in as_list(rec.fields.get("all_of")) \
                + as_list(rec.fields.get("any_of")):
            if name not in hyps:
                errors.append("%s — %s names hypothesis %s, which is not in "
                              "the register" % (rec.where, rid, name))
        req = rec.fields.get("requirement")
        if not isinstance(req, str) or not req:
            continue
        if active(rec):
            by_requirement.setdefault(req, []).append(rid)
        if model is None:
            continue
        target = model.get(req)
        if target is None:
            continue                      # already reported above
        if target.get("status") in ("withdrawn", "superseded"):
            rule_finding(warnings, reports, cfg, "bet-cancelled",
                         "%s — %s stands on %s, which is %s"
                         % (rec.where, rid, req, target["status"]))

    # implements: FR-GND-420, FR-GND-430
    # What a hypothesis says about itself against what the register does
    # with it. Both readings are of the same pair — the record and the bets
    # standing on it — so they are computed together.
    for name in sorted(staked):
        if name not in hyps:
            continue                      # already reported as dangling
        rec = hyps[name]
        on = ", ".join(sorted(staked[name]))
        if rec.fields.get("status") == "untested":
            rule_finding(warnings, reports, cfg, "relied-on-untested",
                         "%s — %s is `untested`, which says nobody relies "
                         "on it, and %s does; the honest status for a "
                         "hypothesis being built on is `assumed`"
                         % (rec.where, name, on))
        expires = as_date(rec.fields.get("expires"))
        if expires is not None and expires < today \
                and not table_with(rec, "verdict"):
            rule_finding(warnings, reports, cfg, "never-measured",
                         "%s — %s passed its term on %s with no measurement "
                         "recorded at all, and %s stands on it"
                         % (rec.where, name, expires.isoformat(), on))

    # Two bets on one requirement turn a maximum into a minimum without
    # saying so, which is the only failure the record encoding introduces.
    for req in sorted(by_requirement):
        names = sorted(by_requirement[req])
        if len(names) > 1:
            rule_finding(warnings, reports, cfg, "bet-duplicated",
                         "%s — %s is named by more than one bet (%s); two "
                         "are two independent sets of alternatives, and the "
                         "reduction reads them that way"
                         % (records[names[0]].where, req, ", ".join(names)))

    # A declaration retires itself when a real bet turns up.
    for rid in sorted(decls):
        rec = decls[rid]
        if not active(rec):
            continue
        req = rec.fields.get("requirement")
        if isinstance(req, str) and req in by_requirement:
            rule_finding(warnings, reports, cfg, "declaration-superfluous",
                         "%s — %s declares %s unclaimed, and %s names it"
                         % (rec.where, rid, req,
                            ", ".join(sorted(by_requirement[req]))))

    check_history(records, cfg, warnings, reports)

    if model_error:
        reports.append("the requirement model could not be read (%s); the "
                       "bets were not resolved against it" % model_error)
    return errors, warnings, reports


def _pick(hyps, names, strongest):
    """The strongest or weakest of the named hypotheses, as (rank, id).

    Ties break on the identifier so that a dashboard regenerated from
    unchanged records comes out byte for byte the same.
    """
    ranked = [(STRENGTH[hyps[n].fields["status"]], n) for n in names
              if n in hyps and hyps[n].fields.get("status") in STRENGTH]
    if not ranked:
        return None
    if strongest:
        return sorted(ranked, key=lambda pair: (-pair[0], pair[1]))[0]
    return sorted(ranked)[0]


def decide(records, req):
    """The hypothesis that decides a requirement, as (rank, id).

    implements: FR-GND-070, INV-GND-020

    Nothing stores what a requirement rests on. It is read off the bets
    every time it is needed, which is what keeps the join in one direction.

    Within a bet: the weakest of what it requires, the strongest of what it
    offers as alternatives, and the weaker of those two. Across the bets of
    one requirement: the weakest. None where nothing decides it.

    The hypothesis is returned rather than its rank alone because two
    statuses can share a rank, and naming a status the record does not
    carry is worse than saying nothing.
    """
    hyps = {i: r for i, r in records.items() if r.kind == "H"}
    best = None
    for rid in sorted(records):
        rec = records[rid]
        if rec.kind != "B" or not active(rec) \
                or rec.fields.get("requirement") != req:
            continue
        candidates = [
            _pick(hyps, as_list(rec.fields.get("all_of")), strongest=False),
            _pick(hyps, as_list(rec.fields.get("any_of")), strongest=True),
        ]
        candidates = [c for c in candidates if c is not None]
        if not candidates:
            continue
        weakest = sorted(candidates)[0]
        best = weakest if best is None else sorted([best, weakest])[0]
    return best


def confirmation_dates(rec):
    """Dates of the evidence rows under a hypothesis, oldest first."""
    out = []
    for row in table_with(rec, "verdict"):
        if row and RE_DATE.match(row[0]):
            out.append(row[0])
    return sorted(out)


def reversals(records):
    # implements: FR-GND-210
    """Per author: verdicts given, and how many a later one reversed.

    Read from the evidence table and not from history. A verdict and the
    measurement that reversed it are two rows of the same table, ordered
    by their own dates, so the file in front of us holds the whole
    answer.
    """
    given, turned = {}, {}
    for hid in sorted(records):
        rec = records[hid]
        if rec.kind != "H":
            continue
        rows = [r for r in table_with(rec, "verdict") if len(r) >= 5]
        rows.sort(key=lambda r: (as_date(r[0]) or datetime.date.min, r[0]))
        for index, row in enumerate(rows):
            verdict, author = row[3], row[4]
            given[author] = given.get(author, 0) + 1
            if any(later[3] != verdict for later in rows[index + 1:]):
                turned[author] = turned.get(author, 0) + 1
    return given, turned


def build_dashboard(records, model, incoming):
    # implements: FR-GND-130, FR-GND-220, FR-GND-240, FR-GND-260,
    # implements: CON-GND-020
    kinds = {k: [i for i, r in sorted(records.items()) if r.kind == k]
             for k in KINDS}
    out = ["# Grounds dashboard", "",
           "**Generated by `tools/srs_grounds.py`. Do not edit by hand —",
           "the next run will overwrite it.**", "",
           "Records: %d — %s." % (len(records), ", ".join(
               "%d %s" % (len(kinds[k]), KINDS[k]) for k in "IFHBU")), ""]

    out += ["## The core", "",
            "Ideologies: %d." % len(kinds["I"]), ""]
    supported = [records[i] for i in kinds["H"]
                 if records[i].fields.get("status") == "supported"]
    out += ["| Class | Supported | Oldest confirmation | Newest |",
            "|---|---|---|---|"]
    for cls in ("I", "II", "III"):
        members = [r for r in supported if r.fields.get("class") == cls]
        dates = [d for r in members for d in confirmation_dates(r)]
        out.append("| %s | %d | %s | %s |"
                   % (cls, len(members),
                      dates[0] if dates else "—", dates[-1] if dates else "—"))
    out += ["",
            "Given as dates and not as a count of days: this file is",
            "committed and compared against a fresh run, so a number that",
            "moved every night would fail the gate every morning without",
            "saying anything new.", ""]

    # implements: FR-GND-250
    out += ["## What each frame has refused", ""]
    if kinds["F"]:
        for fid in kinds["F"]:
            rec = records[fid]
            rows = table_with(rec, "what was refused")
            out.append("**%s — %s**" % (fid, rec.title))
            out.append("")
            if rows:
                out += ["| date | what was refused | who asked |",
                        "|---|---|---|"]
                for row in rows:
                    out.append("| %s |" % " | ".join(row[:3]))
            else:
                out.append("Nothing recorded. A frame that has turned down "
                           "nothing is either untested or drawn where "
                           "nothing was going to happen.")
            out.append("")
    else:
        out += ["No frames are recorded.", ""]

    # implements: FR-GND-210
    out += ["## Verdicts a later measurement reversed", ""]
    given, turned = reversals(records)
    if given:
        out += ["| who | verdicts | reversed |", "|---|---|---|"]
        for author in sorted(given):
            out.append("| %s | %d | %d |"
                       % (author, given[author], turned.get(author, 0)))
        out += ["",
                "The affordable half of weighting a judgement by its "
                "author's",
                "accuracy. The expensive half — calibration questions with "
                "known",
                "answers — is a programme somebody runs, not a file format.",
                ""]
    else:
        out += ["No verdicts are recorded.", ""]

    out += ["## The debt", ""]
    if model is None:
        out += ["The requirement model could not be read, so nothing here",
                "was computed. This is not a reading of zero debt.", ""]
    else:
        staked = sorted({r.fields.get("requirement")
                         for r in records.values()
                         if r.kind == "B" and active(r)
                         and r.fields.get("requirement")})
        rows, weak = [], 0
        for req in staked:
            decided = decide(records, req)
            if decided is None:
                continue
            status = records[decided[1]].fields["status"]
            weak += 1 if status in DEBT_STATUSES else 0
            rows.append("| %s | %s | %s |" % (req, decided[1], status))
        if rows:
            out += ["Of %d requirements carrying a bet, %d rest on "
                    "hypotheses that are" % (len(rows), weak),
                    "`refuted`, `expired` or `assumed` — %.0f%%."
                    % (100.0 * weak / len(rows)), "",
                    "| Requirement | Decided by | Status |",
                    "|---|---|---|"] + rows + [""]
        else:
            out += ["No requirement carries a bet that resolves, so there is",
                    "nothing to reduce. This is not a reading of zero debt.",
                    ""]

    # implements: INV-GND-030
    # The list no rule of this layer is allowed to shorten. A requirement
    # standing on nothing is a reading, and demanding a bet would replace it
    # with invented ones.
    out += ["## Requirements resting on no hypothesis", ""]
    if model is None:
        out += ["The requirement model could not be read, so this list is",
                "not a list of none.", ""]
    else:
        claimed = {r.fields.get("requirement") for r in records.values()
                   if r.kind == "B" and active(r)}
        rows = []
        for req in sorted(model):
            if req in claimed:
                continue
            links = len(incoming.get(req, []))
            files = len(model[req].get("code", []))
            rows.append((links + files, links, files, req))
        out += ["%d of %d requirements. Weight is what stands on them: how "
                "many" % (len(rows), len(model)),
                "requirements link to them, plus how many files their `code` "
                "field names.", ""]
        if rows:
            out += ["| Requirement | Incoming | Code files | Weight |",
                    "|---|---|---|---|"]
            for weight, links, files, req in sorted(rows, key=lambda r: (-r[0], r[3])):
                out.append("| %s | %d | %d | %d |" % (req, links, files, weight))
            out.append("")
    return "\n".join(out).rstrip() + "\n"


def blast(records, model, paths):
    # implements: FR-GND-310
    """What the requirements defined in these files are staked on.

    Quiet where nothing is staked: a report that speaks on every commit
    is a report nobody reads, and the hook this feeds runs on all of
    them.
    """
    if model is None:
        return 0
    wanted = {os.path.normpath(p) for p in paths}
    here = {r["id"] for r in model.values()
            if os.path.normpath(r.get("path", "")) in wanted}
    if not here:
        return 0
    said = False
    for rid in sorted(records):
        rec = records[rid]
        if rec.kind != "B" or not active(rec):
            continue
        req = rec.fields.get("requirement")
        if req not in here:
            continue
        grounds = []
        for name in as_list(rec.fields.get("all_of")) \
                + as_list(rec.fields.get("any_of")):
            status = records[name].fields.get("status", "?") \
                if name in records else "not in the register"
            grounds.append("%s (%s)" % (name, status))
        if not said:
            sys.stdout.write("\nWhat this commit touches is staked on:\n")
            said = True
        sys.stdout.write("  %s — %s rests on %s\n"
                         % (req, rid, ", ".join(grounds) or "nothing named"))
    return 0


def main():
    # implements: FR-GND-010, FR-GND-120, IF-GND-020
    argv = sys.argv[1:]
    paths = []
    if "--blast" in argv:
        cut = argv.index("--blast")
        paths = argv[cut + 1:]
        argv = argv[:cut] + ["--blast"]
    flags = set(argv)
    unknown = sorted(flags - {"--no-write", "--strict", "--blast"})
    if unknown:
        sys.stderr.write("unknown flag(s): %s\nusage: srs_grounds.py "
                         "[--no-write] [--strict] [--blast PATH…]\n"
                         % " ".join(unknown))
        return 2
    if not os.path.isdir(GROUNDS):
        sys.stderr.write("no grounds/ directory here — this project carries "
                         "no register, and there is nothing to check.\n")
        return 2

    cfg = load_config()
    errors = []
    records = read_records(errors)
    model_json, model_error = read_model()
    model = incoming = None
    if model_json is not None:
        model = {r["id"]: r for r in model_json["requirements"]}
        incoming = model_json.get("incoming", {})

    if "--blast" in flags:
        return blast(records, model, paths)

    found, warnings, reports = validate(records, model, model_error, cfg)
    errors += found

    for line in reports:
        sys.stdout.write("report: %s\n" % line)
    for line in warnings:
        sys.stdout.write("warning: %s\n" % line)
    for line in errors:
        sys.stdout.write("error: %s\n" % line)

    wrote = ""
    if not errors and "--no-write" not in flags:
        text = build_dashboard(records, model, incoming or {})
        with open(DASHBOARD, "w", encoding="utf-8") as handle:
            handle.write(text)
        wrote = " Dashboard rewritten: grounds/90-dashboard.md."

    sys.stdout.write(
        "\nRecords: %d. Errors: %d. Warnings: %d.%s (srs_grounds %s)\n"
        % (len(records), len(errors), len(warnings), wrote, __version__))

    if errors:
        return 1
    if warnings and "--strict" in flags:
        sys.stderr.write("strict mode: %d warning(s) treated as errors.\n"
                         % len(warnings))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
