# Philosophy: Security Posture

**Why I run the same baseline security automation on every repo — public or private, ten stars or zero — and why the reporting SLA is in writing.**

This document is the *why*. For the concrete workflow steps and the specific actions/tools, see [CI Automation Surface](../workflows/ci-automation.md).

---

## The core idea

Security is not something I bolt on when a project "gets important enough to matter." It's a baseline that ships with every repo from day one. That baseline is small on purpose — SAST, supply-chain hygiene, vulnerability reporting, branch protection — but it runs uniformly so I never have to ask "is this repo protected?"

The alternative — adding security gates only when something bad happens — is how incidents compound. A vulnerable dependency in a "just a side project" repo still lands on my GitHub account, still gets indexed by anyone scraping, and still sets a bad precedent for the next repo I spin up. Uniformity is the cheapest insurance I can buy.

---

## 1. A published SLA keeps me honest

**Principle:** Every repo has a `SECURITY.md` that commits to concrete SLAs: **7 days to acknowledge** a reported issue, **30 days to resolve or publicly explain why not**. Reporting channel is GitHub's private vulnerability reporting.

**Why:** Putting a number in writing is the difference between "I'll get to it" and "the clock is running." If someone takes the time to responsibly disclose a vulnerability to me, they deserve to know what response to expect. A vague "we take security seriously" statement is worse than no statement at all — it claims a commitment without making one.

The SLA is also a forcing function for me. A tight acknowledge-window (7 days) means I can't let reports sit in a notification backlog. The resolve-window (30 days) is deliberately aggressive for a solo maintainer — if I can't hit it, the policy requires me to explain why publicly, which keeps the decision visible.

---

## 2. Only the latest release is supported

**Principle:** Security fixes land on `main` and are released as the next version. Older tagged versions don't get backports.

**Why:** Maintaining security branches for old versions is a commitment I'm not willing to make at this scale. Saying so explicitly, in `SECURITY.md`, means consumers know the contract up front — "use the latest tag or accept that you're on your own."

This also shapes how I think about breaking changes. If major versions don't get backported security fixes, breaking changes need to be infrequent enough that consumers have a realistic path forward. Semver discipline (see [Release Cadence](release-cadence.md)) is what makes this sustainable.

---

## 3. SAST is part of the default workflow, not opt-in

**Principle:** Every repo runs [Semgrep](https://semgrep.dev/) against the codebase on a weekly schedule and on every PR targeting `develop` or `main`. PRs don't upload findings to the Security tab (to avoid Advanced Security requirements); scheduled runs on `main` do.

**Why:** SAST is cheap, noisy, and occasionally invaluable. Running it weekly on `main` gives me a snapshot of the current state; running it on PRs catches introduced problems before they land. Separating the two outputs means PR noise doesn't pollute the Security tab — only `main`'s actual state does.

The rule pack is intentionally minimal — `p/secrets` by default, language-specific packs added per-repo. I'd rather have a small set of rules I actually listen to than a giant set I reflexively ignore.

---

## 4. Supply-chain hygiene via Scorecard

**Principle:** Every public repo runs [OpenSSF Scorecard](https://scorecard.dev/) on a weekly schedule, on branch protection rule changes, and on every push to `main`. The score is visible as a badge in the README.

**Why:** Scorecard gives me a third-party audit of the things that are easy to forget — are tokens scoped minimally? Is branch protection enforced? Are dependencies pinned? A weekly cadence catches drift (e.g., I relaxed a branch protection rule three months ago and forgot). Running on branch protection changes catches mistakes the moment they're made.

The badge in the README is partly signaling (public repos benefit from visible posture) and partly self-discipline — a falling score is visible to anyone looking, which is motivation not to let it slip.

Private repos have `continue-on-error: true` on Scorecard because many of its checks require the public surface. No noise on repos where it can't give a useful answer.

---

## 5. Branch protection is non-negotiable

**Principle:** `main` and `develop` both require PRs. `main` additionally requires the release PR path. Neither allows force pushes or deletions. Tag ruleset on `v*` blocks creation/deletion/non-ff outside the release flow.

**Why:** Protection rules are the mechanical enforcement of the branching philosophy. A rule that exists only as a convention isn't a rule — it's a preference. `/setup-repo` applies these rules to every new repo as part of the creation ceremony, so there's no gap between "repo exists" and "repo is protected."

The tag protection specifically matters because release tags are the artifact. A deleted or moved `v1.2.3` tag corresponds to a released version that consumers may already have downloaded — moving it is a supply-chain problem, not a git one.

---

## 6. CODEOWNERS enforces "someone reviewed this"

**Principle:** Every protected repo has a `.github/CODEOWNERS` that makes me (or a bot account for AI-authored work) an automatic reviewer on all PRs.

**Why:** Even as a solo maintainer, the PR review is the checkpoint. CODEOWNERS means I can't accidentally merge a PR without GitHub at least trying to request my review. It's a small guardrail, but it closes the "I'll just quickly merge this and look later" failure mode.

This gets more important with AI-authored PRs (see [Claude Bot Account design note](../design/claude-bot-account.md)). If the PR author is a bot, CODEOWNERS is what ensures a human is in the loop before code reaches `main`.

---

## 7. Stale issues are a security concern

**Principle:** Issues and PRs without activity for 30 days get marked stale; another 7 days closes them. Issues labeled `pinned` or `security` are exempt.

**Why:** A stale issue backlog isn't just clutter — it hides live security reports. If a genuine vulnerability report sits next to 40 old "nice to have" issues, the signal gets lost. Aggressive staling forces the backlog to reflect what's actually open; the `security` exemption ensures real reports never get auto-closed.

Auto-close isn't for the reporter's benefit — it's for mine. A clean issue list is one I can actually scan in 30 seconds.

---

## What this philosophy is *not*

- **It's not enterprise security theater.** No paid scanners, no pen-test-on-commit, no six-person approval chains. The baseline is small, free, and automated.
- **It's not zero-trust everything.** This is a pragmatic floor for personal and small-team projects, not a DoD-grade posture.
- **It's not "set and forget."** Scorecard runs weekly precisely because "set and forget" is how drift happens. The automation is there to surface drift, not to hide it.

---

## Related

- [Branching Strategy philosophy](branching-strategy.md) — how branch protection supports the security model.
- [Release Cadence philosophy](release-cadence.md) — why "only the latest release is supported" is viable.
- [Claude Bot Account design note](../design/claude-bot-account.md) — how AI-authored PRs preserve the review checkpoint.
- [CI Automation Surface](../workflows/ci-automation.md) — the concrete workflows that implement this posture.
