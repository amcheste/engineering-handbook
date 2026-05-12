# Workflow: CI Automation Surface

**The concrete set of GitHub Actions workflows that ship with every repo I create, what each one does, and when it fires.**

This document is the *how*. For the reasoning behind each piece, see [Release Cadence](../philosophies/release-cadence.md) and [Security Posture](../philosophies/security-posture.md).

---

## Overview

Every repo created from `repo-template` starts with a standard set of workflows under `.github/workflows/`. Each one is independently useful; together they form a consistent CI surface across all repos so that "how do I contribute?" and "what does CI check?" have the same answer everywhere.

The table below is the complete surface at a glance. The rest of the doc covers each workflow in more depth.

| Workflow | Trigger | Purpose | Gates merge? |
|---|---|---|---|
| `validate.yml` | Push/PR to `main` or `develop` | Lint, commit-lint, semver suggestion | Yes |
| `labeler.yml` | PR open/reopen/sync | Auto-apply labels from file paths | No |
| `release-drafter.yml` | Push to `develop`/`main`, PR events | Accumulate draft release notes | No |
| `monthly-dependency-release.yml` | 1st of month cron + `workflow_dispatch` | Open patch release PR if deps merged | No |
| `release.yml` | `v*` tag push | Publish the release (validate → gate → publish) | N/A (post-release) |
| `sast.yml` | Weekly cron + push/PR to `main`/`develop` | Semgrep static analysis | No (reports only) |
| `gitleaks.yml` | Push/PR to `main`/`develop` | Secret scan as CI backstop (primary line is the pre-commit hook) | Yes |
| `scorecard.yml` | Weekly cron + branch-protection changes + push to `main` | OpenSSF Scorecard posture | No (reports only) |
| `stale.yml` | Daily cron | Close inactive issues/PRs | N/A |
| `acceptance.yml` (where applicable) | PR to `main` + `workflow_dispatch` | Heavy end-to-end tests | Yes (at release PR) |

---

## `validate.yml`. The gate every PR goes through

**Fires on:** every push and PR targeting `main` or `develop`.

