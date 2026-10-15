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

### S-090 — The record as it is written

```yaml
status: built
inside: E-010
requirements: [FR-CHK-110, IF-SPEC-010, IF-SPEC-040, INV-SPEC-080]
names: [Entry, parse_entries, split_fields, fence_len, closer_len, skip_fence, NUMBER, AREA, RE_NUMBER_TAIL, RE_ANY_HEADING, RE_FENCE, RE_FENCE_OPEN, RE_FENCE_CLOSE, RE_FENCE_BARE]
owns: [NUMBER, AREA]
```

A heading, a fenced block of fields and the prose after it, read off the text of a file and nothing more.

**Rationale.** The one form of this part that both layers and four other commands go through, which is why it is a file of its own rather than a function inside the checker; the grammar of a number and of an area name live here because every record of every layer is matched against them.

### S-100 — The order identifiers are read in

```yaml
status: built
inside: E-010
requirements: [INV-SPEC-090]
names: [id_key]
```

One identifier turned into what sorts it: its prefix, then its number compared as a number.

**Rationale.** A form of one function, because the alternative is each tool sorting its own way and `1000` landing after `100` in some listings and not others; it is named by every tool of the framework and owns nothing.

### S-110 — The vocabulary, and what a rule costs

```yaml
status: built
inside: E-010
requirements: [FR-CHK-090, FR-CHK-100, FR-CHK-160, FR-CHK-300, IF-SPEC-020, INV-SPEC-010]
names: [load_config, _config_fail, rule_finding, _alternation, _modal_pattern, DEFAULTS, CFG, AREAS, CODE_ROOTS, TEST_ROOTS, CODE_EXTENSIONS, RULE_SEVERITY, TYPES, STATUSES, CANCELLED, VERIFICATIONS, LINK_FIELDS, LIST_FIELDS, SCALAR_FIELDS, KNOWN_FIELDS, REQUIRED_FIELDS, RETIRED_FIELDS, RULES, SEVERITIES, DEFAULT_SEVERITY, RE_AREA_NAME, RE_ID, RE_HEADING, RE_MODAL, RE_RATIONALE]
owns: [DEFAULTS, CFG, RULES, SEVERITIES, DEFAULT_SEVERITY, RETIRED_FIELDS]
```

What words a block may use, where they come from, and what each rule costs the project that broke it.

**Rationale.** The project's configuration and the checker's own vocabulary are one form because the second is built out of the first: the areas, the modal verbs and the negations come from the lexicon, and the patterns matched against a statement are compiled from them at import.

### S-120 — A requirement as the checker holds it

```yaml
status: built
inside: E-010
requirements: [FR-CHK-170, FR-CHK-180, FR-CHK-250, FR-CHK-260]
names: [Requirement, parse_text, parse_file, _split_body, normalize_meta, collect_spec_files, file_range_of, SKIP_FILES, SKIP_DIRS, RE_RANGE_NAME, RE_MAP_NAME]
owns: [SKIP_FILES, SKIP_DIRS]
holds: [S-090]
```

One requirement with its fields normalized, its place in the specification known, and the files it was read from decided.

**Rationale.** Holds the record grammar rather than restating it: what a requirement adds to an entry is the meaning of its fields and the range of numbers its file may hold.

### S-130 — The rules over the whole set

```yaml
status: built
inside: E-010
requirements: [FR-CHK-010, FR-CHK-020, FR-CHK-030, FR-CHK-040, FR-CHK-050, FR-CHK-060, FR-CHK-070, FR-CHK-075, FR-CHK-140, FR-CHK-150, FR-CHK-190, FR-CHK-240, INV-SPEC-050]
names: [validate, find_cycles, CYCLE_FIELDS, DEPENDENCY_FIELDS]
owns: [CYCLE_FIELDS, DEPENDENCY_FIELDS]
```

Every rule that needs more than one requirement to decide: the links, the cycles, the lifecycle and what rests on what.

**Rationale.** One form and not one per rule, because what they share is the set they are decided over — a rule here is a paragraph, and a record for each would say nothing the function did not.

### S-140 — What the code says back

```yaml
status: built
inside: E-010
requirements: [FR-CHK-055, FR-CHK-080, FR-CHK-200, FR-CHK-210, FR-CHK-270, FR-CHK-280, FR-CHK-290]
names: [annotation_regions, _scan_marks, _match_ends, _fill_regions, read_annotations, read_lines, scan_annotations, check_pairing, check_unclaimed, iter_source_files, collect_code_files, RE_ANNOTATION, RE_END, RE_FILE_SCOPE, RE_CODE_BEFORE, REGION_BOUND, _ANNOT_ID]
owns: [REGION_BOUND, _ANNOT_ID]
```

The other half of the two-way check: the claims the files make about themselves, the region each claim covers, and the two directions in which a claim and a field can disagree.

**Rationale.** A boundary somebody could cross without noticing: how far a claim reaches is decided here and nowhere else, and a second reading of a marker anywhere in the part would give two answers about the same line.

### S-150 — The baselines the log and the tags may disagree about

```yaml
status: built
inside: E-010
requirements: [CON-SPEC-030, FR-CHK-130, FR-CHK-220]
names: [check_baselines]
```

What the baseline log records against what the repository's tags hold, and what to say when the history cannot be read at all.

**Rationale.** The only form of this part that goes outside the files it was given, which is the reason it is one: a run on a shallow clone or an archive has to say the history was unread rather than report a missing entry.

### S-160 — The matrix

```yaml
status: built
inside: E-010
requirements: [CON-SPEC-010, FR-CHK-230, INV-SPEC-020]
names: [build_traceability, _cell, TRACE]
owns: [TRACE]
```

The one file this part writes: every link in one direction, the incoming ones computed, and the counts taken from the same set the rules were decided over.

**Rationale.** Separate from the rules because it is the only form here that writes anything, and because the reverse direction of every link exists here and nowhere in the records.

### S-170 — The command

```yaml
status: built
inside: E-010
requirements: [FR-CHK-120, IF-CI-020]
names: [main]
```

What a run is worth to whatever called it: the flags, the order of the readings, and the exit code.

**Rationale.** A form of its own because the exit codes are a published interface, and a pipeline reads them and nothing else.

### S-180 — The two modules as files the framework ships

```yaml
status: built
inside: E-010
requirements: [NFR-CHK-010, NFR-SPEC-010]
```

What both files must hold whatever they do: the standard library alone, and a run that stays under a second at five hundred requirements.

**Rationale.** These two obligations are about no symbol in the part; a form holding nothing but them is where they are read, as `S-080` is for the model.
