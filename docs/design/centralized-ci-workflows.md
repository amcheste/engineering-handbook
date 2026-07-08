# Design: Centralized CI via Reusable Workflows

**Status:** Approved. Rolling out
**Author:** Alan Chester
**Date:** 2026-07-08

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
jobs:
  gitleaks:
    uses: amcheste/gh-workflows/.github/workflows/reusable-gitleaks.yml@v1.0.0
```

`repo-template` ships stubs instead of full copies, so new repos are born centralized.

### Pinning and propagation

Callers pin **exact release tags** (`@v1.0.0`), never branches and never moving major tags. Two reasons:

1. A moving `v1` tag would require non-fast-forward tag updates, which the tag ruleset on every repo (including `gh-workflows`) exists to forbid. The immutable-tags rule wins.
2. Exact pins keep the supply-chain posture uniform: every `uses:` reference in every repo is immutable, whether it points at a third party or at `gh-workflows`.

Propagation is Dependabot's job. It treats reusable-workflow references like actions: when `gh-workflows` tags a new release, every caller gets a bump PR through its normal CI and review gates, and the monthly dependency release ships it. A central change therefore reaches the fleet in a governed way within the normal dependency cadence, not instantly. That trade is deliberate: instant propagation is also instant fleet-wide breakage when a central change is bad.

The versioning contract: patch and minor releases of `gh-workflows` are behavior-compatible for callers. Anything that changes required inputs, permissions, or observable behavior in a breaking way is a major bump, with the migration documented in the release notes.

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
2. Release `v1.0.0`.
3. Convert `repo-template` to stubs, and fix its gaps while there (it currently ships no `LICENSE`, `VERSION`, or `CHANGELOG`).
4. Fleet-convert existing repos, one sweep per workflow, after the open per-repo fix PRs merge.
5. Port the remaining universal workflows, then validate by type.
6. Stand up the monthly fleet audit.

## Risks

| Risk | Mitigation |
|---|---|
| A bad central release breaks callers as they adopt it | Exact pins mean adoption is per-repo and reviewable; a bad release is yanked by shipping a fixed one, and un-bumped repos were never exposed |
| Central repo compromise reaches every repo | `gh-workflows` gets the strictest protection in the fleet: protected branches and tags, PR-only, admin-enforced, secret scanning |
| Debugging gains an indirection hop | Stubs are four lines; the reusable's header comment names the caller contract; run logs link to the exact pinned version |
| Required-check names change (`Validate / Lint`) | One-time `/setup-repo` sync per repo during conversion |

## Open questions

1. Whether `validate` becomes one reusable with a `repo-type` input or one reusable per type. Leaning per-type: simpler files, no conditional soup.
2. Whether the fleet audit lives in `gh-workflows` (a scheduled workflow with a repo list) or as an Epsilon scheduled task. Leaning Epsilon: it can open fix PRs, not just report.
