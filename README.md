# hz-skills

Personal Claude Code skill collection.

## Custom Skills (12)

| Skill | Purpose |
|-------|---------|
| **bem-class-names-only** | BEM semantic naming, Tailwind `@apply` in CSS, no utilities in HTML |
| **nextjs-hydration-rules** | 7 hydration safety rules for Next.js App Router |
| **dto-mapper-layer** | Mapper/DTO transform BEFORE committing API data to state |
| **react-fe-skill** | Component design review, named hooks, component splitting, hook vs util, state management, ErrorBoundary, Suspense |
| **js-coding-conventions** | `?.`/`??`, flat conditionals, early return, flags, Map/Set/WeakMap/WeakSet, promise catch, design patterns |
| **ts-conventions** | Atomic global types, compose, centralized enums + useGetEnum, type guards, as const |
| **axios-fetch-conventions** | No raw fetch/axios in React, unified instance, interceptors, cancellation |
| **lodash-conventions** | lodash-es, ES native replaces lodash, pipelines over hand-written reduce |
| **ahooks-best-practices** | useMemoizedFn > useCallback, useDebounceFn, useEventListener, useLocalStorageState |
| **react-coding-conventions** | Named hook functions (migrated to react-fe-skill) |

## Third-Party Skills (16 — via `./install.sh`)

| Skill | Source |
|-------|--------|
| **vercel-react-best-practices** | Vercel Engineering — 45+ rules for React/Next.js |
| **web-design-guidelines** | Vercel — 247 design heuristics |
| **planning-with-files** | OthmanAdi — persistent planning across context loss |
| **threejs** | mrgoonie — mega-skill, 5 levels |
| **threejs-fundamentals…interaction** | CloudAI-X — 10 specialized Three.js skills |
| **webgpu-threejs-tsl** | dgreenheck — WebGPU + TSL shader dev |
| **web-quality-accessibility** | Addy Osmani — WCAG 2.2 a11y audit |
| **web-quality-performance** | Addy Osmani — performance optimization |
| **web-quality-core-web-vitals** | Addy Osmani — LCP/INP/CLS |
| **web-quality-best-practices** | Addy Osmani — security + code quality |
| **web-quality-seo** | Addy Osmani — search engine optimization |

## Usage

```bash
git clone https://github.com/haozhang46/hz-skills.git
cd hz-skills
./install.sh  # fetch all third-party skills
cp -r . your-project/.claude/skills/
```

## About This Repo

A curated, skill-by-skill collection built alongside my personal blog project. Each custom skill was test-driven (RED-GREEN-REFACTOR via subagent baseline testing) and addresses a real convention gap not covered by upstream skills. Third-party skills are managed via `sources.yaml` + `install.sh` rather than committed directly — keeps the repo lean and upstream-updateable.
