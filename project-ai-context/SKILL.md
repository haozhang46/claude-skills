---
name: project-ai-context
description: Use when setting up CLAUDE.md or AGENTS.md for a project — standardizes AI context files, what goes in each, and how to structure them
---

# CLAUDE.md / AGENTS.md — Project AI Context

## File Roles

```
CLAUDE.md     → Claude Code specific (this project)
AGENTS.md     → All AI agents (cross-platform)
GEMINI.md     → Gemini CLI specific
CODEX.md      → Codex CLI specific
.cursor/rules/ → Cursor rules
```

| File | Scope | Priority |
|------|-------|----------|
| `CLAUDE.md` | Claude Code only | Claude loads this first |
| `AGENTS.md` | All agents | Fallback if no platform-specific file |
| Both present | Claude uses CLAUDE.md, others use AGENTS.md | CLAUDE.md wins for Claude |

## Standard CLAUDE.md Structure

```markdown
# Project Name

## Tech Stack
- Framework, language, key libraries

## Project Structure
- apps/web, apps/api, packages/ — monorepo layout

## Commands
- `pnpm dev` — start dev server
- `pnpm build` — production build
- `pnpm test` — run tests

## Conventions
- Skills in .claude/skills/
- BEM class names, no Tailwind utilities in HTML
- Conventional commits

## Deploy
- SSH to 42.193.175.197
- docker compose build + up
```

## What Goes Where

| Content | In CLAUDE.md | In Skill |
|---------|-------------|----------|
| Project overview (stack, structure, commands) | ✅ | ❌ |
| Deploy instructions | ✅ | ❌ |
| Coding conventions (>5 rules) | ❌ | ✅ Skill |
| API reference / library docs | ❌ | ✅ Skill (reference) |
| Git workflow | ❌ | ✅ Skill (git-commit-conventions) |

**Rule of thumb:** CLAUDE.md = project-specific setup + commands. Skills = reusable conventions + patterns.

## AGENTS.md for Cross-Platform

```markdown
# AGENTS.md

## Shared Conventions
- Conventional commits: `feat(scope): subject`
- pnpm workspace, no npm/yarn
- ESLint + Prettier via husky pre-commit

## Platform-Specific
See CLAUDE.md for Claude Code specifics.
```

## Red Flags

- CLAUDE.md > 200 lines → extract to skills
- AGENTS.md duplicating CLAUDE.md → have AGENTS.md reference it
- Deploy secrets in CLAUDE.md → use `.env` files
- Every convention in one file → split to skills
