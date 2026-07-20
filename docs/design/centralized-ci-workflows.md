# Design: Centralized CI via Reusable Workflows

**Status:** Implemented. Universal tier live; fleet conversion PRs in review
**Author:** Alan Chester
**Date:** 2026-07-08 (status updated same day; it was a productive one)

---

## Problem

Every repo gets its CI workflows stamped from `repo-template` at creation time. That gives consistency on day one and drift every day after: the template evolves, but existing repos keep whatever copy they were born with. The costs showed up concretely on 2026-07-08, when a latent bug in `monthly-dependency-release.yml` (a tag lookup that could never succeed under the two-branch model) turned out to ship in 13 repos. The fix was one line of logic and thirteen identical pull requests.

Copy-at-creation also means there is no single place to answer "what is the current CI standard?" The template shows what new repos get; nothing states what existing repos should have.

## Goal

One central place where CI logic lives and changes, so that:

1. A workflow fix or improvement lands once and reaches every repo through a governed, reviewable path.
2. Each repo's CI intent is readable at a glance (a thin stub naming the standard it follows).
3. New repos inherit references, not copies. The template stops being a source of drift.
4. The standard itself is versioned, so "what changed in CI and when" has the same answer everywhere.

## Design

### Centralize logic, template data

The rule that decides what moves and what stays:

- **Logic** (job steps, tooling choices, the release-check algorithm) is identical across repos and moves to the central repo as [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows).
- **Data** (triggers, repo type, language lint commands, labeler paths) is repo-specific and stays in the repo, either inside its stub or as workflow inputs.

### The workflows repo

