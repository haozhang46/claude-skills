---
name: form-encoding
description: 表单输入编码 — HTML entity 编码、URL 编码、XSS 防御、DOMPurify 安全输出、encodeURIComponent 与 form 序列化
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

### 手动编码函数

```js
// 完整的 HTML entity 编码
function encodeHtml(str) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
    '/': '&#x2F;',
  };
  return str.replace(/[&<>"'\/]/g, char => map[char]);
}

encodeHtml('<script>alert("xss")</script>');
// → "&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;"
```

```js
// 轻量版（只转义最关键的 5 个字符）
function escapeHtml(str) {
  const div = document.createElement('div');
  div.appendChild(document.createTextNode(str));
  return div.innerHTML;
}
// 利用 DOM API，浏览器帮你转义
```

### 什么时候需要手动编码

```tsx
// ❌ 需要手动编码：dangerouslySetInnerHTML
dangerouslySetInnerHTML={{ __html: encodeHtml(userInput) }}

// ❌ 需要手动编码：HTML 模板拼接
element.innerHTML = `<div>${encodeHtml(userInput)}</div>`

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
| `encodeHtml(userInput)` | ❌ 不允许 | 快 | ✅ 完全 |
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

<!-- ✅ 属性用 encodeHtml 编码 -->
<img src={encodeHtml(userInput)} />
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
| `encodeHtml(input)` | `&lt;script&gt;...` | ✅ |
| `encodeURIComponent(input)` | `%3Cscript%3E...` | ✅ |
| `DOMPurify.sanitize(input)` | 空（script 不在白名单） | ✅ |
| `JSON.stringify(input)` | `"<script>..."` | ✅ |

## Red Flags

- ❌ `{userInput}` 在 JSX 中是安全的，但在 `dangerouslySetInnerHTML` 中不安全
- ❌ `href={userInput}` 不校验 → `javascript:` 协议 XSS
- ❌ 手动拼 URL 参数不 `encodeURIComponent` → 参数注入
- ❌ 用 `encodeURI` 而不是 `encodeURIComponent` 编码参数值 → 一些字符没转义
- ❌ 前端编码就够了，后端不需要编码 → 后端也必须编码/校验（双重防御）
