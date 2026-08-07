# ADR-0002 — The traceability matrix is committed, not generated on demand

- **Status:** accepted
- **Date:** 2026-08-05
- **Related requirements:** CON-SPEC-010, FR-CI-010

## Context and problem statement

The matrix — requirement → code → verification, and the reverse — is derived
data: everything in it comes from the requirement files. Derived data in
version control is normally a smell, and it guarantees a class of merge
conflicts.

But the matrix is also the artifact a reviewer reads to see what a change did
to the coverage, and a reviewer reads a diff, not a build output.

## Considered options

1. Generate on demand; keep it out of the repository.
2. Commit it and trust people to regenerate.
3. Commit it and make staleness a build failure.

## Decision outcome

Option 3. `specs/90-traceability.md` is committed, CI regenerates it and
compares byte-for-byte, and the same comparison runs in the pre-commit hook
so the failure arrives before the push rather than after it.

### Consequences

- A change that alters coverage shows that in its own diff — which is the
  whole point, and is impossible with option 1.
- The file conflicts on merge. The resolution is mechanical: regenerate.
- Line endings matter, so `.gitattributes` pins the file to LF; without that,
  `core.autocrlf` on Windows turns the freshness gate permanently red.
- The generator is the checker alone. The viewer, which reads the same data,
  writes nothing into `specs/` — two writers would mean two truths.
