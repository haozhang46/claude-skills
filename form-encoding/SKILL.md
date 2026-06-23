---
name: form-encoding
description: 表单输入编码与 iframe 安全 — HTML entity 编码、URL 编码、XSS 防御、DOMPurify、encodeURIComponent、form 序列化、iframe postMessage 域名白名单
---

# 表单编码与 XSS 防御

## 编码场景

| 场景 | 编码方式 | 示例 |
|------|---------|------|
| HTML 内容中显示 | HTML Entity | `&lt;script&gt;` |
| HTML 属性中显示 | HTML Entity + 引号转义 | `&quot;` `&#39;` |
| URL 参数中传递 | URL 编码 | `%3Cscript%3E` |
| JSON 中传递 | JSON 序列化（内置转义） | `\u003Cscript\u003E` |
| JavaScript 字符串中 | JS 转义 | `\x3Cscript\x3E` |

## HTML Entity 编码

### 自动编码（框架默认）

```tsx
// ✅ React / Vue 默认 HTML entity 编码
// 以下自动将 <script> 转义为 &lt;script&gt;
const userInput = '<script>alert("xss")</script>';
return <div>{userInput}</div>;   // 显示原文，不执行
```

### 使用 `xss` npm 包（推荐代替手写）

```bash
npm install xss
```

```js
const xss = require('xss');

// 过滤所有 HTML 标签（默认模式）
xss('<script>alert(1)</script>');
// → "&lt;script&gt;alert(1)&lt;/script&gt;"

// 允许白名单标签
xss('<b>加粗</b><script>alert(1)</script>', {
  whiteList: { b: [], i: [], em: [], strong: [], a: ['href'] },
});
// → "<b>加粗</b>&lt;script&gt;alert(1)&lt;/script&gt;"

// 自定义规则：过滤全部 HTML（纯文本模式）
xss(userInput, { whiteList: {} });

// stripIgnoreTag：保留标签体但去掉标签本身
xss('<script>alert(1)</script>', { stripIgnoreTag: true });
// → "alert(1)"
```

**`xss` 包特点：**

| 能力 | `xss` 包 | 手动转义 |
|--|---------|-----------------|
| `<script>` 转义 | ✅ | ✅ |
| 事件属性（`onerror=`） | ✅ | ❌ |
| `javascript:` 协议 | ✅ | ❌ |
| CSS 注入 | ✅ | ❌ |
| 白名单标签允许 | ✅ | ❌ |
| 持续维护（CVE 跟进） | ✅ | ❌ |

### 什么时候需要手动编码

```tsx
// ❌ 需要手动编码：dangerouslySetInnerHTML
dangerouslySetInnerHTML={{ __html: xss(userInput) }}

// ❌ 需要手动编码：HTML 模板拼接
element.innerHTML = `<div>${xss(userInput)}</div>`

// ✅ 不需要：JSX 表达式
<div>{userInput}</div>

// ✅ 不需要：DOM textContent
element.textContent = userInput
```

## DOMPurify 安全输出

```bash
npm install dompurify
```

```tsx
import DOMPurify from 'dompurify';

// 允许部分安全 HTML 标签（加粗、链接等），过滤掉 script/onerror 等
const sanitized = DOMPurify.sanitize(userInput, {
  ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br'],
  ALLOWED_ATTR: ['href', 'target'],
});

<div dangerouslySetInnerHTML={{ __html: sanitized }} />
```

| 方式 | 允许 HTML | 性能 | 防护 |
|------|-----------|------|------|
| `{userInput}` (JSX) | ❌ 不允许 | 最快 | ✅ 完全 |
| `xss(userInput)` | ❌ 不允许 | 快 | ✅ 完全 |
| `DOMPurify.sanitize()` | ✅ 白名单标签 | 中 | ✅ 完全 |
| `不做任何处理` | ✅ 全部 | 快 | ❌ XSS |

## URL 编码

### encodeURIComponent

```js
// ❌ 直接拼接用户输入到 URL
fetch(`/api/search?q=${userInput}`);
// 如果用户输入 "&admin=true" → 多出一个参数

// ✅ 编码后拼接
fetch(`/api/search?q=${encodeURIComponent(userInput)}`);
// q=%26admin%3Dtrue

// encodeURIComponent 和 encodeURI 区别
encodeURIComponent('?a=1&b=2');  // → %3Fa%3D1%26b%3D2（全编码）
encodeURI('?a=1&b=2');           // → ?a=1&b=2（只编码特殊字符，保留 URL 结构）
```

### 表单序列化

```js
// ❌ 手动拼 form 数据
const formData = `name=${userInput}&phone=${phone}`;

// ✅ URLSearchParams（自动编码）
const params = new URLSearchParams();
params.append('name', userInput);
params.append('phone', phone);
fetch('/api/submit', { body: params });

// ✅ FormData（文件上传 + 自动编码）
const form = new FormData();
form.append('name', userInput);
form.append('avatar', fileInput.files[0]);
fetch('/api/upload', { method: 'POST', body: form });
```

| API | 自动编码 | 文件支持 | Content-Type |
|-----|---------|---------|-------------|
| `URLSearchParams` | ✅ | ❌ | `application/x-www-form-urlencoded` |
| `FormData` | ✅ | ✅ | `multipart/form-data` |
| 手动拼接 | ❌ | ❌ | 自定义 |

## 常见 XSS 注入点

### 属性注入

```html
<!-- ❌ 用户输入为 " onfocus="alert(1)" -->
<img src={userInput} />
<!-- 渲染后：<img src="" onfocus="alert(1)"> -->

<!-- ✅ 属性用 xss 编码 -->
<img src={xss(userInput)} />
```

### href / src 注入

