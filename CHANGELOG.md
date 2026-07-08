# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-07-08

### Added

- [Centralized CI design note](docs/design/centralized-ci-workflows.md): workflow logic moves to `amcheste/gh-workflows` as reusable workflows with exact-tag pins and Dependabot propagation; repos keep thin caller stubs. Pointer added in [CI Automation Surface](docs/workflows/ci-automation.md).
- MIT `LICENSE` file; the README badge and license link had pointed at a file that never existed.
- Real lint surface in `validate.yml`: markdownlint-cli2 (config in `.markdownlint-cli2.jsonc`), shellcheck over `scripts/`, and lychee offline link checking so every internal link, anchor, and image path must resolve. Replaces the template's `echo TODO` placeholder.
- Secret-scanning baseline per [Security Posture §4](docs/philosophies/security-posture.md): gitleaks pre-commit hook (`.pre-commit-config.yaml`) and `gitleaks.yml` CI backstop.
- Rendered merge-strategy diagram (`docs/images/merge-strategy.png`); the philosophy doc had referenced it since it was written, but the image was never committed.

### Changed

- [Development Tooling Stack](docs/tooling/dev-tooling-stack.md) restructured into the handbook's house style: fixed heading hierarchy, prose over fragment bullets, layer table up front, redundant Role Definitions/Summary sections folded away.
- Repo setting: merged PR head branches are now deleted automatically (matches the "delete after merge" rule in the branching philosophy).

### Fixed

- Fragment-punctuation tic in the philosophy docs (severed subjects/verbs like "The alternative. … Is how incidents compound.") rewritten into grammatical sentences using commas, colons, and parentheses, keeping the no-em-dash voice rule.
- Stale status markers in the [Claude Bot Account design note](docs/design/claude-bot-account.md): header now says Implemented, the "rendered diagram is planned" note is gone (the diagram has existed since v0.1.0), and the footer reflects the App being live.
- Testing philosophy §6 no longer references private project names; examples are now generic.

## [0.2.0] - 2026-05-12

### Added

- Brand banner under `assets/` (svg + 1200/2400 png) per [`banner-spec.md`](https://github.com/amcheste/alanchester-brand/blob/main/docs/banner-spec.md). Hero shows the four philosophy pillars with a Hunter Green δ marker on Branching. Inline `<style>` block bakes IBM Plex Sans/Mono/Serif metrics into the SVG so it renders standalone on GitHub.
- "GitHub default branch setting" subsection in [Branching & Releases](docs/workflows/branching-and-releases.md), clarifying that the integration trunk (always `develop`) is distinct from GitHub's "default branch" repo setting (develop pre-release, main post-release).
- Step 5 in the release ceremony: ensure `main` is the GitHub default branch. Idempotent — only takes effect on the first release.
- Brand-aligned README badges (license in Hunter Green `#1F4D3A`, version in Ink `#0B0B0C`).

### Changed

- Release Drafter workflow bumped to v7.3.0 (`c2e2804`). Dropped the `pull_request` trigger — v7 was failing CI on PR events because `GITHUB_REF` is `refs/pull/N/merge`, which the Releases API rejects as `target_commitish`.

### Fixed

- Banner SVG `.stack` text overflow into the monogram (font-size 18px → 14px, letter-spacing 0.22em → 0.18em).
- Scorecard workflow imposter `github/codeql-action/upload-sarif` SHA replaced with the real v4 pin. Added `publish_results` condition keyed to `default_branch` instead of hardcoded `refs/heads/main`.

## [0.1.0] - 2026-04-24

### Added

- Philosophies: Branching Strategy, Release Cadence & Semver Discipline, Security Posture, Testing.
- Workflows: Branching & Releases, CI Automation Surface.
- Tooling: Development Tooling Stack (Claude Desktop for planning, Claude Code as primary execution, Cursor as supplemental).
- Design notes: Claude Bot Account for AI-Authored PRs (design approved. Epsilon agent now active).
- Rendered overview diagrams under `docs/images/` for branching strategy, release cadence, and Claude Bot Account.
- Release infrastructure: `VERSION`, `scripts/bump-version.sh`, `CHANGELOG.md`.
- `CONTRIBUTING.md` rewritten for the handbook as canonical source for branching, commits, and releases across all repos.

### Changed

- Repository renamed from `dev-tool-stack` to `engineering-handbook` and refocused from a narrow tooling note into a living handbook of engineering philosophies, workflows, tooling, and design notes.
