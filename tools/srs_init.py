#!/usr/bin/env python3
# -*- coding: utf-8 -*-
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
- **upgrade** — `specs/srs-config.json` exists: the checker and the
  skills are refreshed (no --force needed), the version transition and
  relevant CHANGELOG upgrade notes are printed.

`--mode fresh|adopt` overrides the fresh/adopt detection; upgrade is
always config-driven. `--force` additionally refreshes the "precious"
files (CI config, CLAUDE.md/AGENTS.md, .gitattributes, the pre-commit
hook) — and only when the existing file carries the "SRS-DD" marker; a
file the installer did not install is never overwritten.

Interactive by default; --defaults answers every remaining question with
its default. The script knows no natural language: to write the
specification in another language, pass the word lists (--modal-verbs,
--negation-words, --rationale-markers) — or use the `srs-init` agent
skill, which generates and confirms them for you.

Exit codes: 0 — success; 1 — checker errors in the target, or a failure
after adopt's point of no return (partial completion, see output);
2 — refused before any change (usage, ambiguous target, config errors);
3 — adopt rolled back, the target is byte-identical (modulo removal of a
stale temp file from a previously crashed adopt run).
"""

import argparse
import json
import os
import re
import subprocess
import sys

from srs_check import (DEFAULTS, __version__, parse_file, TYPES,
                       RE_AREA_NAME, SKIP_FILES, SKIP_DIRS)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PLACEHOLDER_NAME = "<Your Project Name>"
RE_AREA = re.compile(r"^[A-Z][A-Z0-9]*$")
# Strict requirement identifier: composed from the framework's TYPES and
# the area grammar, NOT from srs_check.RE_ID (that one is bound to the
# framework's own configured areas).
RE_STRICT_ID = re.compile(r"^(?:%s)-[A-Z][A-Z0-9]*-\d{3}$" % "|".join(TYPES))
RE_VERSION = re.compile(r'^__version__\s*=\s*"([^"]+)"', re.M)

TEMP_CHECKER = ".srs_check_adopt.py"

# specs/ files that are generated per target rather than copied.
SPEC_EXCLUDE = {"90-traceability.md", "srs-config.json", "10-fr-core.md"}

# Skills shipped to targets. srs-init itself stays framework-only.
SKILLS = ("srs", "srs-new", "srs-audit", "srs-harvest")

# Service spec files adopt lays down when (and only when) absent.
ADOPT_SERVICE_FILES = ("README.md", "constitution.md", "00-glossary.md",
                      "91-open-issues.md", "92-baselines.md")

CI_TEMPLATES = {
    "github": (os.path.join("ci", "github-workflow.yml"),
               os.path.join(".github", "workflows", "srs.yml")),
    "gitlab": (os.path.join("ci", "gitlab-ci.yml"), ".gitlab-ci.yml"),
}

HOOK_SRC = os.path.join("ci", "pre-commit")
HOOK_DST = os.path.join(".githooks", "pre-commit")

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
```

When the application is launched for the first time, the system
**%(verb)s** display a greeting that names the product.

**%(marker)s.** A placeholder showing the shape of a requirement: metadata
above, one bolded modal verb, rationale below. Delete it once you have
real requirements.
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
    parser.add_argument("--force", action="store_true",
                        help="also refresh existing SRS-DD-marked precious "
                             "files (CI config, CLAUDE.md/AGENTS.md, "
                             ".gitattributes); the checker and skills are "
                             "refreshed without it in adopt/upgrade modes; "
                             "specification content is never overwritten")
    parser.add_argument("--ci", choices=("github", "gitlab", "both", "none"),
                        default=None, help="which CI template(s) to install")
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


class Installer(object):
    def __init__(self, target, force, refresh_tooling=False):
        self.target = target
        self.force = force
        # adopt/upgrade refresh tooling freely; fresh stays conservative.
        self.refresh_tooling = refresh_tooling
        self.created = []
        self.refreshed = []
        self.skipped = []

    def put(self, dst_rel, content, tooling, precious=False,
            executable=False):
        """Writes one file. `content` is str (utf-8) or bytes.

        Existing tooling files are refreshed in adopt/upgrade modes (or
        with --force); existing specification content is never
        overwritten. `precious` marks files a project commonly owns
        already (CI config, agent docs): those are refreshed only when
        --force is given AND the existing file carries the "SRS-DD"
        marker — a file we did not install is never clobbered.
        """
        dst = os.path.join(self.target, dst_rel)
        exists = os.path.exists(dst)
        if exists:
            if precious:
                try:
                    with open(dst, "r", encoding="utf-8",
                              errors="replace") as handle:
                        ours = "SRS-DD" in handle.read()
                except OSError:
                    ours = False
                if self.force and ours:
                    self.refreshed.append(dst_rel)
                else:
                    reason = ("use --force to refresh" if ours else
                              "no SRS-DD marker — not ours, merge manually")
                    self.skipped.append("%s (%s)" % (dst_rel, reason))
                    return
            elif tooling and (self.force or self.refresh_tooling):
                self.refreshed.append(dst_rel)
            else:
                reason = ("use --force to refresh" if tooling
                          else "specification content, never overwritten")
                self.skipped.append("%s (%s)" % (dst_rel, reason))
                return
        else:
            self.created.append(dst_rel)
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
             precious=False, executable=False):
        src = os.path.join(ROOT, src_rel)
        with open(src, "rb") as handle:
            raw = handle.read()
        if substitute:
            text = raw.decode("utf-8")
            for old, new in substitute.items():
                text = text.replace(old, new)
            self.put(dst_rel, text, tooling, precious=precious,
                     executable=executable)
        else:
            self.put(dst_rel, raw, tooling, precious=precious,
                     executable=executable)

    def summary(self):
        lines = []
        for label, items in (("created", self.created),
                             ("refreshed", self.refreshed),
                             ("skipped", self.skipped)):
            if items:
                lines.append("%s:" % label)
                lines.extend("  %s" % item for item in items)
        return "\n".join(lines) if lines else "nothing to do"

    def gitattributes_hint(self):
        """The LF-pinning hint matters only when the target has its own
        .gitattributes we will never touch."""
        for item in self.skipped:
            if item.startswith(".gitattributes (no SRS-DD marker"):
                sys.stdout.write(
                    "\nHint: your .gitattributes was kept; consider adding\n"
                    "  specs/90-traceability.md text eol=lf\n"
                    "so autocrlf cannot break the CI freshness gate.\n")


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


def collect_spec_skeleton():
    """Framework specs/ files copied verbatim into fresh targets."""
    result = []
    base = os.path.join(ROOT, "specs")
    for current, dirs, files in os.walk(base):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for name in sorted(files):
            rel = os.path.relpath(os.path.join(current, name), ROOT)
            if os.path.basename(rel) in SPEC_EXCLUDE:
                continue
            result.append(rel)
    return sorted(result)


def install_ci(installer, choice):
    keys = {"github": ("github",), "gitlab": ("gitlab",),
            "both": ("github", "gitlab"), "none": ()}[choice]
    for key in keys:
        src, dst = CI_TEMPLATES[key]
        installer.copy(src, dst, tooling=True, precious=True)


def install_skills(installer, substitute):
    for skill in SKILLS:
        rel = os.path.join(".claude", "skills", skill, "SKILL.md")
        if os.path.exists(os.path.join(ROOT, rel)):
            installer.copy(rel, rel, tooling=True, substitute=substitute)


def install_hook(installer):
    installer.copy(HOOK_SRC, HOOK_DST, tooling=True, precious=True,
                   executable=True)


def hook_activation_hint(installer):
    if HOOK_DST in installer.created:
        sys.stdout.write(
            "\nActivate the pre-commit gate (one-time, in the target):\n"
            "  git config core.hooksPath .githooks\n")


def install_agent_docs(installer, substitute):
    for doc in ("CLAUDE.md", "AGENTS.md"):
        if os.path.exists(os.path.join(ROOT, doc)):
            installer.copy(doc, doc, tooling=True, substitute=substitute,
                           precious=True)


def run_target_checker(target):
    checker = os.path.join(target, "tools", "srs_check.py")
    sys.stdout.write("\nRunning the checker in the target:\n")
    sys.stdout.flush()      # keep parent/child output ordered when piped
    return subprocess.call([sys.executable, checker])


def read_target_version(target):
    path = os.path.join(target, "tools", "srs_check.py")
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            text = handle.read()
    except OSError:
        return None
    match = RE_VERSION.search(text)
    return match.group(1) if match else None


def version_tuple(text):
    parts = tuple(int(p) for p in text.split("."))
    return parts + (0,) * (3 - len(parts))


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


def print_upgrade_notes(old_version, show_all):
    """Prints CHANGELOG 'Upgrade notes' blocks newer than old_version.

    The format contract is documented in CHANGELOG.md's header. Missing
    or unparseable CHANGELOG — silently skip.
    """
    path = os.path.join(ROOT, "CHANGELOG.md")
    try:
        with open(path, "r", encoding="utf-8") as handle:
            lines = handle.read().split("\n")
    except OSError:
        return
    re_section = re.compile(r"^## \[(\d+\.\d+\.\d+)\]")
    notes = {}
    version = None
    in_notes = False
    for line in lines:
        match = re_section.match(line)
        if match:
            version = match.group(1)
            in_notes = False
            continue
        if line.startswith("### "):
            in_notes = (version is not None
                        and line.strip() == "### Upgrade notes")
            continue
        if line.startswith("## "):
            in_notes = False
            continue
        if in_notes and line.strip():
            notes.setdefault(version, []).append(line)
    if not notes:
        return
    if show_all:
        relevant = sorted(notes, key=version_tuple)
        caveat = " (target version unknown — showing all)"
    else:
        try:
            old_t = version_tuple(old_version)
        except ValueError:
            return
        relevant = sorted((v for v in notes if version_tuple(v) > old_t),
                          key=version_tuple)
        caveat = ""
    if not relevant:
        return
    sys.stdout.write("\nUpgrade notes%s:\n" % caveat)
    for version in relevant:
        sys.stdout.write("[%s]\n" % version)
        for line in notes[version]:
            sys.stdout.write("%s\n" % line)
    sys.stdout.write("\n")


def collect_settings(args, batch, area_default):
    """Prompts/flags for everything except the project name."""
    areas = split_list(args.areas) if args.areas else split_list(
        ask("Requirement areas (comma-separated)",
            ", ".join(area_default), batch))
    for area in areas:
        if not RE_AREA.match(area):
            sys.stderr.write(
                "Invalid area %r: must match [A-Z][A-Z0-9]* — it is "
                "interpolated into the identifier grammar.\n" % area)
            return None
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
    return settings


def config_json(settings):
    config = dict((key, settings[key]) for key in
                  ("areas", "code_roots", "test_roots", "code_extensions",
                   "modal_verbs", "negation_words", "rationale_markers"))
    return json.dumps(config, ensure_ascii=False, indent=2) + "\n"


def run_fresh(args, target, batch):
    installer = Installer(target, args.force, refresh_tooling=False)
    name = args.name or ask("Project name", os.path.basename(target) or
                            "My Project", batch)
    settings = collect_settings(args, batch, DEFAULTS["areas"])
    if settings is None:
        return 2
    substitute = {PLACEHOLDER_NAME: name}

    sys.stdout.write("\nInstalling into %s\n\n" % target)

    for rel in collect_spec_skeleton():
        installer.copy(rel, rel, tooling=False, substitute=substitute)

    installer.put(os.path.join("specs", "srs-config.json"),
                  config_json(settings), tooling=False)

    area = settings["areas"][0]
    placeholder = PLACEHOLDER_REQ % {
        "area": area,
        "area_low": area.lower(),
        "verb": settings["modal_verbs"][0],
        "marker": settings["rationale_markers"][0],
    }
    installer.put(os.path.join("specs", "10-fr-%s.md" % area.lower()),
                  placeholder, tooling=False)

    installer.copy(os.path.join("tools", "srs_check.py"),
                   os.path.join("tools", "srs_check.py"), tooling=True)
    installer.copy(".gitattributes", ".gitattributes", tooling=True,
                   precious=True)
    install_skills(installer, substitute)
    install_agent_docs(installer, substitute)
    install_ci(installer, settings["ci"])
    install_hook(installer)

    sys.stdout.write(installer.summary() + "\n")
    installer.gitattributes_hint()
    sys.stdout.write("\nInstalled with srs_init (framework %s).\n"
                     % __version__)
    result = run_target_checker(target)
    if result == 0:
        sys.stdout.write(
            "\nNext steps: replace the placeholder requirement in "
            "specs/10-fr-%s.md, then read specs/README.md.\n"
            % area.lower())
        hook_activation_hint(installer)
    return result


def run_adopt(args, target, batch, found_areas):
    installer = Installer(target, args.force, refresh_tooling=True)
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
    substitute = {PLACEHOLDER_NAME: name} if name else None

    specs_dir = os.path.join(target, "specs")
    tools_dir = os.path.join(target, "tools")
    config_path = os.path.join(specs_dir, "srs-config.json")
    temp_path = os.path.join(tools_dir, TEMP_CHECKER)
    checker_dst = os.path.join(tools_dir, "srs_check.py")
    had_own_readme = os.path.exists(os.path.join(specs_dir, "README.md"))

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
            handle.write(config_json(settings))
        wrote_config = True

        with open(os.path.join(ROOT, "tools", "srs_check.py"), "rb") as src:
            checker_bytes = src.read()
        with open(temp_path, "wb") as handle:
            handle.write(checker_bytes)

        sys.stdout.write("Validating the existing specification against "
                         "the proposed configuration:\n")
        sys.stdout.flush()
        rc = subprocess.call([sys.executable, temp_path, "--no-write"])
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
                "\nAdopt will replace the existing tools/srs_check.py "
                "(%s) with the framework checker %s; the old file remains "
                "in your git history.\n"
                % (old_version or "unversioned", __version__))
            answer = ask("Replace tools/srs_check.py? (Y/n)", "Y", batch)
            if answer.strip().lower() in ("n", "no"):
                sys.stdout.write("Aborted by user; nothing was changed.\n")
                return 3
        os.replace(temp_path, checker_dst)      # the point of no return
        committed = True
        if checker_existed:
            installer.refreshed.append(os.path.join("tools", "srs_check.py"))
        else:
            installer.created.append(os.path.join("tools", "srs_check.py"))
        installer.created.append(os.path.join("specs", "srs-config.json"))
    finally:
        if not committed:
            for path in (temp_path, config_path if wrote_config else None):
                if path and os.path.exists(path):
                    os.remove(path)
            if created_tools:
                try:
                    os.rmdir(tools_dir)
                except OSError:
                    pass

    # Past the point of no return: failures below keep the config and the
    # checker and report partial completion instead of rolling back.
    try:
        for service in ADOPT_SERVICE_FILES:
            rel = os.path.join("specs", service)
            if not os.path.exists(os.path.join(target, rel)):
                installer.copy(rel, rel, tooling=False,
                               substitute=substitute)
        if had_own_readme:
            sys.stdout.write(
                "\nNote: your existing specs/README.md was kept. It may "
                "predate framework features (draft lifecycle, annotations, "
                "baselines) — consider merging the relevant sections from "
                "the framework's specs/README.md.\n")
        if os.path.join("specs", "constitution.md") in installer.created \
                and settings["modal_verbs"] != DEFAULTS["modal_verbs"]:
            sys.stdout.write(
                "Note: the installed specs/constitution.md is in English "
                "(framework language); adapt or translate it as you see "
                "fit.\n")

        install_skills(installer, substitute)
        installer.copy(".gitattributes", ".gitattributes", tooling=True,
                       precious=True)
        install_agent_docs(installer, substitute)
        install_ci(installer, settings["ci"])
        install_hook(installer)

        sys.stdout.write("\n" + installer.summary() + "\n")
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
        sys.stdout.write(
            "\nNext steps: commit the regenerated "
            "specs/90-traceability.md together with the new tooling.\n")
        hook_activation_hint(installer)
    return result


def run_upgrade(args, target):
    installer = Installer(target, args.force, refresh_tooling=True)
    sys.stdout.write("Initialized target detected — upgrade mode: "
                     "refreshing the checker and the skills.\n")
    sys.stdout.write("CLAUDE.md and AGENTS.md are not refreshed by "
                     "upgrades; merge changes manually if needed.\n")
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
    show_all = print_version_transition(old_version)
    print_upgrade_notes(old_version, show_all)

    installer.copy(os.path.join("tools", "srs_check.py"),
                   os.path.join("tools", "srs_check.py"), tooling=True)
    installer.copy(".gitattributes", ".gitattributes", tooling=True,
                   precious=True)
    install_skills(installer, substitute=None)
    if args.ci:
        install_ci(installer, args.ci)
    install_hook(installer)
    sys.stdout.write(installer.summary() + "\n")
    installer.gitattributes_hint()
    result = run_target_checker(target)
    if result == 0 and old_version != __version__:
        sys.stdout.write(
            "\nNext steps: commit the refreshed tooling and the "
            "regenerated specs/90-traceability.md.\n")
    if result == 0:
        hook_activation_hint(installer)
    return result


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


if __name__ == "__main__":
    sys.exit(main())
