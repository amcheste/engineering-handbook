# Contributing to the Engineering Handbook

This repo **is** the canonical source for branching strategy, commit convention, and release process. So this file is about contributing *to the handbook itself*, not a copy of the rules documented inside it.

For the rules, see:

- [Branching Strategy philosophy](docs/philosophies/branching-strategy.md). The *why*
- [Branching & Releases workflow](docs/workflows/branching-and-releases.md). The *how*

---

## How to contribute

This is a documentation repo, so the contribution model is the same as any other repo I own, just applied to prose instead of code.

1. Branch from `develop`. `docs/<short-topic>` or `chore/<short-topic>` as appropriate.
2. Edit existing chapters when possible; only add a new doc under `docs/` when a topic is substantial enough to stand alone.
3. Commit with [Conventional Commits](https://www.conventionalcommits.org/). Most changes will be `docs:` or `chore:`.
4. Open a PR targeting `develop`.
5. CI (`Lint`, `Commit Lint`) must pass before merging.

## What belongs where

- **Philosophies** (`docs/philosophies/`). Durable *why* content. Principles that justify decisions. Changes slowly.
- **Workflows** (`docs/workflows/`). Concrete *how* content. Steps, commands, tooling. Changes as tools evolve.
- **Tooling** (`docs/tooling/`). What I use and how it fits together. Start at [`docs/tooling/dev-tooling-stack.md`](docs/tooling/dev-tooling-stack.md).
- **Design notes** (`docs/design/`). Brainstorm-level proposals. Not polished specs.

If a note is truly repo-specific (only applies to one project), it belongs in that repo, not here. If it applies to all my repos, it belongs here.

## Releases

This repo uses the same release ceremony as every other repo I own. Documented in the workflow doc linked above.
