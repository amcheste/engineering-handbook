<div align="center">

# Alan's Engineering Handbook

**How I build software — and the philosophies behind it.**

[![Validate](https://github.com/amcheste/engineering-handbook/actions/workflows/validate.yml/badge.svg)](https://github.com/amcheste/engineering-handbook/actions/workflows/validate.yml)
[![Version](https://img.shields.io/github/v/tag/amcheste/engineering-handbook?label=version&sort=semver)](https://github.com/amcheste/engineering-handbook/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/amcheste/engineering-handbook/badge)](https://scorecard.dev/viewer/?uri=github.com/amcheste/engineering-handbook)

</div>

---

This repo is my personal engineering handbook — the philosophies, workflows, and tooling that shape how I design, build, and ship software. It is written for myself first and shared publicly as a reference for anyone curious about how an engineer-first, AI-amplified practice actually works day to day.

It is a living document. Expect it to grow and change as my thinking evolves.

## Contents

### Philosophies

The *why* — principles that explain the decisions behind how I work. These change slowly.

- [Branching Strategy](docs/philosophies/branching-strategy.md) — why every repo runs on `develop` / `main` with CLI-merged releases and conventional commits.
- [Merge Strategy](docs/philosophies/merge-strategy.md) — why I rebase-merge PRs, never squash, and how that protects bot/human authorship.
- [Release Cadence & Semver Discipline](docs/philosophies/release-cadence.md) — why releases are a deliberate ceremony, why the monthly patch cycle, and how conventional commits drive the version number.
- [Security Posture](docs/philosophies/security-posture.md) — why every repo ships with the same SAST, Scorecard, CODEOWNERS, and SLA baseline from day one.
- [Testing](docs/philosophies/testing.md) — why I write the tests I write, and why I don't write the ones I don't.

### Workflows

The *how* — concrete steps, commands, and tooling that implement the philosophies. These change as tools evolve.

- [Branching & Releases](docs/workflows/branching-and-releases.md) — branch model, day-to-day flow, and the release ceremony.
- [CI Automation Surface](docs/workflows/ci-automation.md) — the GitHub Actions workflows that ship with every repo, what each does, and when it fires.

### Development Tooling Stack

- [Development Tooling Stack](docs/tooling/dev-tooling-stack.md) — the AI-assisted development stack I use, and the end-to-end workflows that run on top of it.

### Design notes

Brainstorm-level design docs capturing how I'm thinking about specific engineering problems. Not polished specs — working documents that evolve as decisions get made.

- [Claude Bot Account for AI-Authored PRs](docs/design/claude-bot-account.md) — separating authorship from review so AI-written code has a clean audit trail.

_More chapters are in progress._

## How this repo works

- `develop` is the default branch. All changes land via pull request.
- `main` tracks released versions of the handbook.
- The handbook is versioned with semver tags so I can reference a specific snapshot of my thinking over time.

## License

[MIT](LICENSE)
