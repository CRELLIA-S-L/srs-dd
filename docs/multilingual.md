# Specifications in any language

The tooling knows no natural language. The checker enforces exactly one
bolded modal verb per statement — but *which* words are modal verbs, which
are negations, and which mark a rationale, it reads from your project's
lexicon in `specs/srs-config.json`:

```json
{
  "modal_verbs": ["shall", "must", "should", "may"],
  "negation_words": ["not"],
  "rationale_markers": ["Rationale"]
}
```

Replace those three lists and the whole standard — statements, statuses,
the traceability matrix, the rendered page — works in your language. Nothing
else in the tooling changes, because nothing else ever looked at the words.

> The framework's own documentation is English-only by policy; this page is
> a deliberate exception, since a demonstration is the point.

## Example: a specification in Russian

`specs/srs-config.json`:

```json
{
  "areas": ["CORE", "UI", "DATA"],
  "code_roots": ["src"],
  "test_roots": ["tests"],
  "code_extensions": [".swift"],
  "modal_verbs": ["должен", "должна", "должно", "должны"],
  "negation_words": ["не"],
  "rationale_markers": ["Обоснование"]
}
```

`specs/10-fr-core.md`:

````markdown
### FR-CORE-010 — Приветствие при первом запуске

```yaml
status: implemented
verification: T
derives_from: []
depends_on: []
code: [src/App.swift]
tests: [tests/AppTests.swift]
```

Когда приложение запускается впервые, система **должна** показать
приветствие с названием продукта.

**Обоснование.** Первый экран объясняет, куда пользователь попал; без него
пустое окно выглядит как сбой запуска.
````

The checker validates this exactly as it validates English: one bolded verb
from the lexicon, a rationale recognised by its marker, links that resolve,
`code` and `tests` paths that exist.

## Getting the lexicon right

Two ways:

- Pass the word lists to the installer yourself:

  ```
  python3 tools/srs_init.py path/to/project \
      --modal-verbs "должен,должна,должно,должны" \
      --negation-words "не" \
      --rationale-markers "Обоснование"
  ```

- Or open a coding agent in a framework clone and ask it to initialize your
  project. The `srs-init` skill generates the lexicon for any language and
  asks you to confirm it before writing anything — the words carry binding
  force, so that decision stays with the maintainer.

Grammatical forms matter: a language that inflects its modal verb needs
every form you intend to write in the list, and it is worth recording in
`specs/00-glossary.md` which form carries which force.

## Adopting an existing non-English specification

The installer's adopt mode infers nothing on its own, but the `srs-init`
skill reads one or two of your existing requirement files, proposes the
lexicon it sees, and asks you to confirm. Validation then runs against your
whole specification **before** anything is written: if the proposed lexicon
does not fit, the installer exits 3 and your repository is byte-identical.
