# Design: Claude Bot Account for AI-Authored PRs

**Status:** Brainstorm / Not yet implemented
**Author:** Alan Chester
**Date:** 2026-04-22

---

## Problem

Claude Code writes all the code. Alan reviews and approves it. But because
Claude pushes using Alan's GitHub credentials, every PR shows Alan as both
the **author** and the only possible **reviewer** --- and GitHub blocks
self-review. This breaks the natural code-review workflow in Graphite,
Linear, and GitHub.

## Goal

Separate authorship from review so that:

1. PRs are **authored** by a bot account (e.g. `amcheste-claude`)
2. Alan is **auto-requested as reviewer** via CODEOWNERS
3. The audit trail is clean: AI wrote it, human reviewed it
4. The day-to-day workflow doesn't change (Alan talks to Claude, Claude ships code)

## Ownership Model

The core question: **who owns the commit and the PR?** This depends on
who is driving the work, not who touches the keyboard.

### Scenarios

#### Scenario 1: Claude-driven coding session

> Alan launches Claude Code and describes what he wants. Claude writes
> the code, commits, and raises the PR. Alan reviews in Graphite.

| | |
|---|---|
| **Driver** | Claude Code |
| **Alan's role** | Guidance, direction, review |
| **Commit author** | `amcheste-claude` |
| **PR author** | `amcheste-claude` |
| **Reviewer** | `amcheste` (auto-requested via CODEOWNERS) |

#### Scenario 2: Claude-driven with human steering in Cursor

> Alan has Claude open a file in Cursor via the side panel. Alan reads
> the code to give better guidance, or edits the file directly to show
> Claude what he means. Claude is still driving the overall task ---
> Alan's edits are guidance, not primary authorship.

| | |
|---|---|
| **Driver** | Claude Code |
| **Alan's role** | Guidance via review and direct edits |
| **Commit author** | `amcheste-claude` (Claude does the commit) |
| **PR author** | `amcheste-claude` |
| **Reviewer** | `amcheste` |

> **Key principle:** Even when Alan touches the code, if Claude is the
> one orchestrating the work and doing the `git commit`, it's a
> Claude-owned deliverable. Alan's edits are steering, not authorship.

#### Scenario 3: Automated from Linear ticket

> A Linear ticket is auto-assigned to Claude (via scheduled task or
> webhook). Claude picks it up, writes the code, commits, and raises the
> PR --- all without Alan initiating a session.

| | |
|---|---|
| **Driver** | Claude Code (autonomous) |
| **Alan's role** | Review only |
| **Commit author** | `amcheste-claude` |
| **PR author** | `amcheste-claude` |
| **Reviewer** | `amcheste` |

#### Scenario 4: Human-driven coding

> Alan opens a terminal or Cursor and writes code himself. He may ask
> Claude for guidance (explain a function, suggest an approach, review
> a snippet) but Alan is driving --- he's on the keyboard, he decides
> what to commit, he runs `git commit`.

