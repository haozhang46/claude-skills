---
name: webpack-conventions
description: Use when configuring Webpack — covers HMR optimization, esbuild-loader, source maps, env files, and package.json scripts
---

# Webpack Conventions

## 1. HMR Optimization

```js
// webpack.config.js
module.exports = {
  cache: { type: 'filesystem' },           // disk cache across restarts
  resolve: {
    symlinks: false,                        // skip symlink resolution in monorepo
    extensions: ['.ts', '.tsx', '.js'],
  },
};
```

## 2. esbuild-loader — Replace babel-loader

```bash
pnpm add -D esbuild-loader
```

```js
// webpack.config.js
module.exports = {
  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: 'esbuild-loader',
        options: {
          loader: 'tsx',
          target: 'es2022',
        },
        exclude: /node_modules/,
      },
    ],
  },
};
```

| Loader | Speed | Notes |
|--------|-------|-------|
| `esbuild-loader` | ~100x faster than babel | Go-based, no type-checking |
| `swc-loader` | ~70x faster than babel | Rust-based |
| `babel-loader` | Baseline | Cache + `@babel/preset-env` `modules: false` |

**Build with esbuild minification:**
```js
const { ESBuildMinifyPlugin } = require('esbuild-loader');
module.exports = {
  optimization: {
    minimizer: [new ESBuildMinifyPlugin({ target: 'es2022', css: true })],
  },
};
```

## 3. Source Maps

```js
module.exports = {
  devtool: 'source-map',       // production — separate .map files
  // devtool: 'cheap-module-source-map',  // dev — fast rebuilds
  // devtool: 'hidden-source-map',        // production — .map hidden from bundle
  // devtool: false,                      // no source maps
};
```

| devtool | Speed | Quality | Use |
|---------|-------|---------|-----|
| `eval-cheap-module-source-map` | Fastest | Lines only | Dev |
| `source-map` | Slow | Full mapping | Production |
| `hidden-source-map` | Slow | Full, not referenced | Prod (Sentry) |
| `false` | Fastest | None | Never in prod |

## 4. Env Files — DefinePlugin

```js
const webpack = require('webpack');

module.exports = {
  plugins: [
    new webpack.DefinePlugin({
      'process.env.API_URL': JSON.stringify(process.env.API_URL),
    }),
  ],
};
```

## 5. DLL — Don't Use, Obsolete

Webpack DLL (`DllPlugin` + `DllReferencePlugin`) pre-compiled vendor bundles separately. **Webpack 5 made this obsolete.**

```js
// ❌ DLL — complex config, manual maintenance, no real benefit on Webpack 5
// Separate webpack.dll.config.js
// DllPlugin + DllReferencePlugin + separate build step
// manual vendor list maintenance
// inject via AddAssetHtmlPlugin
```

**Use instead (Webpack 5 built-in):**
```js
module.exports = {
  cache: { type: 'filesystem' },     // replaces DLL — caches everything on disk
  // Cache invalidates automatically on dep changes. Zero config beyond this line.
};
```

**Or split via code-splitting — better than DLL:**
```js
module.exports = {
  optimization: {
    splitChunks: {
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all',
        },
      },
    },
  },
};
```

**Why DLL is dead:**
- `cache: 'filesystem'` caches ALL modules, not just a manual vendor list
- esbuild-loader/swc-loader makes rebuilds fast enough that DLL's speed gain is negligible
- Code splitting via `splitChunks` achieves the same bundle separation without extra config

## 6. package.json Scripts

```json
{
  "scripts": {
    "dev": "webpack serve --mode development",
    "build": "webpack --mode production",
    "build:analyze": "ANALYZE=true webpack --mode production",
    "typecheck": "tsc --noEmit"
  }
}
```

**Key:** Webpack doesn't type-check — always run `tsc --noEmit` separately (in `build` script or CI).

## Red Flags

- `babel-loader` without cache → switch to `esbuild-loader`
- `devtool: false` in production → can't debug errors
- No `tsc --noEmit` in build pipeline → type errors silently pass
- `process.env.*` hardcoded without `DefinePlugin` → undefined at runtime
