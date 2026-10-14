# Forms

What the parts are made of inside.
The format is `srs-dd/arch.md`; the map is generated into `90-map.md`.

### S-010 — The model the viewer publishes

```yaml
status: built
inside: E-110
requirements: [FR-VIEW-040, FR-VIEW-210, FR-VIEW-310, FR-VIEW-390, IF-VIEW-010, INV-SPEC-090]
names: [build_model, _requirement_dict, outlived, by_id, load_current, read_repo_url, INCOMING_LABEL]
owns: [INCOMING_LABEL]
holds: [S-040]
```

One reading of the specification as data: every requirement with its fields, the links computed backwards, what outlived a cancellation, and what no requirement names.

**Rationale.** The three readers — the command, the page and both layers through `--json` — cross this form and nothing else, which is the boundary `IF-VIEW-010` publishes.
It holds `S-040` because the documents that state no requirement are a key of the model rather than a second reading beside it.

### S-020 — A query over the model

```yaml
status: built
inside: E-110
requirements: [FR-VIEW-220]
names: [select]
```

What a set of filters selects from the model, over the metadata a requirement carries and over the words it is written in.

**Rationale.** A form of its own because it is the one place that decides what a filter means; a caller that narrows the list itself is how two readers come to disagree about the same words.

### S-030 — What a path and a line answer for

```yaml
status: built
inside: E-110
requirements: [FR-VIEW-020, FR-VIEW-300]
names: [requirements_for_path, requirements_for_line, split_line_spec, line_path, _matches_path]
```

The specification read from the other end: the obligations a file carries, and the obligations of the narrowest annotated region holding a line.

**Rationale.** Separate from the model because it reads the files themselves rather than the model — the annotations in the code are its source, and the model never holds them.

### S-040 — The prose beside the requirements

```yaml
status: built
inside: E-110
requirements: [FR-VIEW-260, FR-VIEW-270, FR-VIEW-280]
names: [collect_documents, collect_prose, grep_prose, PROSE_EXCLUDED, PROSE_EXPECTED]
owns: [PROSE_EXCLUDED, PROSE_EXPECTED]
```

The documents in `specs/` that state no requirement: which of them a reader is offered, which a search reaches, and what a search left out.

**Rationale.** Which documents are prose and which are the specification's own machinery is one decision, and it is the state this form owns: a second list of exclusions somewhere else is a search that reads the matrix.

### S-050 — A decision read from its own file

```yaml
status: built
inside: E-110
requirements: [FR-VIEW-330, IF-SPEC-030]
names: [decisions, RE_ADR_ID, RE_ADR_HEADING, RE_ADR_STATUS]
owns: [RE_ADR_HEADING, RE_ADR_STATUS]
```

A decision as the heading and the status its file carries, so it can be cited by its identifier like a requirement.

**Rationale.** The head of a decision is a format `IF-SPEC-030` publishes, and this form is the only reader of it; the architecture layer resolves a decision by the name of the file and reads nothing inside.

### S-060 — A revision of the specification and its baselines

```yaml
status: built
inside: E-110
requirements: [FR-VIEW-050, FR-VIEW-100, FR-VIEW-120, INV-SPEC-040]
names: [load_revision, logged_baselines, baseline_revision, has_tag, introduces, fingerprint, baseline_snapshots, as_deltas, compute_diff, baseline_row, version_key, versions_in, statement_words, BASELINE_LOG, DIFF_FIELDS]
owns: [BASELINE_LOG, DIFF_FIELDS]
holds: [S-070]
```

The specification as it stood at a revision, which revisions the log calls baselines, and what differs between two of them.

**Rationale.** Which fields count as a difference, and that a statement differs by its words rather than by where its lines end, is one decision used by the command, the page and the baseline row.
It holds `S-070` because every revision it reads goes out through that one call and no other.

### S-070 — Reading without writing

```yaml
status: built
inside: E-110
requirements: [CON-SPEC-030, FR-VIEW-080]
names: [git, ViewError]
```

The one way out of this part to git, which reads and never commits, tags or pushes, and the error a failed read raises.

**Rationale.** A boundary somebody could cross without noticing: a second call to git anywhere in the part is the moment a reading command starts writing history, and the form is where that is visible.

### S-080 — The module as a file the framework ships

```yaml
status: built
inside: E-110
requirements: [FR-INIT-280, NFR-SPEC-010]
```

What the file must carry whatever it does: the notice naming whose the text is, and an import list a target's Python can satisfy on its own.

**Rationale.** These two obligations are about no symbol in the part, and a form holding nothing but them is where they are read; without it they are the two the closure rule reports forever.
No `names`: what carries them is the header and the import list, which are not symbols.
