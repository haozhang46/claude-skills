---
name: fe-security
description: Use when implementing authentication, handling user input, configuring CORS/CSP, or reviewing frontend security — covers XSS, CSRF, token storage, CSP, clickjacking, IDOR, and dependency auditing
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

## 8. IDOR — URL 中 ID 的权限校验

URL 里带 ID（`/api/orders/123`）本身不是问题，问题在于**后端有没有校验当前用户是否有权限访问这个 ID**。

### 正确做法：后端校验（不是前端能控制的）

```ts
// ❌ 只查订单，不查归属
app.get('/api/orders/:id', (req, res) => {
  const order = db.query('SELECT * FROM orders WHERE id = ?', req.params.id);
  res.json(order);
});

// ✅ 校验当前用户是否属于这个订单
app.get('/api/orders/:id', (req, res) => {
  const order = db.query(
    'SELECT * FROM orders WHERE id = ? AND user_id = ?',  // ← 关键
    req.params.id, req.user.id
  );
  if (!order) return res.status(403).json({ error: '无权访问' });
  res.json(order);
});
```

### ID 可预测时的额外防护

即使有了权限校验，可预测的 ID（自增 1,2,3）在以下场景仍有风险：

| 场景 | 风险 | 防护 |
|------|------|------|
| 订单列表 | 知道别人的订单号 | ✅ `WHERE user_id = ?` 已过滤 |
| 用户公开资料 | ID 可遍历抓取 | 加频率限制（Rate Limit） |
| 邀请链接 / 分享 | 猜别人 ID 看私密内容 | 用 UUID 替代自增 ID |

### 防止 ID 遍历

```ts
// ❌ 自增 ID 可遍历
/api/users/1
/api/users/2
/api/users/3  // 暴力猜

// ✅ UUID 不可预测
/api/users/a1b2c3d4-e5f6-7890-abcd-ef1234567890

// ✅ 或者加 Rate Limit
app.use('/api/users/:id', rateLimit({
  windowMs: 60 * 1000,   // 1 分钟
  max: 10,                // 最多 10 次
}));
```

### 常见误区

```ts
// ❌ 误区：前端把 ID 藏起来就安全了
// 前端不显示 ID，但浏览器 DevTools Network 还是能看到请求

// ❌ 误区：用 POST 代替 GET 来隐藏 ID
// POST /api/order  body: { id: 123 }  → 同样暴露

// ❌ 误区：前端加密 ID
// 前端加密 → 后端解密 → 加密算法暴露在 JS 里 → 伪安全

// ✅ 正确：后端永远校验权限，URL 里有没有 ID 不重要
```

### 三层防御

```
第一层：认证（你是谁）          → JWT / Session
第二层：授权（你能做什么）      → WHERE user_id = ?
第三层：限流（防止暴力遍历）    → Rate Limit
```

| 措施 | 解决什么问题 | 谁负责 |
|------|------------|--------|
| 权限校验 `WHERE user_id = ?` | 别人拿你的 ID 访问 | 后端 |
| UUID 替代自增 ID | 防止 ID 被猜出来 | 后端 |
| Rate Limit | 防止批量遍历 | 后端/Nginx |
| 前端不暴露多余信息 | 减少攻击面 | 前端 |

### 结论

**URL 里有 ID 本身不是漏洞**（RESTful API 本来就长这样）。真正的漏洞是**后端没有校验当前用户是否有权访问这个 ID 对应的资源**。前端能做的只是辅助（不暴露多余信息），真正防线在后端。

## Red Flags

- `localStorage.getItem('token')` — migrate to httpOnly cookie
- `dangerouslySetInnerHTML` without `DOMPurify`
- `Access-Control-Allow-Origin: *` with credentials
- No CSP header on the page
- `eval()` or `new Function()` anywhere near user input
- JWT stored in sessionStorage — still readable by XSS
