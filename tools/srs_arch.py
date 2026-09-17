#!/usr/bin/env python3
#
# SRS-DD-VERSION — the framework release this file came from
"""The architecture layer's checker: reads arch/, holds it to the specification, writes the map.

    python3 tools/srs_arch.py              read, report, regenerate arch/90-map.md
    python3 tools/srs_arch.py --no-write   report only
    python3 tools/srs_arch.py --strict     treat warnings as errors

The requirement model is read by running tools/srs_view.py as a subprocess and parsing what it
publishes, which the framework promises to keep stable, so this file never learns the requirement
format. The layer's own records go through tools/srs_parse.py, the one reader both formats share.

Nothing here writes outside arch/: declining the layer, or deleting it, has to cost nothing.
"""
# implements: FR-ARCH-010, IF-ARCH-020, CON-ARCH-010
# implements: NFR-SPEC-010, CON-SPEC-030
import ast
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
        "tools/srs_parse.py: missing — the architecture checker reads the record shape through "
        "it, and the two travel together. Copy it beside this file from the framework clone, or "
        "re-run tools/srs_init.py to refresh the tooling.\n")
    sys.exit(2)

# Re-exported: the number lives in srs_parse, the one file every checker must have beside it
# (ADR-0021).
__version__ = srs_parse.__version__

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARCH = os.path.join(ROOT, "arch")
CONFIG = os.path.join(ARCH, "arch-config.json")
MAP = os.path.join(ARCH, "90-map.md")
MAP_REL = os.path.join("arch", "90-map.md")
VIEWER = os.path.join(ROOT, "tools", "srs_view.py")

# Files in arch/ that hold no records.
SKIP_FILES = {"README.md", "90-map.md"}

# Loose enough to catch a heading that meant to be a record and failed, so that
# the identifier rule can say so instead of passing it over in silence.
RE_HEADING = re.compile(r"^###\s+([A-Za-z][A-Za-z0-9]*-\d+(?:-[A-Za-z0-9]+)*)\s*(?:[—–-]\s*)?(.*)$")
RE_ID = re.compile(r"^E-\d{3}$")

REQUIRED_KEYS = ("status", "carries", "requirements")
STATUSES = ("proposed", "built", "superseded", "withdrawn")
CANCELLED = ("superseded", "withdrawn")
REALIZED = ("implemented", "partial")

# implements: IF-ARCH-030
# Published names: a project writes them into arch/arch-config.json, so one is never renamed and
# never given to a different rule.
RULES = ("element-cancelled", "carrier-unclaimed", "requirement-uncarried", "element-empty",
         "dependency-undeclared", "element-cycle")

# `warn` fails a --strict run, `report` is printed and fails nothing, `off` is not printed at all.
SEVERITIES = ("warn", "report", "off")

# implements: FR-ARCH-240
# How the `requirements` field is kept. `written` is the author's claim and the default;
# `derived` counts as carried what the element owns, and the record's key becomes optional.
MODES = ("written", "derived")


def fail_setup(message):
    """Something the layer could not be read through at all — exit 2, never 1."""
    sys.stderr.write("%s\n" % message)
    return 2


def load_config():
    # implements: FR-ARCH-090
    """What each rule costs, as the project set it, and how the requirements are kept. A
    missing file means every default."""
    cfg = {"rules": {}, "requirements": "written"}
    if not os.path.exists(CONFIG):
        return cfg, None
    try:
        with open(CONFIG, encoding="utf-8") as handle:
            raw = json.load(handle)
    except (OSError, ValueError) as exc:
        return None, "arch/arch-config.json: %s" % exc
    if not isinstance(raw, dict):
        return None, "arch/arch-config.json: the top level must be a JSON object"
    rules = raw.get("rules", {})
    if not isinstance(rules, dict):
        return None, "arch/arch-config.json: `rules` must be an object"
    for name, severity in rules.items():
        if name not in RULES:
            return None, ("arch/arch-config.json: unknown rule %r — this checker publishes %s"
                          % (name, ", ".join(RULES)))
        if severity not in SEVERITIES:
            return None, ("arch/arch-config.json: rule %r is %r, expected %s"
                          % (name, severity, "/".join(SEVERITIES)))
    cfg["rules"] = rules
    # implements: FR-ARCH-240
    mode = raw.get("requirements", "written")
    if mode not in MODES:
        return None, ("arch/arch-config.json: `requirements` is %r, expected %s"
                      % (mode, "/".join(MODES)))
    cfg["requirements"] = mode
    return cfg, None


