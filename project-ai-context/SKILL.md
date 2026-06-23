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

---

## env 初始化 — `.env.example` + 初始化脚本

`.env` 不上传 Git，用 `.env.example` + 脚本在项目初始化时生成。

### 文件结构

```
project/
├── .env.example          # ✅ committed — 模板，含占位值
├── .env                  # ❌ gitignored — 开发环境真实值
├── .env.local            # ❌ gitignored — 本地覆盖
├── .env.production       # ❌ gitignored — 生产环境
├── scripts/setup-env.sh  # ✅ 开发环境初始化脚本
└── .gitignore
```

### `.gitignore`

```
.env
.env.local
.env.production
.env.*.local
```

### `.env.example`（提交到 Git）

```
# 复制此文件为 .env 后填入真实值
VITE_API_BASE_URL=https://api.example.com
VITE_APP_TITLE=MyApp
# VITE_SECRET_KEY=  # 敏感值只写 key，不写值
```

### `scripts/setup-env.sh`

```bash
#!/bin/bash
set -e

if [ ! -f .env ]; then
  cp .env.example .env
  echo "✅ 已创建 .env，请填入真实值后运行项目"
else
  echo "⏭️  .env 已存在，跳过"
fi
```

### CI/生产环境通过 API 拉取

```yaml
# CI 中：从 Secret Manager 拉取敏感值
- name: Setup env
  run: |
    scripts/setup-env.sh
    curl -s -H "Authorization: Bearer $CI_TOKEN" \
      https://config.internal/api/env/production \
      | jq -r 'to_entries | map("\(.key)=\(.value)") | .[]' > .env
```

**初始化流程：**
1. 新开发者 `git clone` → 运行 `scripts/setup-env.sh` → 复制 `.env.example` 为 `.env`
2. 填入真实值（API key、DB URL 等）
3. CI/生产 → 从 Secret Manager API 拉取，不手填
