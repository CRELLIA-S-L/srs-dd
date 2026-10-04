# Constitution

Standing engineering principles of the project.
Every plan and every diff is checked against them.
Unlike requirements (what the system does) and ADRs (single decisions with their context), articles apply to all work at all times and change only through the amendment procedure in ART-020.
The articles of the method — the hierarchy of truth, requirement before code, the boundaries of an agent's autonomy, testing discipline, quality gates, nothing sensitive in the repository — are the framework's and stand in `srs-dd/method.md` as `SRS-DD-ART-*`; this file holds what the project decides for itself.

- **Version:** 3.0.0
- **Ratified:** 2026-08-05
- **Amended:** 2026-10-02 — v3.0.0: the two remaining articles renumbered from ART-040 and ART-090 to ART-010 and ART-020, so that a project's set starts at the first number instead of at the gap the method's articles left; no article's text changed, but neither old number resolves here any more, which this log has called a removal before (MAJOR per ART-020)
- **Amended:** 2026-09-25 — v1.2.0: an article on keeping nothing sensitive in the repository added, then one of the six that moved (adding an article is MINOR per ART-020)
- **Amended:** 2026-08-05 — v1.1.0: the article on requirement before code tightened to approved requirements, then one of the six that moved; the amendment taxonomy extended to classify tightening and relaxing (both changes MINOR per ART-020)

Articles are numbered in steps of 10 and referenced from plans, reviews, and ADRs the same way requirements are: “rejected per ART-010”.
The set below is a starting point — adapt the articles to your project, but keep the amendment procedure. Numbers are the project's: the framework never adds an article here.

## ART-010 — Simplicity

The boring solution wins by default; a clever one must earn its place in an ADR.
A new dependency requires an ADR.
Nothing is built for a requirement that does not exist yet.

## ART-020 — Amendments

The constitution changes only by a dedicated commit that bumps the version:
MAJOR — an article is removed, reversed, or relaxed; MINOR — an article is added or tightened; PATCH — wording changes without a change of meaning.
The commit message states the reason.
The project maintainer ratifies the amendment.
