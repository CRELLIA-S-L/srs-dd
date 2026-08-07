# ADR-0003 — The tooling depends on nothing but the standard library

- **Status:** accepted
- **Date:** 2026-08-05
- **Related requirements:** NFR-SPEC-010

## Context and problem statement

The framework is installed into repositories written in any language:
Swift applications, Go services, TypeScript front-ends. Those projects have
no Python toolchain, no virtualenv, and no interest in acquiring one to
validate a specification.

A YAML library, a markdown parser and a templating engine would each have
made the code shorter.

## Considered options

1. Depend on PyYAML and a template engine; ship a `requirements.txt`.
2. Vendor the dependencies into the repository.
3. Standard library only, and shrink the format until that is comfortable.

## Decision outcome

Option 3. `tools/srs_check.py`, `tools/srs_view.py` and `tools/srs_init.py`
import nothing outside the standard library and run on Python 3.9 or newer.
The metadata format is a restricted YAML subset — flat keys, scalars and
bracketed lists — parsed by hand, precisely so that no YAML library is
needed.

### Consequences

- Installing the framework is copying files. There is no lockfile, no
  supply-chain question, and nothing to audit in somebody's security review.
- The metadata format is poorer than YAML: no nesting, no multi-line values.
  This is a feature for reviewability, and a wall the day something genuinely
  needs structure.
- The HTML page is built by string assembly, which is why it is deterministic
  and why every character that reaches it is escaped by hand.
- A new dependency is not a judgement call: ART-040 of the constitution
  requires an ADR that supersedes this one.