**Does:**
1. **Lint**. Language-specific linter (`ruff`, `golangci-lint`, `shellcheck`, whatever fits the repo). This is the check that gets required in branch protection.
2. **Commit Lint**. Enforces [Conventional Commits](https://www.conventionalcommits.org/). Rejects PRs where any commit message doesn't match the `<type>[(scope)]: <description>` grammar with a recognized type (`feat` / `fix` / `docs` / `chore` / `refactor` / `test` / `ci`).
3. **Semver suggestion**. Reads the commits on the PR and posts a suggested bump (`major` / `minor` / `patch` / `none`) in the PR output. `feat:` → minor, `fix:` → patch, any `!` → major.
4. **`detect-changes` short-circuit**. If a PR only touches `.github/` files, skip the expensive lint/test jobs.

**Why it matters:** This is the only workflow whose success is required by branch protection. Everything else reports; this one gates.

**Customizing per repo:** the lint step is the part you'll replace. `validate.yml` ships with a TODO placeholder. After editing, rerun `/setup-repo` to sync the required-check names in branch protection.

---

## `labeler.yml`. Automatic label assignment

**Fires on:** PR open, reopen, and synchronize.

**Does:** Reads `.github/labeler.yml` (or `labelers.yml`) and applies labels based on the paths touched in the PR. E.g. a PR changing `docs/**` gets the `docs` label; one touching `.github/**` gets `ci`.

**Why it matters:** Labels feed Release Drafter. No labels = uncategorized release notes. Automating the labeling means I never forget.

**Customizing per repo:** edit the labeler config to match the repo's directory structure. Defaults from the template cover `docs`, `ci`, `tests`, and a few common code directories.

---

## `release-drafter.yml`. Release notes that write themselves

**Fires on:** push to `develop` or `main`, and every PR event.

**Does:** Accumulates merged PR titles (categorized by label) into a draft GitHub release that updates as PRs merge. At release time, the draft becomes the release.

**Why it matters:** Release notes get written the moment each change lands, not at the chaos of release time. Paired with `labeler.yml`, each PR is auto-categorized without me thinking about it.

**Config:** `.github/release-drafter.yml`. Defines the categories (Features, Bug Fixes, Maintenance, Security, etc.) and which labels map to each.

---

## `monthly-dependency-release.yml`. The patch release cycle

**Fires on:** cron (1st of each month, early UTC) + `workflow_dispatch` for manual trigger.

**Does:**
1. Checks `git log` on `develop` since the last release tag for commits matching `chore(deps):` or `chore: bump`.
2. If none, exits silently (no release this cycle).
3. If any, runs `scripts/bump-version.sh patch` to increment the VERSION file.
4. Updates `CHANGELOG.md`. Moves `[Unreleased]` entries under a new `[<version>] - YYYY-MM-DD` heading.
5. Commits on a branch (`chore/release-v<version>`) and opens a PR to `develop` titled `chore: release v<version>`.
6. Does **not** auto-merge. I review and merge manually.

**Why it matters:** Monthly patch releases eat dependency drift without manual effort. The "open the PR, don't merge" choice is deliberate. See [Release Cadence philosophy §2](../philosophies/release-cadence.md#2-monthly-patch-cycle-for-dependency-drift).

**What runs after:** once the monthly PR merges to `develop`, follow the standard [Branching & Releases workflow](branching-and-releases.md#publishing-a-release). CLI merge `develop → main`, tag, push.

---

## `release.yml`. Publishing a tagged version

**Fires on:** pushing a `v*` tag to `main`.

**Does (structure varies by repo; this is the pattern):**
1. **Validate**. Re-runs the full validate workflow as a sanity check.
2. **Acceptance gate** (if applicable). Runs the heavy end-to-end test suite.
3. **Publish**. Builds artifacts (containers, binaries, packages) and publishes to the appropriate registry (GHCR, npm, PyPI, a GitHub Release, etc.).
4. **Mark release**. If the tag contains `-` (e.g. `-beta.1`), marks as pre-release. Otherwise marks as latest.

**Why it matters:** The tag *is* the release event. Coupling "tag pushed" → "release published" means they can't drift. See [Release Cadence philosophy §5](../philosophies/release-cadence.md#5-the-tag-is-the-release-event).

---

## `sast.yml`. Semgrep static analysis

**Fires on:** weekly cron (Monday ~02:00 UTC) + push/PR to `main` or `develop`.

**Does:** Runs Semgrep with the `p/secrets` rule pack (plus language-specific packs per repo). Generates SARIF.

**Upload behavior:**
- On `main` pushes and scheduled runs: uploads SARIF to the GitHub Security tab.
- On PRs: generates SARIF but does **not** upload (would require GitHub Advanced Security). Findings appear as workflow annotations instead.

**Why the split matters:** PR findings are PR-noise. Scheduled `main` findings are the repo's actual state. Separating them means the Security tab is signal, not clutter. See [Security Posture philosophy §3](../philosophies/security-posture.md#3-sast-is-part-of-the-default-workflow-not-opt-in).

---

## `gitleaks.yml`. Secret-scan CI backstop

**Fires on:** push/PR to `main` or `develop`.

**Does:** Runs [gitleaks](https://github.com/gitleaks/gitleaks) against the changes. Fails the job (and therefore gates the merge) if a secret is detected.

**Why it matters:** The primary defense against committing secrets is the **pre-commit hook** (also gitleaks, wired via the [pre-commit framework](https://pre-commit.com/) and `.pre-commit-config.yaml` in the repo). Developers install it once with `pre-commit install` and every `git commit` runs the scan before the commit is created. The CI check here is a belt-and-suspenders layer for:
- contributors without pre-commit installed
- `git commit --no-verify` bypasses
- Claude Code sessions or other automation that doesn't run local hooks

See [Security Posture §4](../philosophies/security-posture.md#4-prevent-secrets-before-they-land-in-git-history) for the full three-layer model and why prevention beats audit.

---

## `scorecard.yml`. OpenSSF Scorecard

**Fires on:** weekly cron (Monday ~01:30 UTC) + push to `main` + branch-protection-rule changes.

**Does:** Runs the OpenSSF Scorecard action against the repo and uploads results. Badge in README reflects current score.

**Config:** `continue-on-error: true` on private repos (Scorecard doesn't work well on private). No noise for repos it can't give a useful answer on.

**Why it matters:** Third-party audit of branch protection, token scoping, dependency pinning, etc. Catches drift. See [Security Posture philosophy §5](../philosophies/security-posture.md#5-supply-chain-hygiene-via-scorecard).

---

## `stale.yml`. Issue/PR hygiene

**Fires on:** daily cron (09:00 UTC).

**Does:**
- Marks issues/PRs with no activity in **30 days** as `stale`.
- Closes them after another **7 days** of continued inactivity.
- Exempt labels: `pinned`, `security`.

**Why `security` is exempt:** real security reports should never auto-close. See [Security Posture philosophy §8](../philosophies/security-posture.md#8-stale-issues-are-a-security-concern).

---

## `acceptance.yml`. Heavy end-to-end tests (where applicable)

**Fires on:** PRs targeting `main` + `workflow_dispatch`. **Not on `develop` PRs.**

**Does:** Runs the full end-to-end test suite for repos that have one. E.g. `mac-dev-setup` boots a Tart VM and runs `setup.sh` against fresh macOS; `claude-teams-operator` spins up a Kind cluster and runs the controller suite.

**Why gated to `main` PRs:** these tests take 30–45 minutes and consume real infrastructure. Running them on every `develop` PR would be expensive and would train me to ignore failing checks. Gating to the release PR catches release-blocking regressions at the right moment. See [Testing philosophy §3](../philosophies/testing.md#3-acceptance-tests-gate-releases-not-every-pr).

---

## Dependabot (`.github/dependabot.yml`). Not a workflow, but adjacent

**Fires on:** weekly schedule (Monday).

**Does:** Opens PRs bumping dependencies. Targets `develop`, not `main`. Commits use the `chore` prefix (e.g. `chore(deps): bump github/codeql-action from 3.x to 3.y`) so the monthly release workflow can detect them.

**Why `develop` as target:** dependency PRs go through the normal CI gate on `develop` alongside other changes. Merging to `main` directly would bypass integration testing.

**Ecosystems:** `github-actions` by default; language/platform ecosystems (`npm`, `pip`, `gomod`, `bundler`, `brew`) added per-repo.

---

## Applying this to a new repo

1. Run `/create-repo <name>`. Creates from the template with all of the above already wired.
2. Customize `validate.yml`'s lint step for the project's language/toolchain.
3. Customize `labeler.yml` paths for the repo's structure.
4. Rerun `/setup-repo <owner/repo>` to sync required-check names in branch protection after you've renamed any jobs.
5. Add language-specific Dependabot ecosystems to `.github/dependabot.yml`.

That's the whole setup. No per-repo reinvention.

---

## Related

- [Release Cadence philosophy](../philosophies/release-cadence.md). Why the release automation looks like this.
- [Security Posture philosophy](../philosophies/security-posture.md). Why the security automation is the baseline.
- [Testing philosophy](../philosophies/testing.md). Why acceptance tests gate releases and nothing else.
- [Branching & Releases workflow](branching-and-releases.md). How releases actually happen, end-to-end.
