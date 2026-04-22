<div align="center">

# dev-tool-stack

**My AI-assisted software development tooling stack.**

[![Validate](https://github.com/amcheste/dev-tool-stack/actions/workflows/validate.yml/badge.svg)](https://github.com/amcheste/dev-tool-stack/actions/workflows/validate.yml)
[![Version](https://img.shields.io/github/v/tag/amcheste/dev-tool-stack?label=version&sort=semver)](https://github.com/amcheste/dev-tool-stack/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/amcheste/dev-tool-stack/badge)](https://scorecard.dev/viewer/?uri=github.com/amcheste/dev-tool-stack)

</div>

---

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
- Used for system design and architecture thinking
- Helps break down complex tasks into implementation steps
- Used for reviewing approaches, tradeoffs, and edge cases
- Can assist in generating implementation plans for downstream execution tools

---

## 2.3 Execution Layer (Primary Development Environment)

### Cursor
- Primary AI-native IDE
- Handles:
  - code generation
  - multi-file edits
  - refactoring
  - debugging workflows
- Increasingly supports agentic workflows (task → implementation → testing)

Usage pattern:
- implement features
- iterate on code changes
- validate diffs
- prepare pull requests

---

### Claude Code (via Claude Desktop agent mode)
- Lightweight agentic coding interface
- Used for:
  - quick code modifications
  - scaffolding features
  - exploratory coding tasks
- Acts as a secondary execution tool for smaller or isolated tasks

---

## 2.4 Source Control & Collaboration

### GitHub
- Central repository for all code
- Handles:
  - version control
  - pull requests
  - CI/CD pipelines
- Integration point for all development workflows

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
3. Use Cursor to:
   - implement changes
   - refactor code
   - run tests
4. (Optional) Use Claude Code for:
   - small iterative improvements
   - quick fixes or scaffolding
5. Push changes to GitHub
6. Open Pull Request
7. CI/CD validates changes
8. Review and merge

---

## 3.2 Bug Fix Flow

1. Bug reported in Linear or GitHub
2. Claude Desktop used to:
   - analyze root cause hypothesis
3. Cursor used to:
   - reproduce and fix issue
   - validate fix with tests
4. GitHub PR created and reviewed

---

## 3.3 Experimental / Exploratory Flow

1. Claude Desktop used for ideation
2. Cursor used for rapid prototyping
3. Code iterated locally until stable
4. Promising work promoted to GitHub PR

---

# 4. Role Definitions

## Claude Desktop
- System architect
- Problem decomposer
- Technical reasoning engine

## Cursor
- Primary coding environment
- Execution engine for features
- Refactoring and debugging tool

## Claude Code (agent mode)
- Lightweight coding assistant
- Quick task execution tool
- Supplemental builder

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

---

# 6. Future Evolution

Planned evolution of this system:

- Increased agent autonomy in Cursor
- Deeper Linear ↔ GitHub automation
- Expanded use of MCP-style tool integrations
- More automated test and PR generation loops
- Background agents for maintenance and refactoring

---

# 7. Summary

This development stack is designed to function as a semi-autonomous software engineering system where:

- Planning is structured in Linear
- Thinking is done in Claude Desktop
- Execution is handled primarily by Cursor
- GitHub acts as the system of record

The goal is to progressively shift from manual coding to AI-assisted and eventually agent-driven software development.
