# Constitution

Standing engineering principles of the SRS-DD framework itself.
Every plan and every diff is checked against them.
Unlike requirements (what the system does) and ADRs (single decisions with their context), articles apply to all work at all times and change only through the amendment procedure in ART-090.
The articles of the method are the framework's and stand in `srs-dd/method.md` as `SRS-DD-ART-*`, this repository being the first project of its own method; this file holds what the repository decides for itself.

- **Version:** 2.1.0
- **Ratified:** 2026-08-06 — this repository's own constitution, adopted from the skeleton it ships (v1.1.0)
- **Amended:** 2026-10-04 — v2.1.0: ART-110 added, so that a comment stays a line or two and the reasoning behind a decision lives where it can be found and revised rather than in a paragraph above the code (adding an article is MINOR per ART-090)
- **Amended:** 2026-10-01 — v2.0.0: ART-010, ART-020, ART-030, ART-050, ART-060 and ART-100 moved to `srs-dd/method.md` as `SRS-DD-ART-*`; every reference, decisions included, is rewritten, and the release note names the change as incompatible (removing an article is MAJOR per ART-090)
- **Amended:** 2026-09-25 — v1.5.0: ART-100 added, so that keeping credentials, personal data, documents shared in confidence and a machine's raw output out of the repository is a standing principle rather than a habit nobody wrote down (adding an article is MINOR per ART-090)
- **Amended:** 2026-09-25 — v1.4.0: ART-080 added, so that serving any project agents work on — code in any language, documents, diagrams — is a standing principle rather than an intention nobody wrote down; the rule for where an annotation stands had just been designed around the tooling's own language (adding an article is MINOR per ART-090)
- **Amended:** 2026-09-25 — v1.3.0: ART-070 covers everything the installer copies into a project rather than the four things it listed; the standards, the tooling beyond the checker and the viewer, the decision template, the CI templates, the hook and `.gitattributes` were shipped and unnamed (widening an article's reach tightens it, MINOR per ART-090)
- **Amended:** 2026-08-06 — v1.2.0: ART-070 added, so that keeping framework content out of installed projects is a standing principle rather than a note in a guide (adding an article is MINOR per ART-090)

Articles are numbered in steps of 10 and referenced from plans, reviews, and ADRs the same way requirements are: “rejected per ART-040”.
The starting point targets receive is `skeleton/specs/constitution.md`; this file is this repository's own copy, and the two diverge as either side is amended.

## ART-040 — Simplicity

The boring solution wins by default; a clever one must earn its place in an ADR.
A new dependency requires an ADR.
Project tooling stays standard-library only.
Nothing is built for a requirement that does not exist yet.

## ART-070 — Nothing of ours in other people's repositories

What this repository ships — everything the installer copies into a project — carries no content specific to the framework:
no requirement identifiers of ours, no annotations naming them, no paths that exist only here.
A stranger's first install must pass their own checker on the first run.

## ART-080 — Any work an agent does, in any language

The framework serves any project where agents do the work and something must answer for what they made: source code in any programming language, documents, diagrams, configuration, data.
What it asks of a project's files — where a requirement is realized, what verifies it, where an annotation stands — holds for every kind of them.
The tooling is written in Python, which makes Python the tooling's language, not the projects'.
A rule designed around one kind of file or one language, with the others served by a fallback, is rejected; where a tool reads one kind more closely, it reproduces the rule's meaning more precisely and never changes it.

## ART-110 — Comments are minimal

A comment carries what the code cannot, in a line or two.
A comment that needs a paragraph says the decision under it is not obvious: the decision is re-examined first, and whatever reasoning survives goes to `specs/adr/` or `arch/`, with the comment pointing at it in a clause.
A docstring is a comment.

## ART-090 — Amendments

The constitution changes only by a dedicated commit that bumps the version:
MAJOR — an article is removed, reversed, or relaxed; MINOR — an article is added or tightened; PATCH — wording changes without a change of meaning.
The commit message states the reason.
The project maintainer ratifies the amendment.
