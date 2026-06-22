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

## 4. deepSet / deepPick — Without Immer

When immer is overkill, two 10-line utilities handle 90% of deep state needs:

```ts
// deepSet — immutable nested set via path
function deepSet<T>(obj: T, path: string, value: unknown): T {
  const keys = path.split('.');
  if (keys.length === 1) return { ...obj, [keys[0]]: value };
  const [first, ...rest] = keys;
  return { ...obj, [first]: deepSet((obj as any)[first] ?? {}, rest.join('.'), value) } as T;
}

deepSet(state, 'posts.u-123.meta.viewCount', state.posts['u-123'].meta.viewCount + 1);
```

```ts
// deepPick — pick nested paths, return new object
function deepPick<T extends Record<string, unknown>>(obj: T, paths: string[]): Partial<T> {
  return paths.reduce((acc, path) => {
    const keys = path.split('.');
    let src: any = obj;
    let dst = acc;
    for (let i = 0; i < keys.length - 1; i++) {
      if (!(keys[i] in src)) return acc;
      dst[keys[i]] = dst[keys[i]] ?? {};
      dst = dst[keys[i]];
      src = src[keys[i]];
    }
    dst[keys[keys.length - 1]] = structuredClone(src[keys[keys.length - 1]]);
    return acc;
  }, {} as any);
}
```

| Use util | Use immer |
|----------|-----------|
| 1-3 paths to update | Many different mutations in one handler |
| Simple set/pick operations | Complex array insert/delete/filter inside nested state |
| Zero-dependency preference | Already using immer in the project |
| `produce()` overhead > utility | 3+ different nested updates in one pass |

## Red Flags

- `import _ from 'lodash'` — use `lodash-es` tree-shakeable imports
- `.reduce((acc, ...) => { ... }, {})` — check if `groupBy`/`keyBy`/`mapValues` covers it
- `_.get(obj, 'a.b')` — use `obj?.a?.b`
- `_.pick(obj, ...)` — use destructuring
