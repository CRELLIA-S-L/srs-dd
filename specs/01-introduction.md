# 1. Introduction

## Purpose

SRS-DD is a standard and a small set of scripts that make a software requirements specification the source of truth for what a codebase does, in repositories written with the help of AI coding agents.

This document specifies the framework itself: the checker, the viewer, the installer, the agent procedures, and the gates.
A project that adopts SRS-DD writes its own specification; this one describes what it adopts.

## Scope

In scope: the behavior of the tools in `tools/` — the checker, the viewer, the installer and the upgrader, the baseline, dating and release commands, the layers' checkers, the two measurements and the local gate — the procedures in `.claude/skills/`, the CI templates in `ci/`, this repository's own pipeline, the properties of the specification format that they collectively guarantee, and what this repository's own documentation — the landing page and `docs/` — answers and may claim.

Out of scope: the content of any target project's specification, the editors and agents that read the guides, and the forges the repository is hosted on.

## Boundaries

The tooling reads and writes plain files in a git working tree.
It runs no server and stores nothing outside the repository; it reaches the network only where somebody asks it to — the upgrader fetching a framework, and the two measurements asking a model.
It knows no natural language: which words carry binding force is configuration, not code.

## Audience

Maintainers of the framework, and anyone deciding whether to adopt it who wants to read what it actually guarantees rather than what its README claims.
