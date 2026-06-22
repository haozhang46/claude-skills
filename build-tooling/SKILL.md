---
name: build-tooling
description: Use when configuring Vite/Webpack, env files, or optimizing HMR — covers hot reload for large projects, env in scripts, per-environment config
---

# Build Tooling — Vite / Webpack / Env

## 1. HMR Optimization for Large Projects

### Vite
```ts
// vite.config.ts
export default defineConfig({
  server: {
    warmup: {
      clientFiles: ['./src/**/*.tsx'], // pre-transform on startup
    },
  },
  optimizeDeps: {
    include: ['lodash-es', 'ahooks'], // pre-bundle heavy deps
  },
});
```

| Optimization | Effect |
|-------------|--------|
| `warmup.clientFiles` | Pre-transform files on dev start, no first-visit lag |
| `optimizeDeps.include` | Pre-bundle heavy deps, skip per-request transform |
| Route-based code splitting | Only load current page's modules |

### Webpack
```js
// webpack.config.js
module.exports = {
  cache: { type: 'filesystem' },           // disk cache across restarts
  resolve: {
    symlinks: false,                        // skip symlink resolution in monorepo
    extensions: ['.ts', '.tsx', '.js'],
  },
  module: {
    rules: [{ test: /\.tsx?$/, use: 'swc-loader' }], // swc faster than babel
  },
};
```

## 2. Env Files in Scripts

```
.env                # default, committed (non-secret defaults)
.env.local          # local overrides, gitignored
.env.development    # dev-specific
.env.production     # prod-specific
.env.deploy         # Docker/deploy values
```

**`package.json` scripts:**
```json
{
  "scripts": {
    "dev": "vite",
    "dev:staging": "env $(grep -v '^#' .env.staging | xargs) vite",
    "build": "vite build",
    "build:prod": "env $(grep -v '^#' .env.production | xargs) vite build"
  }
}
```

**Inline env in CLI (cross-platform):**
```sh
# Vite — VITE_ prefix auto-exposed
VITE_API_URL=https://api.example.com vite build

# Webpack / Next.js — needs explicit prefix
NEXT_PUBLIC_API_URL=https://api.example.com next build
```

**`.env` file rules:**

| File | Commit? | Purpose |
|------|---------|---------|
| `.env` | ✅ | Default values, no secrets |
| `.env.example` | ✅ | Template for new devs |
| `.env.local` | ❌ | Local overrides |
| `.env.production` | ❌ | Production secrets |
| `.env.deploy` | ❌ | Docker deployment values |

## 3. Environment-Specific Config

```ts
// config/env.ts
const ENV = {
  development: { api: 'http://localhost:4000', debug: true },
  staging:     { api: 'https://staging.example.com', debug: true },
  production:  { api: 'https://api.example.com', debug: false },
} as const;

type EnvName = keyof typeof ENV;

export function getConfig(env: string = import.meta.env.MODE) {
  return ENV[env as EnvName] ?? ENV.development;
}
// Usage: import { getConfig } from '@/config/env';
// const { api, debug } = getConfig(import.meta.env.MODE);
```

**Or with Vite's built-in:**
```ts
// vite.config.ts
export default defineConfig(({ mode }) => ({
  define: { __API_URL__: JSON.stringify(ENV[mode].api) },
}));
```

## Red Flags

- `.env.production` committed with real secrets → immediate security issue
- `import.meta.env.VITE_*` used in server code → only works in client bundles
- `process.env.*` in Vite → use `import.meta.env.*`
- No `.env.example` → new devs have no idea what env vars are needed
