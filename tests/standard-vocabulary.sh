#!/usr/bin/env bash
# The standards name every value their tools define — the requirement types,
# the verification methods, the files the checker does not read, the
# register's kinds, keys, statuses, grades, classes, periods and confidence
# levels, its configuration, and the layer's statuses and required keys —
# and the viewer's own tables of the checker's vocabulary cover it. Each
# list is prose or a table a person keeps; the tuples are in the code, and
# nothing else compares the two.
set -eo pipefail
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_OBJECT_DIRECTORY
unset GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."

# file implements: INV-SPEC-110
# file verifies: FR-SPEC-070, FR-VIEW-390, FR-VIEW-050, FR-INIT-250, INV-SPEC-110
python3 - <<'PY'
import re, sys

sys.dont_write_bytecode = True
sys.path.insert(0, "tools")
import srs_arch
import srs_check
import srs_grounds
import srs_view


def read(path):
    with open(path, encoding="utf-8") as handle:
        return handle.read()


def section(text, heading):
    start = text.find("\n## %s\n" % heading)
    if start < 0:
        return ""
    end = text.find("\n## ", start + 1)
    return text[start:end if end >= 0 else len(text)]


def both_ways(where, named, defined):
    named, defined = set(named), set(defined)
    return (["%s does not name `%s`" % (where, value) for value in sorted(defined - named)]
            + ["%s names `%s`, which the tool does not define" % (where, value)
               for value in sorted(named - defined)])


def mentioned(where, text, values):
    return ["%s never names `%s`" % (where, value) for value in values
            if "`%s`" % value not in text]


def backticked(line):
    return re.findall(r"`([^`]+)`", line)


def table_keys(text):
    return [m.group(1) for m in re.finditer(r"^\| `([^`]+)` \|", text, re.M)]


# --- Negation first: each kind of comparison reports a value left out and,
# --- where it compares both ways, one the tool does not define.
assert both_ways("x", ["a", "c"], ["a", "b"]) == ["x does not name `b`",
                                                  "x names `c`, which the tool does not define"]
assert mentioned("x", "only `a` here", ["a", "b"]) == ["x never names `b`"]
assert table_keys("| `a` | x |\n| b | y |\n| `c` | z |\n") == ["a", "c"]
print("standard-vocabulary: a value a list leaves out, or one the tool does not define, is red")

found = []
spec = read("specs/README.md")

# The requirement types, on the one line that lists them.
types_line = next((line for line in spec.splitlines() if line.startswith("**Types:**")), "")
found += both_ways("specs/README.md, the Types line", backticked(types_line), srs_check.TYPES)

# The files and directories the checker reads no requirement from, in the map.
the_map = "\n".join(line for line in section(spec, "Map").splitlines() if line.startswith("|"))
found += mentioned("specs/README.md's map", the_map,
                   sorted(srs_check.SKIP_FILES) + ["%s/" % name for name in sorted(srs_check.SKIP_DIRS)])

# The verification methods, one row each in the verification document.
verification = read("specs/50-verification.md")
methods = [value for value in table_keys(section(verification, "Verification") or verification)
           if len(value) == 1]
found += both_ways("specs/50-verification.md, the table of methods", methods, srs_check.VERIFICATIONS)

# The register: a heading per kind, and every key, status, grade, class,
# period and confidence level named where a reader looks for it.
grounds = read("grounds/README.md")
for kind, name in sorted(srs_grounds.KINDS.items()):
    if "### `%s` — %s" % (kind, name) not in grounds:
        found.append("grounds/README.md has no heading for `%s` — %s" % (kind, name))
found += mentioned("grounds/README.md", grounds,
                   sorted({key for keys in srs_grounds.REQUIRED.values() for key in keys}))
found += mentioned("grounds/README.md", grounds,
                   sorted({status for statuses in srs_grounds.STATUSES.values() for status in statuses}))
found += mentioned("grounds/README.md", grounds,
                   srs_grounds.GRADES + srs_grounds.CLASSES + srs_grounds.PERIODS + srs_grounds.TESTABLE_KINDS)
found += mentioned("grounds/README.md", grounds, [str(level) for level in srs_grounds.CONFIDENCES])
config = section(grounds, "Configuration")
config = config[:config.find("**Rules.**")] if "**Rules.**" in config else config
found += both_ways("grounds/README.md, the configuration table", table_keys(config), srs_grounds.DEFAULTS)

# The layer: its statuses on the status row, and a row for each required key.
arch = read("arch/README.md")
status_row = next((line for line in arch.splitlines() if line.startswith("| `status` |")), "")
found += both_ways("arch/README.md, the status row", backticked(status_row)[1:], srs_arch.STATUSES)
required = [key for key in table_keys(arch)
            if re.search(r"^\| `%s` \| required" % re.escape(key), arch, re.M)]
