# Development Tooling Stack

**The AI-assisted development stack I use, and the end-to-end workflows that run on top of it.**

This document is the *what*: the tools, the role each one plays, and how a piece of work moves through them. For the branch model and release ceremony the stack operates inside, see [Branching & Releases](../workflows/branching-and-releases.md). For the authorship model it enforces, see the [Claude Bot Account design note](../design/claude-bot-account.md).

---

## The core idea

The stack is built around an agentic workflow where planning, execution, and review are separated across specialized tools, with GitHub as the system of record throughout. Each layer has one job:

| Layer | Tool | Job |
|---|---|---|
| Planning | Linear | Defines *what* to build — issues, features, bugs, backlog |
| Reasoning & design | Claude Desktop | Figures out *how* — architecture, tradeoffs, task breakdown |
| Execution | Claude Code (primary), Cursor (supplemental) | Writes the code, opens the PRs |
| Review & record | GitHub | Validates via CI, holds the history, enforces the review gate |

AI tools are treated as task executors, code generators, and workflow accelerators. Humans remain responsible for architecture decisions, final review and approval, and product direction. The whole stack exists to make that division of labor fast without blurring it.

---

## 1. Planning: Linear

Linear is the work intake system. Features, bugs, and improvements enter as structured issues, and Linear is the source of truth for "what needs to be built." Nothing about the code lives here — only the intent.

---

## 2. Reasoning & design: Claude Desktop

Claude Desktop is where I figure out *what* to build and *why*. It is not a primary code-writing environment — that role belongs to Claude Code. Four distinct modes of use:

- **Chat / conversation.** System design and architecture thinking, breaking down complex tasks, reviewing tradeoffs, exploring edge cases. The classic "thinking partner" use case.
- **Cowork mode.** Claude takes actions on my Mac with my confirmation: running commands, opening files, inspecting state. Useful for debugging workflows that span multiple apps, or for guided exploration of an unfamiliar codebase without switching to a terminal.
- **Artifacts and file sharing.** Uploading designs, screenshots, logs, API responses, or long documents so Claude can reason about them directly rather than from a summary. Important for reviewing incident evidence, long error traces, or design documents that are hard to paste as text.
- **Session continuity per project.** Persistent conversations scoped to a project, which means I can return to a design discussion days later without re-establishing context. This is the biggest reason planning lives in Claude Desktop — the thread survives.

The output of this layer is usually a written plan, a decision, or a set of implementation tasks that get handed to Claude Code for execution.

---

## 3. Execution: Claude Code, with Cursor as the scalpel

### Claude Code (primary)

Claude Code writes the lion's share of my production code. It is the CLI-native agentic coding tool and the default execution surface for every repo I own:

- Multi-file feature implementation from a described task
- Refactoring across an entire codebase, with reasoning about call sites and side effects
- Writing tests for new and existing code
- Creating and iterating on pull requests — branching, commits, PR body, review response
- Debugging with full repo context: it can read the code, run it, interpret failures, and iterate
- Running the branching and release ceremony per the [Branching & Releases workflow](../workflows/branching-and-releases.md)

Claude Code also enforces the authorship boundary. Its commits are authored as `amcheste-ai-agent` (see the [Claude Bot Account design note](../design/claude-bot-account.md)) so the audit trail distinguishes AI-written code from human-written code. My own commits from the terminal or Cursor remain under `amcheste`.

The usage pattern: give Claude Code a task (often decomposed from Claude Desktop planning), let it implement, commit, and open the PR, then review the diff and merge — or iterate via further prompts.

### Cursor (supplemental)

Cursor is my AI-native IDE, used for targeted manual work rather than as a primary code-writing environment: surgical keystroke-by-keystroke edits where I want to drive directly, reading and understanding code with AI assistance without handing off a task, reviewing Claude Code's diffs with the IDE's inline tooling, and quick local changes that aren't worth a full Claude Code session.

When I'm coding in Cursor, commits go under my personal identity (`amcheste`) — Cursor does not author as the bot. This matches the ownership model in the Claude Bot Account design: whoever runs `git commit` determines the author.

---

## 4. Review & record: GitHub

GitHub is the source of truth. Branches represent work units, pull requests represent completed tasks, and CI/CD validates correctness. The [Branching Strategy philosophy](../philosophies/branching-strategy.md) defines the branch model; the [CI Automation Surface](../workflows/ci-automation.md) defines the workflow set that ships with every repo. On bot-authored PRs, CODEOWNERS auto-requests me as reviewer, which is what keeps a human in the loop before anything reaches `main`.

[Graphite](https://graphite.dev/) sits on top as an optional review layer for stacked pull request workflows — useful for iterating on complex features as a series of small, dependent PRs.

---

## End-to-end workflows

### Feature development

1. Create the issue in Linear.
2. Claude Desktop: understand requirements, design the solution, break it into tasks.
3. Claude Code: implement the changes, refactor surrounding code as needed, write or update tests, open the PR as `amcheste-ai-agent`.
4. Optionally, Cursor: surgical manual edits, or reading the resulting diff with IDE tooling.
5. CI validates the PR; CODEOWNERS requests my review.
6. I review and merge.

### Bug fix

1. Bug reported in Linear or GitHub.
2. Claude Desktop: analyze the root-cause hypothesis.
3. Claude Code: reproduce the issue, write a failing test, fix the code, open the PR.
4. Review and merge.

### Experimental / exploratory

1. Claude Desktop for ideation.
2. Claude Code for rapid prototyping in a throwaway branch.
3. Iterate until the direction is clear.
4. If the work has legs, promote it to a proper feature branch and PR.

---

## Future evolution

Planned evolution of this system:

- Increased agent autonomy in Claude Code, especially for multi-step tasks from Linear
- Deeper Linear ↔ GitHub automation — auto-assigning tickets to Claude, auto-closing on PR merge
- Expanded use of MCP-style tool integrations
- More automated test and PR generation loops
- Background agents for maintenance and refactoring

The direction is a semi-autonomous engineering system: planning structured in Linear, thinking in Claude Desktop, execution in Claude Code, GitHub as the record — with a clear audit trail separating what the AI authored from what the human authored at every step.

---

## Related

- [Branching & Releases workflow](../workflows/branching-and-releases.md) — the ceremony this stack executes.
- [CI Automation Surface](../workflows/ci-automation.md) — the checks every PR flows through.
- [Claude Bot Account design note](../design/claude-bot-account.md) — the authorship model Claude Code enforces.
