# Development Tooling Stack

## Overview

This document describes my current AI-assisted software development stack. The system is designed around an agentic workflow where planning, execution, and review are separated across specialized tools.

The goal is to maximize development speed, code quality, and leverage through AI-native workflows while maintaining GitHub as the system of record.

---

# 1. Core Principles

### 1.1 Separation of Concerns
- **Planning layer**: defines what to build
- **Execution layer**: writes and modifies code
- **Review layer**: validates correctness and quality
- **System of record**: tracks all changes and history

---

### 1.2 Agent-First Development
AI tools are treated as:
- task executors
- code generators
- debugging assistants
- workflow accelerators

Humans remain responsible for:
- architecture decisions
- final review and approval
- product direction

---

### 1.3 GitHub-Centric Source of Truth
All code ultimately lives in GitHub:
- branches represent work units
- pull requests represent completed tasks
- CI/CD validates correctness

---

# 2. Tooling Stack

## 2.1 Planning Layer

### Linear
- Used for issue tracking and task management
- Defines structured work units (features, bugs, improvements)
- Source of truth for "what needs to be built"

---

## 2.2 AI Reasoning & Design Layer

### Claude Desktop

Claude Desktop is where I figure out *what* to build and *why*. It is not a primary code-writing environment — that role belongs to Claude Code (see 2.3). Claude Desktop covers four distinct modes of use:

- **Chat / conversation** — system design and architecture thinking, breaking down complex tasks, reviewing tradeoffs, exploring edge cases. The classic "thinking partner" use case.
- **Cowork mode** — Claude takes actions on my Mac with my confirmation: running commands, opening files, inspecting state. Useful for debugging workflows that span multiple apps or for guided exploration of an unfamiliar codebase without switching to a terminal.
- **Artifacts and file sharing** — uploading designs, screenshots, logs, API responses, or long documents so Claude can reason about them directly rather than from a summary. Important for reviewing incident evidence, long error traces, or design documents that are hard to paste as text.
- **Session continuity per project** — persistent conversations scoped to a project, which means I can return to a design discussion days later without re-establishing context. This is the biggest reason Claude Desktop is where planning lives — the thread survives.

Output of this layer is usually a written plan, a decision, or a set of implementation tasks that then get handed to Claude Code for execution.

---

## 2.3 Execution Layer (Primary Development Environment)

### Claude Code (primary)

Claude Code writes the lion's share of my production code. It is the CLI-native agentic coding tool and the default execution surface for every repo I own.

- Multi-file feature implementation from a described task
- Refactoring across an entire codebase with reasoning about call sites and side effects
- Writing tests for new and existing code
- Creating and iterating on pull requests (branching, commits, PR body, review response)
- Debugging with full repo context — Claude Code can read the code, run it, interpret failures, and iterate
- Handles the branching and release ceremony per the [Branching & Releases workflow](../workflows/branching-and-releases.md)

Claude Code also enforces the authorship boundary — commits are authored as `amcheste-ai-agent` (see the [Claude Bot Account design note](../design/claude-bot-account.md)) so that the audit trail distinguishes AI-written code from human-written code. My own commits from the terminal or Cursor remain under `amcheste`.

Usage pattern:
- give Claude Code a task (often decomposed from Claude Desktop planning)
- let it implement, commit, and open the PR
- review the diff and merge (or iterate via further prompts)

### Cursor (supplemental)

Cursor is my AI-native IDE, used for **targeted manual work** — not as the primary code-writing environment.

- Surgical keystroke-by-keystroke edits where I want to drive directly
- Reading and understanding code with AI assistance, without handing off a task
- Reviewing Claude Code's diffs with the IDE's inline tooling
- Quick local changes that aren't worth a full Claude Code session

When I'm coding in Cursor, commits go under my personal identity (`amcheste`) — Cursor does not author as the bot. This matches the ownership model in the Claude Bot Account design: whoever runs `git commit` determines the author.

---

## 2.4 Source Control & Collaboration

### GitHub
- Central repository for all code
- Handles:
  - version control
  - pull requests
  - CI/CD pipelines
- Integration point for all development workflows
- See the [Branching Strategy philosophy](../philosophies/branching-strategy.md) for the branch model and the [CI Automation Surface](../workflows/ci-automation.md) for the workflow surface that ships with every repo

---

## 2.5 Optional Review / Workflow Enhancement

### Graphite (optional)
- Used for stacked pull request workflows
- Improves iteration speed on complex features
- Helps manage incremental changes across multiple PRs

---

# 3. End-to-End Workflow

## 3.1 Feature Development Flow

1. Create issue in Linear
2. Use Claude Desktop to:
   - understand requirements
   - design solution
   - break into tasks
3. Use Claude Code to:
   - implement changes
   - refactor surrounding code as needed
   - write / update tests
   - open the PR as `amcheste-ai-agent`
4. (Optional) Use Cursor for:
   - surgical manual edits
   - reading the resulting diff with IDE tooling
5. CI validates on the PR
6. Review and merge (the PR author is the bot; CODEOWNERS auto-requests me as reviewer)

---

## 3.2 Bug Fix Flow

1. Bug reported in Linear or GitHub
2. Claude Desktop used to:
   - analyze root cause hypothesis
3. Claude Code used to:
   - reproduce the issue
   - write a failing test
   - fix the code
   - open the PR
4. Review and merge

---

## 3.3 Experimental / Exploratory Flow

1. Claude Desktop used for ideation
2. Claude Code used for rapid prototyping in a throwaway branch
3. Code iterated until the direction is clear
4. If the work has legs, promoted to a proper feature branch and PR

---

# 4. Role Definitions

## Claude Desktop
- System architect
- Problem decomposer
- Technical reasoning engine
- Thinking partner with session continuity per project

## Claude Code
- Primary coding environment
- Execution engine for features, refactors, tests, and PRs
- Authors commits as the bot account for clean audit trail

## Cursor
- Supplemental IDE for surgical manual work
- Diff review and code reading with AI assistance
- Personal commits under `amcheste` when I'm driving directly

## GitHub
- Source of truth
- Collaboration layer
- CI/CD enforcement

## Linear
- Work intake system
- Task tracking
- Product backlog management

---

# 5. Design Philosophy

This stack is optimized for:

- High leverage development via AI agents
- Rapid iteration cycles
- Strong separation between thinking and execution
- Minimal manual boilerplate work
- Scalable solo or small-team engineering
- Clear authorship audit trail between AI-written and human-written code

---

# 6. Future Evolution

Planned evolution of this system:

- Increased agent autonomy in Claude Code, especially for multi-step tasks from Linear
- Deeper Linear ↔ GitHub automation (auto-assigning tickets to Claude, auto-closing on PR merge)
- Expanded use of MCP-style tool integrations
- More automated test and PR generation loops
- Background agents for maintenance and refactoring

---

# 7. Summary

This development stack is designed to function as a semi-autonomous software engineering system where:

- Planning is structured in Linear
- Thinking is done in Claude Desktop
- Execution is handled primarily by Claude Code, with Cursor as a supplemental tool for targeted manual work
- GitHub acts as the system of record

The goal is to progressively shift from manual coding to AI-assisted and eventually agent-driven software development — with a clear audit trail separating what the AI authored from what the human authored.
