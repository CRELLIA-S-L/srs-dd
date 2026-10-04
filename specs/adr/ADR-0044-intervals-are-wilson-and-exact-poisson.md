# ADR-0044 — A measurement's error is a one-sided Wilson or exact Poisson bound

- **Status:** accepted
- **Date:** 2026-10-04
- **Related requirements:** FR-GND-150, FR-GND-490

## Context and problem statement

A bet names a threshold and a measurement comes in against it, and whether the measurement refutes the hypothesis is a question about error: 47 of 500 is not the same evidence as 4 of 5.
`FR-GND-150` makes the checker compel a verdict where the arithmetic can, and `FR-GND-490` lets the project choose how much error it allows for.
Which interval that arithmetic uses was decided in 2026 and recorded nowhere: the reasoning stood in four comments inside `srs-dd/tools/srs_grounds.py`, where a reader deciding whether to keep it could not find it and a reader of the specification could not tell it had been decided at all.
This records what was chosen, so that the next person can weigh it rather than re-derive it.

## Considered options

For a proportion:

1. The normal approximation, `p ± z·sqrt(pq/n)`.
2. Wilson's score interval.
3. Clopper–Pearson, the exact binomial interval.

For a count:

4. The normal approximation, `k ± z·sqrt(k)`.
5. The exact Poisson interval, solved from the distribution.
6. The exact interval up to a crossover and the approximation beyond it.

And for the band itself: two-sided, or one-sided against the threshold.

## Decision outcome

Wilson for a proportion, the exact Poisson interval up to a thousand events and the approximation beyond, one-sided in both cases.
A mean is not compared at all: it is `class I`, closed by a person.

**The normal approximation fails where thresholds are drawn.**
A proportion's threshold in a register of product hypotheses sits near nought or near one — "fewer than 2% abandon", "over 95% succeed" — and that is exactly where `p ± z·sqrt(pq/n)` runs off the end of [0, 1] and reports a bound no proportion can have.
For counts it is worse: at nought observations it gives a bound of nought, which reads as certainty from the one measurement that carries none.

**Clopper–Pearson was not worth its conservatism.**
It is exact for the binomial, and it is wider than Wilson at every n, so a measurement that refutes under Wilson may be undecided under it.
The register's purpose is to force a verdict where one is compelled, and the interval that is right on average serves that better than the one that is never wrong but often silent.

**The crossover is where the two methods agree.**
The exact Poisson interval costs a term per event counted, so a register recording millions of events would wait half a minute for what a square root answers at once.
Beyond a thousand events the normal approximation is within two tenths of a percent of the exact bound, so the seam is invisible in any message either produces.

**One-sided, because a threshold asks one question.**
The hypothesis says the truth is past a line; whether it also sits inside a band is a question nobody wrote.
A two-sided quantile would demand more of a measurement than its author's sentence does, and would refuse verdicts the sentence compels.

**A mean carries no error the row can produce.**
Its interval needs the spread behind it, and a row holds the mean and the sample size, so a mean closes `class I` rather than falling back to a comparison that refutes on noise.

### Consequences

The project chooses the confidence from three named levels (`FR-GND-490`) rather than typing a number: 0.973 came from nowhere and cannot be discussed.
A proportion or a count is compared; a mean, a duration or anything else is a reading a person signs.
Changing the interval changes verdicts already recorded, so a future change is a decision of its own and names this one.
