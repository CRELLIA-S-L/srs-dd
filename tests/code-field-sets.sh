#!/usr/bin/env bash
# A requirement whose statement claims a set — every procedure, every Python
# tool, every command — names the whole set in its `code` field. An
# incomplete field is green forever: the checker proves the paths exist and
# never that they are all of them. Each set is derived from the repository
# here, so a file added to it is asked of the field on the day it lands.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# implements: INV-SPEC-100
# verifies: INV-SPEC-100
python3 tools/srs_view.py --json /tmp/srs-code-sets.json >/dev/null
python3 - <<'PY'
import glob, json, os, re, sys

with open("/tmp/srs-code-sets.json", encoding="utf-8") as handle:
    fields = {r["id"]: r.get("code") or [] for r in json.load(handle)["requirements"]}


def skills(predicate=lambda text: True):
    found = set()
    for path in glob.glob(".claude/skills/*/SKILL.md"):
        with open(path, encoding="utf-8") as handle:
            if predicate(handle.read()):
                found.add(path)
    return found


def names_records(text):
    """A procedure that names a record to a person: by the command that
    prints the citation, or by pointing at the guide's rule for it."""
    return "--cite" in text or "as `AGENTS.md` asks" in text


tools_py = set(glob.glob("tools/*.py"))
# The requirement, the kind of path it claims, and the set of that kind it
# must name — the kind filters the field, so a guide beside the procedures
# in FR-SKILL-200's field is neither required nor in the way.
CLAIMS = (
    ("FR-SKILL-020", r"^\.claude/skills/", skills()),
    # srs-upgrade names `--cite` only to forbid it: the identifiers it relays
    # are the framework's, and the citation would find the project's own.
    ("FR-SKILL-200", r"^\.claude/skills/",
     skills(names_records) - {".claude/skills/srs-upgrade/SKILL.md"}),
    ("NFR-SPEC-010", r"^tools/.*\.py$", tools_py),
    # Every command: the Python tools less the module the checkers import,
    # and the local gate.
    ("CON-SPEC-030", r"^tools/", (tools_py - {"tools/srs_parse.py"}) | {"tools/ci_selftest.sh"}),
    # Every tool that reads an identifier's number, and every one that
    # orders identifiers: the grammar and the order are the parser's, and a
    # tool that uses them is one the invariant binds.
    ("INV-SPEC-080", r"^tools/", {p for p in tools_py if "NUMBER" in open(p, encoding="utf-8").read()}),
    ("INV-SPEC-090", r"^tools/", {p for p in tools_py if "id_key" in open(p, encoding="utf-8").read()}),
)


def check(fields, claims):
    problems = []
    for rid, kind, wanted in claims:
        named = {path for path in fields.get(rid, []) if re.search(kind, path)}
        problems += ["%s claims %s and its code field does not name it" % (rid, path)
                     for path in sorted(wanted - named)]
        problems += ["%s names %s, which is not of the set it claims" % (rid, path)
                     for path in sorted(named - wanted)]
    return problems


# --- Negation first: a member left out and a path that does not belong are
# --- each reported; a path of another kind in the same field is neither.
lab = check({"R-1": ["tools/a.py", "tools/stray.py", "AGENTS.md"]},
            (("R-1", r"^tools/", {"tools/a.py", "tools/b.py"}),))
assert lab == ["R-1 claims tools/b.py and its code field does not name it",
               "R-1 names tools/stray.py, which is not of the set it claims"], lab
print("code-field-sets: a member the field leaves out and a path outside the set are each red")

found = check(fields, CLAIMS)
for line in found:
    print("  " + line)
if found:
    print("code-field-sets: %d problem(s)" % len(found))
    sys.exit(1)
print("code-field-sets: every field claiming a set names all of it (%s)"
      % ", ".join("%s %d" % (rid, len(wanted)) for rid, _kind, wanted in CLAIMS))
PY
