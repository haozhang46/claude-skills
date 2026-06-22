---
name: lodash-conventions
description: Use when writing data transformation code with arrays/objects — use lodash-es, prefer lodash pipelines over hand-written reduce, know when TypeScript replaces lodash
---

# Lodash Conventions

## 1. Use `lodash-es` — Never `lodash`

```ts
// ❌ CommonJS bundle, no tree-shaking
import _ from 'lodash';

// ✅ ES modules, tree-shakeable
import { groupBy, map, filter } from 'lodash-es';
```

## 2. ES/JS Already Has These — Don't Use Lodash

Modern JavaScript (ES6+) covers many lodash methods natively:

| Instead of | Use | Since |
|-----------|-----|-------|
| `_.map(arr, fn)` | `arr.map(fn)` | ES5 |
| `_.filter(arr, fn)` | `arr.filter(fn)` | ES5 |
| `_.find(arr, fn)` | `arr.find(fn)` | ES6 |
| `_.some(arr, fn)` | `arr.some(fn)` | ES5 |
| `_.every(arr, fn)` | `arr.every(fn)` | ES5 |
| `_.pick(obj, ['a','b'])` | `const { a, b } = obj` | ES6 |
| `_.omit(obj, ['x'])` | `const { x: _, ...rest } = obj` | ES2018 |
| `_.get(obj, 'a.b.c')` | `obj?.a?.b?.c` | ES2020 |
| `_.isNil(x)` | `x == null` | — |
| `_.defaults(obj, d)` | `{ ...d, ...obj }` | ES2018 |
| `_.assign(obj, a, b)` | `Object.assign(obj, a, b)` or `{ ...obj, ...a, ...b }` | ES6/ES2018 |

**Keep lodash for:** `groupBy`, `keyBy`, `uniqBy`, `debounce`, `throttle`, `cloneDeep`, `merge`, `flow` — these don't have concise native equivalents.

## 3. Lodash for Pipelines — Don't Hand-Write Reduce

```ts
// ❌ hand-written reduce — noisy, error-prone
const byCategory = items.reduce((acc, item) => {
  const key = item.category;
  (acc[key] ??= []).push(item);
  return acc;
}, {} as Record<string, Item[]>);

// ✅ lodash — declarative, one line
const byCategory = groupBy(items, 'category');
```

```ts
// ❌ hand-written transform
const result = items
  .filter(i => i.active)
  .map(i => ({ ...i, score: i.count * 2 }))
  .reduce((acc, i) => { acc[i.id] = i.score; return acc; }, {});

// ✅ lodash flow — pipeline of pure functions
const result = flow(
  (arr) => filter(arr, 'active'),
  (arr) => map(arr, (i) => ({ ...i, score: i.count * 2 })),
  (arr) => keyBy(arr, 'id'),
  (obj) => mapValues(obj, 'score')
)(items);
```

## 4. Good Lodash Uses

| Method | Use for |
|--------|--------|
| `groupBy` | Group array by key |
| `keyBy` | Index array by key |
| `uniqBy` | Deduplicate by field |
| `orderBy` / `sortBy` | Stable multi-field sort |
| `debounce` / `throttle` | Rate-limit callbacks |
| `cloneDeep` | Deep copy (when structuredClone unavailable) |
| `isEqual` | Deep equality check |
| `merge` | Deep object merge |
| `flow` | Function pipeline |

## Red Flags

- `import _ from 'lodash'` — use `lodash-es` tree-shakeable imports
- `.reduce((acc, ...) => { ... }, {})` — check if `groupBy`/`keyBy`/`mapValues` covers it
- `_.get(obj, 'a.b')` — use `obj?.a?.b`
- `_.pick(obj, ...)` — use destructuring