def rule_finding(warnings, reports, cfg, rule, text):
    # implements: FR-ARCH-090
    """Route one rule's finding by what the project decided it costs."""
    severity = cfg["rules"].get(rule, "warn")
    if severity == "off":
        return
    (warnings if severity == "warn" else reports).append(text)


def read_model():
    # implements: FR-ARCH-010
    """The requirement model, through the viewer's published JSON.

    A subprocess rather than an import: the viewer is a command with a promised output, and
    borrowing its internals would tie this checker to a shape nothing guarantees.
    """
    if not os.path.exists(VIEWER):
        return None, "tools/srs_view.py is not here — the architecture checker reads the " \
                     "requirement model through it"
    try:
        done = subprocess.run([sys.executable, VIEWER, "--json"], stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE)
    except OSError as exc:
        return None, "could not run tools/srs_view.py: %s" % exc
    if done.returncode != 0:
        return None, "tools/srs_view.py exited %d: %s" % (
            done.returncode, done.stderr.decode("utf-8", "replace").strip())
    try:
        return json.loads(done.stdout.decode("utf-8")), None
    except ValueError as exc:
        return None, "tools/srs_view.py produced unreadable JSON: %s" % exc


def collect_files():
    # implements: FR-ARCH-010
    """Every record file in the layer, subdirectories included."""
    out = []
    if not os.path.isdir(ARCH):
        return out
    for current, dirs, files in os.walk(ARCH):
        dirs.sort()
        for name in sorted(files):
            if not name.endswith(".md") or name in SKIP_FILES:
                continue
            full = os.path.join(current, name)
            out.append((full, os.path.relpath(full, ROOT)))
    return sorted(out, key=lambda pair: pair[1])


def read_records(errors):
    # implements: FR-ARCH-010
    """Every element the layer holds, in the order the files present them."""
    records = []
    for full, rel in collect_files():
        try:
            with open(full, encoding="utf-8") as handle:
                text = handle.read()
        except (OSError, UnicodeDecodeError) as exc:
            errors.append("%s — cannot read the file: %s" % (rel, exc))
            continue
        for entry in srs_parse.parse_entries(text, rel, errors, RE_HEADING):
            records.append(entry)
    return records


def as_list(value):
    """A bracketed list as the parser left it, or a single value as a list of one."""
    if isinstance(value, list):
        return value
    if value is None or value == "":
        return []
    return [value]


