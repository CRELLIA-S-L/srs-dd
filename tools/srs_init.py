#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Initialize a target repository with the SRS-DD skeleton.

Run from a clone of the framework repository:

    python3 tools/srs_init.py ../my-project
    python3 tools/srs_init.py ../my-project --defaults --ci github

Interactive by default; --defaults answers every remaining question with
its default. The script knows no natural language: to write the
specification in another language, pass the word lists (--modal-verbs,
--negation-words, --rationale-markers) — or use the `srs-init` agent
skill, which generates and confirms them for you.

Re-running against an initialized target (detected by the presence of
specs/srs-config.json) switches to upgrade mode: only tooling is
refreshed, and only with --force; specification content is never touched.
"""

import argparse
import json
import os
import re
import subprocess
import sys

from srs_check import DEFAULTS, __version__

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PLACEHOLDER_NAME = "<Your Project Name>"
RE_AREA = re.compile(r"^[A-Z][A-Z0-9]*$")

# specs/ files that are generated per target rather than copied.
SPEC_EXCLUDE = {"90-traceability.md", "srs-config.json", "10-fr-core.md"}

# Skills shipped to targets. srs-init itself stays framework-only.
SKILLS = ("srs", "srs-new", "srs-audit")

CI_TEMPLATES = {
    "github": (os.path.join("ci", "github-workflow.yml"),
               os.path.join(".github", "workflows", "srs.yml")),
    "gitlab": (os.path.join("ci", "gitlab-ci.yml"), ".gitlab-ci.yml"),
}

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
        description="Copy the SRS-DD skeleton into a target repository.")
    parser.add_argument("target", help="target repository root")
    parser.add_argument("--defaults", action="store_true",
                        help="non-interactive: answer every remaining "
                             "question with its default")
    parser.add_argument("--force", action="store_true",
                        help="refresh existing tooling files "
                             "(specification content is never overwritten)")
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
    def __init__(self, target, force):
        self.target = target
        self.force = force
        self.created = []
        self.refreshed = []
        self.skipped = []

    def put(self, dst_rel, content, tooling, precious=False):
        """Writes one file. `content` is str (utf-8) or bytes.

        Existing tooling files are refreshed only with --force; existing
        specification content is never overwritten. `precious` marks
        files a project commonly owns already (CI config, agent docs):
        those are refreshed only when --force is given AND the existing
        file carries the "SRS-DD" marker — a file we did not install is
        never clobbered.
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
            elif tooling and self.force:
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

    def copy(self, src_rel, dst_rel, tooling, substitute=None,
             precious=False):
        src = os.path.join(ROOT, src_rel)
        with open(src, "rb") as handle:
            raw = handle.read()
        if substitute:
            text = raw.decode("utf-8")
            for old, new in substitute.items():
                text = text.replace(old, new)
            self.put(dst_rel, text, tooling, precious=precious)
        else:
            self.put(dst_rel, raw, tooling, precious=precious)

    def summary(self):
        lines = []
        for label, items in (("created", self.created),
                             ("refreshed", self.refreshed),
                             ("skipped", self.skipped)):
            if items:
                lines.append("%s:" % label)
                lines.extend("  %s" % item for item in items)
        return "\n".join(lines) if lines else "nothing to do"


def collect_spec_skeleton():
    """Framework specs/ files copied verbatim into targets."""
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


def install_tooling(installer, substitute):
    installer.copy(os.path.join("tools", "srs_check.py"),
                   os.path.join("tools", "srs_check.py"), tooling=True)
    installer.copy(".gitattributes", ".gitattributes", tooling=True,
                   precious=True)
    for skill in SKILLS:
        rel = os.path.join(".claude", "skills", skill, "SKILL.md")
        if os.path.exists(os.path.join(ROOT, rel)):
            installer.copy(rel, rel, tooling=True, substitute=substitute)


