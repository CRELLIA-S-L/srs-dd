#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Copyright (c) 2026 CRELLIA S.L. — part of SRS-DD, distributed under the MIT License
"""Install, adopt, or upgrade the SRS-DD skeleton in a target repository.

Run from a clone of the framework repository:

    python3 tools/srs_init.py ../my-project
    python3 tools/srs_init.py ../my-project --defaults --ci github

Three modes, detected automatically:

- **fresh** — the target has no specification: the full skeleton is laid
  out, including a placeholder requirement.
- **adopt** — the target already has an SRS-shaped specification but no
  `specs/srs-config.json`: the spec is validated against the proposed
  configuration BEFORE anything else changes; on validation failure the
  target is left untouched (exit 3). Only tooling and missing service
  files are installed — existing specification files are never modified.
- **upgrade** — `specs/srs-config.json` exists: the tooling and the
  skills are refreshed without a flag, the version
  transition and relevant CHANGELOG upgrade notes are printed.

`--mode fresh|adopt` overrides the fresh/adopt detection; upgrade is
always config-driven. Everything the framework owns lives under srs-dd/
in the target and is rewritten whole by every upgrade; the hook, the
pipelines, the agent guides and .gitattributes are starters, written
where the file is absent and never again — only the region of AGENTS.md
between <!-- srs-dd --> and <!-- /srs-dd --> is refreshed in place. The
project's requirements are never touched.

`--dry-run` writes nothing in any mode and prints the created /
refreshed / skipped list the real run would produce, so the change can
be reviewed — or shown to a maintainer by an agent — before it happens.
In adopt mode it skips the spec validation, which needs the checker
running inside the target; the real run does that first regardless.

Interactive by default; --defaults answers every remaining question with
its default. The script knows no natural language: to write the
specification in another language, pass the word lists (--modal-verbs,
--negation-words, --rationale-markers) — or use the `srs-init` agent
skill, which generates and confirms them for you.

Exit codes: 0 — success; 1 — checker errors in the target, or a failure
after adopt's point of no return (partial completion, see output);
2 — refused before any change (usage, ambiguous target, config errors);
3 — adopt refused or rolled back, the target is byte-identical (modulo removal of a
stale temp file from a previously crashed adopt run).
"""

# file implements: NFR-SPEC-010, CON-SPEC-030

import sys

# Importing srs_check writes tools/__pycache__ in this clone, and a
# cached module is validated by (mtime, size) alone: a version string
# that changes without changing the file size — 0.5.0 to 0.6.0 — can be
# served stale, so the installer would report and select upgrade notes
# for a version it is not installing. This line must stay above the
# import below.
sys.dont_write_bytecode = True

import argparse                                            # noqa: E402
import json                                                # noqa: E402
import os                                                  # noqa: E402
import re                                                  # noqa: E402
import subprocess                                          # noqa: E402

# The shipped tools live in the framework's directory, two doors down from
# this installer, which never ships.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                os.pardir, "srs-dd", "tools"))
from srs_check import (DEFAULTS, __version__, parse_file,  # noqa: E402
                       RE_ANNOTATION, RE_END, TYPES, RE_AREA_NAME, SKIP_FILES,
                       SKIP_DIRS)
import srs_parse                                           # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PLACEHOLDER_NAME = "<Your Project Name>"
# implements: IF-SPEC-040
RE_AREA = RE_AREA_NAME
# Strict requirement identifier: composed from the framework's TYPES and
# the area grammar, NOT from srs_check.RE_ID (that one is bound to the
# framework's own configured areas).
RE_STRICT_ID = re.compile(r"^(?:%s)-%s-%s$"   # implements: INV-SPEC-080
                          % ("|".join(TYPES), srs_parse.AREA, srs_parse.NUMBER))
# srs-end: IF-SPEC-040
RE_VERSION = re.compile(r'^__version__\s*=\s*"([^"]+)"', re.M)

TEMP_CHECKER = ".srs_check_adopt.py"

# The payload directory: starter files a target edits into its own
# specification. It is deliberately not specs/ — this repository keeps a
# real specification of the framework there, and requirements about the
# framework's own tooling must never travel into somebody's project.
# implements: CON-SPEC-020
SKELETON = "skeleton"
# srs-end: CON-SPEC-020

# Where a target upgrades from when this clone has no remote of its own.
DEFAULT_FRAMEWORK_URL = "https://github.com/CRELLIA-S-L/srs-dd.git"

# What the specification skeleton is made of. Anything else under
# skeleton/specs/ in the framework clone is not ours to ship.
SKELETON_SUFFIXES = (".md", ".json", ".gitkeep")

# implements: FR-INIT-320
# The framework's directory in a target: everything that stays the
# framework's lives under it and is rewritten whole by every upgrade. In
# this repository the directory is the source the installer copies, not a
# copy — the repository is the first project of its own method.
SRS_DIR = "srs-dd"
SRS_TOOLS = os.path.join(SRS_DIR, "tools")
SPEC_STANDARD = os.path.join(SRS_DIR, "standard.md")
METHOD = os.path.join(SRS_DIR, "method.md")
GUIDE_SOURCE = os.path.join(SRS_DIR, "guide.md")
DIR_README = os.path.join(SRS_DIR, "README.md")
# Copied into every target with the tools, whatever layers it keeps.
DIR_FILES = (DIR_README, os.path.join(SRS_DIR, "LICENSE"), SPEC_STANDARD,
             METHOD, GUIDE_SOURCE)
# srs-end: FR-INIT-320
# implements: FR-INIT-370
# The one place of the framework's inside a file of the project's: the
# region of AGENTS.md between these lines holds the framework's guide.
REGION_BEGIN = "<!-- srs-dd -->"
REGION_END = "<!-- /srs-dd -->"
# srs-end: FR-INIT-370
# The decision template: identical for the framework and for every target
# in the same way, and kept beside the decisions it shapes so that this
# repository's own authors see the copy a target gets.
# implements: INV-SKILL-010
ADR_TEMPLATE = os.path.join("specs", "adr", "template.md")
# srs-end: INV-SKILL-010

# The grounds register: optional, and the same single-copy arrangement for
# its standard. Its presence in a target is read from the configuration
# file rather than from a setting — what is on disk is the only answer that
# cannot disagree with itself.
GROUNDS_STANDARD = os.path.join(SRS_DIR, "grounds.md")
GROUNDS_CONFIG = os.path.join("grounds", "grounds-config.json")
GROUNDS_TOOLS = ("srs_grounds.py",)
GROUNDS_SKILLS = ("srs-bet",)

# The architecture layer: optional in the same way, its presence read from
# its own configuration file for the same reason (ADR-0023).
ARCH_STANDARD = os.path.join(SRS_DIR, "arch.md")
ARCH_CONFIG = os.path.join("arch", "arch-config.json")
ARCH_TOOLS = ("srs_arch.py",)
ARCH_SKILLS = ("srs-arch",)

# implements: FR-INIT-330, FR-INIT-340
# How the installer tells a file it wrote from one the project wrote.
# Shipped files carry the token; `copy` stamps the running version into
# it on the way out, and `carries_marker` looks for the stamped shape.
# The version is what makes the marker a marker: the bare name turns up
# in ordinary prose — skeleton/AGENTS.md teaches the sentence "the
# project follows the SRS-DD standard" — and a project that wrote that
# in a file of its own would have it read as ours and overwritten. Two
# questions still need it: whether a `srs-dd/` already in a target is
# ours, and whether a file an earlier version wrote elsewhere is ours to
# move.
MARKER_TOKEN = "SRS-DD-VERSION"
# srs-end: FR-INIT-330, FR-INIT-340
# A whole line of the agent guide, so a project that states no width
# gets no bullet rather than an empty one (FR-INIT-220).
WIDTH_TOKEN = "<SRS-DD-WIDTH-LINE>\n"
WIDTH_LINE = ("- **Line width** — this project's code stays inside %d "
              "columns.\n")
# What an annotation becomes on the way out. The line stays a line so
# that a traceback from a target names the same number as the source
# here, and the identifier it named does not travel (CON-SPEC-020).
ANNOTATION_REMOVED = "annotation removed on install"
MARKER = "SRS-DD-" + __version__
RE_MARKER = re.compile(r"SRS-DD-\d+\.\d+\.\d+")

# Tooling copied into every target, refreshed by adopt and upgrade. The
# gate is among it, so that the hook and the pipeline, which may be the
# project's own, call a tool that moves with the framework.
# implements: FR-CI-180
TOOLS = ("srs_check.py", "srs_parse.py", "srs_view.py", "srs_upgrade.py",
         "srs_baseline.py", "srs_dates.py", "srs_gate.py")
# srs-end: FR-CI-180

# Skills shipped to targets. srs-init itself stays framework-only, and so
# does srs-release: a target releases nothing of ours (FR-SKILL-070), and
# this tuple is where that is kept.
# implements: FR-SKILL-060, FR-SKILL-070, FR-SKILL-080, FR-SKILL-100
# implements: FR-SKILL-110
SKILLS = ("srs", "srs-new", "srs-audit", "srs-harvest", "srs-upgrade",
          "srs-baseline", "srs-check", "srs-page")
# srs-end: FR-SKILL-060, FR-SKILL-070, FR-SKILL-080, FR-SKILL-100, FR-SKILL-110

# Service spec files adopt lays down when (and only when) absent.
ADOPT_SERVICE_FILES = ("constitution.md", "00-glossary.md",
                      "91-open-issues.md", "92-baselines.md")

# implements: FR-CI-050
CI_TEMPLATES = {
    "github": (os.path.join("ci", "github-workflow.yml"),
               os.path.join(".github", "workflows", "srs.yml")),
    "gitlab": (os.path.join("ci", "gitlab-ci.yml"), ".gitlab-ci.yml"),
}
# srs-end: FR-CI-050