def check_records(records, model, errors, warnings, reports, cfg):
    # implements: FR-ARCH-020, FR-ARCH-030, FR-ARCH-040, FR-ARCH-050, FR-ARCH-080
    """Everything decidable from one element and the requirement model."""
    seen = {}
    by_id = {r["id"]: r for r in model["requirements"]}
    derived = cfg["requirements"] == "derived"
    computed = carried_by(records, model, cfg)[1]
    for record in records:
        if not RE_ID.match(record.id):
            errors.append("%s — identifier does not match E-<NNN>" % record.where)
            continue
        if record.id in seen:
            errors.append("%s — %s is already used at %s" % (record.where, record.id,
                                                             seen[record.id]))
            continue
        seen[record.id] = record.where

        for key in REQUIRED_KEYS:
            # The standard requires the field only where it is written.
            if key == "requirements" and derived:
                continue
            if key not in record.fields:
                errors.append("%s — required key %r is missing" % (record.where, key))
        status = record.fields.get("status")
        if status is not None and status not in STATUSES:
            errors.append("%s — status %r is not one of %s"
                          % (record.where, status, ", ".join(STATUSES)))

        cancelled = status in CANCELLED
        named = as_list(record.fields.get("requirements"))
        for rid in named:
            requirement = by_id.get(rid)
            if requirement is None:
                errors.append("%s — %s names %s, which the specification does not carry"
                              % (record.where, record.id, rid))
                continue
            if requirement.get("status") in CANCELLED:
                rule_finding(warnings, reports, cfg, "element-cancelled",
                             "%s — %s carries %s, which is %s"
                             % (record.where, record.id, rid, requirement["status"]))
        # A dissolved part has nothing left to answer for, and saying so
        # every run is how a report teaches its reader to skim it.
        # Over what the element carries, not what it names: under `derived` a record naming
        # nothing may carry a dozen, and one naming nothing and owning nothing is empty even
        # though no key is missing.
        carried = named or computed.get(record.id)
        if not carried and not cancelled and ("requirements" in record.fields or derived):
            rule_finding(warnings, reports, cfg, "element-empty",
                         "%s — %s carries no requirement, so nothing says what it is for"
                         % (record.where, record.id))


def check_ownership(records, model, warnings, reports, cfg):
    # implements: FR-ARCH-060, FR-ARCH-070
    """The two directions of the same decay: a file no part owns, a requirement no part carries.

    Both are computed from what the specification already publishes, so neither needs the language
    of a file read.
    """
    carried = set()
    claimed = set()
    written, computed = carried_by(records, model, cfg)
    for record in records:
        if not RE_ID.match(record.id):
            continue
        if record.fields.get("status") in CANCELLED:
            continue
        for path in as_list(record.fields.get("carries")):
            carried.add(path.rstrip("/"))
        claimed.update(written[record.id])
        claimed.update(computed[record.id])

    for requirement in model["requirements"]:
        if requirement.get("status") not in REALIZED:
            continue
        if requirement["id"] not in claimed:
            rule_finding(warnings, reports, cfg, "requirement-uncarried",
                         "%s — %s is %s and no element carries it"
                         % (requirement["path"], requirement["id"], requirement["status"]))
        for path in (requirement.get("code") or []):
            if owner_of(path, carried) is None:
                rule_finding(warnings, reports, cfg, "carrier-unclaimed",
                             "%s — named by %s and carried by no element"
                             % (path, requirement["id"]))


def carried_by(records, model, cfg):
    # implements: FR-ARCH-240
    """What each element carries, as ({id: written}, {id: derived}) — two sets per element,
    kept apart because they are two claims: the record's, that the part answers for the
    obligation; the derivation's, that the part owns a file the obligation names.

    The derived set is empty under `written`, and empty for a cancelled element under either
    mode: a dissolved part owns nothing the way it depends on nothing. Ownership is decided by
    owner_of over every live carrier, so the file a requirement names lands in the element
    whose carrier is nearest — by the rule that decides whether a carrier is unclaimed at all.
    """
    written, derived, owners = {}, {}, {}
    for record in records:
        if not RE_ID.match(record.id):
            continue
        written[record.id] = set(as_list(record.fields.get("requirements")))
        derived[record.id] = set()
        if record.fields.get("status") in CANCELLED:
            continue
        for path in as_list(record.fields.get("carries")):
            owners.setdefault(path.rstrip("/"), []).append(record.id)
    if cfg["requirements"] == "derived":
        for requirement in model["requirements"]:
            if requirement.get("status") not in REALIZED:
                continue
            for path in requirement.get("code") or []:
                for element in owners.get(owner_of(path, owners), ()):
                    derived[element].add(requirement["id"])
    return written, derived


