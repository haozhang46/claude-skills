---
name: git-commit-conventions
description: Use when setting up git hooks, writing commit messages, or configuring Husky/Prettier/ESLint — enforces conventional commits, lint-staged, and pre-commit quality gates
---

# Git Commit Conventions

## 1. Commit Message Format — Conventional Commits

```
<type>(<scope>): <subject>

<body>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
```

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes nor adds |
| `chore` | Build, deps, config |
| `style` | Formatting, semicolons (not code change) |
| `test` | Adding/updating tests |
| `perf` | Performance improvement |

**Rules:**
- Subject ≤ 72 chars, imperative mood ("add" not "added")
- No period at end of subject
- Body explains WHY, not WHAT
- Scope is optional but encouraged: `feat(web):`, `fix(api):`

## 2. Husky + lint-staged

```bash
pnpm add -D husky lint-staged
pnpm exec husky init
```

**`.husky/pre-commit`:**
```sh
pnpm lint-staged
```

**`.husky/commit-msg`:**
```sh
pnpm exec commitlint --edit $1
```

**`package.json` — lint-staged config:**
```json
{
  "lint-staged": {
    "*.{ts,tsx}": ["prettier --write", "eslint --fix --max-warnings 0"],
    "*.{css,md,json,yaml}": ["prettier --write"]
  }
}
```

## 3. Prettier — No Discussion on Formatting

**.prettierrc:**
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2
}
```

## 4. ESLint — Catch Bugs, Not Bikeshed

```bash
pnpm add -D eslint @eslint/js typescript-eslint
```

Key rules to enforce beyond defaults:
```json
{
  "rules": {
    "no-console": "warn",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/no-explicit-any": "error"
  }
}
```

## 5. commitlint — Enforce Format

```bash
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

**`commitlint.config.js`:**
```js
export default { extends: ['@commitlint/config-conventional'] };
```

## Red Flags

- Commit without type prefix → husky should reject
- `git commit --no-verify` to bypass hooks → fix the issue, don't skip
- Prettier format change mixed with logic change → separate commits
- ESLint warnings ignored → treat warnings as errors in CI