found += both_ways("arch/README.md, the required keys", required, srs_arch.REQUIRED_KEYS)

# The viewer keeps its own tables of the checker's vocabulary: a method it
# cannot name, a link it cannot label backwards, a status with no colour,
# or a field the comparison between two revisions skips is the viewer
# falling behind the checker.
found += both_ways("srs_view.py METHODS", [key for key, _label in srs_view.METHODS], srs_check.VERIFICATIONS)
found += both_ways("srs_view.py INCOMING_LABEL", srs_view.INCOMING_LABEL,
                   srs_check.LINK_FIELDS + ("superseded_by",))
page_css = read("tools/srs_view.py")
found += ["srs_view.py has no colour for the status `%s`" % status for status in srs_check.STATUSES
          if ".st-%s {" % status not in page_css]
# The fields two revisions are compared on: every field but `created`,
# which is written once and never changes, and the title.
found += both_ways("srs_view.py DIFF_FIELDS", srs_view.DIFF_FIELDS,
                   (srs_check.KNOWN_FIELDS - {"created"}) | {"title"})

# Every place that says which files an upgrade leaves alone without --force
# names each kind of them. The kinds are FR-INIT-060's, whose list the
# installer's suite walks against what the installer does; each place words
# them its own way, so each kind carries the words that count as naming it.
PRECIOUS = (
    ("the CI configuration", ("CI",)),
    ("the agent guides", ("AGENTS.md", "agent guides")),
    (".gitattributes", (".gitattributes",)),
    ("the hook", ("hook",)),
    ("the specification's standard", ("specs/README.md", "the standards", "specification standard")),
    ("the register's standard", ("grounds/README.md", "the standards", "optional layer", "grounds standard")),
    ("the layer's standard", ("arch/README.md", "the standards", "optional layer", "architecture standard")),
)


def precious_place(path, start, stop):
    if stop is None:
        # A row of a table: the row is the place, read as the line it is.
        return next((line for line in read(path).splitlines() if line.startswith(start)), None)
    text = " ".join(read(path).split())
    if path.endswith(".py"):
        # Adjacent string literals are one string to Python and one
        # sentence to a reader: `"agent " "guides"` names the guides.
        text = text.replace('" "', "")
    at = text.find(start)
    if at < 0:
        return None
    end = text.find(stop, at + len(start)) if stop else -1
    return text[at:end if end >= 0 else at + 600]


PLACES = (
    ("specs/10-fr-init.md, FR-INIT-060", "specs/10-fr-init.md", "while files that may be the project's own", "are refreshed only"),
    ("specs/00-glossary.md", "specs/00-glossary.md", "| Precious file |", None),
    ("docs/install.md", "docs/install.md", "CI config, `CLAUDE.md`", "are \"precious\""),
    ("docs/upgrade.md", "docs/upgrade.md", "Left alone: CI configuration", "files that may be your own"),
    ("tools/srs_init.py", "tools/srs_init.py", "additionally refreshes the \"precious\"", "marker"),
    ("tools/srs_init.py --force", "tools/srs_init.py", "also refresh existing SRS-DD-marked precious", "; a file"),
    ("tools/srs_upgrade.py", "tools/srs_upgrade.py", "also refresh precious files", ")\")"),
    ("the srs-init procedure", ".claude/skills/srs-init/SKILL.md", "precious files (", "only with"),
    ("the srs-upgrade procedure", ".claude/skills/srs-upgrade/SKILL.md", "Left alone:", "All of them"),
)


def unnamed(place, words_of):
    return [kind for kind, words in words_of if not any(word in place for word in words)]


assert unnamed("CI and the hook", PRECIOUS[:4]) == ["the agent guides", ".gitattributes"]
for where, path, start, stop in PLACES:
    place = precious_place(path, start, stop)
    if place is None:
        found.append("%s: the list of files an upgrade leaves alone is not where the suite looks (%r)" % (where, start))
        continue
    found += ["%s does not name %s among the files an upgrade leaves alone" % (where, kind)
              for kind in unnamed(place, PRECIOUS)]

# --- The specification's configuration: the keys the tools read, both ways.
# The checker's defaults name most; five more are read by one tool each, and
# each is asked of the tool that reads it, so this is no list kept by hand.
READ_ELSEWHERE = {"rules": "tools/srs_check.py", "repo_url": "tools/srs_view.py",
                  "framework_url": "tools/srs_upgrade.py", "line_width": "tools/srs_init.py",
                  "project_name": "tools/srs_init.py"}
for key, tool in sorted(READ_ELSEWHERE.items()):
    if '"%s"' % key not in read(tool):
        found.append("%s does not read `%s`, which this suite says it does" % (tool, key))
