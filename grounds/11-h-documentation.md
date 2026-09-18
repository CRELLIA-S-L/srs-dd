# Hypotheses — documentation

What the specification's own documentation is expected to do once it is described the way the code is.

### H-030 — Specified documents stay current

```yaml
status: assumed
class: II
population: documents of this repository that a requirement names — the landing page and docs/
refuted_if: count > 1 at n >= 4
expires: 2026-12-18
owner: @crellia_admin
impact: the landing page as the one document read before anything is cloned; the cost of a stale claim there is a reader who found it first
```

Once a document is named by a requirement that says what it must answer and a test that holds its commands to the tools, a claim it made that a release shipped stale is corrected after that release at most once in the next four releases.

**Rationale.** The claim that prompted this is on record: `docs/upgrade.md` said the architecture layer had one setting for the whole of 0.17.0 while it had two, and the sentence was found by accident while a different proposal was being read.
Nothing described the documentation, so nothing noticed.
No frame refuses the claim: this register holds no frames, which `specs/91-open-issues.md` records under the four kinds it lacks, so the step is walked and finds nothing to walk against.

The action is a correction, not an opinion about freshness: a commit after a release that changes a sentence the release already shipped, where the sentence was wrong at the time of shipping rather than made wrong by the change beside it.
Class II rather than I, because the number does not arrive on its own — the commits to `README.md` and `docs/` between two tags are a list `git log` prints, but sorting a correction of a stale claim from an extension takes a person reading the diff, once per release.

The magnitude and the threshold are the same number, as they are for H-010: there is no size this is being built for beyond the line below which it is false.
One correction in four releases is the noise of writing; more than one is the drift returning through a door the requirement was supposed to close.

Three months and four releases rather than a year, because a claim about a habit is settled in the first few repetitions or not at all, and a term long enough to forget the question is a term that expires unmeasured.

The second half of what the maintainer said — that a specified landing page makes the framework more attractive — is not written here.
It is a claim about adoptions, and there is nothing to count them with and no base to compare against; a threshold for it today would be invented, and the register's rule is that nobody writes one on somebody's behalf.
It is worth measuring, and saying so is not recording it.
