# Philosophy: Release Cadence & Semver Discipline

**Why releases are a deliberate, automated-but-not-automatic ceremony — and how conventional commits drive the version number.**

This document is the *why*. For the concrete workflow steps, see [Branching & Releases](../workflows/branching-and-releases.md) and [CI Automation Surface](../workflows/ci-automation.md).

---

## The core idea

Every repo I own treats a release as a first-class event, not a side effect of merging. Patch releases happen on a predictable monthly cadence for dependency updates; feature and breaking releases happen when the work is ready. The version number is derived from what the commits say happened, not from what I remember to type into a release notes field.

A few rules hold across all of it:

1. **Every release corresponds to a tag on `main`.** Nothing else releases.
2. **Every version is semver-compliant, validated by CI.**
3. **Conventional commit prefixes determine the bump.** `feat:` = minor, `fix:` = patch, `!` = major. No judgment calls at release time.
4. **Releasing is automated to remove toil, not decision-making.** A human still approves the release PR before anything ships.

---

## 1. Releases are a ceremony, not a continuous stream

**Principle:** A release happens when I decide to release. It's not triggered by "merged a PR" or "end of sprint."

**Why:** Continuous deployment on every merge is a fine model for services that can afford to ship unfinished state behind feature flags. My repos generally don't have that luxury — they're libraries, CLIs, operators, and personal tooling where a tagged version is an artifact other systems depend on. Making the release explicit means the version number on `main` is a point I can return to, not a moving target.

The ceremony is the feature. Friction at release time catches "wait, I don't want to ship that yet." Friction at merge time doesn't.

---

## 2. Monthly patch cycle for dependency drift

**Principle:** On the 1st of each month, a workflow checks whether any `chore(deps):` commits (from Dependabot or manual dep bumps) have landed on `develop` since the last release. If so, it opens a patch-version-bump PR. If not, it does nothing.

**Why:** Dependency updates are noise I don't want to think about release-by-release, but I also don't want to let them accumulate for a year. A monthly cadence is frequent enough that each release is small (easy to review, low rollback risk) and infrequent enough that I'm not spending mental cycles on it daily.

This only works because the PR is auto-opened but manually merged. The automation handles the boring part (bump `VERSION`, generate changelog section, open PR); I handle the judgment part (is this safe to release?). If I decide "no, not this month," I close the PR and the next cycle picks up where this one left off.

---

## 3. Conventional commits drive the version number

**Principle:** The commit prefix decides the semver bump. No separate "what kind of release is this?" question at release time.

| Commit | Bump |
|---|---|
| `feat:` | minor |
| `fix:` | patch |
| `docs:`, `chore:`, `refactor:`, `test:`, `ci:` | no bump on their own |
| Any commit with `!` after the type | major |

**Why:** Deferring the bump decision to release time is where semver discipline breaks down. You look at a list of 40 commits, try to remember which ones were breaking, and pick a number. That's error-prone and subjective. Moving the decision to commit time — when I'm looking at a single change and know exactly what it does — makes it accurate by construction.

This is enforced mechanically: the validate workflow's Commit Lint job rejects PRs with non-conventional messages. The monthly release workflow reads the commits and suggests the correct bump. A human still confirms, but they're confirming a calculation, not making one.

---

## 4. The `VERSION` file is the single source of truth

**Principle:** Every repo has a one-line `VERSION` file at the root. It holds the current (released) version. Nothing else — no `package.json` sprinkling, no `setup.py` duplication, no hardcoded version strings in source.

**Why:** Multiple sources of version truth is how you end up with `v1.3.0` in one place and `1.2.9` in another, with nobody sure which is "real." A single `VERSION` file is trivial to read from any language, trivial for CI to validate, and forces every part of the system that cares about the version to look in one place.

The `bump-version.sh` script (in repo-template) is the only thing that writes to it. CI validates the format (`^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$`) so malformed versions never land.

---

## 5. The tag is the release event

**Principle:** A `v*` semver tag on `main` is what triggers the release pipeline. Pushing the tag publishes the release. There is no separate "release" button.

