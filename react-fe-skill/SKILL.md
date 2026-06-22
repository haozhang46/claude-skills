---
name: react-fe-skill
description: Use when writing React components or hooks — enforces named hook functions, component/hook splitting by cohesion, and team conventions not covered by vercel-react-best-practices
---

# React Frontend Conventions

Team-specific React rules complementing `vercel-react-best-practices`.

## 1. Component Design — Before Writing Code

Before implementing, write a component breakdown:

```
Component: PostCard
  Props: { post: PostCardDTO; index: number }
  Responsibility: render a single post with left accent bar
  Scope: page — only used in BlogHomeSections
  Data flow: BlogHomeSections → useSWR → toPostCard[] → PostCard

Component: PostHero
  Props: { post: PostCardDTO }
  Responsibility: expanded first post with excerpt
  Scope: page — only used in BlogHomeSections
  Data flow: same as PostCard

Decision:
  - PostCard + PostHero → DON'T merge (different layout, different responsibilities)
  - PostCard → page-level, NOT global (only used by one page)
```

**Checklist before writing code:**

1. List each component with its props type signature
2. One sentence describing what it does (no "and")
3. Page-level or global?
4. Data source → which parent provides props → which child consumes them
5. Can any components merge? (same data, same responsibility, only styling differs)
6. Does any page component need promotion to global? (now used by 2+ pages)

## 2. Named Hook Functions

All React hooks must use named functions. Anonymous arrow functions forbidden.

```tsx
// ❌ anonymous
useEffect(() => { fetchData(); }, []);

// ✅ named
useEffect(function syncScroll() { fetchData(); }, []);
```

## 3. Component Splitting — High Cohesion, Low Coupling

**By scope:**

```
components/
├── ParticleBackground.tsx    # global — used across multiple pages
├── ScrollIndicator.tsx       # global
├── PostHero.tsx              # page — only used in blog home
├── PostListItem.tsx          # page
```

| Type | Location | Rule |
|------|----------|------|
| Global | `components/` | Used by 2+ pages or the root layout |
| Page | `app/<page>/` colocated | Only used by one page |

**By responsibility:** One component = one clear job. If you need "and" to describe what it does, split it.

```tsx
// ❌ too many responsibilities
function PostCardAndChat() { ... }

// ✅ single responsibility
function PostCard() { ... }
function ChatPanel() { ... }
```

## 4. Hook vs Util — The State Rule

```
Needs useState/useEffect/useRef? → Custom hook (useXxx)
Pure computation / formatting?    → Util function (src/utils/)
```

```tsx
// ❌ duplicate stateful logic in components
function PageA() {
  const [scroll, setScroll] = useState(0);
  useEffect(() => { ... }, []);
}
function PageB() {
  const [scroll, setScroll] = useState(0); // duplicated!
  useEffect(() => { ... }, []);
}

// ✅ extract to custom hook
function useScrollProgress() {
  const [scroll, setScroll] = useState(0);
  useEffect(() => { ... }, []);
  return scroll;
}

// ✅ extract to util (no state)
function formatPostDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}
```

| Has state / effects? | Extract to |
|---------------------|------------|
| Yes | `hooks/useXxx.ts` |
| No | `lib/xxx.ts` or `utils/xxx.ts` |

## 5. useContext + useReducer + useSelector

When `useContext` holds complex state, pair it with `useReducer` for predictable transitions and a custom `useSelector` to avoid full re-renders.

```tsx
// ✅ Context + Reducer + Selector pattern
type State = { posts: Post[]; filter: string; loading: boolean };
type Action = { type: 'SET_POSTS'; posts: Post[] } | { type: 'SET_FILTER'; filter: string };

function postReducer(state: State, action: Action): State { ... }

const PostCtx = createContext<{ state: State; dispatch: Dispatch<Action> }>(null!);

// Custom selector — component only re-renders when its slice changes
function useSelector<T>(selector: (s: State) => T): T {
  const { state } = useContext(PostCtx);
  const ref = useRef(selector(state));
  const next = selector(state);
  if (!Object.is(ref.current, next)) ref.current = next;
  return ref.current;
}

// Usage in component — no re-render on unrelated state changes
function PostList() {
  const posts = useSelector(s => s.posts);
  ...
}
```

**Why not just useContext alone:** Every state change re-renders ALL consumers. `useReducer` + `useSelector` gives you Redux-like precision without a library.

## 6. State Management — When to Use What

```
Component local state?
  → useState / useReducer

Shared by 2-5 components in same subtree?
  → useContext + custom hook wrapping it

Shared across pages, or 6+ consumers, or needs outside-React access?
  → Zustand (lightweight, selector-based, no boilerplate)

Large team, complex middleware, time-travel debugging?
  → Redux Toolkit
```

| Tool | Use when |
|------|----------|
| `useState` | Local to one component |
| `useContext` | Few consumers, same subtree, simple get/set |
| **Zustand** | App-wide, many consumers, outside React, selectors |
| Redux | Rare — only if the team/project already uses it |

**Key rule:** Never jump to a state library because "we might need it later." Start with `useContext`, extract to Zustand when the context re-render problem actually bites.

## 7. Error Boundaries — Crash a Section, Not the Whole Page

Wrap each logical section in its own ErrorBoundary. One component crashes → only that section shows fallback, the rest stays functional.

```tsx
// ✅ section-level boundaries
<ScrollSections>
  <section id="posts">
    <ErrorBoundary fallback={<p>Failed to load posts.</p>}>
      <PostList />
    </ErrorBoundary>
  </section>
  <section id="about">
    <ErrorBoundary fallback={<p>About section crashed.</p>}>
      <About />
    </ErrorBoundary>
  </section>
</ScrollSections>
```

Use `react-error-boundary` — same API as class-based, but hooks-friendly:

```tsx
import { ErrorBoundary } from 'react-error-boundary';

function PostList() {
  return (
    <ErrorBoundary
      fallback={<p className="editorial-empty">Something went wrong.</p>}
      onError={(err) => console.error(err)}
    >
      <Posts />
    </ErrorBoundary>
  );
}
```

| Rule | Why |
|------|-----|
| One per logical section | Isolate crashes, don't take down the page |
| `fallback` is a ReactNode | Match the design system, not a generic "Error!" text |
| `onError` to log | Don't swallow errors silently |
| NOT around every component | Only at meaningful boundaries (page sections, feature blocks) |

## Why a Separate Skill

`vercel-react-best-practices` is upstream. Team conventions live here so the upstream skill stays updateable.
