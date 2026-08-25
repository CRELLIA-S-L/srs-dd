# ADR-0021 — One version for the whole delivery, and the register already shared it

- **Status:** accepted
- **Date:** 2026-08-25
- **Related requirements:** FR-CI-070, FR-INIT-060, NFR-SPEC-010

## Context and problem statement

`tools/srs_grounds.py` carried its own `__version__`, written when the
grounds layer arrived and read by nothing outside the file. It printed the
number on every run. Both copies said `0.14.0`, so nothing had noticed, and
they would have diverged at the first release after the layer: the
specification checker going to 0.15.0 while the register's checker went on
announcing 0.14.0 to everybody who ran it, in every target that took the
register.

The obvious framing — two numbers that need syncing — is the wrong one, and
following it leads to a real question about the register's independence.
ADR-0015 gives hypotheses their own tree, their own owners and their own
rules, and ADR-0019 keeps the two checkers from importing each other. If the
register is that separate, why should it not carry a version of its own?

## Considered options

1. Bump both files from `tools/srs_release.py`.
2. Give the number one home in `tools/srs_parse.py` and re-export it.
3. Delete the register checker's copy and let it announce no version.
4. Version the register independently, on purpose.

## Decision outcome

Option 2.

**Option 4 is not a decision left open — it is a build.** The premise it
rests on is already false in the code. `grounds/README.md:3` carries the
`SRS-DD-VERSION` token, which the installer replaces with
`"SRS-DD-" + __version__` taken from `srs_check` (`tools/srs_init.py:68`,
`:126`, `:299-301`). The standard of the grounds register is therefore
stamped today with the specification checker's number, and has been since the
layer shipped. There is no independent versioning to preserve; there is one
number and an unread copy of it.

What is versioned is neither the specification nor the register but the
**delivery**: the set of tools and standards `tools/srs_init.py` writes into
a target and `tools/srs_upgrade.py` refreshes. FR-INIT-060's rationale
already names it correctly — "the marker carries the framework version". One
installer places both trees; `grounds/` is installed from it when a project
takes the register (`GROUNDS_TOOLS`, `tools/srs_init.py:110`). One upgrade
command refreshes both, and it does not know about individual files at all:
it fetches the framework and runs that framework's installer. One release
command cuts both. `RE_MARKER` matches one shape across all eight stamped
files.

So giving the register its own number would mean a second branch in
`srs_release.py`, a second number in `CHANGELOG.md`, a second pattern in
`RE_MARKER`, and an upgrade that can move one tree without the other. That is
a delivery mechanism nobody has asked for, built to record a distinction
nobody can yet observe. The register is separate in subject matter, which is
what ADR-0015 protects; it is not separately delivered, and the version
describes delivery.

**Option 1 pays at every release, forever,** for two numbers a command has to
keep equal — the arrangement that produced this entry.

**Option 3 is two lines and turns the mismatch over rather than removing it.**
The installer would still stamp `grounds/README.md` with `SRS-DD-x.y.z`, so a
target would hold a versioned register standard beside a register checker
that names no version, and a bug report would lose the first thing it needs.

**Option 2 puts the number where both checkers can reach it without either
importing the other.** `tools/srs_parse.py` is the one file both must have
beside them — each already exits 2 when it is missing — and it has no
configuration and not one `sys.exit`, so ADR-0019's objection does not apply:
that decision refused an import of `srs_check`, not of the parser it created.
Both checkers re-export the number, so `tools/srs_init.py`,
`tools/srs_view.py` and `tools/srs_dates.py` read it exactly where they read
it before, unchanged.

## Consequences

`tools/srs_release.py` bumps `tools/srs_parse.py` instead of
`tools/srs_check.py`, and says so in what it reports as the release commit.
FR-CI-070's statement said "bump the checker's version"; the checker is no
longer where the number lives, and the statement now names the framework's
version, which is what FR-INIT-060 had been calling it all along.

The module that holds the number is documented as knowing "the physical shape
of a record, and nothing about its meaning", and a release version is not
part of that shape. This is the cost of the option and it is paid in a
comment: the file says whose number it is and why it lives there, because a
reader who finds `__version__` in a parser will otherwise read it as the
parser's own.

`tests/release-smoke.sh` asserts the bump against `tools/srs_parse.py` and,
new here, against what the two checkers print. The failure this replaced was
not a wrong number in a file — it was a number that reached the file and not
the tools reading it, which no assertion on file contents can see.

Nothing about a target changes. The same single number reaches the same eight
stamped files by the same path.

If the register ever becomes separately delivered — its own repository, its
own upgrade — a version of its own follows, and its home is
`tools/srs_grounds.py`. This decision does not stand in the way of that; it
removes a copy, and takes no position on a delivery that does not exist.
