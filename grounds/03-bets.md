# Bets

`B-NNN` — which requirement rests on which hypotheses.
The join lives here and only here: a requirement never says what it stands on, so the register says what stands on it, and the other direction is computed.

`all_of` is a chain — refute any one and the ground is gone.
`any_of` is a set of alternatives, and the strongest carries the requirement.
Two independent sets of alternatives are two bets naming the same requirement, and the checker asks whether that was deliberate.

### B-010 — The cut into ten sections rests on documents staying current

```yaml
status: active
requirement: FR-DOC-010
all_of: [H-030]
```

The sections are worth naming as a decision only if a page cut by decision drifts less than one cut by habit.

### B-020 — The command check is the instrument

```yaml
status: active
requirement: FR-DOC-020
all_of: [H-030]
instrument: yes
```

The test that holds every documented command to its tool is what makes the corrections countable: a stale command fails the gate before a release rather than being found after one, and what remains to count after a release is what the test cannot read.

### B-030 — The opening

```yaml
status: active
requirement: FR-DOC-030
all_of: [H-030]
```

What the first screen owes a stranger is worth writing down only if a described opening stays true longer than an undescribed one.

### B-040 — The problem section

```yaml
status: active
requirement: FR-DOC-040
all_of: [H-030]
```

Same ground as the opening: the section is a restatement, and the claim is that a restatement with a requirement behind it is corrected before a release rather than after.

### B-050 — The requirement section

```yaml
status: active
requirement: FR-DOC-050
all_of: [H-030]
```

The example and the two lists of what the checker does are the page's most copied lines, and the bet is that binding them to rules keeps them current.

### B-060 — The benefits section

```yaml
status: active
requirement: FR-DOC-060
all_of: [H-030]
```

A benefits list drifts fastest; the bet is that one entry per requirement drifts slower than one entry per wish.

### B-070 — The grounds section

```yaml
status: active
requirement: FR-DOC-070
all_of: [H-030]
```

The layers are described in their own specification's terms; the bet is that this keeps the description current as the layers move.

### B-080 — The install section

```yaml
status: active
requirement: FR-DOC-080
all_of: [H-030]
```

The commands and the installer's questions are what a person copies; the bet is that a section standing on the installer's requirements is corrected when they change.

### B-090 — The agent section

```yaml
status: active
requirement: FR-DOC-090
all_of: [H-030]
```

The entry point, the codes and the two decisions are what an agent acts on; the bet is the same as for the install section.

### B-100 — The skills table

```yaml
status: active
requirement: FR-DOC-100
all_of: [H-030]
```

The table's prose about each procedure stands on the procedure's requirement; the names are held by an instrument of their own.

### B-110 — The loop section

```yaml
status: active
requirement: FR-DOC-110
all_of: [H-030]
```

Five steps restated from the installed guide; the bet is that saying so keeps the two copies the same.

### B-120 — The reading section

```yaml
status: active
requirement: FR-DOC-120
all_of: [H-030]
```

One line per question the viewer answers; the flags are held by an instrument, the questions by this.

### B-130 — The map section

```yaml
status: active
requirement: FR-DOC-130
all_of: [H-030]
```

What each path is stands on this; which paths there are is held by an instrument.

### B-140 — The headings instrument

```yaml
status: active
requirement: FR-DOC-140
all_of: [H-030]
instrument: yes
```

Holds the sections to the decision; what it fails on is counted as a correction the gate caught rather than a reader.

### B-150 — The example instrument

```yaml
status: active
requirement: FR-DOC-150
all_of: [H-030]
instrument: yes
```

Holds the example to the checker.

### B-160 — The skills instrument

```yaml
status: active
requirement: FR-DOC-160
all_of: [H-030]
instrument: yes
```

Holds the table's names to the installer's list; it found the tenth procedure missing on its first run.

### B-170 — The map instrument

```yaml
status: active
requirement: FR-DOC-170
all_of: [H-030]
instrument: yes
```

Holds the map to the top level; it found five paths without a row on its first run.

### B-180 — The exit-codes instrument

```yaml
status: active
requirement: FR-DOC-180
all_of: [H-030]
instrument: yes
```

Holds the page's codes to the installer's usage text.

### B-190 — The links instrument

```yaml
status: active
requirement: FR-DOC-190
all_of: [H-030]
instrument: yes
```

Holds every relative link in the page and in docs/ to a file that exists.

### B-200 — Re-reading a section when its requirement moves

```yaml
status: active
requirement: FR-DOC-200
all_of: [H-030]
```

The one currency rule no instrument reaches, and the bet the whole hypothesis turns on: whether a section that names what it restates is re-read when that moves.

### B-210 — The picture instrument

```yaml
status: active
requirement: FR-DOC-210
all_of: [H-030]
instrument: yes
```

Holds the image the page shows to the file the pipeline publishes; the picture itself is regenerated at every deploy, which is the whole point of not keeping one.

