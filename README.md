# hz-skills

Personal skill collection — 40+ skills covering frontend, backend, CSS, database, DevOps, mobile, and engineering workflow.

## Frontend Core

| Skill | Description |
|-------|------------|
| **react-fe-skill** | React component design — named hooks, ErrorBoundary, Suspense, dynamic render, forwardRef/cloneElement ban, anchor scroll, virtual scroll |
| **nextjs-hydration-rules** | App Router hydration safety — browser APIs, client/server boundaries, list keys |
| **css-practices** | CSS 实践 — Grid vs Flexbox, gap > margin-bottom, BEM 命名, rem/px/vw, z-index 具名规范, 1px 方案, sticky, ::before/::after, box-sizing |
| **api-codegen** | TypeScript types + React hooks from OpenAPI/GraphQL specs |
| **dto-mapper-layer** | Mapper/DTO transform before committing API data to state |
| **ahooks-best-practices** | useMemoizedFn, useDebounceFn, useEventListener, useLocalStorageState |
| **fe-security** | XSS, form encoding, CSRF, CSP, CORS, IDOR, postMessage, dependency audit |
| **i18n-conventions** | next-intl, ICU format, locale routing |
| **image-optimization** | 懒加载, BlurHash, srcset/picture, 响应式图片, CDN 动态裁剪 |
| **font-loading** | 多国字体加载, unicode-range, CJK 子集化, font-display, UniApp 系统字体替代 |
| **nginx-cache** | 静态资源缓存, Cache-Control, ETag, CDN 分层, SPA 路由, Gzip/Brotli |
| **stories** | Storybook stories and documentation |

### JS / TS

| Skill | Description |
|-------|------------|
| **js-coding-conventions** | Optional chaining, nullish coalescing, early return, flat conditionals |
| **ts-conventions** | Atomic types, composition, enum patterns, type guards |
| **lodash-conventions** | lodash-es, flow pipelines, deepSet/deepPick utils |

### Data Fetching & Bundler

| Skill | Description |
|-------|------------|
| **axios-fetch-conventions** | httpOnly cookie, interceptors, cancellation, retry, SSE streaming, blob download |
| **vite-conventions** | HMR optimization, esbuild, env files |
| **webpack-conventions** | HMR optimization, esbuild-loader, source maps |

---

## Backend & Database

| Skill | Description |
|-------|------------|
| **mysql-database-design** | Schema 设计, DDL/DML, 索引优化, EXPLAIN, 事务锁, 死锁, 分页, 窗口函数, MyBatis, N+1, LIKE 全文搜索, 表关系设计 |
| **idempotency-cache** | 幂等 Token/去重表/状态机, Redis/MySQL 双缓存, Caffeine+Redis 多级缓存, 穿透/击穿/雪崩 |
| **elk-logging** | Log4j2 JSON 输出, Filebeat 采集, ES 索引模板, Kibana KQL/Dashboard/告警 |
| **backend-development** | Node.js/Python/Go, NestJS/FastAPI, Docker/K8s, CI/CD, OAuth |

---

## Mobile

| Skill | Description |
|-------|------------|
| **react-native-keyboard-safearea** | SafeArea, KeyboardAvoidingView, keyboard-controller, isTyping, nativeEvent.isComposing, 自定义键盘 |
| **react-native-ota-update** | CodePush, Expo Updates, Re.Pack code splitting, 全量 vs 部分发布 |
| **webview-performance** | 浏览器 CRP, 原生 Android/iOS WebView 优化, RN WebView JS Bridge |
| **expo-native-modules** | Expo Go vs Dev Build, Expo Modules API Swift/Kotlin, Config Plugin |
| **uniapp-subpackage** | pages.json 分包配置, 主包体积控制, preloadRule, 独立分包 |

---

## DevOps & Workflow

| Skill | Description |
|-------|------------|
| **git-commit-conventions** | Conventional commits, husky, lint-staged, commitlint |
| **monorepo-conventions** | pnpm workspaces, Turborepo, shared package rules |
| **mermaid** | Mermaid 图表 — flowchart, sequence, class, state, ER, gitgraph, mindmap, timeline |
| **node-performance** | Node.js profiling (clinic.js), V8 GC, Next.js ISR/bundle, Nest.js 优化 |
| **project-ai-context** | CLAUDE.md / AGENTS.md 结构规范 |
| **chrome-devtools** | 浏览器自动化, Puppeteer, 性能分析 |
| **micro-frontend** | Module Federation, 独立部署, 灰度 + 版本 API, CDN 多版本 |

---

## Community Skills

| Skill | Source | Content |
|-------|--------|---------|
| **vercel-react-best-practices** | Vercel | React/Next.js performance |
| **web-design-guidelines** | Vercel | Design heuristics |
| **zustand-patterns** | yonatangross/orchestkit | Zustand 5.x |
| **react-native-best-practices** | callstackincubator | RN performance |
| **planning-with-files** | OthmanAdi | Persistent planning |
| **turborepo** | Vercel | Turborepo CLI |
| **threejs / threejs-10-pack / webgpu** | mrgoonie / CloudAI-X / dgreenheck | Three.js / WebGPU |
| **web-quality-*** | Addy Osmani | Performance, a11y, SEO |
| **ponytail** | dietrichgebert | YAGNI lazy dev |
| **databases** | claudekit-skills | MongoDB + PostgreSQL |

---

## Usage

```bash
git clone https://github.com/haozhang46/hz-skills.git
cd hz-skills
./install.sh   # install third-party skills
```

40+ skills covering the full stack — React → MySQL → Redis → Expo → Nginx → ELK.
