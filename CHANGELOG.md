# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-05-12

### Added
- Brand banner under `assets/` (svg + 1200/2400 png) per [`banner-spec.md`](https://github.com/amcheste/alanchester-brand/blob/main/docs/banner-spec.md). Hero shows the four philosophy pillars with a Hunter Green δ marker on Branching.
- "GitHub default branch setting" subsection in [Branching & Releases](docs/workflows/branching-and-releases.md), clarifying that the integration trunk (always `develop`) is distinct from GitHub's "default branch" repo setting (develop pre-release, main post-release).
- Step 5 in the release ceremony: ensure `main` is the GitHub default branch. Idempotent — only takes effect on the first release.
- Brand-aligned README badges (license in Hunter Green `#1F4D3A`, version in Ink `#0B0B0C`) and em-dash sweep across prose.

### Changed
- Release Drafter workflow bumped to v7.3.0 (`c2e2804`). Dropped the `pull_request` trigger — v7 split autolabeling into a separate action, and v7 was failing CI on PR events because `GITHUB_REF` is `refs/pull/N/merge` (rejected by the Releases API as `target_commitish`).

### Fixed
- Scorecard workflow: replaced imposter `github/codeql-action/upload-sarif` SHA with the real v4 pin (`68bde55`). Added `publish_results` condition keyed to `default_branch` instead of hardcoded `refs/heads/main` so it works on repos where develop is the integration trunk.

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
