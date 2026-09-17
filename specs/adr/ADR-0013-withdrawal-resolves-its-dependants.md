# ADR-0013 — Withdrawing a requirement resolves what depends on it

- **Status:** accepted
- **Date:** 2026-08-12
- **Related requirements:** INV-SPEC-050

## Context and problem statement

INV-SPEC-050 gives a cancelled requirement somewhere to go when nothing replaces it.
It says where such a requirement is recorded and nothing about what was pointing at it, and a requirement worth withdrawing is rarely one that stands alone.

The four link fields are not one relation.
`depends_on` says the dependant is meaningless without its target; `derives_from` says the dependant exists because the target does; `refines` says the dependant is the same thing made precise for one branch; `conflicts_with` says the dependant diverges from the target on purpose.
Withdraw the target and each of those breaks differently — the first leaves a requirement with no meaning, the second one with no reason, the third a special case of nothing, and the fourth a divergence from something that is no longer there, which costs nothing at all.

Nothing computes this today.
`srs_view.py <ID>` resolves incoming links one level deep across every field, which is half the answer; `--tree` walks `derives_from` and `refines` only, so the field that matters most for a withdrawal is the one it does not follow — FR-VIEW-060 prints as a bare root while the matrix records fourteen requirements depending on it.

The question this settles is not whether a dangling reference is an error.
It is what happens at the moment somebody decides to withdraw.

## Considered options

1. A checker rule alone: a live requirement pointing at a `withdrawn` one is a finding, and the maintainer works out the rest.
2. A procedure alone: the authoring skills resolve the dependants and require a resolution before the status is set.
3. Both, with the closure shown one level at a time and the resolutions enumerated.
4. Refuse the withdrawal while anything points at the requirement.

## Decision outcome

Option 3.

A rule guards the result and a procedure guards the act, and neither substitutes for the other.
A rule alone reports the corner after somebody has painted themselves into it, with no account of which of the four relations broke or what to do about it.
A procedure alone is bypassed by anyone who edits the file directly, and the format exists to make that possible: markdown a review tool diffs line by line, with nothing between the author and the file (NFR-SPEC-020).
The `FR-SKILL-*` requirements bind what a procedure does when one is run; none of them compels running one.
The gate here has always been the checker.

Option 4 is rejected outright.
Forbidding withdrawal while dependants exist makes a tree impossible to dismantle from the top, and the only remaining move is to leave the requirement where it was: `deferred`, reading as a live promise.
That is precisely the state INV-SPEC-050 exists to end, and a rule that reinstates it defeats the status it is meant to protect.

**The display is one level plus a count.** Direct incoming links are shown in full, grouped by field, because those are what a decision applies to.
The transitive remainder is a number and a depth, not a listing.
This is not a concession to screen space: every resolution below acts on direct dependants, and each resolution may itself be a withdrawal with a tree of its own.
A closure is never decided at once — it is decided recursively, one level per decision, and a display that showed it whole would invite the opposite.

**The resolutions the procedure offers**, none of which is a default:

- *Do not withdraw.*
  Always available, and the honest answer when the tree is large and no one has time to dismantle it.
- *Narrow instead.*
  Reword the requirement to cover only what is still wanted.
  Nothing is replaced and nothing is cancelled; the dependants keep their ground.
- *Supersede instead.*
  The need survives and the shape changed.
  Dependants re-point at the successor, and `superseded` already covers it — this case never needed a new status.
- *Cascade.*
  Withdraw the dependants too, where the branch died with its root.
  Each is a withdrawal in its own right and goes through this same procedure.
- *Re-parent.*
  Point the dependants at another requirement carrying the same ground.
  The cheapest resolution where the withdrawn requirement was a middleman.
- *Promote.*
  Drop the link and let the dependant stand alone, rewording it where it leaned on its parent's words.
  Mostly a `refines` answer: a special case can usually survive the general rule it sharpened.
- *Orphan deliberately.*
  The dependant outlives its target because the link recorded provenance rather than necessity.
  Permitted, and required to be said rather than left silent.
- *Stage it.*
  Where the tree is large the withdrawal is a migration:
  record the intent, resolve the dependants, withdraw last.
  A cascade abandoned halfway is worse than one never started.

`conflicts_with` is exempt.
A divergence from a withdrawn requirement is merely beside the point, and reporting it would leave every deliberate trade-off outliving its subject as noise.

### Consequences

- The checker gains a rule name.
  Names are a published contract with a one-way property (ADR-0009): adding one is compatible, so it can ship in the same release as the status.
- The viewer needs a closure over all four link fields.
  `--tree` today answers a different question and should keep answering it; this is a new query, not a widened one.
- The procedure lives in the skills, so a specification edited by hand reaches the same corner unguided.
  That is the whole reason the rule is also required, and the reason the rule must name which relation broke rather than only that one did.
- Withdrawing a subtree of N requirements is N withdrawals, each with its own dialog.
  This is deliberate — a cascade that took one confirmation for a whole branch would be the fastest way to lose a specification — but it makes staging the expected answer for anything large, and the procedure has to say so rather than let somebody discover it at the fortieth confirmation.
- Two requirements remain to be authored: the rule, and the procedure.
  This decision binds their shape and neither is written yet.
