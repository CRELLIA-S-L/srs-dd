#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cut a framework release: one command.

    python3 tools/srs_release.py 1.2.0 --dry-run
    python3 tools/srs_release.py 1.2.0

It dates the changelog section, bumps the checker's version, regenerates
the matrix, and stops. Committing is yours, with whatever git client this
repository is driven by, and so is the `vX.Y.Z` tag.

It cuts no baseline. A release ships what the system does; a baseline
freezes what it must do, and `tools/srs_baseline.py` is the command for
that. Cut both when both are true, in either order.

It writes no prose: the `## [X.Y.Z]` section belongs to whoever made the
change, and its absence is what this refuses on. A section that already
carries a date is what tells it the release was cut already.

Framework-only — a target project releases nothing of ours.

Exit codes: 0 prepared · 2 refused, having changed nothing.
"""

import argparse
import datetime
import os
import re
import subprocess
import sys

sys.dont_write_bytecode = True                              # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CHANGELOG = os.path.join(ROOT, "CHANGELOG.md")
CHECKER = os.path.join(ROOT, "tools", "srs_check.py")
MATRIX = os.path.join("specs", "90-traceability.md")

TOUCHED = ["CHANGELOG.md", os.path.join("tools", "srs_check.py"), MATRIX]


def relative(path):
    return path.replace(os.sep, "/")


def fail(message):
    sys.stderr.write("srs-release: %s\n" % message)
    return 2


def run_checker(*flags):
    """Runs the checker; returns None when it passes and its own output
    when it does not.

    Captured rather than inherited so a refusal carries the reasons with
    it: the verdict goes to stderr and the checker's findings to stdout,
    and whoever redirects one of the two is otherwise told that something
    is wrong without being told what.
    """
    probe = subprocess.Popen([sys.executable, CHECKER] + list(flags),
                             cwd=ROOT, stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT)
    output = probe.communicate()[0].decode("utf-8", "replace")
    if probe.returncode == 0:
        sys.stdout.write(output)
        return None
    return output.rstrip()


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
    parser.add_argument("--dry-run", action="store_true",
                        help="print what would happen and write nothing")
    args = parser.parse_args()

    version = args.version.lstrip("v")
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        return fail("%s is not a version of the form X.Y.Z" % version)
    date = args.date or datetime.date.today().isoformat()

    # Everything that can refuse, refuses first: a half-prepared release
    # is worse than an unprepared one.
    changelog = read(CHANGELOG)
    heading = re.search(r"^## \[%s\](.*)$" % re.escape(version),
                        changelog, re.M)
    if not heading:
        return fail("CHANGELOG.md has no `## [%s]` section — the release "
                    "notes are yours to write, not mine" % version)
    if heading.group(1).strip():
        return fail("`## [%s]` is already dated%s — this release was cut"
                    % (version, heading.group(1).rstrip()))

    # The checker regenerates the matrix, so it runs before the edits:
    # everything then goes into one commit.
    checked = run_checker("--strict")
    if checked is not None:
        return fail("the checker does not pass; nothing was written\n%s"
                    % checked)

    checker_source = read(CHECKER)
    bumped = re.sub(r'^__version__ = "[^"]+"',
                    '__version__ = "%s"' % version, checker_source,
                    count=1, flags=re.M)
    dated = changelog[:heading.start()] \
        + "## [%s] — %s" % (version, date) + changelog[heading.end():]
    plan = ["CHANGELOG.md      dated %s" % date,
            "tools/srs_check.py __version__ -> %s" % version]
    sys.stdout.write("\n".join("  " + line for line in plan) + "\n")
    if args.dry_run:
        sys.stdout.write("\nDry run: nothing was written.\n")
        return 0

    write(CHANGELOG, dated)
    write(CHECKER, bumped)
    checked = run_checker()
    if checked is not None:
        return fail("the checker failed after the edits; they are still in "
                    "the working tree — undo them with\n  git checkout -- "
                    "%s\n%s"
                    % (" ".join(relative(path) for path in TOUCHED), checked))

    sys.stdout.write(
        "\nPrepared. Commit %s — that commit is the release.\n"
        "A tag is optional; where you want one it is `v%s`, on that same "
        "commit.\n" % (", ".join(relative(path) for path in TOUCHED), version))
    return 0


if __name__ == "__main__":
    sys.exit(main())
