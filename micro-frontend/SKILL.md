---
name: micro-frontend
description: Use when architecting large frontend projects with multiple teams or independent deployments — covers Module Federation, qiankun, wujie, and micro-frontend vs monorepo decision
---

# Micro-Frontend Architecture

## 1. When to Use — Threshold Check

| Scale | Solution |
|-------|----------|
| 1 team, 1 app, single deploy | Monolith or monorepo |
| 1-2 teams, shared code, same deploy | **Monorepo** (pnpm workspaces + Turborepo) |
| 3+ teams, independent deploy cycles | **Micro-frontend** |
| Legacy migration (gradual rewrite) | Micro-frontend (strangler pattern) |

**Micro-frontend is NOT free.** It adds complexity: shared deps, CSS isolation, inter-app communication, routing. Only use it when independent deploy is non-negotiable.

## 2. Framework Choice

| Framework | Approach | Best for |
|-----------|----------|----------|
| **Module Federation** (Webpack 5 / `@originjs/vite-plugin-federation`) | Runtime shared modules | Webpack or Vite projects, shared deps |
| **qiankun** | Sandboxed iframe-like sub-apps | Alibaba ecosystem, Chinese docs |
| **wujie** | WebComponent sandbox | Modern alternative to qiankun |
| **single-spa** | Framework-agnostic router | Mix React/Vue/Angular |
| **micro-app** | WebComponent-based | JD.com ecosystem |

## 3. Module Federation (Webpack 5)

```js
// Host app — webpack.config.js
const { ModuleFederationPlugin } = require('webpack').container;
module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'host',
      remotes: {
        posts: 'posts@https://posts.example.com/remoteEntry.js',
        editor: 'editor@https://editor.example.com/remoteEntry.js',
      },
      shared: { react: { singleton: true }, 'react-dom': { singleton: true } },
    }),
  ],
};
```

```js
// Remote app (posts)
new ModuleFederationPlugin({
  name: 'posts',
  filename: 'remoteEntry.js',
  exposes: { './PostList': './src/PostList' },
  shared: { react: { singleton: true }, 'react-dom': { singleton: true } },
});
```

**Host consumes:**
```tsx
const PostList = lazy(() => import('posts/PostList'));
<Suspense fallback={<Skeleton />}><PostList /></Suspense>
```

| Pro | Con |
|-----|-----|
| Share deps at runtime (single React instance) | Complex config |
| Independent deploy per module | Version mismatch risk |
| No iframe overhead | Shared dep negotiation |

## 4. Vite Module Federation

```bash
pnpm add -D @originjs/vite-plugin-federation
```

```ts
// vite.config.ts (host)
import federation from '@originjs/vite-plugin-federation';
export default defineConfig({
  plugins: [
    federation({
      name: 'host',
      remotes: { posts: 'http://localhost:5001/assets/remoteEntry.js' },
      shared: ['react', 'react-dom'],
    }),
  ],
});
```

## 5. Chunk Strategy for Micro-Frontend

```ts
// Each micro-app controls its own chunks
// vite.config.ts — posts micro-app
build: {
  rollupOptions: {
    output: {
      manualChunks: {
        'posts-vendor': ['react', 'react-dom', 'lodash-es'],
        'posts-editor': ['@blog/editor'],
      },
    },
  },
}
```

Shared deps (`react`, `react-dom`) should be `{ singleton: true }` in Module Federation — only one instance loaded at runtime.

## 6. Monorepo + Micro-Frontend Hybrid

```
apps/
├── host/         # shell — routing, layout, auth
├── posts/        # micro-app — blog posts
├── editor/       # micro-app — writing editor
├── admin/        # micro-app — admin panel
packages/
├── api-client/   # shared — types + fetch (NOT loaded by Module Federation)
├── ui/           # shared — Button, Card (could be a remote module)
└── theme/        # shared — design tokens
```

**Rule:** `packages/` for code that can be bundled at build time. Module Federation for code that must be shared at runtime.

## Red Flags

- Micro-frontend for < 3 teams → overengineering, use monorepo
- Each micro-app loads its own React → 3× bundle size, use `shared: { singleton: true }`
- CSS leaking between apps → need CSS Modules / Shadow DOM / scoped styles
- Different React versions across apps → singleton + `shared` negotiation
