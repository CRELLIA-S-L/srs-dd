# ADR-0033 — A skipped file is compared with what ships, the marker's version aside

- **Status:** accepted
- **Date:** 2026-09-24
- **Related requirements:** FR-INIT-240, FR-INIT-060, FR-INIT-190

## Context and problem statement

`FR-INIT-240` has the installer tell, for each precious file it skipped, whether that file differs from what this version ships.
Every file the installer writes that carries the marker carries it as `SRS-DD-<version>`, stamped on the way out (`FR-INIT-190`), so a copy installed by 0.19.0 and the same text shipped by 0.20.0 differ in exactly that string.

## Considered options

1. Compare the marker's version with the framework's: older means "may have changed".
2. Ship a manifest of the hashes each release wrote, and compare the target's file with the hash of the version that installed it.
3. Compare the target's file with what this version would write, byte for byte after the marker's version is replaced by its token on both sides.

## Decision outcome

Option 3.
Option 1 answers the question of every skipped file with "yes" after any release, which is the list that could not be read in the first place.
Option 2 tells a framework change from a local edit, which option 3 cannot, at the price of a file every release must write and every clone keep; neither answer changes what the reader does — look at the file before `--force` — so the distinction is not worth the manifest.

### How it works

`Installer.same_as_shipped` reads the target's copy as text, takes the content `put` was about to write — already stamped and with the project's substitutions made, the name and the width line — and replaces every `SRS-DD-<x.y.z>` in both with `SRS-DD-VERSION` before comparing them whole.
It is asked only for a precious file that carries the marker and is being skipped for want of `--force`; a file without the marker keeps the reason "not ours", and a refreshed or created file is never compared.

What it keeps: the verdict depends on the text alone, so running the same upgrade twice gives the same list, and a release that changed nothing in a file reports it the same.
Where it stops working: it cannot say who made a difference, the framework or the project; and a file whose substitutions changed — a project renamed after install — reads as different although only its filled-in lines are.

### Consequences

- The list names what to look at, and a skipped file that matches costs the reader nothing.
- A difference is reported without a diff; the reader opens the file, or the framework's copy, to see it.
