# Constitution

Standing engineering principles of the project.
Every plan and every diff is checked against them.
Unlike requirements (what the system does) and ADRs (single decisions with their context), articles apply to all work at all times and change only through the amendment procedure in ART-090.
The articles of the method — the hierarchy of truth, requirement before code, the boundaries of an agent's autonomy, testing discipline, quality gates, nothing sensitive in the repository — are the framework's and stand in `srs-dd/method.md` as `ART-SRS-*`; this file holds what the project decides for itself.

- **Version:** 2.0.0
- **Ratified:** 2026-08-05
- **Amended:** 2026-10-01 — v2.0.0: ART-010, ART-020, ART-030, ART-050, ART-060 and ART-100 moved to `srs-dd/method.md` as the framework's `ART-SRS-*` (removing an article is MAJOR per ART-090)
- **Amended:** 2026-09-25 — v1.2.0: ART-100 added — nothing sensitive in the repository (adding an article is MINOR per ART-090)
- **Amended:** 2026-08-05 — v1.1.0: ART-020 tightened to approved requirements; ART-090 taxonomy extended to classify tightening and relaxing (both changes MINOR per ART-090)

Articles are numbered in steps of 10 and referenced from plans, reviews, and ADRs the same way requirements are: “rejected per ART-040”.
The set below is a starting point — adapt the articles to your project, but keep the amendment procedure. Numbers are the project's: the framework never adds an article here.

## ART-040 — Simplicity

The boring solution wins by default; a clever one must earn its place in an ADR.
A new dependency requires an ADR.
Project tooling stays standard-library only.
Nothing is built for a requirement that does not exist yet.

## ART-090 — Amendments

The constitution changes only by a dedicated commit that bumps the version:
MAJOR — an article is removed, reversed, or relaxed; MINOR — an article is added or tightened; PATCH — wording changes without a change of meaning.
The commit message states the reason.
The project maintainer ratifies the amendment.
