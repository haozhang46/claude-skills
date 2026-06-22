---
name: react-fe-skill
description: Use when writing React components or hooks — enforces named hook functions, component/hook splitting by cohesion, and team conventions not covered by vercel-react-best-practices
---

# React Frontend Conventions

Team-specific React rules complementing `vercel-react-best-practices`.

## 1. Named Hook Functions

All React hooks must use named functions. Anonymous arrow functions forbidden.

```tsx
// ❌ anonymous
useEffect(() => { fetchData(); }, []);

// ✅ named
useEffect(function syncScroll() { fetchData(); }, []);
```

## 2. Component Splitting — High Cohesion, Low Coupling

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

## 3. Hook vs Util — The State Rule

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

## 4. State Management — When to Use What

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

## Why a Separate Skill

`vercel-react-best-practices` is upstream. Team conventions live here so the upstream skill stays updateable.
