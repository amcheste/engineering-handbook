# Workflow: Branching & Releases

**The concrete how. Branch model, day-to-day flow, and the release process that every repo I own follows.**

This document is the *how*. For the reasoning behind each decision below, see [Branching Strategy](../philosophies/branching-strategy.md).

---

## Branch model

| Branch | Purpose | Protection |
|---|---|---|
| `main` | Latest release. Always stable. Never directly committed to. | PR required. CI must pass. No force pushes. No deletions. |
| `develop` | Default branch. Integration for all in-flight work. | PR required. CI must pass (`Lint`, `Commit Lint`). No force pushes. No deletions. |
| `feature/*`, `fix/*`, `chore/*`, `docs/*`, `refactor/*` | Short-lived branches off `develop`. One logical change each. Deleted after merge. | None — ephemeral. |
| `v*` tags | Cut from `main` at release time. Trigger the release pipeline. | Ruleset: cannot be created, deleted, or non-ff-moved outside the release flow. |

---

## Commit convention

[Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use |
|---|---|
| `feat:` | New feature or capability |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `chore:` | Maintenance, dependencies, housekeeping, releases |
| `refactor:` | Code change that neither fixes a bug nor adds a feature |

Breaking changes: append `!` after the type. E.g. `feat!: remove legacy API`.

One logical change per PR. Keep commits atomic and the history readable.

---

## Setting up a new repo

Two paths:

**New repo from scratch:** run `/create-repo <name>`. Creates from the template, clones locally, applies branch protection, default branch, and tag ruleset in one shot.

**Existing repo:** run `/setup-repo <owner/repo>`. Applies the standard branch model, protection, and tag ruleset to a repo that's already there.

Both skills set up:
- `develop` branch created from `main` if missing, set as default
- Branch protection on `develop`. Require PR, require `Lint` and `Commit Lint` status checks
- Branch protection on `main`. Require PR, require `Lint`
- Tag ruleset on `v*`. No creation, deletion, or non-fast-forward

After `/setup-repo`, customise `.github/workflows/validate.yml` for the project's language/toolchain, then rerun `/setup-repo` to update required status check names to match the actual job names.

---

## Day-to-day development

### 1. Branch from `develop`

```bash
git checkout develop && git pull
git checkout -b feature/<short-description>
```

Use the prefix that matches the change type. `feature/`, `fix/`, `chore/`, `docs/`, `refactor/`.

### 2. Make changes, commit atomically

Conventional commit messages, one logical change per commit:

```bash
git add <files>
git commit -m "feat: <short imperative description>"
```

### 3. Open a PR targeting `develop`

```bash
git push -u origin feature/<short-description>
gh pr create --base develop --assignee amcheste
```

PR body: a short summary of what changed and why, plus a test plan checklist.

### 4. CI must pass, then merge

Wait for `Lint` and `Commit Lint` (plus any project-specific checks) to pass. Then merge via the GitHub UI. A standard merge is fine for feature branches landing on `develop`.

### 5. Delete the feature branch

GitHub can do this automatically on merge, or delete locally:

```bash
git checkout develop && git pull
git branch -d feature/<short-description>
```

---

## Publishing a release

Releases are handled by `/publish-release <version>`, which walks through the four-step ceremony below. The version argument is either an explicit semver (`1.2.0`, `0.3.0-beta.1`) or a bump level (`patch`, `minor`, `major`).

### Pre-flight

1. Working tree clean
2. On `develop`, up to date with `origin/develop`
3. `VERSION` file exists in the repo root

### Step 1. Version bump PR to `develop`

```bash
git checkout -b chore/release-v<version>
./scripts/bump-version.sh set <version>      # or: patch | minor | major
# Script commits: "chore: release v<version>"
git push -u origin chore/release-v<version>

gh pr create \
  --base develop \
  --head chore/release-v<version> \
  --title "chore: release v<version>" \
  --body "Version bump to v<version>. Merge to proceed with the develop→main release."
```

Wait for CI. Merge via the GitHub UI.

### Step 2. Promote `develop` → `main` via CLI merge

**This step does *not* use a GitHub PR.** GitHub's merge button squash-merges by default, which drops commit ancestry and causes merge conflicts on every subsequent release. See [the philosophy doc](../philosophies/branching-strategy.md#5-releases-preserve-commit-ancestry--cli-merge-not-ui-merge) for the full story.

```bash
git checkout main && git pull
git merge --no-ff origin/develop -m "chore: release v<version>"
git push origin main
```

This preserves the full commit graph. `main` remains a strict ancestor of `develop`, and the next release cycle starts from clean state.

### Step 3. Tag `main`

```bash
git tag -a "v<version>" -m "Release v<version>"
git push origin "v<version>"
```

The tag push triggers the release pipeline via the `v*` tag filter on the release workflow.

### Step 4. Confirm pipeline

```bash
gh run list --limit 3
```

Watch the pipeline at `https://github.com/amcheste/<repo>/actions`. Pre-release versions (containing `-`, e.g. `-beta.1`) are published as pre-releases and do not become `latest`. Stable versions become `latest` once all pipeline gates pass.

---

## Release ceremony at a glance

```
feature branch ──► develop ──► develop ──► main ──► v1.2.0 tag ──► pipeline
   (PR merge)      (PR merge)   (CLI merge --no-ff)  (push tag)     (auto-fires)
                     ▲             ▲
                     │             │
              version bump       CLI only
              PR merged first    (NOT a GitHub PR)
```

---

## Related

- [Branching Strategy philosophy](../philosophies/branching-strategy.md). The reasoning behind every decision above.
- [Development Tooling Stack](../tooling/dev-tooling-stack.md). How this workflow runs inside the broader AI-assisted development stack.