def run_target_checker(target):
    checker = os.path.join(target, "tools", "srs_check.py")
    sys.stdout.write("\nRunning the checker in the target:\n")
    sys.stdout.flush()      # keep parent/child output ordered when piped
    return subprocess.call([sys.executable, checker])


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

    upgrade = os.path.exists(
        os.path.join(target, "specs", "srs-config.json"))
    installer = Installer(target, args.force)

    if upgrade:
        sys.stdout.write("Initialized target detected — upgrade mode: "
                         "refreshing tooling only.\n")
        sys.stdout.write("CLAUDE.md and AGENTS.md are not refreshed by "
                         "upgrades; merge changes manually if needed.\n")
        ignored = [flag for flag, value in (
            ("--name", args.name), ("--areas", args.areas),
            ("--code-roots", args.code_roots),
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
        install_tooling(installer, substitute=None)
        if args.ci:
            install_ci(installer, args.ci)
        sys.stdout.write(installer.summary() + "\n")
        return run_target_checker(target)

    batch = args.defaults
    name = args.name or ask("Project name", os.path.basename(target) or
                            "My Project", batch)
    areas = split_list(args.areas) if args.areas else split_list(
        ask("Requirement areas (comma-separated)",
            ", ".join(DEFAULTS["areas"]), batch))
    for area in areas:
        if not RE_AREA.match(area):
            sys.stderr.write(
                "Invalid area %r: must match [A-Z][A-Z0-9]* — it is "
                "interpolated into the identifier grammar.\n" % area)
            return 2
    if not areas:
        sys.stderr.write("At least one area is required.\n")
        return 2

    def listed(flag_value, prompt, default):
        if flag_value:
            return split_list(flag_value)
        return split_list(ask(prompt, ", ".join(default), batch))

    code_roots = listed(args.code_roots, "Production code roots",
                        DEFAULTS["code_roots"])
    test_roots = listed(args.test_roots, "Test roots",
                        DEFAULTS["test_roots"])
    extensions = listed(args.extensions, "Source file extensions",
                        DEFAULTS["code_extensions"])
    modal_verbs = listed(args.modal_verbs, "Lexicon: modal verbs",
                         DEFAULTS["modal_verbs"])
    negation_words = listed(args.negation_words, "Lexicon: negation words",
                            DEFAULTS["negation_words"])
    rationale_markers = listed(args.rationale_markers,
                               "Lexicon: rationale markers",
                               DEFAULTS["rationale_markers"])
    ci_choice = args.ci or ("none" if batch else ask(
        "CI template (github/gitlab/both/none)", "none", batch))
    if ci_choice not in ("github", "gitlab", "both", "none"):
        sys.stderr.write("Unknown CI choice %r.\n" % ci_choice)
        return 2

    substitute = {PLACEHOLDER_NAME: name}

    sys.stdout.write("\nInstalling into %s\n\n" % target)

    for rel in collect_spec_skeleton():
        installer.copy(rel, rel, tooling=False, substitute=substitute)

    config = {
        "areas": areas,
        "code_roots": code_roots,
        "test_roots": test_roots,
        "code_extensions": extensions,
        "modal_verbs": modal_verbs,
        "negation_words": negation_words,
        "rationale_markers": rationale_markers,
    }
    installer.put(os.path.join("specs", "srs-config.json"),
                  json.dumps(config, ensure_ascii=False, indent=2) + "\n",
                  tooling=False)

    area = areas[0]
    placeholder = PLACEHOLDER_REQ % {
        "area": area,
        "area_low": area.lower(),
        "verb": modal_verbs[0],
        "marker": rationale_markers[0],
    }
    installer.put(os.path.join("specs", "10-fr-%s.md" % area.lower()),
                  placeholder, tooling=False)

    install_tooling(installer, substitute)
    for doc in ("CLAUDE.md", "AGENTS.md"):
        if os.path.exists(os.path.join(ROOT, doc)):
            installer.copy(doc, doc, tooling=True, substitute=substitute,
                           precious=True)
    install_ci(installer, ci_choice)

    sys.stdout.write(installer.summary() + "\n")
    sys.stdout.write("\nInstalled with srs_init (framework %s).\n"
                     % __version__)
    result = run_target_checker(target)
    if result == 0:
        sys.stdout.write(
            "\nNext steps: replace the placeholder requirement in "
            "specs/10-fr-%s.md, then read specs/README.md.\n"
            % area.lower())
    return result


if __name__ == "__main__":
    sys.exit(main())
