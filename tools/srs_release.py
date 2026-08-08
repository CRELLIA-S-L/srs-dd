#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cut a framework release: one command, in the order the standard asks for.

    python3 tools/srs_release.py 1.2.0 --dry-run
    python3 tools/srs_release.py 1.2.0

It dates the changelog section, bumps the checker's version, adds the
baseline row, regenerates the matrix, commits those files and creates both
tags — `vX.Y.Z` for the release and `spec/vX.Y.Z` for the specification
baseline. The row goes in before the tag, so the tag lands on a commit that
already describes itself.

It writes no prose: the `## [X.Y.Z]` section belongs to whoever made the
change, and its absence is what this refuses on. It does not push. The
commit it makes runs the project's hooks like any other.

Framework-only — a target project releases nothing of ours.

Exit codes: 0 released · 2 refused before changing anything.
"""

import argparse
import datetime
import os
import re
import subprocess
import sys

sys.dont_write_bytecode = True                              # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import srs_view                                             # noqa: E402

CHANGELOG = os.path.join(ROOT, "CHANGELOG.md")
CHECKER = os.path.join(ROOT, "tools", "srs_check.py")
BASELINES = os.path.join(ROOT, "specs", "92-baselines.md")
MATRIX = os.path.join("specs", "90-traceability.md")

TOUCHED = ["CHANGELOG.md", os.path.join("tools", "srs_check.py"),
           os.path.join("specs", "92-baselines.md"), MATRIX]


def fail(message):
    sys.stderr.write("srs-release: %s\n" % message)
    return 2


def git(args):
    return subprocess.check_output(["git", "-C", ROOT] + args,
                                   stderr=subprocess.STDOUT).decode("utf-8")


def read(path):
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def write(path, text):
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def main():
    parser = argparse.ArgumentParser(
        description="Cut a framework release.")
    parser.add_argument("version", help="the release, e.g. 1.2.0")
    parser.add_argument("--date", metavar="YYYY-MM-DD",
                        help="release date; today by default")
    parser.add_argument("--message", "-m",
                        help="commit subject; \"SRS-DD X.Y.Z\" by default")
    parser.add_argument("--dry-run", action="store_true",
                        help="print what would happen and write nothing")
    args = parser.parse_args()

    version = args.version.lstrip("v")
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        return fail("%s is not a version of the form X.Y.Z" % version)
    date = args.date or datetime.date.today().isoformat()

    # Everything that can refuse, refuses first: a half-cut release is
    # worse than an uncut one.
    try:
        dirty = git(["status", "--porcelain"]).strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        return fail("git is unavailable: %s" % exc)
    if dirty:
        return fail("the working tree is not clean:\n%s" % dirty)

    for tag in ("v%s" % version, "spec/v%s" % version):
        if git(["tag", "-l", tag]).strip():
            return fail("tag %s already exists" % tag)

    changelog = read(CHANGELOG)
    heading = re.search(r"^## \[%s\](.*)$" % re.escape(version),
                        changelog, re.M)
    if not heading:
        return fail("CHANGELOG.md has no `## [%s]` section — the release "
                    "notes are yours to write, not mine" % version)

    if subprocess.call([sys.executable, CHECKER, "--strict"],
                       cwd=ROOT) != 0:
        return fail("the checker does not pass; nothing was written")
    if git(["status", "--porcelain", MATRIX]).strip():
        return fail("the traceability matrix changed when it was "
                    "regenerated — commit it first")

    row = srs_view.baseline_row(version, date)
    checker_source = read(CHECKER)
    bumped = re.sub(r'^__version__ = "[^"]+"',
                    '__version__ = "%s"' % version, checker_source,
                    count=1, flags=re.M)
    dated = changelog[:heading.start()] \
        + "## [%s] — %s" % (version, date) + changelog[heading.end():]
    baselines = read(BASELINES)
    anchor = re.search(r"^\|---\|---\|---\|---\|$", baselines, re.M)
    if not anchor:
        return fail("specs/92-baselines.md has no table to add a row to")
    logged = baselines[:anchor.end()] + "\n" + row + baselines[anchor.end():]

    subject = args.message or "SRS-DD %s" % version
    plan = ["CHANGELOG.md      dated %s" % date,
            "tools/srs_check.py __version__ -> %s" % version,
            "specs/92-baselines.md  %s" % row.strip(),
            "commit            %s" % subject,
            "tag               v%s and spec/v%s" % (version, version)]
    sys.stdout.write("\n".join("  " + line for line in plan) + "\n")
    if args.dry_run:
        sys.stdout.write("\nDry run: nothing was written.\n")
        return 0

    write(CHANGELOG, dated)
    write(CHECKER, bumped)
    write(BASELINES, logged)
    if subprocess.call([sys.executable, CHECKER], cwd=ROOT) != 0:
        return fail("the checker failed after the edits; nothing committed")

    # Past this point the files are written, so a failure has to say what
    # state it left behind rather than raise a traceback over it. The
    # commit runs the project's hooks, and those can fail for reasons that
    # have nothing to do with the release.
    try:
        git(["add"] + TOUCHED)
        git(["commit", "-m", subject])
    except subprocess.CalledProcessError as exc:
        return fail("the commit failed, and the edits are still in the "
                    "working tree — undo them with\n  git checkout -- %s\n%s"
                    % (" ".join(TOUCHED),
                       exc.output.decode("utf-8", "replace").strip()))
    for tag in ("v%s" % version, "spec/v%s" % version):
        try:
            git(["tag", tag])
        except subprocess.CalledProcessError as exc:
            return fail("committed, but tagging %s failed — the release is "
                        "in history and needs its tags by hand:\n%s"
                        % (tag, exc.output.decode("utf-8", "replace").strip()))
    sys.stdout.write("\nReleased %s. Nothing was pushed.\n" % version)
    return 0


if __name__ == "__main__":
    sys.exit(main())
