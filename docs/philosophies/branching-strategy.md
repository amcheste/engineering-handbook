# Philosophy: Branching Strategy

**Why I run every repo on a `develop` / `main` model with CLI-merged releases and conventional commits.**

This document is the *why*. For the concrete steps, commands, and tooling that implement this philosophy, see [Branching & Releases](../workflows/branching-and-releases.md).

---

## The core idea

Every repo I own follows the same two-branch model — `main` is the latest release, `develop` is the integration branch, and every change lands via pull request. Releases are an explicit, ceremonial promotion of `develop` into `main`, followed by a semver tag that triggers the release pipeline.

This isn't the simplest possible setup. Trunk-based development with a single `main` branch is simpler. I run the two-branch model on purpose. The rest of this document is why.

---

## 1. Separate what's shipped from what's integrating

**Principle:** `main` always points at the last thing I released. `develop` is where in-progress work integrates.

**Why:** A reader (or a CI system, or a downstream consumer) should be able to answer "what's in production right now?" without spelunking through git history. With one branch, "latest commit" can mean anything from "released an hour ago" to "experimental WIP someone merged this morning." With `main` = latest release, the answer is always just `git checkout main`.

This also means tags on `main` are meaningful by construction — every tag corresponds to an actual release event, not a mid-flight commit.

---

## 2. No direct commits to protected branches

**Principle:** Nothing lands on `develop` or `main` except through a pull request.

**Why:** The PR is the review surface. Skipping it removes the one forcing function that catches bad commit messages, missed tests, accidentally committed secrets, or "just a quick fix" changes that weren't actually quick. Even when I'm the only reviewer, the PR gives me a moment to look at the diff with fresh eyes, which almost always surfaces something.

Branch protection enforces this mechanically — not just as a convention. The rule is only real if the tooling refuses to break it.

---

## 3. Feature branches are short-lived and single-purpose

**Principle:** One logical change per branch. One branch per PR. Delete after merge.

**Why:** Long-lived feature branches accumulate drift, merge conflicts, and scope creep. They also hide work — until the PR opens, nobody (including future-me) has visibility into what's in flight. A short-lived branch forces the change to be small enough to review as a single unit. If it's too big for that, it's too big for one PR.

One logical change per PR also means the commit history on `develop` tells a coherent story. Each merge commit answers "what did this change do?" in a single sentence.

---

## 4. Conventional commits as a history contract

**Principle:** Commits use [Conventional Commits](https://www.conventionalcommits.org/) prefixes — `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, with `!` for breaking changes.

**Why:** The prefix is a promise to the reader (and to tooling) about the *kind* of change this is. It drives semver bumps automatically (`feat` → minor, `fix` → patch, `!` → major), makes release notes generate themselves, and lets me grep history by change type. It also forces a tiny moment of discipline at commit time: "is this actually a fix, or am I rolling a refactor into a fix PR?"

The cost is near-zero. The benefit compounds across hundreds of commits and every release.

---

## 5. Releases preserve commit ancestry — CLI merge, not UI merge

**Principle:** The `develop → main` promotion happens via `git merge --no-ff` from the command line. Not via GitHub's merge button.

**Why:** GitHub's default merge button **squash-merges**, which flattens every commit on `develop` into a single new commit on `main`. That new commit has no ancestry relationship with any of the commits on `develop`. On the *next* release cycle, `main` and `develop` have diverged at every single commit — because from git's perspective the squashed commit is a completely different object. The result is a merge conflict on every release, forever.

A non-fast-forward merge (`git merge --no-ff`) preserves the full commit graph. `main` becomes a strict ancestor of `develop` again at merge time, and the next release cycle starts from clean state. The ceremony is one CLI command; the cost of getting it wrong is permanent history corruption.

This is one of those rules that looks pedantic until you've lived through the consequences once.

---

## 6. Releases are explicit events

**Principle:** Releasing isn't a side effect of merging. It's a deliberate step: version bump PR → `develop → main` CLI merge → semver tag → pipeline fires.

**Why:** "Continuous deployment on every merge" is a fine model for some shops — it's not my model. I want releases to be intentional, so that the version number on `main` means something, so that each tag is a point I can actually return to, and so that the release process has enough friction to catch "wait, I don't want to ship that yet." The friction is a feature.

The tag itself triggers the release pipeline. That keeps the release event and the release artifact mechanically linked — there's no way to tag without publishing, and no way to publish without tagging.

---

## 7. Consistency across repos beats per-repo customization

**Principle:** Every repo I own uses the same branch model, protection rules, commit convention, and release process. New repos start from a template that bakes this in.

**Why:** I have enough repos that remembering per-repo conventions is not free. When I jump into any repo, the answer to "how do I contribute?" and "how do I cut a release?" is the same answer. Muscle memory transfers. Tooling (`/setup-repo`, `/publish-release`, `/create-repo`) works identically everywhere. The cost of occasional friction when a repo would have wanted something bespoke is lower than the cost of cognitive overhead everywhere else.

This is also why this handbook is canonical — per-repo `CONTRIBUTING.md` files point here instead of drifting into their own dialects.

---

## What this philosophy is *not*

- It's not trunk-based development. Trunk-based is great for teams that release continuously off a single branch. I don't.
- It's not GitFlow. GitFlow adds release branches, hotfix branches, and long-lived support branches. I don't need any of that at this scale.
- It's not dogma. If a repo genuinely needs a different model — say, a docs-only repo where there's no meaningful "release" — the model bends. But bending is the exception, and it's a deliberate choice, not a drift.

---

## Related

- [Branching & Releases](../workflows/branching-and-releases.md) — the concrete steps, commands, and tooling.
- [Development Tooling Stack](../tooling/dev-tooling-stack.md) — how this workflow fits into the broader AI-assisted development stack.
