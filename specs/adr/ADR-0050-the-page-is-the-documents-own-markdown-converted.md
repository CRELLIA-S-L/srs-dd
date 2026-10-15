# ADR-0050 — The page is the document's own markdown, converted

- **Status:** accepted
- **Date:** 2026-10-06
- **Related requirements:** FR-ARCH-520

## Context and problem statement

`FR-ARCH-520` asks for the architecture document as a page carrying the same sections as its markdown form, and `FR-ARCH-420` to `FR-ARCH-460` specify those sections without naming a form.
Two forms of one document can drift: a section added to one and forgotten in the other is a document that says different things to two readers, and nothing in the specification would report it.

## Considered options

1. Convert the markdown the document already produces, over the grammar this generator emits.
2. Two renderers over one data layer: the gathering functions stay shared, each form writes its own headings, lists and paragraphs.
3. A document model — sections holding typed blocks — rendered to markdown and to HTML.
4. Convert at publication time with a third-party markdown tool.

## Decision outcome

Option 1.

"The same sections" is then true by construction rather than by two renderers kept in agreement: the page is the document, with its markup translated.
The grammar is closed because this file writes it — three heading levels, two levels of list, paragraphs, three inline spans and one fenced block — so the converter is a translator over a known input and not a markdown parser over an unknown one.

Option 2 doubles every section and makes the agreement a matter of discipline; option 3 buys that agreement at the price of a block model for a document of five sections; option 4 was refused before it was weighed, because nothing is installed to run this framework (`NFR-SPEC-010`) and a page rendered by a tool only CI has is a page nobody can reproduce locally.

### How it works

The markdown is read line by line. A fence opens the drawing's box, a `#`-prefixed line becomes a heading of the same level, a `- ` line becomes an item — with two spaces of indent putting it inside the item above, which is where a nested list belongs — a blank line closes what is open, and anything else joins the current paragraph.
Inline, three spans are translated and nothing else: `**bold**`, `` `code` `` and `_emphasis_`, the last only at a word boundary so that a path like `srs_arch_doc.py` outside backticks is not read as emphasis.
Everything else is escaped as text, so a record that contains a `<` cannot reach the page as markup.

The converter must not grow into a markdown parser. A new shape in the document — a table, a quote, a link — is a line in the converter and a fixture in the suite, added with the shape.

### Consequences

The suite compares the two forms rather than asserting the page's text twice: every heading of the markdown must be a heading of the page, which is what makes a section added later arrive in both without the fixture naming it.
A page that a browser would have to repair is caught by a parse of the output, including the one mistake this converter made first — a nested list beside its item instead of inside it.

The register's dashboard takes the same decision and a translator of its own, not a shared one: the two layers are installed one without the other, so neither may reach into the other's tools. The copies are not duplicates — each handles the grammar its own document writes, which is lists and one fenced block here and tables there.
