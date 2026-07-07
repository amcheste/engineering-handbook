# Philosophy: Testing

**Why I write the tests I write. And, more importantly, why I don't write the ones I don't.**

This document is the *why*. Concrete testing conventions per-language or per-project live in each repo's CLAUDE.md or CONTRIBUTING.md.

---

## The core idea

Tests exist to protect behavior that matters. That's the whole philosophy. Everything else — coverage thresholds, test pyramids, TDD/BDD/TDC acronyms — is scaffolding around that idea, and some of that scaffolding is actively unhelpful.

A test is worth writing if it would fail when I break something that matters, and pass otherwise. A test that fails when I refactor without changing behavior is a bad test. A test that passes while real behavior silently regresses is a worse test. Everything below is an elaboration of that one principle.

---

## 1. Separate pure logic from integration, then test the logic

**Principle:** When a piece of code does both calculation and I/O, split it. The calculation gets unit tests. The I/O gets integration tests, sparingly.

**Why:** Pure logic is trivially testable. No mocks, no fixtures, no setup. The moment I mix calculation with a database call or an HTTP request, the test cost jumps by an order of magnitude, and the resulting test is usually worse (slow, flaky, dependent on environment). Separating the two is a design decision driven by testability, not a test style.

In practice this means: stats computations, date parsing, file path manipulation, normalization, parsing. All pure, all heavily tested. Network calls, database reads, filesystem writes. Integration surface, tested with the minimum necessary coverage to know it works end-to-end.

When I see code where I can't figure out how to test a piece of logic without mocking three things, the answer is almost always "extract the logic into a pure function". Not "write the three mocks."

---

## 2. Mocks are a last resort, not a first tool

**Principle:** I avoid mocking internal code. If a function needs to be mocked to test its caller, the caller is probably doing too much.

**Why:** Every mock is a lie I'm telling the test about how the real system behaves. One or two lies are fine. E.g. mocking a third-party API response so I don't hit it from CI. Twenty lies means the test is essentially a restatement of the implementation, not a verification that it works. That test will pass when I refactor the implementation and fail when I change the mock expectations, which is exactly backwards.

Integration tests that hit real dependencies (real database, real file system) catch problems that mocked tests cannot. Migration failures, connection handling, serialization mismatches. They're slower and more annoying to set up, but they're where I get my real signal.

---

## 3. Acceptance tests gate releases, not every PR

**Principle:** Heavy end-to-end tests. VM boot-and-verify runs, full-cluster acceptance tests, real API integration with external services. Run on PRs *to `main`* and on `workflow_dispatch`. They do not run on every PR to `develop`.

**Why:** Acceptance tests are expensive: 30–45 minutes of runner time, real infrastructure, real API quota. Running them on every commit turns CI into a bottleneck and trains me to ignore failing checks. Gating them to the release PR (the `develop → main` merge commit) means they run once per release, at the moment it actually matters. Before any version tag gets pushed.

The tradeoff: if an acceptance-breaking change lands on `develop`, I find out at release time instead of at PR time. That's acceptable because the release-time failure still blocks the release, and the smaller fast-CI signal on `develop` is fast enough to catch the same class of problems earlier for anything the unit/integration tests can see.

Fast feedback on `develop` PRs; comprehensive gating at release. That's the division.

---

## 4. No coverage-threshold gaming

**Principle:** Coverage is measured, reported, and watched. But there's no required percentage that blocks merges.

**Why:** Coverage targets optimize the wrong thing. Code can be 100% covered by tests that don't actually verify any meaningful behavior (test just calls the function and checks it returns something). Conversely, a critical 20-line function can be fully protected by two well-chosen tests with middling line coverage. Locking the gate at "85%" pushes people to write the former to avoid writing the latter.

What I look at instead: is the critical path tested? If this function silently returned wrong results, would a test catch it? If I deleted a branch, would something fail? Those questions aren't answerable from a coverage number. They're answerable from reading the tests.

Coverage is useful as a trend signal. If it drops 30 points in a PR, I want to know why. It's not useful as a gate.

---

## 5. Tests that run locally match tests that run in CI

**Principle:** The same command I run locally (`make test`, `pytest`, `go test`, etc.) is what CI runs. No CI-only test suite, no local-only test suite.

**Why:** If tests pass locally but fail in CI (or vice versa), I'm debugging the environment rather than the code. Making the commands identical means CI is just "my machine, but in a cleaner room." Catching issues locally saves the CI round-trip; reproducing CI failures locally is trivial.

This also means the repo has to be honest about its dependencies. If the test requires a running database, the `make test` target has to either start one or clearly fail telling me to. Hidden CI-only setup steps are a tax on every contributor, including me, three months from now.

---

## 6. Credentials-required tests are documented, not hidden

**Principle:** If a test requires credentials, API keys, or access to a live third-party service, it's either skipped in CI with a clear explanation or excluded from the default test target entirely. The README documents how to run it locally.

**Why:** A test that silently passes in CI because it can't run is worse than no test. A test that requires "wait, do I have the right env var set?" is a daily paper cut. Either the test runs everywhere or it doesn't. Ambiguity is the failure mode to avoid.

For anything that talks to a third party I don't control — a scraper against someone else's site, a script that publishes to an external service — the integration layer is tested manually with documented steps. The pure logic extracted from it is unit-tested and runs in CI.

---

## 7. Failing tests get fixed, not skipped

**Principle:** A flaky or broken test gets fixed or removed. Skipping a test because "it'll be fixed later" is almost always a lie.

**Why:** Every skipped test is a commitment I've implicitly deferred to future-me. Future-me has no memory of why the test was skipped, and the skip is invisible in CI output. It just silently passes. Better to delete the test (with a commit message explaining why) than to leave a skip that nobody will ever revisit.

If a test is flaky because of a real race condition, the fix is to address the race, not increase retries or add `sleep()`. Retries are a signal that the test knows something is wrong and is lying about it.

---

## What this philosophy is *not*

- **It's not "don't write tests."** I write tests constantly. I just write them for behavior that matters.
- **It's not TDD-mandatory.** I sometimes write tests first, sometimes after, sometimes during. The timing matters less than whether the test does its job.
- **It's not "only unit tests."** Integration tests are essential, especially for the boundaries (databases, filesystems, APIs). The principle is that they're rare and expensive, so each one has to earn its cost.
- **It's not a coverage cult.** Coverage is a measurement, not a target.

---

## Related

- [Security Posture philosophy](security-posture.md). Why the baseline includes SAST (which is a different kind of verification than unit tests).
- [CI Automation Surface](../workflows/ci-automation.md). How validate, acceptance, and release workflows are gated in practice.
- Per-repo CLAUDE.md or CONTRIBUTING.md. Project-specific test commands, frameworks, and credentials.