| | |
|---|---|
| **Driver** | Alan |
| **Claude's role** | Guidance, rubber duck, Q&A |
| **Commit author** | `amcheste` (Alan's default git config) |
| **PR author** | `amcheste` |
| **Reviewer** | N/A (self-authored, or request a peer) |

### The Rule

> **Whoever runs `git commit` determines the author.**
>
> - Claude Code always uses `--author="amcheste-claude <...>"` (per CLAUDE.md)
> - Alan's terminal and Cursor use his default git config (`amcheste`)
>
> No manual switching required. The tools enforce the boundary.

The beauty of this model is the enforcement mechanism is dead simple.
Claude Code always adds `--author`, your terminal and Cursor don't. There
is no config switching, no remembering which mode you're in. You sit down,
you code, your commits are yours. You talk to Claude, Claude codes, Claude's
commits are the bot's. Even in the same repo, on the same branch, five
minutes apart.

### Edge Case: Scenario 2 Boundary

Scenario 2 has one subtle edge case worth calling out. If Alan edits a
file in Cursor and then *Alan* runs `git commit` from Cursor's terminal
(not Claude Code), the commit will be under `amcheste` --- because Alan's
git config is the default. But per the intent of Scenario 2, if Claude is
driving the overall task, Claude should be the one committing.

The rule of thumb: **if Claude is driving, let Claude commit.** Don't
commit from Cursor's terminal while Claude is orchestrating the work. If
you make edits to steer Claude in the right direction, save the file and
let Claude pick up the changes and do the commit. This keeps the
ownership model clean without any tooling gymnastics.

### Summary Table

| Scenario | Who drives | Who commits | Commit author | PR author | Reviewer |
|---|---|---|---|---|---|
| 1. Claude session | Claude | Claude | `amcheste-claude` | `amcheste-claude` | `amcheste` |
| 2. Claude + Cursor steering | Claude | Claude | `amcheste-claude` | `amcheste-claude` | `amcheste` |
| 3. Linear ticket (automated) | Claude | Claude | `amcheste-claude` | `amcheste-claude` | `amcheste` |
| 4. Alan coding | Alan | Alan | `amcheste` | `amcheste` | --- |

## Proposed Architecture

```
 Alan (human)                    Claude Code                     GitHub
 ───────────                    ───────────                     ──────
 "add event flags"  ──────►  writes code locally
                              commits as amcheste-claude  ──►  pushes branch
                              gh pr create (bot token)    ──►  opens PR
                                                               │
                              CODEOWNERS: * @amcheste    ──►  auto-requests
                                                               Alan as reviewer
                                                               │
 reviews in Graphite  ◄─────────────────────────────────────  PR visible in
 approves / merges                                            review queue
```

## Components

### 1. Bot GitHub Account

| Field | Value |
|---|---|
| Username | `amcheste-claude` (or similar) |
| Email | `amcheste-claude@users.noreply.github.com` |
| Role | Collaborator with push access on target repos |
| Avatar | Something that makes it obvious it's a bot |

**Setup steps:**
1. Create a new GitHub account (requires a separate email --- use a `+` alias: `amcheste+claude@gmail.com`)
2. Add a clear bio: "Bot account for AI-authored PRs. Code written by Claude, reviewed by @amcheste."
3. Invite as collaborator on each repo (or create a GitHub Org team)

### 2. Personal Access Token (PAT)

The bot account needs a **fine-grained PAT** with:

| Permission | Scope | Why |
|---|---|---|
| `contents` | Read & Write | Push branches |
| `pull_requests` | Read & Write | Create/edit PRs |
| `metadata` | Read | Required by GitHub |

**Setup steps:**
1. Log into the bot account on GitHub
2. Settings > Developer settings > Personal access tokens > Fine-grained tokens
3. Create token scoped to Alan's repos (or all repos the bot can access)
4. Save the token securely (1Password, etc.)

### 3. Local Git Configuration (Per-Repo)

Claude Code uses standard git config. To author commits as the bot:

```bash
# Per-repo (does NOT affect other repos)
git config user.name "amcheste-claude"
git config user.email "amcheste-claude@users.noreply.github.com"
```

This should **only apply to Claude Code sessions**, not to Alan's own
coding in Cursor or the terminal. There are three approaches:

#### Option A: Claude Code sets identity per-commit (Recommended)

Claude Code overrides the author at commit time using git flags, without
touching the repo's git config at all:

```bash
git commit --author="amcheste-claude <amcheste-claude@users.noreply.github.com>" -m "..."
```

Alan's global git config (`amcheste` / `amcheste@gmail.com`) stays
untouched. When Alan codes in Cursor or the terminal, commits are his.
When Claude Code commits, it uses the `--author` flag per CLAUDE.md.

> **Why this wins:** Zero repo setup, zero risk of Alan's commits
> appearing as the bot, works everywhere immediately. The only
> requirement is the CLAUDE.md instruction.

#### Option B: Per-repo git config (manual per repo)

```bash
# Only in repos where Claude is the primary author
git config user.name "amcheste-claude"
git config user.email "amcheste-claude@users.noreply.github.com"
```

> **Downside:** Alan's own commits in that repo also appear as the bot
> unless he remembers to use `--author` himself. Flips the problem.

#### Option C: Global conditional config

```gitconfig
# ~/.gitconfig
[includeIf "gitdir:~/Repos/amcheste/"]
    path = ~/.gitconfig-claude-bot
```

```gitconfig
# ~/.gitconfig-claude-bot
[user]
    name = amcheste-claude
    email = amcheste-claude@users.noreply.github.com
```

> **Downside:** ALL commits in `~/Repos/amcheste/` appear as the bot ---
> including Alan's own Cursor work. Not suitable for mixed authorship.

#### Recommendation

**Option A** is the clear winner. It keeps the default git identity as
Alan's, and only Claude Code overrides it via `--author`. The CLAUDE.md
instruction handles this automatically:

```markdown
# In ~/.claude/CLAUDE.md
- When committing, always use:
  git commit --author="amcheste-claude <amcheste-claude@users.noreply.github.com>"
```

This gives clean separation:
- **Alan commits in Cursor/terminal** -> `amcheste` (his normal identity)
- **Claude Code commits** -> `amcheste-claude` (bot identity)
- **Both** -> same repo, same branch, no config switching

### 4. `gh` CLI Auth for Bot Account

The `gh` CLI manages its own auth separately from git:

```bash
# Option A: switch default gh auth to bot
echo "<BOT_PAT>" | gh auth login --with-token

# Option B: per-command token (doesn't change default)
GH_TOKEN=<BOT_PAT> gh pr create ...
```

**Recommended: Option B** --- set `GH_TOKEN` as an environment variable that
Claude Code sessions pick up, while leaving Alan's default `gh auth` intact
for his own manual GitHub usage.

```bash
# In ~/.zshrc or ~/.config/claude/env
export CLAUDE_GH_TOKEN="ghp_xxxxxxxxxxxx"
```

Then update CLAUDE.md to instruct Claude Code to use:
```
GH_TOKEN=$CLAUDE_GH_TOKEN gh pr create ...
```

### 5. CODEOWNERS (Already Done)

```
# .github/CODEOWNERS
* @amcheste
```

Since the PR author is now `amcheste-claude` (not `amcheste`), GitHub
will **auto-request `amcheste` as reviewer**. This is the key unlock.

### 6. Branch Protection (Optional but Recommended)

```
Settings > Branches > main:
  [x] Require pull request before merging
  [x] Require approvals: 1
  [x] Require review from CODEOWNERS
  [ ] Include administrators  (leave unchecked so Alan can emergency-merge)
```

This enforces that no code reaches `main` without Alan's explicit approval.

## What Changes Day-to-Day

**For Alan:** Nothing. Talk to Claude the same way. Review PRs in Graphite.
Code in Cursor whenever you want --- your commits are yours, Claude's
commits are the bot's, even in the same repo on the same branch.

**For Claude Code:** Two differences baked into CLAUDE.md:
1. Commits use `--author="amcheste-claude <...>"` (Alan's git config unchanged)
2. PR creation uses `GH_TOKEN=$CLAUDE_GH_TOKEN`

**For Alan in Cursor/terminal:** Nothing changes. Default git identity
stays `amcheste`. Cursor's AI agent assistance still commits as Alan
(which is correct --- Alan is directing Cursor, not delegating wholesale).

**Commit messages** continue to include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` for additional audit trail.

## Audit Trail

Every PR has three clear signals:

| Signal | What it shows |
|---|---|
| PR author: `amcheste-claude` | Code was AI-generated |
| `Co-Authored-By` in commits | Which Claude model wrote it |
| Reviewer/approver: `amcheste` | Human reviewed and approved |

## Implementation Plan

| Step | Effort | Dependency |
|---|---|---|
| 1. Create `amcheste-claude` GitHub account | 5 min | Separate email (`amcheste+claude@gmail.com`) |
| 2. Generate fine-grained PAT | 5 min | Step 1 |
| 3. Add bot as collaborator on repos | 2 min/repo | Step 1 |
| 4. Configure `CLAUDE_GH_TOKEN` env var | 5 min | Step 2 |
| 5. Update `~/.claude/CLAUDE.md` with `--author` flag + `GH_TOKEN` | 5 min | Steps 1, 4 |
| 6. Enable branch protection on key repos | 5 min/repo | Step 3 |
| 7. Test: open a PR and verify reviewer assignment | 5 min | All above |

**Total estimated effort: ~35 minutes** (one-time setup, no per-repo git config needed)

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| GitHub rate limits on bot account | Fine-grained PAT has generous limits; we're low-volume |
| Bot account gets locked for TOS | GitHub explicitly allows bot accounts; add clear bio |
| Alan accidentally commits as bot | Use per-repo config (not global) or check `git config user.name` in a pre-commit hook |
| Token leaked in logs | Never echo the token; use env vars; rotate if compromised |
| Bot can push directly to main | Branch protection prevents this |

## Open Questions

1. **Account naming:** `amcheste-claude`? `claude-for-amcheste`? `amcheste-ai`?
2. **Scope:** All repos or just active projects (pokemon-red-ai, ea-agent, etc.)?
3. ~~**Global vs per-repo git config:**~~ **Resolved** --- Option A (`--author` flag) avoids this entirely. Alan's git config stays his.
4. **GitHub App vs PAT:** A GitHub App is more robust (no token rotation, better audit logs) but more setup. Worth it at this scale?
5. **Should the auto-assign action change?** Currently assigns PR creator --- with the bot account, it would assign the bot. We'd want to change it to always assign `amcheste` as reviewer instead. Updated action:

```yaml
# Assigns amcheste as reviewer on bot-authored PRs
steps:
  - uses: actions/github-script@v7
    with:
      script: |
        const author = context.payload.pull_request.user.login;
        // Assign creator
        await github.rest.issues.addAssignees({
          owner: context.repo.owner,
          repo: context.repo.repo,
          issue_number: context.issue.number,
          assignees: [author]
        });
        // If bot authored, request Alan as reviewer
        if (author !== 'amcheste') {
          await github.rest.pulls.requestReviewers({
            owner: context.repo.owner,
            repo: context.repo.repo,
            pull_number: context.issue.number,
            reviewers: ['amcheste']
          });
        }
```

---

*This is a brainstorm document. No changes will be made until Alan decides to proceed.*
