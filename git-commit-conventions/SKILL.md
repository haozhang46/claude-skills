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

```bash
pnpm add -D prettier prettier-plugin-tailwindcss
```

**.prettierrc:**
```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

**.prettierignore:**
```
.next
dist
node_modules
pnpm-lock.yaml
```

`prettier-plugin-tailwindcss` auto-sorts Tailwind classes. Even with BEM, it sorts `@apply` directives in CSS.

## 4. ESLint — Catch Bugs, Not Bikeshed

```bash
pnpm add -D \
  eslint @eslint/js \
  typescript-eslint \
  eslint-config-prettier \
  eslint-plugin-react-hooks \
  eslint-plugin-import
```

**`eslint.config.mjs`** (flat config):
```js
import js from '@eslint/js';
import ts from 'typescript-eslint';
import prettier from 'eslint-config-prettier';
import reactHooks from 'eslint-plugin-react-hooks';
import importPlugin from 'eslint-plugin-import';

export default [
  js.configs.recommended,
  ...ts.configs.recommended,
  prettier,
  {
    plugins: { 'react-hooks': reactHooks, import: importPlugin },
    rules: {
      'no-console': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'error',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
      'import/order': ['warn', { 'newlines-between': 'never', alphabetize: { order: 'asc' } }],
    },
  },
];
```

**Package breakdown:**

| Package | Purpose |
|---------|---------|
| `eslint` + `@eslint/js` | Core + recommended rules |
| `typescript-eslint` | TS parser + TS-specific rules |
| `eslint-config-prettier` | Turns off ESLint rules that conflict with Prettier |
| `eslint-plugin-react-hooks` | Rules of hooks + exhaustive deps |
| `eslint-plugin-import` | Import ordering, duplicates, missing extensions |

## 5. commitlint — Enforce Format

```bash
pnpm add -D @commitlint/cli @commitlint/config-conventional
```

**`commitlint.config.js`:**
```js
export default { extends: ['@commitlint/config-conventional'] };
```

## 6. Lock Files — Always Commit

```
pnpm-lock.yaml   → commit
package-lock.json → commit
yarn.lock        → commit
```

**Never `.gitignore` the lock file.** It guarantees CI, deploy, and every dev installs the exact same dependency tree.

## Red Flags

- Commit without type prefix → husky should reject
- `git commit --no-verify` to bypass hooks → fix the issue, don't skip
- Prettier format change mixed with logic change → separate commits
- ESLint warnings ignored → treat warnings as errors in CI
- `pnpm-lock.yaml` in `.gitignore` → delete that line