[`amcheste/gh-workflows`](https://github.com/amcheste/gh-workflows) hosts the reusable workflows under `.github/workflows/reusable-*.yml`. It follows the full standard itself: two-branch model, protected branches and tags, releases by ceremony. Its lint is actionlint over every workflow file, because workflow YAML is this repo's product. It consumes its own reusables by local path, so each PR exercises the code it changes.

### Caller stubs

Each consuming repo keeps a thin stub per workflow. The stub owns the triggers and pins a release tag:

```yaml
# .github/workflows/gitleaks.yml
name: Gitleaks
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
permissions:
  contents: read
  pull-requests: read
jobs:
  gitleaks:
    uses: amcheste/gh-workflows/.github/workflows/reusable-gitleaks.yml@v1.1.3
```

`repo-template` ships stubs instead of full copies, so new repos are born centralized.

A stub's `permissions:` block must grant everything its pinned reusable workflow's jobs request — a reusable workflow can only *downgrade* the caller's token, never elevate it, so any gap here fails the job at startup (see the fleet permissions incident below). Don't copy this example's permission set as gospel for other workflows: check the pinned reusable's own header comment, which documents its actual caller contract.

### Pinning and propagation

Callers pin **exact release tags** (`@v1.0.0`), never branches and never moving major tags. Two reasons:

1. A moving `v1` tag would require non-fast-forward tag updates, which the tag ruleset on every repo (including `gh-workflows`) exists to forbid. The immutable-tags rule wins.
2. Exact pins keep the supply-chain posture uniform: every `uses:` reference in every repo is immutable, whether it points at a third party or at `gh-workflows`.

Propagation is Dependabot's job. It treats reusable-workflow references like actions: when `gh-workflows` tags a new release, every caller gets a bump PR through its normal CI and review gates, and the monthly dependency release ships it. A central change therefore reaches the fleet in a governed way within the normal dependency cadence, not instantly. That trade is deliberate: instant propagation is also instant fleet-wide breakage when a central change is bad.

The versioning contract: patch and minor releases of `gh-workflows` are behavior-compatible for callers. Anything that changes required inputs, permissions, or observable behavior in a breaking way is a major bump, with the migration documented in the release notes. **In practice this means any edit to a reusable workflow's `permissions:` block — workflow-level or job-level — is a breaking change by definition and must be committed `fix!:`/`feat!:`, never a bare `fix:`.** The semver-bump suggestion in `reusable-validate.yml` only looks for the `!` marker; a plain `fix:` gets suggested (and, per the incident below, actually released) as a patch even when it adds a required permission.

**Fleet permissions incident (2026-07-08 – 2026-07-20):** `reusable-gitleaks.yml`, `reusable-sast.yml`, and `reusable-scorecard.yml` each gained a new required caller permission across v1.1.1–v1.1.3 (2026-07-08/09), committed as plain `fix:` and released as patches. `reusable-stale.yml` shipped with an insufficient caller example from v1.1.0's initial release and was never revisited. Dependabot auto-proposed the patch bumps as routine, so every caller that merged them (or was born after with the bad example) silently lost CI: `startup_failure` on Stale, SAST, Scorecard, and Gitleaks across roughly 20 repos, undetected until a manual audit on 2026-07-20 (prompted by an unrelated unread-notifications check) found and fixed all of it. No single run failure paged anyone — GitHub Actions doesn't surface `startup_failure` as loudly as a failed test — so this sat latent for up to two weeks, despite the Rollout section below already marking the underlying workflows "done." That gap is exactly what the fleet audit (Resolved Questions, below) exists to close going forward.

### Repo-type taxonomy

Workflows come in two tiers:

| Tier | Workflows | Applies to |
|---|---|---|
| Universal | gitleaks, monthly dependency release, scorecard, stale, release-drafter | every repo |
| Type-specific validate | docs (markdownlint, link check), shell (adds shellcheck), service (language lint plus tests) | by repo type |

The universal tier centralizes first; it is identical everywhere and benefits most. Validate centralizes per type, with the language-specific lint command as an input or a repo-local make target.

### Governance and its limits

A personal GitHub account has no org-level "required workflows," so adoption cannot be forced mechanically; it has to be verified. The governance loop:

- **Scorecard** (already fleet-wide) audits the third-party posture.
- **A fleet audit** runs monthly: compare each repo's stubs against the standard for its type, open PRs on drift. This is a natural Epsilon task and closes the same gap that let the tag-lookup bug sit latent for months.
- If the repo count keeps growing, moving to a GitHub organization unlocks required workflows and org rulesets; that is a structural decision outside this note's scope.

## Rollout

1. ~~Create `gh-workflows`, port the first two universal workflows (monthly dependency release with the tag fix, gitleaks), self-consume, actionlint.~~ Done ([PR #1](https://github.com/amcheste/gh-workflows/pull/1)).
2. ~~Release `v1.0.0`.~~ Done, followed same-day by `v1.0.1` carrying the two pilot findings (title-scoped release-PR guard; optional `RELEASE_PR_TOKEN` so auto-opened release PRs can trigger their own CI).
3. ~~Pilot one repo before the fleet.~~ Done: the engineering-handbook converted, then shipped `v0.2.1` end to end through the centralized machinery. The pilot surfaced five latent defects, all fixed centrally.
4. ~~Convert `repo-template` to stubs and fix its gaps~~ (`LICENSE`, `VERSION`, `CHANGELOG`, real default lint, placeholder advisory URL): [PR #27](https://github.com/amcheste/repo-template/pull/27).
5. ~~Fleet-convert existing repos~~: conversion PRs open across all 11 remaining repos (monthly release stub plus a gitleaks stub everywhere).
6. ~~Port the remaining universal workflows, then validate.~~ Done: sast (rule packs as input), scorecard (default-branch guard), stale, release-drafter, and a docs/tooling validate ([gh-workflows PR #8](https://github.com/amcheste/gh-workflows/pull/8), released as `v1.1.0`).
7. ~~Stand up the monthly fleet audit.~~ Done: an Epsilon scheduled task runs on the 1st of each month, compares every repo's stubs to the standard, opens fix PRs on drift, and reports anything it cannot fix. Stood up in direct response to the fleet permissions incident above — this exact check, done once by hand, is what caught it.

## Risks

| Risk | Mitigation |
|---|---|
| A bad central release breaks callers as they adopt it | Exact pins mean adoption is per-repo and reviewable; a bad release is yanked by shipping a fixed one, and un-bumped repos were never exposed |
| Central repo compromise reaches every repo | `gh-workflows` gets the strictest protection in the fleet: protected branches and tags, PR-only, admin-enforced, secret scanning |
| Debugging gains an indirection hop | Stubs are four lines; the reusable's header comment names the caller contract; run logs link to the exact pinned version |
| Required-check names change (`Validate / Lint`) | One-time `/setup-repo` sync per repo during conversion |

## Resolved questions

1. ~~One `validate` reusable with a `repo-type` input, or one per type?~~ Neither, exactly: one docs/tooling reusable (`reusable-validate.yml`, with an optional `shellcheck-paths` input) covers every repo without a language toolchain, and service repos keep a local `validate.yml` because their lint and test commands are per-repo data. Adopters' required checks become `validate / Lint` and `validate / Commit Lint`.
2. ~~Fleet audit in `gh-workflows` or as an Epsilon task?~~ Epsilon scheduled task, monthly on the 1st. It can open fix PRs rather than just report, and it runs with the bot identity and full git tooling.