HOOK_SRC = os.path.join("ci", "pre-commit")
HOOK_DST = os.path.join(".githooks", "pre-commit")
# implements: FR-INIT-300
# The hook managers the report knows: what says the manager is in use,
# the configuration it runs on commit — where the call goes, whether the
# file exists yet or not — and the command that makes git run it at all.
# What to add to each is in GATE_LINES.
HOOK_MANAGERS = (
    ("the pre-commit framework", ".pre-commit-config.yaml", ".pre-commit-config.yaml",
     "pre-commit install"),
    ("husky", ".husky", os.path.join(".husky", "pre-commit"), "npx husky"),
    ("lefthook", "lefthook.yml", "lefthook.yml", "lefthook install"),
    ("lefthook", ".lefthook.yml", ".lefthook.yml", "lefthook install"),
)
GATE_CALL = "python3 srs-dd/tools/srs_gate.py --staged"
GATE_LINES = {
    ".pre-commit-config.yaml": (
        "Add to its repos: list",
        "  - repo: local\n"
        "    hooks:\n"
        "      - id: srs-gate\n"
        "        name: SRS-DD gate\n"
        "        entry: " + GATE_CALL + "\n"
        "        language: system\n"
        "        pass_filenames: false\n"),
    "lefthook.yml": (
        "Add to it",
        "  pre-commit:\n"
        "    commands:\n"
        "      srs-gate:\n"
        "        run: " + GATE_CALL + "\n"),
}
GATE_LINES[".lefthook.yml"] = GATE_LINES["lefthook.yml"]
# srs-end: FR-INIT-300

PLACEHOLDER_REQ = """# Functional requirements — %(area_low)s

<!-- The requirement below is a placeholder demonstrating the format.
     Replace it with your project's first real requirement. -->

### FR-%(area)s-010 — Example: greet the user on first launch

```yaml
status: deferred
verification: D
derives_from: []
depends_on: []
refines: []
conflicts_with: []
code: []
tests: []
exempt: [unlinked]
```

When the application is launched for the first time, the system
**%(verb)s** display a greeting that names the product.

**%(marker)s.** A placeholder showing the shape of a requirement: metadata
above, one bolded modal verb, rationale below. Delete it once you have
real requirements.

The `exempt` line excuses this one requirement from the `unlinked` rule,
which reports a requirement no link touches — true of the first one in any
project, and of almost none after that. Delete the line along with the
placeholder; the rules a project can tune this way are listed in the
Configuration section of `srs-dd/standard.md`.
"""


def parse_args():
    parser = argparse.ArgumentParser(
        description="Install, adopt, or upgrade the SRS-DD skeleton in a "
                    "target repository. Exit codes: 0 ok; 1 checker errors "
                    "or partial completion after adopt's point of no "
                    "return; 2 refused before any change; 3 adopt rolled "
                    "back, target untouched.")
    parser.add_argument("target", help="target repository root")
    parser.add_argument("--mode", choices=("fresh", "adopt"), default=None,
                        help="override fresh/adopt detection (upgrade is "
                             "always chosen when specs/srs-config.json "
                             "exists)")
    parser.add_argument("--defaults", action="store_true",
                        help="non-interactive: answer every remaining "
                             "question with its default")
    parser.add_argument("--dry-run", dest="dry_run", action="store_true",
                        help="write nothing at all; print the same "
                             "created/refreshed/skipped list the real run "
                             "would produce. In adopt mode the existing "
                             "specification is not validated — that needs "
                             "the checker inside the target — but the real "
                             "run validates before touching anything")
    parser.add_argument("--period", choices=("month", "quarter", "year"),
                        default=None,
                        help="the unit the grounds dashboard counts "
                             "unclaimed arrivals in")
    parser.add_argument("--arch", choices=("yes", "no"), default=None,
                        help="install the architecture layer: the parts the "
                             "system is made of and what each one carries")
    parser.add_argument("--grounds", choices=("yes", "no"), default=None,
                        help="install the grounds register: the hypotheses "
                             "the requirements rest on. Declined, nothing "
                             "of it is written")
    parser.add_argument("--ci", choices=("github", "gitlab", "both", "none"),
                        default=None, help="which CI template(s) to install")
    parser.add_argument("--line-width", dest="line_width", default=None,
                        help="the line width the project's code follows; "
                             "found by whoever runs the install, not by "
                             "this tool")
    parser.add_argument("--name", help="project name")
    parser.add_argument("--areas", help="comma-separated requirement areas")
    parser.add_argument("--code-roots", dest="code_roots",
                        help="comma-separated production code roots")
    parser.add_argument("--test-roots", dest="test_roots",
                        help="comma-separated test roots")
    parser.add_argument("--extensions", help="comma-separated source file "
                                             "extensions (with dots)")
    parser.add_argument("--modal-verbs", dest="modal_verbs",
                        help="comma-separated modal verbs of the lexicon")
    parser.add_argument("--negation-words", dest="negation_words",
                        help="comma-separated negation words of the lexicon")
    parser.add_argument("--rationale-markers", dest="rationale_markers",
                        help="comma-separated rationale markers of the lexicon")
    return parser.parse_args()


def split_list(text):
    return [item.strip() for item in text.split(",") if item.strip()]


def ask(prompt, default, batch):
    if batch:
        return default
    sys.stdout.write("%s [%s]: " % (prompt, default))
    sys.stdout.flush()
    answer = sys.stdin.readline()
    if not answer:          # EOF — behave like --defaults from here on
        return default
    answer = answer.strip()
    return answer or default


# implements: FR-INIT-100
def is_inside(path, ancestor):
    """True when path is the ancestor or lies anywhere below it.

    Compares inodes (samefile) while walking up, so neither symlinks nor
    case variations on case-insensitive filesystems bypass the refusal
    (os.path.normcase is a no-op everywhere except Windows).
    """
    probe = os.path.realpath(os.path.abspath(path))
    while True:
        try:
            if os.path.exists(probe) and os.path.samefile(probe, ancestor):
                return True
        except OSError:
            pass
        parent = os.path.dirname(probe)
        if parent == probe:
            return False
        probe = parent
# srs-end: FR-INIT-100


# implements: FR-INIT-190
def outbound(raw, rel):
    """The bytes a file leaves this repository as.

    Every path that puts one of our files into a target goes through
    here — the copier below, and adopt, which writes the checker itself
    because it has to run it before the tooling is installed. A second
    path that transformed nothing is how a target ended up with a file
    the framework never meant to ship.
    """
    # Stamped byte-level, so a file this does not concern is never
    # decoded. Threading the version through six `substitute`
    # dictionaries instead would leave the seventh unstamped and
    # unrecognizable.
    if MARKER_TOKEN.encode("utf-8") in raw:
        raw = raw.replace(MARKER_TOKEN.encode("utf-8"),
                          MARKER.encode("utf-8"))
    # implements: FR-INIT-180
    # The shipped tooling carries this framework's annotations, and they
    # are what CON-SPEC-020 forbids travelling: in a target declaring an
    # area this framework also uses, an `implements:` line naming one of
    # our requirements resolves to *their* requirement under that number.
    # Stripped here rather than in the source, because the two-way check
    # those lines exist for is checked in this repository.
    if rel.endswith(".py") and rel.startswith(SRS_TOOLS + os.sep):
        raw = strip_decisions(strip_annotations(raw.decode("utf-8"))).encode("utf-8")
    # srs-end: FR-INIT-180
    return raw
# srs-end: FR-INIT-190


# implements: FR-INIT-220
def substitutions(name, settings):
    """What a template's placeholders become on the way into a target.

    Both install paths ask this rather than building their own map: fresh
    and adopt each write the agent guide, and a marker filled in by one of
    them and not the other reaches a project as itself.
    """
    out = {}
    if name:
        out[PLACEHOLDER_NAME] = name
    # Always answered, never left standing: the line is filled in where the
    # project stated a width and removed where it did not.
    out[WIDTH_TOKEN] = (WIDTH_LINE % settings["line_width"]
                        if settings.get("line_width") else "")
    return out
# srs-end: FR-INIT-220


# A citation of one of this framework's decisions, as a comment in the
# shipped tooling carries it: the number in brackets after the sentence it
# supports.
RE_DECISION = re.compile(r" ?\(ADR-\d{4}\)")


# implements: FR-INIT-260
def strip_decisions(text):
    """Takes this framework's decision numbers out of the shipped tooling on
    the way into a target, leaving the sentence they supported.

    In a target `ADR-0009` points at nothing, or at the project's own
    decision under that number, which is worse; the reasoning stays in the
    comment and the number stays here, where the decision is. Lines keep
    their place, as they do when an annotation is taken out.
    """
    return RE_DECISION.sub("", text)
# srs-end: FR-INIT-260


# implements: FR-INIT-180
def strip_annotations(text):
    """Takes this framework's traceability annotations out of a file on
    the way into a target, leaving the line where it was.

    Exactly what the checker would have read as a claim, and nothing
    else. A line carrying `srs-ignore` is how the standard marks an
    example rather than a claim, and the two examples in the checker's
    own comments are where a target reads the annotation format at all;
    stripping those would ship a file documenting a syntax it no longer
    shows.

    The line survives so that a traceback from a target names the same
    number as the source here, which is the first thing a bug report is
    read against.
    """
    lines = text.split("\n")
    for index, line in enumerate(lines):
        if "srs-ignore" in line:
            continue
        lines[index] = RE_END.sub(ANNOTATION_REMOVED, RE_ANNOTATION.sub(ANNOTATION_REMOVED, line))
    return "\n".join(lines)
# srs-end: FR-INIT-180


