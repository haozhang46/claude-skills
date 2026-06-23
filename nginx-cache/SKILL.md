---
name: nginx-cache
description: Nginx 前端缓存策略 — 静态资源缓存、Cache-Control、ETag、hash 缓存破坏、Gzip、CDN 回源、SPA 路由配置
---

# Nginx 前端缓存策略

## 静态资源缓存

### 按文件类型配置缓存

```nginx
# 图片 — 长缓存（文件 hash 或版本号在 URL 中）
location ~* \.(jpg|jpeg|png|gif|webp|avif|svg|ico)$ {
    expires 365d;
    add_header Cache-Control "public, immutable, max-age=31536000";
    access_log off;          # 静态资源不记日志
}

# 字体 — 长缓存
location ~* \.(woff|woff2|ttf|eot)$ {
    expires 365d;
    add_header Cache-Control "public, immutable, max-age=31536000";
    add_header Access-Control-Allow-Origin "*";  # 跨域字体
    access_log off;
}

# CSS/JS — 长缓存（通过文件名 hash 破坏缓存）
location ~* \.(css|js)$ {
    expires 365d;
    add_header Cache-Control "public, immutable, max-age=31536000";
    access_log off;
}

# HTML — 不缓存（或短缓存）
location ~* \.(html|htm)$ {
    expires -1;                           # 不缓存
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}
```

| 文件类型 | TTL | Cache-Control | 说明 |
|---------|-----|---------------|------|
| 图片 (jpg/png/webp) | 365d | `public, immutable` | hash 文件名 |
| 字体 (woff2/ttf) | 365d | `public, immutable` | 需跨域头 |
| CSS/JS | 365d | `public, immutable` | 构建工具打 hash |
| HTML | 不缓存 | `no-cache, no-store` | 确保实时更新 |

### 缓存破坏（Cache Busting）

前端构建工具（webpack/vite）在文件名中注入 hash，Nginx 直接配长缓存：

```nginx
# ✅ 构建后的文件：main.a1b2c3.js → 永远缓存
location ~* \.[a-f0-9]{8}\.(css|js)$ {
    expires 365d;
    add_header Cache-Control "public, immutable, max-age=31536000";
}
```

```tsx
// webpack/vite 输出
// main.a1b2c3f4.js   ← hash 变了就是新文件
// main.5678abcd.css
// 每次部署文件 hash 不同，浏览器自动下载新版本
```

### HTML 不缓存的正确写法

```nginx
location / {
    # SPA 路由：所有路径返回 index.html
    try_files $uri $uri/ /index.html;

    # HTML 不缓存
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
}
```

**`no-cache` vs `no-store`：**

| 头 | 行为 |
|----|------|
| `no-cache` | 每次请求回源验证（ETag/Last-Modified），验证通过用缓存 |
| `no-store` | 完全不存缓存，每次都下载 |
| `must-revalidate` | 过期后必须回源验证 |

HTML 推荐用 `no-cache`（配合 ETag），不要用 `no-store`。

---

## ETag / Last-Modified

```nginx
# 开启 ETag（默认开启）
etag on;

# 关闭 Last-Modified（如果不需要）
# last_modified off;

# 强 ETag（默认） vs 弱 ETag
# 强 ETag: "abc123" — 内容不同 ETag 一定不同
# 弱 ETag: W/"abc123" — 语义等价时 ETag 可相同
```

Nginx 默认自动生成 ETag（基于文件 mtime + size）。304 响应比完整 200 快得多。

---

## Gzip / Brotli 压缩

```nginx
# Gzip
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 5;                    # 1~9，推荐 5（平衡比）
gzip_min_length 1024;                 # 小于 1KB 不压缩
gzip_types
    text/plain
    text/css
    text/javascript
    application/javascript
    application/json
    image/svg+xml
    font/woff
    font/woff2
    application/vnd.ms-fontobject;

# Brotli（需要 ngx_brotli 模块）
brotli on;
brotli_comp_level 6;
brotli_types
    text/plain
    text/css
    text/javascript
    application/javascript
    application/json;
```

| 压缩方式 | 压缩率 | 需要模块 | 浏览器支持 |
|---------|--------|---------|-----------|
| Gzip | 中 | 内置 | 所有 |
| Brotli | 高（比 gzip 小 20~30%） | `ngx_brotli` | 现代浏览器 |

---

## CDN 回源缓存配置

