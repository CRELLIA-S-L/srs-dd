# Hypotheses: who keeps the register

`H-NNN` — claims about whether the division of labour this project is built on survives contact with the people it names.
Product managers keep `grounds/`, engineers keep `specs/`, and a bet joins the two; none of that has been observed anywhere yet.

### H-010 — Product managers keep the register themselves

```yaml
status: untested
class: III
population: product managers given write access to a grounds register
refuted_if: proportion < 0.50 at n >= 8
expires: 2027-08-23
owner: @crellia_admin
impact: the whole product-manager half of the plan; nothing else drives it
```

At least half of the product managers given write access to a grounds register add an entry of their own within a month.

**Rationale.** The whole product-manager side of the plan assumes this and nothing has ever tested it.
Class III because nothing instruments it: the answer comes from looking at who wrote what, which is a person reading a history rather than a number arriving on its own.

The magnitude and the threshold are the same number here, and that is deliberate rather than an oversight: there is no size this is being built for beyond the line below which it is false.
Half of them keeping it is the point; fewer than half and the division of labour is somebody's idea rather than how the work goes.

### H-020 — Git mechanics is what stops them

```yaml
status: untested
class: III
population: abandoned attempts by product managers to edit a register entry
refuted_if: proportion < 0.30 at n >= 20
expires: 2027-08-23
owner: @crellia_admin
impact: whether hiding version control is worth building at all
```

When a product manager abandons an edit to the register, it is a git operation that stopped them at least three times in ten.

**Rationale.** That they stumble is already observed on a live team, so this does not ask whether — it asks what the stumble is made of.
Class III: it comes from watching an abandoned attempt and asking what happened.

Second, and only worth measuring if H-010 says there is anything to keep:
twenty abandoned attempts cost far more to observe than eight people's first month, and what to build depends on the cheaper answer first.