class Installer(object):
    def __init__(self, target, dry_run=False):
        self.target = target
        # Classify exactly as a real run would, then stop short of the
        # write. The lists still fill, so summary() needs no special case.
        self.dry_run = dry_run
        self.created = []
        self.refreshed = []
        self.skipped = []
        self.moved = []
        self.notes = []

    # implements: FR-INIT-330, FR-INIT-340
    def carries_marker(self, dst_rel):
        """Whether the target's copy of this file is one of ours. The
        marker is how the installer tells its own files from a
        project's; a file without it is never overwritten. Any version
        counts — the question is who wrote the file, not when."""
        try:
            with open(os.path.join(self.target, dst_rel), "r",
                      encoding="utf-8", errors="replace") as handle:
                return RE_MARKER.search(handle.read()) is not None
        except OSError:
            return False

    # srs-end: FR-INIT-330, FR-INIT-340

    def put(self, dst_rel, content, tooling, executable=False, starter=False):
        """Writes one file. `content` is str (utf-8) or bytes.

        Three kinds of file, told apart by place and not by marker. What is
        under srs-dd/ is the framework's — `tooling` — and is written on
        every run, created or refreshed. A `starter` is the project's from
        the moment it exists — the hook, the pipelines, the guides,
        .gitattributes — written once and never again. Everything else is
        specification content, the project's, never overwritten.
        """
        dst = os.path.join(self.target, dst_rel)
        exists = os.path.exists(dst)
        if exists:
            # implements: FR-INIT-290, FR-INIT-360
            if starter:
                self.skipped.append("%s (the project's file — never rewritten)"
                                    % dst_rel)
                return
            # srs-end: FR-INIT-290, FR-INIT-360
            # implements: FR-INIT-270
            if tooling:
                self.refreshed.append(dst_rel)
            # srs-end: FR-INIT-270
            else:
                self.skipped.append("%s (specification content, never overwritten)"
                                    % dst_rel)
                return
        else:
            self.created.append(dst_rel)
        if self.dry_run:
            return
        directory = os.path.dirname(dst)
        if directory:
            os.makedirs(directory, exist_ok=True)
        mode = "w" if isinstance(content, str) else "wb"
        kwargs = {"encoding": "utf-8"} if isinstance(content, str) else {}
        with open(dst, mode, **kwargs) as handle:
            handle.write(content)
        if executable:
            os.chmod(dst, 0o755)

    def copy(self, src_rel, dst_rel, tooling, substitute=None,
             executable=False, starter=False):
        src = os.path.join(ROOT, src_rel)
        with open(src, "rb") as handle:
            raw = handle.read()
        # Stamped and stripped here rather than at the call sites: every
        # file the installer writes arrives through this method.
        raw = outbound(raw, dst_rel)
        if substitute:
            text = raw.decode("utf-8")
            for old, new in substitute.items():
                text = text.replace(old, new)
            self.put(dst_rel, text, tooling, executable=executable,
                     starter=starter)
        else:
            self.put(dst_rel, raw, tooling, executable=executable,
                     starter=starter)


    def summary(self):
        lines = []
        for label, items in (("created", self.created),
                             ("refreshed", self.refreshed),
                             ("moved", self.moved),
                             ("skipped", self.skipped)):
            if items:
                lines.append("%s:" % label)
                lines.extend("  %s" % item for item in items)
        return "\n".join(lines) if lines else "nothing to do"

    def print_notes(self):
        for note in self.notes:
            sys.stdout.write("\nNote: %s\n" % note)

    def gitattributes_hint(self):
        """The LF-pinning hint matters only when the target has its own
        .gitattributes we will never touch."""
        for item in self.skipped:
            if item.startswith(".gitattributes (the project's file") \
                    and not calls_pins(self.target):
                sys.stdout.write(
                    "\nHint: your .gitattributes was kept; consider adding\n"
                    "  specs/90-traceability.md text eol=lf\n"
                    "and, for a layer you keep, grounds/90-dashboard.md or\n"
                    "arch/90-map.md the same way, so autocrlf cannot break\n"
                    "the CI freshness gate.\n")