spec_config = section(spec, "Configuration")
spec_config = spec_config[:spec_config.find("**Rules.**")] if "**Rules.**" in spec_config else spec_config
found += both_ways("specs/README.md, the configuration table", table_keys(spec_config),
                   set(srs_check.DEFAULTS) | set(READ_ELSEWHERE))

# --- What a rule can cost, in each standard beside its checker.
for path, module in (("specs/README.md", srs_check), ("grounds/README.md", srs_grounds), ("arch/README.md", srs_arch)):
    found += mentioned(path, read(path), module.SEVERITIES)

# --- The glossary's rows that list a tool's set.
glossary = read("specs/00-glossary.md")
record_row = next((line for line in glossary.splitlines() if line.startswith("| Record |")), "")
found += ["specs/00-glossary.md, the Record row, does not name the kind %s" % name
          for name in srs_grounds.KINDS.values() if name not in record_row]
lexicon_row = next((line for line in glossary.splitlines() if line.startswith("| Lexicon |")), "")
# The row says them in words: `modal_verbs` is "modal verbs" there.
found += ["specs/00-glossary.md, the Lexicon row, does not name the %s" % key.replace("_", " ")
          for key in ("modal_verbs", "negation_words", "rationale_markers")
          if key.replace("_", " ") not in lexicon_row]

# --- INV-SPEC-110: a copy of a tool's list, in another file, held to it.
import os
generated = [os.path.relpath(p, os.getcwd()) for p in (srs_check.TRACE, srs_grounds.DASHBOARD, srs_arch.MAP)]
guide_generated = next((line for line in read("AGENTS.md").splitlines() if line.startswith("- **Generated files**")), "")
found += ["AGENTS.md, Generated files, does not name %s" % path for path in generated if path not in guide_generated]
map_rows = the_map
found += ["srs_view.py expects %s as prose and the standard's map has no row for it" % name
          for name in srs_view.PROSE_EXPECTED if "`%s`" % name not in map_rows]
found += ["srs_view.py excludes %s from prose, and the checker reads requirements from it" % name
          for name in srs_view.PROSE_EXCLUDED if name not in srs_check.SKIP_FILES]
for tool in ("tools/srs_init.py", "tools/srs_upgrade.py"):
    choices = re.search(r'"--period", choices=\(([^)]*)\)', read(tool))
    offered = re.findall(r'"([a-z]+)"', choices.group(1)) if choices else []
    found += both_ways("%s --period" % tool, offered, srs_grounds.PERIODS)
import srs_cite_eval
kinds = {kind: "srs_grounds.py" for kind in srs_grounds.KINDS}
kinds["E"] = "srs_arch.py"
if srs_cite_eval.TOOLS != kinds:
    found.append("srs_cite_eval.py TOOLS does not map each record kind to the tool that cites it: %s" % srs_cite_eval.TOOLS)
import srs_release
release_line = next((line for line in read(".claude/skills/srs-release/SKILL.md").splitlines() if "The command edits" in line), "")
for path in srs_release.TOUCHED:
    name = os.path.relpath(path, os.getcwd()) if os.path.isabs(path) else path
    if name == "specs/90-traceability.md":
        continue
    if "`%s`" % name not in release_line:
        found.append("the srs-release procedure does not say the command edits %s" % name)
if "the matrix" not in release_line:
    found.append("the srs-release procedure does not say the command edits the matrix")
import srs_proc_eval
found += mentioned("srs_proc_eval.py's docstring", srs_proc_eval.__doc__.replace("check: ", "check: `").replace(" NAME", "` NAME").replace(" REGEX", "` REGEX"), srs_proc_eval.CHECK_KINDS)
# The hand-written usage of the tools that parse their own flags: every flag
# main() accepts is in the usage it prints on a flag it does not.
import ast, subprocess
for name in ("srs_check.py", "srs_grounds.py", "srs_arch.py", "srs_dates.py"):
    source = read("tools/" + name)
    main = next(node for node in ast.parse(source).body if isinstance(node, ast.FunctionDef) and node.name == "main")
    accepted = {node.value for node in ast.walk(main)
                if isinstance(node, ast.Constant) and isinstance(node.value, str) and re.fullmatch(r"--[a-z][a-z-]*", node.value)}
    run = subprocess.run([sys.executable, "tools/" + name, "--no-such-flag"], capture_output=True, text=True,
                         env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"))
    usage = run.stderr + run.stdout
    found += ["tools/%s accepts %s and its usage does not say so" % (name, flag) for flag in sorted(accepted) if flag not in usage]
    found += ["tools/%s accepts %s and its docstring does not say so" % (name, flag) for flag in sorted(accepted)
              if flag not in (ast.get_docstring(ast.parse(source)) or "")]

for line in found:
    print("  " + line)
if found:
    print("standard-vocabulary: %d problem(s)" % len(found))
    sys.exit(1)
print("standard-vocabulary: the standards and the viewer name every value the tools define")
PY