**Why:** Coupling the tag and the release means they can't drift. You can't accidentally tag without publishing. You can't accidentally publish without tagging. The tag is the truth; the pipeline is a consequence.

This also means tags are protected (ruleset on `refs/tags/v*` — no creation, deletion, or non-fast-forward moves outside the release flow). Accidentally deleting a tag after publish would create a version number that corresponds to nothing, which is worse than nothing at all.

---

## 6. Pre-releases are first-class, not a hack

**Principle:** Versions containing a `-` (e.g. `1.0.0-beta.1`, `2.0.0-rc.3`) are published as pre-releases. They do not become `latest`. Users have to explicitly opt in.

**Why:** Some changes need real-world exposure before I'm willing to call them stable — new features that might behave differently than the tests suggest, breaking changes where I want to give consumers a chance to adapt. Pre-releases let me get artifacts into the world without committing to stability.

The release pipeline handles this automatically based on the tag format. No separate workflow, no manual steps, no risk of accidentally promoting a beta to latest.

### What each pre-release stage means

Semver technically just says "anything after `-` is a pre-release." That's too loose to coordinate around. I follow the [Kubernetes pre-release convention](https://kubernetes.io/docs/reference/using-api/#api-versioning), adapted for single-maintainer projects:

| Stage | Suffix | What it signals |
|---|---|---|
| **Alpha** | `-alpha.N` (e.g. `1.0.0-alpha.3`) | Experimental. APIs and behavior **will change** without notice. Features may be off by default or gated. I may drop or redesign them before the stable release. Use at your own risk. |
| **Beta** | `-beta.N` (e.g. `1.0.0-beta.1`) | Feature-complete for this release cycle. APIs are well-tested and won't silently break, but details may still shift in response to feedback. Features default to on. Suitable for non-critical use. |
| **Release Candidate** | `-rc.N` (e.g. `1.0.0-rc.2`) | Code-complete. **Only bug fixes** land between RCs and the stable release — no new features, no API changes. If no blockers surface, the next version tagged is the stable release. |
| **Stable** | no suffix (e.g. `1.0.0`) | Supported. Becomes `latest`. Ready for production use within the support policy. |

The progression: `alpha` → `beta` → `rc` → stable. Each stage is a promise about *what can change between now and the next tag*.

For solo or small-scale projects, I often skip alpha and go straight to beta when the shape is clear enough. Alpha is mostly useful when you have external users you want to involve early in API decisions.

### The contract each stage makes

- **Alpha:** "I'm showing you this so you can tell me it's wrong."
- **Beta:** "I think this is right. Please tell me if you hit anything."
- **RC:** "I'm trying to ship. Please tell me if I'm about to ship something broken."
- **Stable:** "This is supported. File bugs."

The value of this discipline is that consumers (including future-me) know what promise they're accepting when they install a particular tag.

---

## 7. Release notes are derived, not written

**Principle:** Release Drafter accumulates PR titles and labels into a draft release as PRs merge. At release time, the draft becomes the release notes with minimal editing.

**Why:** Writing release notes from scratch at release time means either (a) scrolling through commits trying to remember what shipped, or (b) skipping it, which makes the GitHub release page useless. Accumulating them as work happens means the notes are written by the person closest to each change, at the moment they made it.

This pairs with conventional commits and the PR labeler — the label determines the category in the release notes, the commit type determines the bump, and the PR title becomes the bullet. All three reuse the same underlying discipline.

---

## What this philosophy is *not*

- **It's not release-on-every-commit.** Some teams release continuously. I don't.
- **It's not manual release engineering.** Toil gets automated. Judgment stays with a human.
- **It's not calendar-based for everything.** Only patch releases for dependency drift are monthly. Feature releases happen when features are ready. Breaking releases happen when I've decided the cost is worth it.

---

## Related

- [Branching Strategy philosophy](branching-strategy.md) — how `develop`/`main` and CLI-merged promotion support this cadence.
- [Branching & Releases workflow](../workflows/branching-and-releases.md) — concrete steps for cutting a release.
- [CI Automation Surface](../workflows/ci-automation.md) — the validate/commit-lint/release-drafter/monthly-dep-release workflows that implement this.
