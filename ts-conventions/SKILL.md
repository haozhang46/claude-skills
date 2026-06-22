---
name: ts-conventions
description: Use when writing TypeScript types, enums, or interfaces — enforces atomic global types, composition over duplication, enum patterns with useGetEnum hook
---

# TypeScript Conventions

## 1. Types Go Global, Atomic First

Define small, composable types in a shared location before using them.

```
types/
├── post.ts        # Post, PostStatus, PostMeta
├── user.ts        # User, UserRole
├── common.ts      # Paginated<T>, AsyncState<T>
└── index.ts       # re-export all
```

**Atomic:** One type = one concept. Compose later.

```ts
// ✅ atomic — small, focused
type PostStatus = 'draft' | 'published' | 'archived';
type PostMeta = { createdAt: string; updatedAt: string };

// ✅ compose from atoms
interface Post {
  id: string;
  title: string;
  status: PostStatus;
  meta: PostMeta;
}
```

## 2. Compose — interface extends / type union

```ts
// ✅ interface extends
interface PostCard extends PostMeta {
  id: string;
  title: string;
  excerpt: string;
}

// ✅ type intersection
type PostDetail = Post & { author: User; relatedPosts: PostCard[] };

// ✅ union for variants
type AsyncState<T> = 
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };
```

## 3. Enum + useGetEnum Hook

Enums defined as const objects with a companion hook for UI labels:

```ts
// types/post.ts
export const PostStatus = {
  DRAFT: 'draft',
  PUBLISHED: 'published',
  ARCHIVED: 'archived',
} as const;

export type PostStatus = (typeof PostStatus)[keyof typeof PostStatus];
```

```ts
// hooks/useGetEnum.ts
type EnumPair = [value: string, label: string];

function useGetEnum<T extends Record<string, string>>(
  enumObj: T,
  labels: Record<T[keyof T], string>
): EnumPair[] {
  return useMemo(
    () => Object.values(enumObj).map((v) => [v, labels[v]] as EnumPair),
    [enumObj, labels]
  );
}

// Usage
const STATUS_LABELS = { draft: 'Draft', published: 'Published', archived: 'Archived' };

function PostFilter() {
  const statusOptions = useGetEnum(PostStatus, STATUS_LABELS);
  // [['draft', 'Draft'], ['published', 'Published'], ['archived', 'Archived']]
  return statusOptions.map(([value, label]) => <option key={value} value={value}>{label}</option>);
}
```

## 4. No `any` — Use `unknown`

```ts
// ❌
function parse(data: any): Post { ... }

// ✅
function parse(data: unknown): Post {
  if (!isPost(data)) throw new Error('Invalid');
  return data;
}
```

## 5. Type Guards for External Data

Everything from API / localStorage needs runtime validation:

```ts
function isPost(data: unknown): data is Post {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'title' in data
  );
}
```

## 6. Prefer `type` Over `interface` Unless Extending

```ts
// ✅ type — for unions, primitives, tuples
type Status = 'on' | 'off';
type Pair = [string, number];

// ✅ interface — when you plan to extend
interface BasePost { id: string; title: string; }
interface PostWithAuthor extends BasePost { author: User; }
```

## 7. `as const` for Literal Inference

```ts
// ❌ type is string[]
const COLORS = ['red', 'green', 'blue'];

// ✅ type is readonly ['red', 'green', 'blue']
const COLORS = ['red', 'green', 'blue'] as const;
```

## Red Flags

- `any` — use `unknown` or proper type
- API data without type guard — runtime will break
- Duplicate type definitions across files — extract to `types/`
- `interface` with only primitives — use `type`
- String union repeated inline — extract to named type
- Missing `as const` on const objects — type widens to `string`
