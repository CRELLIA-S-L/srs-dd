# Baselines

A baseline freezes the specification at a milestone. Each row here is one,
frozen by the commit that added it; a `spec/vX.Y.Z` tag on that commit is an
optional bookmark. The procedure is in the Baselines section of `README.md`.

| Version | Date | Tag | What changed |
|---|---|---|---|
| 0.11.1 | 2026-08-09 | `spec/v0.11.1` | Since 0.11.0: changed FR-VIEW-090. 72 requirements: 72 `implemented`. |
| 0.11.0 | 2026-08-09 | `spec/v0.11.0` | Since 0.10.0: added CON-SPEC-030, FR-SKILL-080, FR-SPEC-010, INV-SPEC-030, INV-SPEC-040; changed FR-CI-070, FR-VIEW-050, FR-VIEW-120. 72 requirements: 72 `implemented`. |
| 0.10.0 | 2026-08-08 | `spec/v0.10.0` | Since 0.9.0: added FR-CI-070, FR-SKILL-070, FR-VIEW-120; changed FR-SKILL-010, FR-VIEW-110. 67 requirements: 67 `implemented`. |
| 0.9.0 | 2026-08-08 | `spec/v0.9.0` | Four requirements added, none removed or reworded: FR-CHK-130 reports a baseline tag this log has no row for, and FR-VIEW-090/100/110 make the page state what it shows, compare any two baselines, and let the graph be explored. 64 requirements, all `implemented`. |
| 0.8.0 | 2026-08-08 | `spec/v0.8.0` | Six requirements added, none removed or reworded: FR-INIT-120…160 and FR-SKILL-060 — a project upgrades itself with one command, records the framework it came from, and is told what to do after an install and what arrived after an upgrade. 60 requirements, all `implemented`. |
| 0.7.2 | 2026-08-08 | `spec/v0.7.2` | No requirement added, removed or reworded since 0.7.1. FR-CI-040 moved from `partial` to `implemented`: the specification is served as a page, so all 54 requirements are realized. |
| 0.7.1 | 2026-08-07 | `spec/v0.7.1` | The first baseline. 54 requirements in six areas — `SPEC`, `CHK`, `VIEW`, `INIT`, `SKILL`, `CI` — harvested from the code and approved on 2026-08-06, of which 53 `implemented` and one `partial`: FR-CI-040, whose page was not served yet. |
