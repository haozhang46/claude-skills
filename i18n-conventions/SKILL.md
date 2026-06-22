---
name: i18n-conventions
description: Use when implementing multi-language support, choosing i18n library, or structuring translation files — covers next-intl, i18next, ICU format, and locale routing
---

# i18n — Multi-Language Conventions

## 1. Library Choice

| Library | Use when |
|---------|----------|
| **next-intl** | Next.js App Router, server-side i18n, RSC-compatible |
| **i18next** + **react-i18next** | Framework-agnostic, largest ecosystem, most plugins |
| **FormatJS / react-intl** | ICU message format, complex plural/gender rules |
| **lingui** | Compile-time extraction, macro-based, smallest bundle |

**Recommendation:** `next-intl` for Next.js projects — server-side translations, no client JS for static content.

```bash
pnpm add next-intl
```

## 2. Translation File Structure

```
messages/
├── en.json          # base language
├── zh.json          # Chinese
├── ja.json          # Japanese
└── index.ts         # import + re-export
```

**`en.json`:**
```json
{
  "home": {
    "title": "Thoughts & Code",
    "subtitle": "Writing about technology, design, and building software.",
    "scrollHint": "Scroll"
  },
  "posts": {
    "label": "Latest Posts",
    "empty": "No posts yet."
  },
  "about": {
    "label": "About",
    "text": "Hi, I'm hz — a software engineer."
  }
}
```

**Key rules:**
- JSON flat or nested by page/section — don't mix styles
- Key names in English (source language), values translated
- No concatenation: `"Welcome, " + name` → use ICU: `"Welcome, {name}"`
- Plural: `"{count, plural, =0 {No posts} one {# post} other {# posts}}"`

## 3. next-intl Setup

```ts
// i18n.ts
import { getRequestConfig } from 'next-intl/server';

export default getRequestConfig(async ({ locale }) => ({
  messages: (await import(`./messages/${locale}.json`)).default,
}));
```

```ts
// middleware.ts — locale routing
import createMiddleware from 'next-intl/middleware';
export default createMiddleware({ locales: ['en', 'zh'], defaultLocale: 'en' });
export const config = { matcher: ['/((?!api|_next|_vercel|.*\\..*).*)'] };
```

**Component usage:**
```tsx
// Server component — no client JS
import { useTranslations } from 'next-intl';
function HomePage() {
  const t = useTranslations('home');
  return <h1>{t('title')}</h1>;
}

// Client component — interactive translations
'use client';
import { useTranslations } from 'next-intl';
```

## 4. Locale-Aware Formatting

```ts
// Date / number respect locale automatically
import { useFormatter } from 'next-intl';
const format = useFormatter();
format.dateTime(new Date(), { dateStyle: 'medium' }); // "Jun 23, 2026" vs "2026年6月23日"
format.number(1234567); // "1,234,567" vs "1.234.567"
```

## 5. Dynamic Content — ICU Message Format

```json
{
  "postCount": "{count, plural, =0 {No posts} one {# post} other {# posts}}",
  "publishedAt": "Published on {date, date, medium}",
  "authorNote": "{name} wrote {count, plural, one {# article} other {# articles}}"
}
```

## Red Flags

- Hardcoded strings in components → extract to messages JSON
- `"Post" + "s"` for plurals → ICU plural
- Server-only i18n library for SPA → won't work without server
- No locale prefix in URL (`/about` vs `/en/about`) → SEO penalty
