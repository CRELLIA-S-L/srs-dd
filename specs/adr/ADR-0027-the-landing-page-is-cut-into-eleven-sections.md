# ADR-0027 — The landing page is cut into eleven sections, in the order a stranger's questions arise

- **Status:** accepted
- **Date:** 2026-09-18
- **Related requirements:** FR-DOC-010, FR-DOC-020, FR-DOC-210, FR-DOC-030, FR-DOC-040, FR-DOC-050, FR-DOC-060, FR-DOC-070, FR-DOC-080, FR-DOC-090, FR-DOC-100, FR-DOC-110, FR-DOC-120, FR-DOC-130, FR-DOC-140, FR-DOC-150, FR-DOC-160, FR-DOC-170, FR-DOC-180, FR-DOC-190, FR-DOC-200, IF-SKILL-010

## Context and problem statement

`README.md` is the one document read before anything is cloned: a stranger deciding whether to adopt the framework, an agent handed the repository URL, a maintainer looking for a command.
Until this decision nothing said what it consisted of.
One requirement bound it to carry the agent's entry point, and the rule on line breaks bound it as any markdown; the nine headings it had grown were whatever the last edit left, and a sentence about a tool outlived the tool — `srs_baseline.py` was credited with the viewer's `--diff` for a release, and a count of scripts stood while the scripts were named elsewhere on the same page.

The maintainer asked for the page to be specified as the code is: which sections, why these, in what order, what each owes its reader, and what holds the content to the repository.
The first three of those are a decision, not a behaviour — a page could be cut otherwise and still be a landing page — so they are recorded here, and the requirements stand on this record.

## Considered options

1. **Eleven sections, in the order a reader's questions arise** — an opening that says what the thing is and for whom, *What breaks without it*, *What it looks like*, *A requirement, and what the tooling does with it*, *What you get back*, *Why the thing exists, not only what it does*, *Install*, *Handing this to an agent* with *What you then tell the agent to do* under it, *The loop*, *Reading the specification*, *Where things are*.
2. **A short page** — the opening, *Install*, and a list of links into `docs/` for everything else.
3. **A page that is an index** — one paragraph and a table of every document in the repository, the way a generated site's front page is.

## Decision outcome

Option 1.

**The opening answers three readers in a line each before any section does at length.** A stranger, an adopter and an agent arrive with different first questions — what is this, what would it take to see it, where is my procedure — and a page that makes any of them scroll for the answer has lost that reader; so the opening says in plain words what the thing is before it names a standard, shows a dry run that writes nothing, and points the agent at its section.

**The order is the reader's, not the repository's.** A person arrives not knowing why the thing exists, and is not helped by how to install it; one who has installed it is not helped by being told again what it is for.
The eleven sections walk one path — why, what it looks like, what, what I get, why the register, how to install, how to hand it to an agent, how a day goes, how to read, where things are — and each answers the question the previous one raised.
The picture is the one bend toward the adopter: demonstration before argument, because a reader who has just recognised the problem wants to see the thing, and a forge shows an image where it shows nothing else from elsewhere; the image is the pipeline's, drawn from the specification at every deploy, so that showing it costs nobody a screenshot.
That is what makes the order part of the decision rather than a habit: a section moved breaks the path even when its content is unchanged.

**Option 2 assumes a reader who will follow a link before deciding, and the stranger will not.** The page is read on a forge, in one scroll, by somebody weighing whether to spend an afternoon; what is behind a link is what they decide without.
It would also move the claims about behaviour into `docs/` where the same drift lives with fewer readers, and the drift this decision exists to catch is in what is read most.

**Option 3 describes the repository and not the framework.** An index answers where things are — the tenth section — and nothing before it.

**What the cut is not.** It is not a fact about the system's parts: `E-100` carries the page as a file, and the architecture layer has nothing to say below the file, as it has nothing to say about the functions inside the checker.
The sections are the page's behaviour toward its reader, which is the specification's to state, and this record is why those sections and not others.

**The cut is a hypothesis-shaped decision, and is meant to be measured.** Whether a section earns its place is a claim about readers — that a page with *What breaks without it* first wins more adoptions than one without, that an opening joke does or does not — and the register is where such claims go.
A section is added or removed by a bet on a hypothesis of that kind, the requirement for the section follows, and `FR-DOC-140` — which holds the headings to the list — changes with the decision rather than against it.
Today the eleven sections rest on one hypothesis, `H-030`, that a page so described drifts less than one nobody described; nothing yet measures whether any of them draws a reader, and that is the first measurement worth taking.

## Consequences

Every section carries a requirement saying what it owes the reader and which requirements of the specification it restates, so a change to one of those reaches the section through the incoming links the `srs` procedure already reads as the blast radius (`FR-DOC-200`).
What the page derives from the repository — its headings, its example, its skills, its paths, the installer's exit codes, its commands, its links — is held to the repository by the gate, one instrument per claim, so that the drift this record opens with fails a build rather than waiting for a reader.
The page stays long, and stays one page.
Changing the cut is changing this record first.