```nginx
# ┌─────────┐       ┌─────────┐       ┌──────────┐
# │ 浏览器   │  ←→  │  CDN    │  ←→  │  Nginx   │
# │ (私有)   │      │ (公有)  │      │ (源站)   │
# └─────────┘       └─────────┘       └──────────┘
```

```nginx
# CDN 回源时给 CDN 的缓存指令（区分客户端和 CDN）
location ~* \.(css|js|jpg|png)$ {
    # 客户端缓存 1 年
    add_header Cache-Control "public, immutable, max-age=31536000";

    # CDN 缓存 1 天（CDN 会忽略 private，只认 public）
    add_header X-Cache-TTL "86400";
}
```

```nginx
# CDN 回源忽略 cookie（避免缓存被 cookie 打碎）
location ~* \.(css|js|jpg|png|woff2)$ {
    proxy_no_cache $http_cookie;    # 有 cookie 时不从缓存取
    proxy_cache_bypass $http_cookie; # 有 cookie 时绕过缓存
}
```

**CDN 缓存注意事项：**
- 静态资源（hash 文件名）→ CDN 长缓存（1 年）
- HTML → CDN 短缓存或不缓存
- 区分 CDN 缓存和浏览器缓存：CDN 用 `s-maxage`，浏览器用 `max-age`

```nginx
# 同时控制浏览器和 CDN 缓存
location ~* \.(css|js)$ {
    add_header Cache-Control "public, immutable, max-age=31536000, s-maxage=86400";
}
# 浏览器: 1 年
# CDN:     1 天
```

---

## SPA 路由配置

```nginx
server {
    listen 80;
    server_name example.com;

    root /var/www/dist;
    index index.html;

    # Gzip
    gzip on;
    gzip_types text/css application/javascript image/svg+xml;

    # 静态资源长缓存
    location ~* \.(?:css|js|jpg|jpeg|png|gif|webp|svg|ico|woff2?|ttf|eot)$ {
        expires 365d;
        add_header Cache-Control "public, immutable, max-age=31536000";
        add_header Access-Control-Allow-Origin "*";
        access_log off;
    }

    # SPA 路由：所有路径指向 index.html
    location / {
        try_files $uri $uri/ /index.html;

        # HTML 不缓存
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }

    # API 反向代理（不缓存）
    location /api/ {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;

        # API 不缓存
        add_header Cache-Control "no-store";
    }
}
```

---

## 安全性补充

```nginx
# 隐藏 Nginx 版本号
server_tokens off;

# 防止 MIME 类型嗅探
add_header X-Content-Type-Options "nosniff";

# 静态资源防盗链
location ~* \.(jpg|jpeg|png|gif|webp|svg)$ {
    valid_referers none blocked ~\.example\.com;
    if ($invalid_referer) {
        return 403;
    }
}
```

---

## 完整示例

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    root /var/www/dist;
    index index.html;

    # SSL（省略具体配置）
    ssl_certificate /etc/ssl/certs/example.com.pem;
    ssl_certificate_key /etc/ssl/private/example.com.key;

    # 安全头
    server_tokens off;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_comp_level 5;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    # 静态资源（hash 文件名）→ 长缓存
    location ~* \.[a-f0-9]{8}\.(css|js)$ {
        expires 365d;
        add_header Cache-Control "public, immutable, max-age=31536000";
        access_log off;
    }

    # 静态资源（非 hash）→ 短缓存
    location ~* \.(?:jpg|jpeg|png|gif|webp|svg|ico|woff2?|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
        access_log off;
    }

    # SPA 路由
    location / {
        try_files $uri $uri/ /index.html;
    }

    # HTML 不缓存
    location ~* \.html$ {
        expires -1;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # API
    location /api/ {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        add_header Cache-Control "no-store";
    }
}
```

---

## Red Flags

- ❌ HTML 也设长缓存 → 更新后用户看不到新页面
- ❌ 所有静态资源无 hash 统一长缓存 → 更新后用户缓存不失效
- ❌ 字体不设跨域头 → 浏览器加载字体 404（`Access-Control-Allow-Origin`）
- ❌ `no-cache` 和 `no-store` 混用 — HTML 用 `no-cache` 配合 ETag，API 用 `no-store`
- ❌ 大文件开 Gzip（> 1MB）→ CPU 开销大收益低，设 `gzip_min_length`
- ❌ CDN 回源时 cookie 打碎缓存 → 静态资源无视 cookie