def spec_order(model):
    """A sort key placing identifiers the way the specification does: by type, then by the
    area order the project declared, then by number."""
    types = list(model.get("types") or ())
    areas = list(model.get("areas") or ())

    def key(rid):
        parts = rid.split("-")
        kind, area = parts[0], parts[1] if len(parts) > 2 else ""
        number = parts[-1]
        return (types.index(kind) if kind in types else len(types),
                areas.index(area) if area in areas else len(areas),
                int(number) if number.isdigit() else 0, rid)
    return key


def owner_of(path, carried):
    # implements: FR-ARCH-060
    """The carrier that covers a path: the path itself, or a directory above it.

    A directory in `carries` owns what is under it, so a part is described once rather than
    re-listed every time a file is added beside its siblings.
    """
    if path in carried:
        return path
    parts = path.split("/")
    for depth in range(len(parts) - 1, 0, -1):
        prefix = "/".join(parts[:depth])
        if prefix in carried:
            return prefix
    return None


def python_modules(records):
    # implements: FR-ARCH-200
    """Every Python file the layer carries, as path -> element, plus the names that resolve.

    Two maps rather than one, because a bare module name is not unique: `a/util.py` and
    `b/util.py` both answer to `util`, and a dictionary keyed by the name would report the import
    against whichever file was read last. A name only one carried file answers to resolves; the
    rest are left alone, which is the same rule the unresolvable import gets.
    """
    by_path = {}
    for record in records:
        if not RE_ID.match(record.id) or record.fields.get("status") in CANCELLED:
            continue
        for path in as_list(record.fields.get("carries")):
            full = os.path.join(ROOT, path)
            if os.path.isfile(full) and path.endswith(".py"):
                by_path[path] = record.id
            elif os.path.isdir(full):
                for current, dirs, files in os.walk(full):
                    dirs[:] = [d for d in dirs if not d.startswith(".")]
                    for name in sorted(files):
                        if name.endswith(".py"):
                            rel = os.path.relpath(os.path.join(current, name), ROOT)
                            by_path[rel] = record.id
    by_name = {}
    for path in sorted(by_path):
        by_name.setdefault(os.path.basename(path)[:-3], []).append(path)
    # A name two carried files answer to resolves to neither: reporting it against whichever file
    # was read last is how this rule would name an element the importer never touched.
    unique = {name: paths[0] for name, paths in by_name.items() if len(paths) == 1}
    return by_path, unique


