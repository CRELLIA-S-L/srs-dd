# Constitution

Standing engineering principles of the SRS-DD framework itself.
Every plan and every diff is checked against them.
Unlike requirements (what the system does) and ADRs (single decisions with their context), articles apply to all work at all times and change only through the amendment procedure in ART-090.

- **Version:** 1.5.0
- **Ratified:** 2026-08-06 — this repository's own constitution, adopted from the skeleton it ships (v1.1.0)
- **Amended:** 2026-09-25 — v1.5.0: ART-100 added, so that keeping credentials, personal data, documents shared in confidence and a machine's raw output out of the repository is a standing principle rather than a habit nobody wrote down (adding an article is MINOR per ART-090)
- **Amended:** 2026-09-25 — v1.4.0: ART-080 added, so that serving any project agents work on — code in any language, documents, diagrams — is a standing principle rather than an intention nobody wrote down; the rule for where an annotation stands had just been designed around the tooling's own language (adding an article is MINOR per ART-090)
- **Amended:** 2026-09-25 — v1.3.0: ART-070 covers everything the installer copies into a project rather than the four things it listed; the standards, the tooling beyond the checker and the viewer, the decision template, the CI templates, the hook and `.gitattributes` were shipped and unnamed (widening an article's reach tightens it, MINOR per ART-090)
- **Amended:** 2026-08-06 — v1.2.0: ART-070 added, so that keeping framework content out of installed projects is a standing principle rather than a note in a guide (adding an article is MINOR per ART-090)

Articles are numbered in steps of 10 and referenced from plans, reviews, and ADRs the same way requirements are: “rejected per ART-040”.
The starting point targets receive is `skeleton/specs/constitution.md`; this file is this repository's own copy, and the two diverge as either side is amended.

## ART-010 — Hierarchy of truth

The specification stands above the code; the code stands above all other documentation.
On conflict, neither side is silently fixed: the discrepancy is recorded in `91-open-issues.md` and the maintainer decides which side is wrong.

## ART-020 — Requirement before code

No behavior changes without an **approved** requirement that describes the change — a `draft` is recorded, not approved (see the Lifecycle section of `specs/README.md`).
The mechanics — statuses, numbering, closing the loop — live in `specs/README.md`; this article only makes the principle non-negotiable.

## ART-030 — Boundaries of agent autonomy

Within an established requirement, an agent edits code and specification freely.
Builds, test runs, external network calls, data migrations, and deletion of files it did not create require the user's explicit confirmation — each time, not once per session.

## ART-040 — Simplicity

The boring solution wins by default; a clever one must earn its place in an ADR.
A new dependency requires an ADR.
Project tooling stays standard-library only.
Nothing is built for a requirement that does not exist yet.

## ART-050 — Testing discipline

A requirement with `verification: T` is flipped to `implemented` in the same set of edits that adds its test, and the test path goes into the `tests` field.
Verification by `D`, `I`, or `A` is carried out as described in `50-verification.md`, not by assertion.

## ART-060 — Quality gates

A change merges only when `python3 tools/srs_check.py` passes and, if the change alters behavior, the commit or PR description names the requirement identifiers it implements.

## ART-070 — Nothing of ours in other people's repositories

What this repository ships — everything the installer copies into a project — carries no content specific to the framework:
no requirement identifiers of ours, no annotations naming them, no paths that exist only here.
A stranger's first install must pass their own checker on the first run.

## ART-080 — Any work an agent does, in any language

The framework serves any project where agents do the work and something must answer for what they made: source code in any programming language, documents, diagrams, configuration, data.
What it asks of a project's files — where a requirement is realized, what verifies it, where an annotation stands — holds for every kind of them.
The tooling is written in Python, which makes Python the tooling's language, not the projects'.
A rule designed around one kind of file or one language, with the others served by a fallback, is rejected; where a tool reads one kind more closely, it reproduces the rule's meaning more precisely and never changes it.

## ART-090 — Amendments

The constitution changes only by a dedicated commit that bumps the version:
MAJOR — an article is removed, reversed, or relaxed; MINOR — an article is added or tightened; PATCH — wording changes without a change of meaning.
The commit message states the reason.
The project maintainer ratifies the amendment.

## ART-100 — Nothing sensitive in the repository

What the repository holds is read by everyone who can clone it, for as long as its history lives, and a commit that deletes a file does not remove it from that history.
No credentials, keys, tokens or connection strings; no personal data beyond what its authors chose to publish; no document shared in confidence or not released by its owner; no raw output of one machine or one session that carries its paths, names or environment — traces, logs, local configuration.
A file that must stay on one machine is named in `.gitignore` before it is written, and what is untracked is looked at before anything is staged, so that no sweep takes a file nobody read.
Where something sensitive was committed, it is revoked or withdrawn first and the history rewritten second: deleting it in a new commit is not removal.
