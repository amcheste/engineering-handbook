# CLAUDE.md

This file is read by Claude Code at the start of every session in this repo.

---

## About This Repo

This is my personal engineering handbook. A documentation-primarily repo that captures the philosophies, workflows, and tooling that shape how I build software.

- Content lives in `docs/` as markdown files, with `README.md` acting as the landing page / table of contents.
- There is no application code to lint, test, or build. Treat this repo as a writing project: prioritize clarity, consistency of voice, and structure.
- Prefer editing existing chapters over creating new ones. Only add a new doc under `docs/` when the topic is substantial enough to stand alone.

---

## Developer Preferences

### Editor
- Primary: Vim
- AI editor: Cursor

### Shell
- zsh, minimal prompt

### Git & GitHub Workflow
- **Branch model:** `main` = latest release. `develop` = integration branch.
- Always branch from `develop`, never commit directly
- PRs always target `develop`
- `main` is only updated via CLI merge (`git merge --no-ff origin/develop`) by `/publish-release`. **never via a GitHub PR**. GitHub's merge button squash-merges by default, dropping ancestry and causing conflicts on the next release.
- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`

### Scripting Standards
- Shell scripts must pass `shellcheck`
- Use `set -euo pipefail`
- Scripts should be idempotent

---

## Learned Preferences

<!-- Claude Code will suggest additions here as patterns emerge across sessions -->