def imports_of(path):
    # implements: FR-ARCH-200
    """The module names one file imports, as written."""
    try:
        with open(path, encoding="utf-8") as handle:
            tree = ast.parse(handle.read())
    except (OSError, UnicodeDecodeError, SyntaxError):
        return []
    names = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            names.extend(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module:
            names.append(node.module)
    return [name.split(".")[0] for name in names]


def declared_dependencies(records):
    # implements: FR-ARCH-200, FR-ARCH-220
    """The graph the elements declare, live elements only.

    One place, read by the reflexion check and by the cycle walk: two readings of `depends_on`
    would one day disagree about which elements are in the graph. A cancelled element is out of
    it — it keeps its field for the record, and a circle surviving through it would be one
    nothing live can break. Targets are kept as written, resolving or not: nothing here checks
    that a dependency names an element, and the walk has to tolerate one that does not.
    """
    declared = {}
    for record in records:
        if RE_ID.match(record.id) and record.fields.get("status") not in CANCELLED:
            declared[record.id] = set(as_list(record.fields.get("depends_on")))
    return declared


def check_dependencies_resolve(records, errors):
    # implements: FR-ARCH-230
    """A dependency names an element the layer carries.

    Its own walk after every record is read, not a clause of check_records: that one reads
    records one at a time, and an element declared further down the file would be reported as
    absent. A cancelled element is present — it has a status that says it left — and a
    dependency on it is not this rule's finding.
    """
    present = set(record.id for record in records if RE_ID.match(record.id))
    for record in records:
        if record.id not in present:
            continue
        for target in as_list(record.fields.get("depends_on")):
            if target not in present:
                errors.append("%s — %s depends on %s, which no element carries"
                              % (record.where, record.id, target))


def check_cycles(records, warnings, reports, cfg):
    # implements: FR-ARCH-220
    """Elements that depend on each other in a circle, each circle named once.

    A warning with a name where the same finding between requirements is an error with none:
    nothing here is broken by a circle — the map renders, the reflexion check runs — and two
    parts that need each other are a fact about the code the project may choose to live with.
    A dependency naming no element ends the path rather than the walk.
    """
    declared = declared_dependencies(records)
    where = dict((record.id, record.where) for record in records)
    colour = {}
    stack = []

    def walk(node):
        colour[node] = "grey"
        stack.append(node)
        for target in sorted(declared.get(node, ())):
            # Cancelled or never declared: a path ends here, and the name stays out of the
            # walk's own bookkeeping so a circle is never reported through it.
            if target not in declared:
                continue
            if colour.get(target) == "grey":
                circle = stack[stack.index(target):]
                # The degenerate circle has no "each other" in it, and the layer has no rule
                # of its own for a self-reference the way the specification checker does.
                # Located at the element the circle is named from, since a circle has no
                # single line of its own and the other findings all start with a place.
                if len(circle) == 1:
                    text = "%s — %s depends on itself" % (where[node], node)
                else:
                    text = ("%s — elements depend on each other in a circle: %s"
                            % (where[target], " → ".join(circle + [target])))
                rule_finding(warnings, reports, cfg, "element-cycle", text)
            elif target not in colour:
                walk(target)
        stack.pop()
        colour[node] = "black"

    for node in sorted(declared):
        if node not in colour:
            walk(node)


def check_conformance(records, warnings, reports, cfg):
    # implements: FR-ARCH-200
    """The declared model against the one the code has.

    One direction only, as the requirement states it: an edge the code has and the model does not.
    The other direction — a declared edge nothing in the code walks — is a different reading and
    has no rule here.
    """
    by_path, unique = python_modules(records)
    declared = declared_dependencies(records)
    seen = set()
    for path in sorted(by_path):
        element = by_path[path]
        for name in imports_of(os.path.join(ROOT, path)):
            target_path = unique.get(name)
            if target_path is None:
                continue
            target = by_path[target_path]
            if target == element or target in declared.get(element, set()):
                continue
            if (element, target) in seen:
                continue
            seen.add((element, target))
            rule_finding(warnings, reports, cfg, "dependency-undeclared",
                         "%s — imports %s, carried by %s, and %s does not declare it"
                         % (path, name, target, element))


def print_drivers(model, limit=10):
    # implements: FR-ARCH-210
    """The requirements that lead, by what makes a requirement drive structure.

    Incoming links first — over this repository the ones that took part in an architecture
    decision carry three times as many — and the type as the tie-break, because an interface or
    an invariant constrains structure by construction. Candidates for a person to accept: the
    trade-off nobody wrote down is not in the model to be found.
    """
    incoming = model.get("incoming", {})
    weight = {"IF": 0, "INV": 1, "CON": 2, "NFR": 3, "FR": 4}
    ranked = sorted(model["requirements"],
                    key=lambda r: (-len(incoming.get(r["id"], [])),
                                   weight.get(r["id"].split("-")[0], 9), r["id"]))
    sys.stdout.write("Architectural drivers, most constrained first. "
                     "A design is worked against a few of these, not all of them.\n\n")
    for entry in ranked[:limit]:
        sys.stdout.write("%s — %s (%s, %s)\n    %d incoming, type %s\n"
                         % (entry["id"], entry["title"], entry["path"], entry["status"],
                            len(incoming.get(entry["id"], [])), entry["id"].split("-")[0]))
    return 0


def render_map(records, model, cfg):
    # implements: FR-ARCH-110, FR-ARCH-250, CON-ARCH-020
    """The map, generated from the records and never edited by hand.

    Under `derived` an entry the record names is bold and one computed from what the element
    owns is plain, and the map says so above the table: the two are different claims, and a
    reader deciding whether a part answers for an obligation has to see which one they hold.
    """
    by_id = {r["id"]: r for r in model["requirements"]}
    derived = cfg["requirements"] == "derived"
    written, computed = carried_by(records, model, cfg)
    order = spec_order(model)
    out = ["# The map", "",
           "**Generated by `tools/srs_arch.py`. Do not edit by hand — "
           "run the command and commit the result.**", "",
           "What each part of this project is, what it carries and what state it is in.", ""]
    if derived:
        out += ["Requirements are derived: an entry in **bold** is one the record names, "
                "an entry in plain text one computed from what the element owns.", ""]
    out += ["| Element | Status | Carries | Requirements |", "|---|---|---|---|"]
    carrying = set()
    for record in sorted(records, key=lambda r: r.id):
        if not RE_ID.match(record.id):
            continue
        carries = ", ".join("`%s`" % p for p in as_list(record.fields.get("carries"))) or "—"
        named = as_list(record.fields.get("requirements"))
        extra = sorted(computed[record.id] - set(named), key=order)
        shown = ", ".join(["**%s**" % rid for rid in named] + extra) or "—"
        held = set(named) | set(extra)
        carrying |= held
        live = sum(1 for rid in held if by_id.get(rid, {}).get("status") in REALIZED)
        out.append("| **%s** %s | `%s` | %s | %s (%d realized) |"
                   % (record.id, record.title, record.fields.get("status") or "?",
                      carries, shown, live))
    out.append("")
    out.append("%d elements, carrying %d of the %d requirements this specification holds."
               % (len([r for r in records if RE_ID.match(r.id)]),
                  len(carrying), len(model["requirements"])))
    out.append("")
    return "\n".join(out)


def main(argv=None):
    # implements: FR-ARCH-100, IF-ARCH-020
    args = list(sys.argv[1:] if argv is None else argv)
    unknown = sorted(set(args) - {"--no-write", "--strict", "--drivers"})
    if unknown:
        return fail_setup("unknown flag(s): %s\n"
                          "usage: srs_arch.py [--no-write] [--strict] [--drivers]"
                          % " ".join(unknown))
    strict = "--strict" in args
    write = "--no-write" not in args

    if not os.path.isdir(ARCH):
        return fail_setup("arch/ directory not found: %s\nThe architecture layer is optional; "
                          "install it with tools/srs_init.py --arch yes." % ARCH)

    cfg, problem = load_config()
    if problem:
        return fail_setup(problem)
    model, problem = read_model()
    if problem:
        return fail_setup(problem)

    if "--drivers" in args:
        return print_drivers(model)

    errors, warnings, reports = [], [], []
    records = read_records(errors)
    check_records(records, model, errors, warnings, reports, cfg)
    check_dependencies_resolve(records, errors)
    check_ownership(records, model, warnings, reports, cfg)
    check_conformance(records, warnings, reports, cfg)
    check_cycles(records, warnings, reports, cfg)

    for text in warnings:
        sys.stdout.write("warning: %s\n" % text)
    for text in reports:
        sys.stdout.write("note: %s\n" % text)
    for text in errors:
        sys.stdout.write("error: %s\n" % text)

    if errors:
        sys.stdout.write("\nElements: %d. Errors: %d. (srs_arch %s)\n"
                         % (len(records), len(errors), __version__))
        return 1

    if write:
        with open(MAP, "w", encoding="utf-8") as handle:
            handle.write(render_map(records, model, cfg))

    sys.stdout.write("Elements: %d. Errors: 0. Warnings: %d.%s (srs_arch %s)\n"
                     % (len(records), len(warnings),
                        " Map rewritten: %s." % MAP_REL if write else "", __version__))
    if strict and warnings:
        sys.stdout.write("strict mode: %d warning(s) treated as errors.\n" % len(warnings))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
