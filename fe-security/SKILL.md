---
name: fe-security
description: Use when implementing authentication, handling user input, configuring CORS/CSP, or reviewing frontend security — covers XSS, CSRF, token storage, CSP, clickjacking, and dependency auditing
---

# Frontend Security

## 1. XSS — Never `dangerouslySetInnerHTML` Without Sanitization

```tsx
// ❌ XSS hole — user content rendered as HTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// ✅ sanitize first
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userInput) }} />
```

**Rules:**
- React's JSX auto-escapes `{userInput}` — safe by default
- `dangerouslySetInnerHTML` = must sanitize with `DOMPurify`
- URL params rendered in JSX → encode with `encodeURIComponent`
- Never pass user input to `eval()`, `new Function()`, `setTimeout(string)`

## 2. Token Storage — httpOnly Cookie, Not localStorage

```ts
// ❌ XSS steals token
localStorage.setItem('token', jwt);

// ✅ httpOnly cookie — JS can't read it
// Set-Cookie: token=xxx; HttpOnly; SameSite=Strict; Secure; Path=/
```

| Storage | XSS-safe? | CSRF-safe? | Use |
|---------|-----------|------------|-----|
| `localStorage` | ❌ | ✅ | Never for tokens |
| `sessionStorage` | ❌ | ✅ | Never for tokens |
| Cookie (no HttpOnly) | ❌ | ❌ | Never |
| **Cookie + HttpOnly + SameSite** | ✅ | ✅ | Always |

Axios: `withCredentials: true` sends httpOnly cookies automatically.

## 3. CSRF — SameSite Cookie + Token Header

```ts
// SameSite=Lax — blocks cross-site POST requests
// Set-Cookie: token=xxx; HttpOnly; SameSite=Lax; Path=/
```

Modern browsers block cross-site cookies by default with `SameSite=Lax`. Double-submit cookie or CSRF token header for extra safety on critical endpoints.

## 4. CSP — Content Security Policy Header

```html
<!-- server response header -->
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' https:; connect-src 'self' https://api.example.com; font-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none';
```

**Key directives:**

| Directive | Purpose |
|-----------|---------|
| `script-src 'self'` | Block inline scripts + external scripts |
| `connect-src` | Limit where fetch/XHR can go |
| `frame-ancestors 'none'` | Prevent clickjacking |
| `object-src 'none'` | Block Flash/ActiveX |

## 5. CORS — Whitelist, Not Wildcard

```ts
// ❌
Access-Control-Allow-Origin: *

// ✅
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Credentials: true
```

Credentials + wildcard origin = browser rejects the combination. Always whitelist specific origins.

## 6. Dependency Audit

```bash
pnpm audit                    # npm audit equivalent
pnpm audit --prod             # production deps only
```

CI should run `pnpm audit --audit-level=high` and fail on critical vulnerabilities.

## 7. Input / Output Boundaries

```ts
// Input — validate at the boundary
const email = z.string().email().parse(input); // Zod validates

// Output — encode for context
encodeURIComponent(userInput)   // URL param
DOMPurify.sanitize(userInput)   // HTML
JSON.stringify(userInput)       // JSON (prevents injection in <script> tags)
```

## Red Flags

- `localStorage.getItem('token')` — migrate to httpOnly cookie
- `dangerouslySetInnerHTML` without `DOMPurify`
- `Access-Control-Allow-Origin: *` with credentials
- No CSP header on the page
- `eval()` or `new Function()` anywhere near user input
- JWT stored in sessionStorage — still readable by XSS