```tsx
// ❌ javascript: 伪协议
<a href={userInput}>链接</a>
// 用户输入 "javascript:alert(1)"

// ✅ 协议白名单校验
function safeUrl(url) {
  const allowed = ['http:', 'https:', 'mailto:', 'tel:'];
  try {
    const parsed = new URL(url);
    return allowed.includes(parsed.protocol) ? url : '#';
  } catch {
    return '#';
  }
}
<a href={safeUrl(userInput)}>链接</a>
```

### innerHTML 注入

```js
// ❌
element.innerHTML = userInput;

// ✅
element.textContent = userInput;

// ✅ 需要 HTML 时用 DOMPurify
element.innerHTML = DOMPurify.sanitize(userInput);
```

## 编码与 XSS 对比表

| 输入 `<script>alert(1)</script>` | 输出 | 是否安全 |
|------|------|---------|
| 不处理直接渲染 | 弹窗 | ❌ |
| React `{input}` | 显示文本 | ✅ |
| `xss(input)` | `&lt;script&gt;...` | ✅ |
| `encodeURIComponent(input)` | `%3Cscript%3E...` | ✅ |
| `DOMPurify.sanitize(input)` | 空（script 不在白名单） | ✅ |
| `JSON.stringify(input)` | `"<script>..."` | ✅ |

---

## iframe postMessage — 域名白名单

跨域 iframe 通信必须校验 `event.origin`，绝对不能相信 `event.source` 或 `event.data` 本身。

### 父页面发送消息给 iframe

```tsx
const iframeRef = useRef<HTMLIFrameElement>(null);

// ✅ 指定 targetOrigin（白名单域名）
iframeRef.current?.contentWindow?.postMessage(
  { type: 'USER_INFO', payload: { id: 1, name: 'John' } },
  'https://trusted-app.example.com',    // ✅ 只发给这个域名
);

// ❌ 绝对不能用 '*'
iframeRef.current?.contentWindow?.postMessage(data, '*'); // 任何 iframe 都能收到
```

### 父页面接收 iframe 消息

```tsx
useEffect(() => {
  const allowedOrigins = [
    'https://trusted-app.example.com',
    'https://app-v2.example.com',
  ];

  const handleMessage = (event: MessageEvent) => {
    // 1️⃣ 校验域名白名单
    if (!allowedOrigins.includes(event.origin)) {
      console.warn('拒绝来自未知域名的消息:', event.origin);
      return;
    }

    // 2️⃣ 校验数据类型（避免 prototype pollution）
    if (typeof event.data !== 'object' || event.data === null) return;
    if (!event.data.type) return;

    // 3️⃣ 按 type 分发
    switch (event.data.type) {
      case 'HEIGHT_CHANGE':
        setIframeHeight(event.data.payload.height);
        break;
      case 'NAVIGATE':
        router.push(event.data.payload.path);
        break;
      default:
        console.warn('未知消息类型:', event.data.type);
    }
  };

  window.addEventListener('message', handleMessage);
  return () => window.removeEventListener('message', handleMessage);
}, []);
```

### iframe 内发送消息给父页面

```tsx
// iframe 内部
window.parent?.postMessage(
  { type: 'HEIGHT_CHANGE', payload: { height: document.body.scrollHeight } },
  'https://parent-app.example.com',    // ✅ 指定父页面域名
);
```

### iframe 内接收父页面消息

```tsx
useEffect(() => {
  const parentOrigins = [
    'https://parent-app.example.com',
  ];

  const handleMessage = (event: MessageEvent) => {
    // ❌ 不校验 origin → 任何网页都可以给 iframe 发消息（钓鱼）
    // ✅ 必须校验 origin
    if (!parentOrigins.includes(event.origin)) return;

    if (event.data.type === 'THEME_CHANGE') {
      applyTheme(event.data.payload.theme);
    }
  };

  window.addEventListener('message', handleMessage);
  return () => window.removeEventListener('message', handleMessage);
}, []);
```

### 安全 checklist

```js
// ❌ 常见错误
window.addEventListener('message', (e) => {
  if (e.data.type === 'login') {          // 没校验 origin
    doLogin(e.data.token);                // 任意网站都能伪造
  }
});

// ✅ 安全写法
const ALLOWED = ['https://myapp.com'];
window.addEventListener('message', (e) => {
  if (!ALLOWED.includes(e.origin)) return;  // 先校验
  if (!e.data?.type) return;                // 再验证结构
  // 然后处理
});
```

| 做法 | 风险 |
|------|------|
| `postMessage(data, '*')` | 任何窗口都能收到消息 |
| 不校验 `event.origin` | 任意网站伪造消息 |
| 不校验 `event.data` 结构 | Prototype pollution / 类型注入 |
| 只校验 `event.source` | `event.source` 可伪造（钓鱼页面） |

## Red Flags

- ❌ `{userInput}` 在 JSX 中是安全的，但在 `dangerouslySetInnerHTML` 中不安全
- ❌ `href={userInput}` 不校验 → `javascript:` 协议 XSS
- ❌ 手动拼 URL 参数不 `encodeURIComponent` → 参数注入
- ❌ 用 `encodeURI` 而不是 `encodeURIComponent` 编码参数值 → 一些字符没转义
- ❌ 前端编码就够了，后端不需要编码 → 后端也必须编码/校验（双重防御）
- ❌ `postMessage(data, '*')` → 任何窗口都能收到消息，必须指定具体域名
- ❌ `message` 事件不校验 `event.origin` → 任意网站可伪造消息，钓鱼/数据泄露
- ❌ `message` 事件不校验 `event.data` 结构 → prototype pollution / 类型注入
- ❌ 只校验 `event.source` 不校验 `event.origin` → `event.source` 可以被钓鱼页面利用