# implements: FR-INIT-010
def scan_target_spec(target):
    """Scans the target's specs/ directory.

    Returns (raw_md_count, strict_requirement_count, areas):
    raw_md_count counts every .md under specs/ with no filtering at all;
    the requirement parse applies the checker's SKIP sets; only strictly
    valid identifiers (framework TYPES, uppercase area, 3 digits) count
    as requirements and contribute areas.
    """
    specs_dir = os.path.join(target, "specs")
    if not os.path.isdir(specs_dir):
        return 0, 0, []

    raw_md = 0
    for current, _dirs, files in os.walk(specs_dir):
        raw_md += sum(1 for name in files if name.endswith(".md"))

    strict = []
    for current, dirs, files in os.walk(specs_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in sorted(files):
            if not name.endswith(".md") or name in SKIP_FILES:
                continue
            full = os.path.join(current, name)
            rel = os.path.relpath(full, target)
            for req in parse_file(full, rel, []):
                if RE_STRICT_ID.match(req.id):
                    strict.append(req)
    areas = sorted({req.id.split("-")[1] for req in strict})
    return raw_md, len(strict), areas
# srs-end: FR-INIT-010


def skeleton_src(rel):
    """Where a specs/-relative payload file lives in the framework clone.

    Everything comes from skeleton/, except the decision template, which
    has one canonical copy under specs/ and would otherwise have to be
    maintained twice.
    """
    if rel == ADR_TEMPLATE:
        return rel
    return os.path.join(SKELETON, rel)


def collect_spec_skeleton():
    """(source, destination) pairs of the skeleton copied into fresh
    targets, destinations being specs/-relative.

    Only skeleton file types travel: a maintainer who generated
    something under skeleton/specs/ in their clone must not have it land
    in every target they install afterwards.
    """
    result = []
    base = os.path.join(ROOT, SKELETON, "specs")
    for current, dirs, files in os.walk(base):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for name in sorted(files):
            if not name.endswith(SKELETON_SUFFIXES):
                continue
            src = os.path.relpath(os.path.join(current, name), ROOT)
            dst = os.path.relpath(os.path.join(current, name),
                                  os.path.join(ROOT, SKELETON))
            result.append((src, dst))
    result.append((ADR_TEMPLATE, ADR_TEMPLATE))
    return sorted(result, key=lambda pair: pair[1])


# implements: FR-INIT-290
def install_ci(installer, choice):
    """A starter pipeline for each service this run chose, written only
    where the project has none: once it exists it is the project's."""
    keys = {"github": ("github",), "gitlab": ("gitlab",),
            "both": ("github", "gitlab"), "none": (), None: ()}[choice]
    for key in keys:
        src, dst = CI_TEMPLATES[key]
        installer.copy(src, dst, tooling=True, starter=True)
# srs-end: FR-INIT-290


# implements: FR-INIT-320
def install_tools(installer, skip=()):
    """The directory's constant part: the tools — the checker and the
    viewer travel together, since the viewer imports the checker's parser
    — and the files every project gets whatever layers it keeps."""
    for name in TOOLS:
        if name in skip:
            continue
        rel = os.path.join(SRS_TOOLS, name)
        installer.copy(rel, rel, tooling=True)
    for rel in DIR_FILES:
        installer.copy(rel, rel, tooling=True)
# srs-end: FR-INIT-320


def install_skills(installer, substitute):
    for skill in SKILLS:
        rel = os.path.join(".claude", "skills", skill, "SKILL.md")
        if os.path.exists(os.path.join(ROOT, rel)):
            installer.copy(rel, rel, tooling=True, substitute=substitute)


# implements: FR-GND-290
def has_grounds(target):
    """Whether this project carries the register."""
    return os.path.exists(os.path.join(target, GROUNDS_CONFIG))
# srs-end: FR-GND-290


def collect_grounds_skeleton():
    """(source, destination) pairs of the register skeleton.

    The standard comes from grounds/ for the reason srs-dd/standard.md comes
    from specs/: one canonical copy, kept in the place it describes.
    """
    result = []
    base = os.path.join(ROOT, SKELETON, "grounds")
    for name in sorted(os.listdir(base)):
        if name.endswith(SKELETON_SUFFIXES):
            result.append((os.path.join(SKELETON, "grounds", name),
                           os.path.join("grounds", name)))
    # The configuration is written rather than copied: it carries a choice.
    result = [pair for pair in result if pair[1] != GROUNDS_CONFIG]
    result.append((GROUNDS_STANDARD, GROUNDS_STANDARD))
    return sorted(result, key=lambda pair: pair[1])


def grounds_config_json(period):
    """The register's configuration, with the one answer the install takes."""
    return ('{\n'
            '  "rules": {},\n'
            '  "period": "%s"\n'
            '}\n' % period)


# implements: FR-GND-280, FR-GND-300, FR-GND-320
def install_grounds(installer, substitute=None, period="quarter"):
    """The register, its checker and its procedure — all or none of them.

    Declined, this writes nothing at all: a target that said no is
    byte-for-byte a target that was never asked, which is what makes the
    choice cheap to make and cheap to reverse.
    """
    installer.put(GROUNDS_CONFIG, grounds_config_json(period), tooling=False)
    for src, dst in collect_grounds_skeleton():
        installer.copy(src, dst, tooling=dst == GROUNDS_STANDARD,
                       substitute=substitute)
    for name in GROUNDS_TOOLS:
        rel = os.path.join(SRS_TOOLS, name)
        installer.copy(rel, rel, tooling=True)
    for skill in GROUNDS_SKILLS:
        rel = os.path.join(".claude", "skills", skill, "SKILL.md")
        if os.path.exists(os.path.join(ROOT, rel)):
            installer.copy(rel, rel, tooling=True, substitute=substitute)
# srs-end: FR-GND-280, FR-GND-300, FR-GND-320


# implements: FR-INIT-170
def undated_hint(target):
    """Says that an undated specification can be dated, and runs nothing.

    The dating command exists for specifications written before the field
    did, which is every specification a project already has, and nobody
    looks for a tool they have not heard of. Said and not done: nothing
    else here writes a requirement block unasked, and a project that wants
    no dates at all is not a project in error.
    """
    specs_dir = os.path.join(target, "specs")
    if not os.path.isdir(specs_dir):
        return
    seen, undated = 0, 0
    for current, dirs, files in os.walk(specs_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in sorted(files):
            if not name.endswith(".md") or name in SKIP_FILES:
                continue
            full = os.path.join(current, name)
            for req in parse_file(full, os.path.relpath(full, target), []):
                if not RE_STRICT_ID.match(req.id):
                    continue
                seen += 1
                if not req.meta.get("created"):
                    undated += 1
    if not undated:
        return
    sys.stdout.write(
        "\n%d of %d requirements carry no `created` date. One command "
        "writes\nthe date each first appeared, read from this repository's "
        "own history:\n  python3 srs-dd/tools/srs_dates.py --dry-run   to see what "
        "it would write\n  python3 srs-dd/tools/srs_dates.py             to write "
        "it\n" % (undated, seen))
# srs-end: FR-INIT-170


# implements: FR-ARCH-130
def has_arch(target):
    """Whether this project carries the architecture layer."""
    return os.path.exists(os.path.join(target, ARCH_CONFIG))
# srs-end: FR-ARCH-130


def collect_arch_skeleton():
    """(source, destination) pairs of the layer skeleton.

    The standard comes from arch/ for the reason srs-dd/standard.md comes from
    specs/: one canonical copy, kept in the place it describes.
    """
    result = []
    base = os.path.join(ROOT, SKELETON, "arch")
    if os.path.isdir(base):
        for name in sorted(os.listdir(base)):
            if name.endswith(SKELETON_SUFFIXES):
                result.append((os.path.join(SKELETON, "arch", name),
                               os.path.join("arch", name)))
    result.append((ARCH_STANDARD, ARCH_STANDARD))
    return sorted(result, key=lambda pair: pair[1])


def arch_config_json():
    """The layer's configuration. Every rule at its default; a project
    lowers what it wants lowered while it is still describing its parts."""
    return '{\n  "rules": {}\n}\n'


# implements: FR-ARCH-120, FR-ARCH-140, FR-ARCH-150
def install_arch(installer, substitute=None):
    """The layer, its checker and its procedure — all or none of them.

    Declined, this writes nothing at all: a target that said no is
    byte-for-byte a target that was never asked.
    """
    installer.put(ARCH_CONFIG, arch_config_json(), tooling=False)
    for src, dst in collect_arch_skeleton():
        installer.copy(src, dst, tooling=dst == ARCH_STANDARD,
                       substitute=substitute)
    for name in ARCH_TOOLS:
        rel = os.path.join(SRS_TOOLS, name)
        installer.copy(rel, rel, tooling=True)
    for skill in ARCH_SKILLS:
        rel = os.path.join(".claude", "skills", skill, "SKILL.md")
        if os.path.exists(os.path.join(ROOT, rel)):
            installer.copy(rel, rel, tooling=True, substitute=substitute)
# srs-end: FR-ARCH-120, FR-ARCH-140, FR-ARCH-150


# implements: FR-ARCH-140
def run_target_arch(target):
    """The target's own architecture checker, on what was just installed.

    It writes the map, which a gate compares against a fresh run — a target
    whose first commit has no map would fail that gate before anybody had
    written a single element. Not `--strict`, for the reason the grounds
    checker is not run strictly either: a project that has just installed
    the layer owns no parts yet, and every carrier is unclaimed until it
    does.
    """
    checker = os.path.join(target, SRS_TOOLS, "srs_arch.py")
    if not os.path.exists(checker):
        return 0
    sys.stdout.write("\nRunning the architecture checker in the target:\n")
    sys.stdout.flush()
    return subprocess.call([sys.executable, checker])
# srs-end: FR-ARCH-140


# implements: FR-GND-300
def run_target_grounds(target):
    """The target's own grounds checker, on what was just installed.

    It writes the dashboard, which a gate compares against a fresh run —
    a target whose first commit has no dashboard would fail that gate
    before anybody had written a single record.
    """
    checker = os.path.join(target, SRS_TOOLS, "srs_grounds.py")
    if not os.path.exists(checker):
        return 0
    sys.stdout.write("\nRunning the grounds checker in the target:\n")
    sys.stdout.flush()
    # Not `--strict`, for the reason the specification checker is not run
    # strictly either: an expired hypothesis is the most ordinary state a
    # register can be in and the thing this layer exists to surface, and an
    # install that reports failure over one is an install nobody believes.
    # The exit code the installer publishes is for errors.
    return subprocess.call([sys.executable, checker])
# srs-end: FR-GND-300


def describe_hooks(target):
    """What the target already runs on commit.

    `core.hooksPath` decides which directory git looks in, so an
    existing hook may live anywhere; pointing that setting at
    .githooks would silently stop whatever is there today.
    """
    info = {"active": "", "framework": "", "config": "", "install": ""}
    try:
        # One question to git rather than two guesses: --git-path
        # resolves core.hooksPath and the shared hooks directory of a
        # worktree (where .git is a file, not a directory) in one go.
        out = subprocess.check_output(
            ["git", "-C", target, "rev-parse", "--git-path", "hooks"],
            stderr=subprocess.DEVNULL)
    except (OSError, subprocess.CalledProcessError):
        return info                 # no git, no repository, no hooks
    # Relative to the target, since git ran there; join keeps an
    # absolute answer absolute.
    hooks_dir = out.decode("utf-8", "replace").strip()
    # lexists: a dangling symlink at that path is still something git
    # will try to run.
    if os.path.lexists(os.path.join(target, hooks_dir, "pre-commit")):
        info["active"] = os.path.join(hooks_dir, "pre-commit")
    # A hook manager's own file is a shim that calls its configuration,
    # so the configuration is what says whether the gate runs (FR-INIT-300).
    for name, presence, config, install in HOOK_MANAGERS:
        if os.path.exists(os.path.join(target, presence)):
            info["framework"] = "%s (%s)" % (name, config)
            info["config"] = config
            info["install"] = install
            break
    return info


def runs_starter_path(target, active):
    """Whether the hook git runs is the one at .githooks/pre-commit:
    core.hooksPath may say ./.githooks, .githooks/, or an absolute path
    to the very same directory."""
    return bool(active) and (
        os.path.realpath(os.path.join(target, active))
        == os.path.realpath(os.path.join(target, HOOK_DST)))


# implements: FR-INIT-080, FR-INIT-290
def install_hook(installer, hooks):
    """The starter hook, written only where nothing runs on commit and
    nothing is at .githooks/pre-commit. A project that already runs a
    hook, or a hook manager, keeps it and is told what to call from it
    (FR-INIT-300); nothing is laid beside it, because the gate is a tool
    and what the hook needs is one line."""
    if hooks["framework"]:
        return
    if hooks["active"] and not runs_starter_path(installer.target,
                                                  hooks["active"]):
        return
    installer.copy(HOOK_SRC, HOOK_DST, tooling=True, starter=True,
                   executable=True)
# srs-end: FR-INIT-080, FR-INIT-290


def calls_gate(target, rel):
    """Whether a file names the gate tool at all: the one line that a hook,
    a manager's configuration or a pipeline holds of ours."""
    try:
        with open(os.path.join(target, rel), "r", encoding="utf-8",
                  errors="replace") as handle:
            return "srs-dd/tools/srs_gate.py" in handle.read()
    except OSError:
        return False


# implements: FR-INIT-080, FR-INIT-300
def report_hook(installer, hooks):
    """Whether git runs a pre-commit hook here, whether that hook — or
    the manager's configuration it is a shim for — calls the gate, and
    what to add where it does not. Said after every install and upgrade,
    because both rest on a line the project keeps."""
    target = installer.target
    active = hooks["active"]
    if runs_starter_path(target, active):
        # The starter is what git runs; a manager's configuration lying
        # beside it runs nothing on commit and is not what is read.
        active = HOOK_DST
        hooks = dict(hooks, framework="", config="")
    managed = ", managed by %s" % hooks["framework"] if hooks["framework"] else ""
    read = hooks["config"] or active
    lines = ["\nPre-commit gate:"]
    if active:
        lines.append("  git already runs %s on commit%s." % (active, managed))
    elif hooks["framework"]:
        lines.append("  git runs no pre-commit hook: %s is configured but not "
                     "installed here — run: %s" % (hooks["framework"], hooks["install"]))
    else:
        lines.append("  git runs no pre-commit hook.")
        if os.path.exists(os.path.join(target, HOOK_DST)):
            lines.append("  Activate %s (one-time, in this repository):\n"
                         "    git config core.hooksPath .githooks" % HOOK_DST)
    if read:
        if calls_gate(target, read):
            lines.append("  %s calls srs-dd/tools/srs_gate.py." % read)
        elif read in GATE_LINES:
            intro, block = GATE_LINES[read]
            lines.append("  %s does not call srs-dd/tools/srs_gate.py. %s:\n%s"
                         % (read, intro, block.rstrip("\n")))
        else:
            lines.append("  %s does not call srs-dd/tools/srs_gate.py. Add to it:\n"
                         "    %s" % (read, GATE_CALL))
    if active and active != HOOK_DST and not hooks["framework"]:
        lines.append("  Pointing core.hooksPath at .githooks would disable it, "
                     "so no hook was written.")
    sys.stdout.write("\n".join(lines) + "\n")
# srs-end: FR-INIT-080, FR-INIT-300


# implements: FR-INIT-310
def report_pipelines(target):
    """Whether any GitHub workflow or the GitLab file calls the gate; the
    step to add where none does. Any workflow will do — a project's other
    workflows have no reason to run it, and naming each would be noise."""
    workflows = sorted(
        os.path.join(".github", "workflows", name)
        for name in (os.listdir(os.path.join(target, ".github", "workflows"))
                     if os.path.isdir(os.path.join(target, ".github", "workflows")) else ())
        if name.endswith((".yml", ".yaml")))
    gitlab = ".gitlab-ci.yml" if os.path.exists(os.path.join(target, ".gitlab-ci.yml")) else ""
    lines = ["\nPipeline gate:"]
    if not workflows and not gitlab:
        lines.append("  no pipeline for GitHub or GitLab was found; one on another "
                     "service is yours to read for a step that runs: python3 srs-dd/tools/srs_gate.py")
    if workflows:
        calling = [w for w in workflows if calls_gate(target, w)]
        if calling:
            lines.append("  %s calls srs-dd/tools/srs_gate.py." % calling[0])
        else:
            lines.append("  no workflow under .github/workflows/ calls srs-dd/tools/srs_gate.py. "
                         "Add a step to one of them, after checkout and setup-python:\n"
                         "    - run: python3 srs-dd/tools/srs_gate.py")
    if gitlab:
        if calls_gate(target, gitlab):
            lines.append("  %s calls srs-dd/tools/srs_gate.py." % gitlab)
        else:
            lines.append("  %s does not call srs-dd/tools/srs_gate.py. Add a job:\n"
                         "    srs-gate:\n      image: python:3.12\n      script:\n"
                         "        - python3 srs-dd/tools/srs_gate.py" % gitlab)
    sys.stdout.write("\n".join(lines) + "\n")
# srs-end: FR-INIT-310


def report_wiring(installer, target):
    report_hook(installer, describe_hooks(target))
    report_pipelines(target)


# implements: FR-INIT-360
def install_agent_docs(installer, substitute):
    """The target's agent guides come from skeleton/ — the ones in this
    repository's root describe the framework repository itself — and are
    the project's from the moment they exist: written where absent, never
    rewritten. What the framework keeps current in them is the region
    (FR-INIT-370)."""
    for doc in ("CLAUDE.md", "AGENTS.md"):
        src = os.path.join(SKELETON, doc)
        if os.path.exists(os.path.join(ROOT, src)):
            installer.copy(src, doc, tooling=False, substitute=substitute,
                           starter=True)
    refresh_guide_region(installer)
# srs-end: FR-INIT-360


# implements: FR-INIT-370, FR-SKILL-440
def refresh_guide_region(installer):
    """Rewrites the framework's region of the target's AGENTS.md with the
    current guide, and nothing outside it. A guide without the region is
    reported, with what to add: the rules cannot reach an agent that reads
    the file as plain text any other way."""
    path = os.path.join(installer.target, "AGENTS.md")
    try:
        with open(path, "r", encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return
    begin, end = text.find(REGION_BEGIN), text.find(REGION_END)
    if begin < 0 or end < 0 or end < begin:
        installer.notes.append(
            "AGENTS.md carries no region %s … %s, so the framework's rules "
            "in it are whatever it holds today. Add the two lines where the "
            "rules should stand; the next run fills the region from %s."
            % (REGION_BEGIN, REGION_END, GUIDE_SOURCE))
        return
    with open(os.path.join(ROOT, GUIDE_SOURCE), "r", encoding="utf-8") as handle:
        guide = handle.read().strip("\n")
    fresh = text[:begin + len(REGION_BEGIN)] + "\n" + guide + "\n" + text[end:]
    if fresh == text:
        return
    installer.refreshed.append("AGENTS.md (the region %s … %s)"
                               % (REGION_BEGIN, REGION_END))
    if installer.dry_run:
        return
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(fresh)
# srs-end: FR-INIT-370, FR-SKILL-440


def calls_pins(target):
    """Whether the target's .gitattributes pins the matrix to LF."""
    try:
        with open(os.path.join(target, ".gitattributes"), "r",
                  encoding="utf-8", errors="replace") as handle:
            return "specs/90-traceability.md" in handle.read()
    except OSError:
        return False


# implements: FR-INIT-070
def dry_run_notice(extra=""):
    sys.stdout.write("\nDry run: nothing was written.%s Re-run without "
                     "--dry-run to apply.\n" % (" " + extra if extra else ""))
# srs-end: FR-INIT-070


def run_target_checker(target):
    checker = os.path.join(target, SRS_TOOLS, "srs_check.py")
    sys.stdout.write("\nRunning the checker in the target:\n")
    sys.stdout.flush()      # keep parent/child output ordered when piped
    return subprocess.call([sys.executable, checker])


# implements: FR-INIT-200
def read_target_config(target):
    """The target's own configuration, for the answers its install took.

    Unreadable is not a failure here: everything taken from it has a
    fallback, and the checker runs at the end of this same command and
    will say so properly.
    """
    path = os.path.join(target, "specs", "srs-config.json")
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError):
        return {}
    return data if isinstance(data, dict) else {}
# srs-end: FR-INIT-200


# implements: FR-INIT-200
def guide_answers(target):
    """(name, settings) for filling the agent guides on an upgrade.

    Both values come out of a file a maintainer edits by hand, and both
    are about to be interpolated into text — a name that is not a string
    and a width that is not a number each end in a traceback out of
    `str.replace` and `%d`. Neither is worth refusing an upgrade over:
    the rest of it is fine and each has an honest fallback, so the run
    says what it disbelieved and carries on.
    """
    cfg = read_target_config(target)
    name = cfg.get("project_name")
    if name is not None and not isinstance(name, str):
        sys.stdout.write("Note: `project_name` in specs/srs-config.json is "
                         "not a string; the directory name is used for the "
                         "agent guides instead.\n")
        name = None
    width = cfg.get("line_width")
    if width is not None and (isinstance(width, bool)
                              or not isinstance(width, int)):
        sys.stdout.write("Note: `line_width` in specs/srs-config.json is not "
                         "a whole number; the agent guides state no width.\n")
        width = None
    # A guide titled after the directory beats one nothing refreshes at all,
    # which is what a project installed before the name was recorded gets.
    return (name or os.path.basename(os.path.abspath(target)),
            {"line_width": width})
# srs-end: FR-INIT-200


def read_target_version(target):
    """The framework version a target is on, read from its own tooling.

    Two files, in order: the parser is where the number lives from 0.15.0
    on, and the checker is where it lived before. A project upgrading from
    0.14.0 or earlier has it only in the second, and reporting it as
    unversioned would drop the version transition and the upgrade notes —
    the two things an upgrade exists to show.
    """
    for home in (SRS_TOOLS, "tools"):
        for name in ("srs_parse.py", "srs_check.py"):
            path = os.path.join(target, home, name)
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as handle:
                    text = handle.read()
            except OSError:
                continue
            match = RE_VERSION.search(text)
            if match:
                return match.group(1)
    return None


def version_tuple(text):
    parts = tuple(int(p) for p in text.split("."))
    return parts + (0,) * (3 - len(parts))


# implements: FR-INIT-110
def print_version_transition(old):
    """Returns True when upgrade notes for all versions should print."""
    if old is None:
        sys.stdout.write("checker (unversioned) → %s\n" % __version__)
        return True
    try:
        old_t, new_t = version_tuple(old), version_tuple(__version__)
    except ValueError:
        sys.stdout.write("checker %s → %s (versions not comparable)\n"
                         % (old, __version__))
        return True
    if old_t == new_t:
        sys.stdout.write("checker already at %s\n" % __version__)
    elif old_t > new_t:
        sys.stdout.write("warning: downgrading checker %s → %s\n"
                         % (old, __version__))
    else:
        sys.stdout.write("checker %s → %s\n" % (old, __version__))
    return False
# srs-end: FR-INIT-110


def changelog_sections(headings):
    """{version: {heading: [lines]}} for the `### <heading>` blocks named.

    The format contract is documented in CHANGELOG.md's header. Missing
    or unparseable CHANGELOG — an empty result, and the caller says
    nothing.
    """
    path = os.path.join(ROOT, "CHANGELOG.md")
    try:
        with open(path, "r", encoding="utf-8") as handle:
            lines = handle.read().split("\n")
    except OSError:
        return {}
    re_section = re.compile(r"^## \[(\d+\.\d+\.\d+)\]")
    wanted = set("### %s" % h for h in headings)
    found = {}
    version = None
    heading = None
    for line in lines:
        match = re_section.match(line)
        if match:
            version, heading = match.group(1), None
            continue
        if line.startswith("### "):
            heading = line.strip() if (version is not None
                                       and line.strip() in wanted) else None
            continue
        if line.startswith("## "):
            heading = None
            continue
        if heading and line.strip():
            found.setdefault(version, {}).setdefault(
                heading[4:], []).append(line)
    return found


def crossed_versions(collected, old_version, show_all):
    """The versions an upgrade steps over, oldest first, and a caveat."""
    if show_all:
        return sorted(collected, key=version_tuple), \
            " (target version unknown — showing all)"
    try:
        old_t = version_tuple(old_version)
    except ValueError:
        return [], ""
    return sorted((v for v in collected if version_tuple(v) > old_t),
                  key=version_tuple), ""


def one_line(bullet, width=76):
    """A bullet reduced to its first sentence, or to one cut line.

    Whole entries would be a wall of text across several versions; a raw
    first line ends mid-sentence, which reads worse than a cut one.
    """
    text = " ".join(part.strip() for part in bullet).strip()
    stop = text.find(". ")
    if 0 < stop <= width:
        return text[:stop + 1]
    if len(text) <= width:
        return text
    cut = text.rfind(" ", 0, width)
    return text[:cut if cut > 0 else width].rstrip(",;:") + "…"


def bullets(lines):
    """Groups the lines of a section into its `- ` entries."""
    entries = []
    for line in lines:
        if line.lstrip().startswith("- ") and not line.startswith("  "):
            entries.append([line.lstrip()[2:]])
        elif entries:
            entries[-1].append(line)
    return entries


# implements: FR-INIT-160
def print_whats_new(old_version, show_all):
    """What the crossed versions added and changed, one line per entry."""
    collected = changelog_sections(("Added", "Changed"))
    if not collected:
        return
    relevant, caveat = crossed_versions(collected, old_version, show_all)
    if not relevant:
        return
    sys.stdout.write("\nWhat is new%s:\n" % caveat)
    for version in relevant:
        sys.stdout.write("[%s]\n" % version)
        for heading in ("Added", "Changed"):
            for bullet in bullets(collected[version].get(heading, [])):
                sys.stdout.write("  %s %s\n"
                                 % ("+" if heading == "Added" else "~",
                                    one_line(bullet)))
    sys.stdout.write("  Full text: CHANGELOG.md in the framework "
                     "repository.\n")
# srs-end: FR-INIT-160


# implements: FR-INIT-110
def print_upgrade_notes(old_version, show_all):
    """Prints CHANGELOG 'Upgrade notes' blocks newer than old_version."""
    collected = changelog_sections(("Upgrade notes",))
    if not collected:
        return
    relevant, caveat = crossed_versions(collected, old_version, show_all)
    if not relevant:
        return
    sys.stdout.write("\nUpgrade notes%s:\n" % caveat)
    for version in relevant:
        sys.stdout.write("[%s]\n" % version)
        for line in collected[version].get("Upgrade notes", []):
            sys.stdout.write("%s\n" % line)
    sys.stdout.write("\n")
# srs-end: FR-INIT-110


# implements: FR-INIT-090
def collect_settings(args, batch, area_default):
    """Prompts/flags for everything except the project name."""
    areas = split_list(args.areas) if args.areas else split_list(
        ask("Requirement areas (comma-separated)",
            ", ".join(area_default), batch))
    for area in areas:
        if not RE_AREA.match(area):
            sys.stderr.write(
                "Invalid area %r: uppercase letters and digits, beginning with "
                "a letter, its words joined by single underscores — it is "
                "interpolated into the identifier grammar.\n" % area)
            return None
        # implements: FR-INIT-350
        # An area grouped into its folder is read from specs/<area>/, and a
        # folder of that name is one the checker skips: its requirements
        # would vanish without a word.
        if area.lower() in SKIP_DIRS:
            sys.stderr.write(
                "Invalid area %r: its folder, specs/%s/, is one the checker "
                "skips, so the area grouped there would vanish.\n"
                % (area, area.lower()))
            return None
        # srs-end: FR-INIT-350
    if not areas:
        sys.stderr.write("At least one area is required.\n")
        return None

    def listed(flag_value, prompt, default):
        if flag_value:
            return split_list(flag_value)
        return split_list(ask(prompt, ", ".join(default), batch))

    settings = {
        "areas": areas,
        "code_roots": listed(args.code_roots, "Production code roots",
                             DEFAULTS["code_roots"]),
        "test_roots": listed(args.test_roots, "Test roots",
                             DEFAULTS["test_roots"]),
        "code_extensions": listed(args.extensions, "Source file extensions",
                                  DEFAULTS["code_extensions"]),
        "modal_verbs": listed(args.modal_verbs, "Lexicon: modal verbs",
                              DEFAULTS["modal_verbs"]),
        "negation_words": listed(args.negation_words,
                                 "Lexicon: negation words",
                                 DEFAULTS["negation_words"]),
        "rationale_markers": listed(args.rationale_markers,
                                    "Lexicon: rationale markers",
                                    DEFAULTS["rationale_markers"]),
    }
    ci_choice = args.ci or ("none" if batch else ask(
        "CI template (github/gitlab/both/none)", "none", batch))
    if ci_choice not in ("github", "gitlab", "both", "none"):
        sys.stderr.write("Unknown CI choice %r.\n" % ci_choice)
        return None
    settings["ci"] = ci_choice
    # implements: FR-GND-280
    grounds = args.grounds or ("no" if batch else ask(
        "Keep a grounds register — the hypotheses the requirements rest "
        "on? (yes/no)", "no", batch))
    if grounds not in ("yes", "no"):
        sys.stderr.write("Unknown answer %r for the grounds register.\n"
                         % grounds)
        return None
    settings["grounds"] = grounds == "yes"
    # srs-end: FR-GND-280
    # implements: FR-ARCH-120
    arch = args.arch or ("no" if batch else ask(
        "Keep an architecture layer — the parts the system is made of? "
        "(yes/no)", "no", batch))
    if arch not in ("yes", "no"):
        sys.stderr.write("Unknown answer %r for the architecture layer.\n"
                         % arch)
        return None
    settings["arch"] = arch == "yes"
    # srs-end: FR-ARCH-120
    # implements: FR-GND-480
    # What counts as "lately" is the project's rhythm, and the dashboard
    # counts arrivals in it. Asked only where the register is wanted.
    period = args.period
    if settings["grounds"] and not period:
        period = "quarter" if batch else ask(
            "Count unclaimed arrivals by (month/quarter/year)", "quarter",
            batch)
    if period and period not in ("month", "quarter", "year"):
        sys.stderr.write("Unknown period %r.\n" % period)
        return None
    if period and not settings["grounds"]:
        # The setting belongs to a register, and there is not going to be
        # one. Said rather than dropped: a flag that does nothing and says
        # nothing is a flag somebody believes worked.
        sys.stdout.write(
            "Note: --period sets the grounds dashboard's calendar unit and "
            "this install takes no register, so it has nothing to set.\n")
    settings["period"] = period or "quarter"
    # srs-end: FR-GND-480

    # implements: FR-INIT-210
    # Taken as given. Which file a project states this in differs by
    # toolchain, and reading them is the install procedure's job
    # (FR-SKILL-190) — a heuristic here would be wrong quietly.
    width = args.line_width
    if width is not None:
        try:
            width = int(width)
        except ValueError:
            width = 0
        if width < 1:
            sys.stderr.write("--line-width takes a positive number of "
                             "columns.\n")
            return None
    settings["line_width"] = width
    return settings
    # srs-end: FR-INIT-210
# srs-end: FR-INIT-090


# implements: FR-INIT-140
def framework_url():
    """The address a target upgrades from: this clone's own remote.

    A fork or a mirror must send its targets back to itself, not to the
    address compiled into the tooling. SSH remotes are rewritten to HTTPS
    — the target that upgrades is somebody else's machine, without this
    maintainer's keys.
    """
    try:
        remotes = subprocess.check_output(
            ["git", "-C", ROOT, "remote"],
            stderr=subprocess.DEVNULL).decode("utf-8").split()
        # `origin` when it exists: a clone with several remotes usually has
        # the one it came from under that name, and the alphabetically
        # first is nobody's idea of the canonical source.
        chosen = "origin" if "origin" in remotes else remotes[0]
        url = subprocess.check_output(
            ["git", "-C", ROOT, "remote", "get-url", chosen],
            stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except (OSError, subprocess.CalledProcessError, IndexError):
        return DEFAULT_FRAMEWORK_URL
    match = re.match(r"^(?:ssh://)?git@([^:/]+)[:/](.+)$", url)
    if match:
        url = "https://%s/%s" % (match.group(1), match.group(2))
    return url or DEFAULT_FRAMEWORK_URL
# srs-end: FR-INIT-140


# implements: FR-INIT-140, FR-INIT-200, FR-CHK-210
def config_json(settings, adopting=False, name=None):
    config = dict((key, settings[key]) for key in
                  ("areas", "code_roots", "test_roots", "code_extensions",
                   "modal_verbs", "negation_words", "rationale_markers"))
    config["framework_url"] = settings.get("framework_url") or framework_url()
    # The agent guides are filled in from this rather than copied, and an
    # upgrade does not ask again (FR-INIT-200). Absent where adoption found
    # the guides already written and never asked for a name.
    if name:
        config["project_name"] = name
    # Absent where the project states none: a width invented here would be
    # this framework formatting somebody else's code (FR-INIT-210).
    if settings.get("line_width"):
        config["line_width"] = settings["line_width"]
    if adopting:
        # A project that arrives with code already written has files under
        # its roots that no requirement names yet, and every one of them
        # would be reported on the first run. That is a wall rather than a
        # queue, so adoption starts with the rule silenced; switching it on
        # is what finishing the adoption means (ADR-0014).
        config["rules"] = {"annotation-absent": "off"}
    return json.dumps(config, ensure_ascii=False, indent=2) + "\n"
# srs-end: FR-INIT-140, FR-INIT-200, FR-CHK-210


# implements: FR-INIT-020, FR-INIT-150
def run_fresh(args, target, batch):
    installer = Installer(target, dry_run=args.dry_run)
    name = args.name or ask("Project name", os.path.basename(target) or
                            "My Project", batch)
    settings = collect_settings(args, batch, DEFAULTS["areas"])
    if settings is None:
        return 2
    substitute = substitutions(name, settings)

    sys.stdout.write("\nInstalling into %s\n\n" % target)

    for src, dst in collect_spec_skeleton():
        installer.copy(src, dst, tooling=False, substitute=substitute)

    installer.put(os.path.join("specs", "srs-config.json"),
                  config_json(settings, name=name), tooling=False)

    area = settings["areas"][0]
    placeholder = PLACEHOLDER_REQ % {
        "area": area,
        "area_low": area.lower(),
        "verb": settings["modal_verbs"][0],
        "marker": settings["rationale_markers"][0],
    }
    installer.put(os.path.join("specs", "10-fr-%s.md" % area.lower()),
                  placeholder, tooling=False)

    install_tools(installer)
    if settings["grounds"]:
        install_grounds(installer, substitute, settings["period"])
    if settings["arch"]:
        install_arch(installer, substitute)
    installer.copy(".gitattributes", ".gitattributes", tooling=False,
                   starter=True)
    install_skills(installer, substitute)
    install_agent_docs(installer, substitute)
    install_ci(installer, settings["ci"])
    install_hook(installer, describe_hooks(target))

    sys.stdout.write(installer.summary() + "\n")
    installer.print_notes()
    if args.dry_run:
        dry_run_notice()
        return 0
    installer.gitattributes_hint()
    sys.stdout.write("\nInstalled with srs_init (framework %s).\n"
                     % __version__)
    result = run_target_checker(target)
    if result == 0:
        undated_hint(target)
    if result == 0 and settings["grounds"]:
        result = run_target_grounds(target)
    if result == 0 and settings["arch"]:
        result = run_target_arch(target)
    if result == 0:
        sys.stdout.write(
            "\nFirst steps:\n"
            "  1. Point your coding agent at AGENTS.md — every agent "
            "reads it. The\n"
            "     procedures it follows are in .claude/skills/:\n"
            "       srs          find the requirement a change belongs "
            "to, then code\n"
            "       srs-new      author one requirement through a "
            "dialog\n"
            "       srs-audit    specification against code, and whether "
            "tests prove it\n"
            "       srs-harvest  mine requirements out of code that has "
            "none yet\n"
            "       srs-upgrade  pick up a new framework version\n"
            "       srs-baseline freeze the specification at a "
            "milestone\n"
            "       srs-check    name and run the checks a change calls "
            "for\n"
            "       srs-page     read the specification as a page\n"
            "  2. Replace the placeholder requirement in "
            "specs/10-fr-%s.md; the\n"
            "     rules are in srs-dd/standard.md.\n"
            "  3. python3 srs-dd/tools/srs_check.py — validates the "
            "specification and\n"
            "     regenerates the traceability matrix.\n"
            "  4. python3 srs-dd/tools/srs_view.py --html — the same thing as "
            "a page.\n"
            "  For a new framework version: python3 "
            "srs-dd/tools/srs_upgrade.py\n"
            % area.lower())
        report_wiring(installer, target)
    return result
# srs-end: FR-INIT-020, FR-INIT-150


# implements: FR-INIT-040
def install_adopt_files(installer, settings, substitute, target,
                        tools_skip=()):
    """Everything adopt lays down beside the config and the checker.

    Shared by the real run, which reaches it past its point of no
    return, and by --dry-run, which never reaches that point at all. A
    README the project keeps under specs/ is its own and stays: the
    standard lives in srs-dd/ and the checker never reads a README.
    """
    for service in ADOPT_SERVICE_FILES:
        rel = os.path.join("specs", service)
        if not os.path.exists(os.path.join(target, rel)):
            installer.copy(skeleton_src(rel), rel, tooling=False,
                           substitute=substitute)
    if os.path.join("specs", "constitution.md") in installer.created \
            and settings["modal_verbs"] != DEFAULTS["modal_verbs"]:
        sys.stdout.write(
            "Note: the installed specs/constitution.md is in English "
            "(framework language); adapt or translate it as you see "
            "fit.\n")

    install_tools(installer, skip=tools_skip)
    if settings["grounds"]:
        install_grounds(installer, substitute, settings["period"])
    if settings["arch"]:
        install_arch(installer, substitute)
    install_skills(installer, substitute)
    installer.copy(".gitattributes", ".gitattributes", tooling=False,
                   starter=True)
    install_agent_docs(installer, substitute)
    install_ci(installer, settings["ci"])
    install_hook(installer, describe_hooks(target))
# srs-end: FR-INIT-040


# implements: FR-INIT-030, FR-INIT-050
def run_adopt(args, target, batch, found_areas):
    installer = Installer(target, dry_run=args.dry_run)
    settings = collect_settings(args, batch, found_areas or DEFAULTS["areas"])
    if settings is None:
        return 2
    missing_areas = sorted(set(found_areas) - set(settings["areas"]))
    if missing_areas:
        sys.stdout.write(
            "warning: areas discovered in the spec but not in your list: "
            "%s — their requirements will fail identifier validation.\n"
            % ", ".join(missing_areas))

    docs_absent = [doc for doc in ("CLAUDE.md", "AGENTS.md")
                   if not os.path.exists(os.path.join(target, doc))]
    name = None
    if docs_absent:
        name = args.name or ask("Project name",
                                os.path.basename(target) or "My Project",
                                batch)
    substitute = substitutions(name, settings)

    specs_dir = os.path.join(target, "specs")
    tools_dir = os.path.join(target, SRS_TOOLS)
    config_path = os.path.join(specs_dir, "srs-config.json")
    temp_path = os.path.join(tools_dir, TEMP_CHECKER)
    checker_dst = os.path.join(tools_dir, "srs_check.py")

    if args.dry_run:
        # The transactional block below is skipped whole: validating the
        # existing spec needs the checker running inside the target, and
        # --dry-run promises not to write. The real run validates before
        # touching anything, so nothing is lost by deferring it.
        installer.created.append(os.path.join("specs", "srs-config.json"))
        install_adopt_files(installer, settings, substitute, target)
        sys.stdout.write("\n" + installer.summary() + "\n")
        installer.print_notes()
        dry_run_notice("The existing specification was not validated "
                       "against the proposed configuration — the real "
                       "run does that first, and leaves the target "
                       "untouched if it fails.")
        return 0

    # A leftover from a previously crashed adopt run is ours to remove —
    # the single documented exception to the byte-identical guarantee.
    if os.path.exists(temp_path):
        os.remove(temp_path)

    created_tools = not os.path.isdir(tools_dir)
    wrote_config = False
    committed = False       # flips True at the point of no return
    try:
        if created_tools:
            os.makedirs(tools_dir)
        with open(config_path, "w", encoding="utf-8") as handle:
            handle.write(config_json(settings, adopting=True, name=name))
        wrote_config = True

        with open(os.path.join(ROOT, SRS_TOOLS, "srs_check.py"), "rb") as src:
            checker_bytes = src.read()
        # This file becomes the target's checker at the point of no
        # return below, without passing through the copier, so it is
        # prepared the same way the copier prepares everything else.
        checker_bytes = outbound(checker_bytes,
                                 os.path.join(SRS_TOOLS, "srs_check.py"))
        with open(temp_path, "wb") as handle:
            handle.write(checker_bytes)

        sys.stdout.write("Validating the existing specification against "
                         "the proposed configuration:\n")
        sys.stdout.flush()
        # The checker reads the record shape through srs_parse, which it
        # imports from beside itself — and nothing of ours is in the
        # target yet, because the tooling is installed only once this
        # validation has passed. Lend it the framework's copy for the
        # duration rather than writing a second file the rollback would
        # have to take back out.
        env = dict(os.environ)
        env["PYTHONPATH"] = os.pathsep.join(
            [os.path.join(ROOT, SRS_TOOLS)]
            + ([env["PYTHONPATH"]] if env.get("PYTHONPATH") else []))
        rc = subprocess.call([sys.executable, temp_path, "--no-write"],
                             env=env)
        if rc != 0:
            sys.stdout.write(
                "\nValidation failed — nothing was installed. Fix the "
                "specification or the lexicon and re-run (the srs-init "
                "agent skill can derive the lexicon for you).\n")
            return 3

        checker_existed = os.path.exists(checker_dst)
        if checker_existed:
            old_version = read_target_version(target)
            sys.stdout.write(
                "\nAdopt will replace the existing srs-dd/tools/srs_check.py "
                "(%s) with the framework checker %s; the old file remains "
                "in your git history.\n"
                % (old_version or "unversioned", __version__))
            answer = ask("Replace srs-dd/tools/srs_check.py? (Y/n)", "Y", batch)
            if answer.strip().lower() in ("n", "no"):
                sys.stdout.write("Aborted by user; nothing was changed.\n")
                return 3
        os.replace(temp_path, checker_dst)      # the point of no return
        committed = True
        if checker_existed:
            installer.refreshed.append(os.path.join(SRS_TOOLS, "srs_check.py"))
        else:
            installer.created.append(os.path.join(SRS_TOOLS, "srs_check.py"))
        installer.created.append(os.path.join("specs", "srs-config.json"))
    finally:
        if not committed:
            for path in (temp_path, config_path if wrote_config else None):
                if path and os.path.exists(path):
                    os.remove(path)
            if created_tools:
                for gone in (tools_dir, os.path.dirname(tools_dir)):
                    try:
                        os.rmdir(gone)
                    except OSError:
                        pass

    # Past the point of no return: failures below keep the config and the
    # checker and report partial completion instead of rolling back.
    try:
        install_adopt_files(installer, settings, substitute, target,
                            tools_skip=("srs_check.py",))  # already placed

        sys.stdout.write("\n" + installer.summary() + "\n")
        installer.print_notes()
        installer.gitattributes_hint()
        sys.stdout.write("\nAdopted with srs_init (framework %s).\n"
                         % __version__)
    except Exception as exc:            # noqa: BLE001 — report, don't roll back
        sys.stdout.write("\n" + installer.summary() + "\n")
        sys.stdout.write(
            "\nPartial completion: the config and the checker are "
            "installed, but a later step failed: %s\nRe-run to finish "
            "(the target will be detected as initialized).\n" % exc)
        return 1

    result = run_target_checker(target)
    if result == 0:
        undated_hint(target)
    if result == 0 and settings["grounds"]:
        result = run_target_grounds(target)
    if result == 0 and settings["arch"]:
        result = run_target_arch(target)
    if result == 0:
        sys.stdout.write(
            "\nNext steps: commit the regenerated "
            "specs/90-traceability.md together with the new tooling.\n")
        report_wiring(installer, target)
    return result
# srs-end: FR-INIT-030, FR-INIT-050


# implements: FR-INIT-340
def old_layout_files(target):
    """What an earlier version wrote outside srs-dd/ and this one moves:
    the tools under tools/ and the standards beside what they govern —
    only where the file is ours, by its marker; a project's own README is
    not the standard and stays."""
    old = [os.path.join("tools", name)
           for name in TOOLS + GROUNDS_TOOLS + ARCH_TOOLS]
    old += [os.path.join("specs", "README.md"), os.path.join("grounds", "README.md"),
            os.path.join("arch", "README.md")]
    found = []
    for rel in old:
        path = os.path.join(target, rel)
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as handle:
                    if RE_MARKER.search(handle.read()):
                        found.append(rel)
            except OSError:
                pass
    return found


def new_home(rel):
    name = os.path.basename(rel)
    if rel.startswith("tools" + os.sep):
        return os.path.join(SRS_TOOLS, name)
    return {"specs": SPEC_STANDARD, "grounds": GROUNDS_STANDARD,
            "arch": ARCH_STANDARD}[rel.split(os.sep)[0]]


def migrate_layout(installer, old):
    """Deletes the copies an earlier version left outside srs-dd/, once
    the directory holds the current files: a stale tools/srs_check.py
    beside a current one is two checkers, and the project's gate would
    run whichever its pipeline still names."""
    for rel in old:
        installer.moved.append("%s -> %s" % (rel, new_home(rel)))
        if not installer.dry_run:
            os.remove(os.path.join(installer.target, rel))
    # An emptied tools/ is ours too; one the project uses stays.
    if old and not installer.dry_run:
        try:
            os.rmdir(os.path.join(installer.target, "tools"))
        except OSError:
            pass
    if old:
        installer.notes.append(
            "the framework's files now live under %s/; the hook, the "
            "pipelines and the guide call them there — the reports below "
            "say what each has to call." % SRS_DIR)
# srs-end: FR-INIT-340


# implements: FR-INIT-270
def run_upgrade(args, target):
    installer = Installer(target, dry_run=args.dry_run)
    sys.stdout.write("Initialized target detected — upgrade mode: "
                     "refreshing the tooling and the skills.\n")
    ignored = [flag for flag, value in (
        ("--mode", args.mode), ("--name", args.name),
        ("--areas", args.areas), ("--code-roots", args.code_roots),
        ("--test-roots", args.test_roots),
        ("--extensions", args.extensions),
        ("--modal-verbs", args.modal_verbs),
        ("--negation-words", args.negation_words),
        ("--rationale-markers", args.rationale_markers)) if value]
    if ignored:
        sys.stdout.write("Note: %s have no effect in upgrade mode — "
                         "edit specs/srs-config.json instead.\n"
                         % ", ".join(ignored))
    sys.stdout.write("\n")

    old_version = read_target_version(target)       # before the refresh
    # implements: FR-INIT-130
    # The upgrader owns the command; the three things it shows before
    # anything is written are printed from here.
    show_all = print_version_transition(old_version)
    print_whats_new(old_version, show_all)
    print_upgrade_notes(old_version, show_all)
    # srs-end: FR-INIT-130

    old = old_layout_files(target)
    install_tools(installer)
    installer.copy(".gitattributes", ".gitattributes", tooling=False,
                   starter=True)
    # implements: FR-GND-290
    # Refreshed where the register already is; added only when this run
    # was told to add it. An upgrade is what every project runs, and a
    # subsystem that arrived through one would arrive at projects that
    # never declined it because they never heard of it.
    if has_grounds(target):
        if args.grounds == "no":
            sys.stdout.write(
                "Note: --grounds no does not remove a register that is "
                "already there; it is refreshed like the rest of the "
                "tooling. To be rid of it, delete grounds/, "
                "srs-dd/tools/srs_grounds.py and the srs-bet skill.\n")
        if args.period:
            # Same silence the note above exists to break: the register's
            # configuration is the project's and an upgrade never edits it.
            sys.stdout.write(
                "Note: --period sets the dashboard's calendar unit when a "
                "register is created, and this project already has one. To "
                "change it, edit `period` in grounds/grounds-config.json.\n")
        install_grounds(installer)
    elif args.grounds == "yes":
        sys.stdout.write("Adding the grounds register, as asked.\n")
        install_grounds(installer, period=args.period or "quarter")
    elif args.grounds is None:
        sys.stdout.write(
            "This project carries no grounds register. To add one: "
            "re-run with --grounds yes.\n")
    # srs-end: FR-GND-290
    # implements: FR-ARCH-130
    # The same promise for the architecture layer: refreshed where it is,
    # added only when this run was told to add it.
    if has_arch(target):
        if args.arch == "no":
            sys.stdout.write(
                "Note: --arch no does not remove a layer that is already "
                "there; it is refreshed like the rest of the tooling. To be "
                "rid of it, delete arch/, srs-dd/tools/srs_arch.py and the srs-arch "
                "skill.\n")
        install_arch(installer)
    elif args.arch == "yes":
        sys.stdout.write("Adding the architecture layer, as asked.\n")
        install_arch(installer)
    elif args.arch is None:
        sys.stdout.write(
            "This project carries no architecture layer. To add one: "
            "re-run with --arch yes.\n")
    # srs-end: FR-ARCH-130
    install_skills(installer, substitute=None)
    # implements: FR-INIT-200
    # The guides are starters, written only where absent — and filled in
    # rather than copied, so this needs the answers the install took: the
    # name from the configuration, the width beside it (FR-INIT-210). A
    # project installed before the name was recorded falls back to its
    # directory. Whether or not a guide is written, its region is refreshed.
    install_agent_docs(installer, substitutions(*guide_answers(target)))
    # srs-end: FR-INIT-200
    # A pipeline starter only where this run asked for one: an upgrade run
    # through srs_upgrade.py has no --ci to pass, and what the project
    # already has is its own, starter or not (FR-INIT-290).
    install_ci(installer, args.ci)
    install_hook(installer, describe_hooks(target))
    migrate_layout(installer, old)
    sys.stdout.write(installer.summary() + "\n")
    installer.print_notes()
    if args.dry_run:
        dry_run_notice()
        return 0
    installer.gitattributes_hint()
    result = run_target_checker(target)
    if result == 0:
        undated_hint(target)
    if result == 0 and has_grounds(target):
        result = run_target_grounds(target)
    if result == 0 and has_arch(target):
        result = run_target_arch(target)
    if result == 0 and old_version != __version__:
        sys.stdout.write(
            "\nNext steps: commit the refreshed tooling and the "
            "regenerated specs/90-traceability.md.\n")
    if result == 0:
        report_wiring(installer, target)
    return result
# srs-end: FR-INIT-270


# implements: IF-CI-010
def main():
    args = parse_args()
    target = os.path.abspath(args.target)

    if is_inside(target, ROOT):
        sys.stderr.write(
            "Refusing to install into the framework repository itself "
            "(%s is inside %s).\n" % (target, ROOT))
        return 2
    if os.path.exists(target) and not os.path.isdir(target):
        sys.stderr.write("Target is not a directory: %s\n" % target)
        return 2

    # implements: FR-INIT-330
    # The one directory the installer rewrites without asking is the one
    # it must never touch when somebody else made it.
    if os.path.isdir(os.path.join(target, SRS_DIR)):
        try:
            with open(os.path.join(target, DIR_README), "r",
                      encoding="utf-8", errors="replace") as handle:
                ours = RE_MARKER.search(handle.read()) is not None
        except OSError:
            ours = False
        # A directory holding nothing but the checker a crashed adopt left
        # behind is ours too: adopt removes that file and carries on.
        leftover = {os.path.relpath(os.path.join(root, name), os.path.join(target, SRS_DIR))
                    for root, _dirs, names in os.walk(os.path.join(target, SRS_DIR))
                    for name in names}
        if leftover <= {os.path.join("tools", TEMP_CHECKER)}:
            ours = True
        if not ours:
            sys.stderr.write(
                "%s/ exists in the target and carries no marker of the "
                "framework in its README.md: it is not ours, and the "
                "installer rewrites that directory whole. Move it and "
                "re-run; nothing was changed.\n" % SRS_DIR)
            return 2
    # srs-end: FR-INIT-330

    config_exists = os.path.exists(
        os.path.join(target, "specs", "srs-config.json"))
    if config_exists and args.mode:
        sys.stderr.write(
            "Target is initialized; drop --mode to run an upgrade, or "
            "remove specs/srs-config.json to re-initialize.\n")
        return 2
    if config_exists:
        return run_upgrade(args, target)

    raw_md, strict_count, found_areas = scan_target_spec(target)
    if args.mode == "fresh":
        mode = "fresh"
    elif args.mode == "adopt":
        if strict_count == 0:
            sys.stderr.write(
                "--mode adopt: no valid requirements found under specs/ — "
                "nothing to adopt.\n")
            return 2
        mode = "adopt"
    elif strict_count > 0:
        mode = "adopt"
    elif raw_md > 0:
        sys.stderr.write(
            "specs/ contains markdown but no requirements — refusing to "
            "guess; use --mode fresh or --mode adopt to disambiguate.\n")
        return 2
    else:
        mode = "fresh"

    batch = args.defaults
    if mode == "adopt":
        sys.stdout.write("Existing specification detected (%d requirements"
                         ", areas: %s) — adopt mode.\n\n"
                         % (strict_count, ", ".join(found_areas) or "—"))
        return run_adopt(args, target, batch, found_areas)
    return run_fresh(args, target, batch)
# srs-end: IF-CI-010


if __name__ == "__main__":
    sys.exit(main())
