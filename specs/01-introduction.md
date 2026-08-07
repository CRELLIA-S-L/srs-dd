# 1. Introduction

## Purpose

SRS-DD is a standard and a small set of scripts that make a software
requirements specification the source of truth for what a codebase does, in
repositories written with the help of AI coding agents.

This document specifies the framework itself: the checker, the viewer, the
installer, the agent procedures, and the gates. A project that adopts SRS-DD
writes its own specification; this one describes what it adopts.

## Scope

In scope: the behavior of `tools/srs_check.py`, `tools/srs_view.py`,
`tools/srs_init.py`, the procedures in `.claude/skills/`, the CI templates
in `ci/`, this repository's own pipeline, and the properties of the
specification format that they collectively guarantee.

Out of scope: the content of any target project's specification, the
editors and agents that read the guides, and the forges the repository is
hosted on.

## Boundaries

The tooling reads and writes plain files in a git working tree. It runs no
server, stores nothing outside the repository, and makes no network calls.
It knows no natural language: which words carry binding force is
configuration, not code.

## Audience

Maintainers of the framework, and anyone deciding whether to adopt it who
wants to read what it actually guarantees rather than what its README claims.
