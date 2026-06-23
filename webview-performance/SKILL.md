---
name: webview-performance
description: WebView 渲染过程与优化 — 浏览器 CRP、原生 WebView (Android/iOS)、React Native WebView 加载与渲染优化
---

# WebView 渲染过程与优化

## 浏览器渲染原理（CRP）

### 关键渲染路径（Critical Rendering Path）

```
HTML → DOM
        ↓
CSS  → CSSOM
        ↓
     Render Tree
        ↓
      Layout（回流）
        ↓
      Paint（绘制）
        ↓
     Composite（合成）
```

### 各阶段详解

#### 1. DOM 构建

```
HTML 字节 → 字符 → Token → 节点 → DOM 树
```

- 遇到 `<script>`（无 async/defer）→ **阻塞 DOM 构建**，先下载执行 JS
- 遇到 `<link rel="stylesheet">` → **不阻塞 DOM 构建**，但阻塞 Render Tree

#### 2. CSSOM 构建

```
CSS 字节 → 字符 → Token → CSSOM 树
```

- CSS 被认为**渲染阻塞**（Render Blocking）—— 没有 CSSOM 就不会渲染
- 浏览器会等所有 CSS 下载完才渲染

#### 3. Render Tree

DOM + CSSOM → **Render Tree**（只包含可见节点）

- `display: none` 的节点不进入 Render Tree
- `visibility: hidden` 进入 Render Tree（占位但不可见）
- `opacity: 0` 进入 Render Tree

#### 4. Layout（回流）

计算每个节点的**几何位置**（宽、高、x、y）。

```
触发回流：窗口 resize、DOM 增删、样式变化、className 变化
代价：重算整棵或部分 Render Tree 的几何
```

#### 5. Paint（绘制）

将节点绘制为**像素**。

```
触发重绘：颜色、背景、visibility 变化（不影响布局）
代价：小于回流，但仍走一遍 Paint 流水线
```

#### 6. Composite（合成）

将不同图层**合成为最终画面**（GPU 加速）。

```
只触发合成的属性：transform、opacity
代价：最小，GPU 合成，不触发 Layout 和 Paint
```

### 优化关键路径

```html
<!-- ❌ 同步 JS 阻塞 DOM -->
<script src="app.js"></script>

<!-- ✅ async：下载完就执行，不保证顺序 -->
<script async src="analytics.js"></script>

<!-- ✅ defer：HTML 解析完才执行，保证顺序 -->
<script defer src="app.js"></script>

<!-- ✅ 首屏关键 CSS 内联，非关键 CSS 延迟 -->
<style>/* 首屏关键 CSS */</style>
<link rel="preload" href="non-critical.css" as="style" onload="this.rel='stylesheet'">

<!-- ✅ preload 关键资源 -->
<link rel="preload" href="hero.webp" as="image">

<!-- ✅ prefetch 下一页 -->
<link rel="prefetch" href="/next-page">
```

| 优化手段 | 影响阶段 | 效果 |
|---------|---------|------|
| 内联关键 CSS | CSSOM → Render Tree | 减少 RTT，首屏更快 |
| async/defer | DOM 构建 | 不阻塞 DOM |
| preload 关键资源 | 所有阶段 | 提前下载，减少等待 |
| 避免强制同步布局 | Layout | 避免反复回流 |
| transform/opacity 做动画 | Composite | 跳过 Layout + Paint |
| 图片 lazy loading | Paint | 减少首屏渲染量 |

---

## 原生 WebView（Android / iOS）

### 加载流程

```
用户打开 WebView
  │
  ├─ 1. WebView 初始化（创建 WebView 实例）
  │     ⏱ 10~50ms
  │
  ├─ 2. loadUrl(url) / loadData()
  │
  ├─ 3. 网络请求（DNS + TCP + TLS + HTTP）
  │     ⏱ 取决于网络
  │
  ├─ 4. HTML 下载
  │
  ├─ 5. HTML 解析 + DOM 构建（内联 JS/CSS 阻塞）
  │
  ├─ 6. 子资源加载（CSS、JS、图片 → 并行下载，有并发上限）
  │
  ├─ 7. 渲染（Layout → Paint → Composite）
  │
  └─ 8. 首次内容绘制（FCP）/ 首次有效绘制（FMP）
```

### Android WebView 优化

```java
// 1. 预热 WebView（Android 7+）
// 在 Application.onCreate() 中提前初始化
WebView.setWebContentsDebuggingEnabled(true);

// 2. 启用硬件加速（默认开启）
// AndroidManifest.xml
<application android:hardwareAccelerated="true">

// 3. 缓存策略
webView.getSettings().setCacheMode(WebSettings.LOAD_DEFAULT);
// LOAD_DEFAULT  — 有缓存且未过期用缓存，否则网络
// LOAD_CACHE_ELSE_NETWORK — 离线模式
// LOAD_NO_CACHE — 不用缓存

// 4. 启用 DOM 缓存
webView.getSettings().setDomStorageEnabled(true);

// 5. 启用数据库缓存
webView.getSettings().setDatabaseEnabled(true);

// 6. 启用应用缓存
webView.getSettings().setAppCacheEnabled(true);
webView.getSettings().setAppCachePath(getCacheDir().getAbsolutePath());

// 7. 并行加载（Android 8+ 默认多进程渲染）
// 8. 资源拦截（拦截本地资源替代网络请求）
webView.setWebViewClient(new WebViewClient() {
    @Override
    public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
        String url = request.getUrl().toString();
        if (url.endsWith(".js") || url.endsWith(".css")) {
            // 返回本地缓存的资源
            return new WebResourceResponse("text/javascript", "UTF-8",
                new FileInputStream(getLocalCacheFile(url)));
        }
        return null;
    }
});
```

### iOS WebView（WKWebView）优化

```swift
// 1. 使用 WKWebView（不要用 UIWebView，已废弃）
import WebKit

// 2. 预热 WKWebView（iOS 9+）
let pool = WKProcessPool()  // 全局复用，共享 cookie、缓存
let config = WKWebViewConfiguration()
config.processPool = pool

// 3. 配置缓存
config.websiteDataStore = WKWebsiteDataStore.default()
// 或非持久化（隐私模式）
// config.websiteDataStore = WKWebsiteDataStore.nonPersistent()

// 4. 预加载
// iOS 15+ 支持预加载（SFSafariViewController 预加载）
// WKWebView 可通过 prefetch 链接或 Service Worker 实现

// 5. JS 注入时机
config.userContentController.addUserScript(
    WKUserScript(source: jsCode,
                 injectionTime: .atDocumentEnd,  // DOM 加载完后注入
                 forMainFrameOnly: true)
)

// 6. 禁用不用的功能
config.preferences.javaScriptEnabled = true  // 需要时开启
config.allowsInlineMediaPlayback = false     // 不需要则关闭

// 7. 评估性能
webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
```

### 通用优化

#### WebView 池化

```java
// Android — WebView 复用池，避免每次创建
public class WebViewPool {
    private final Queue<WebView> pool = new LinkedList<>();

    public WebView acquire() {
        WebView wv = pool.poll();
        if (wv == null) {
            wv = createWebView();
        }
        return wv;
    }

    public void release(WebView wv) {
        wv.loadUrl("about:blank");  // 清空
        wv.removeAllViews();
        pool.offer(wv);
    }
}
```

#### 预加载 + 缓存

```java
// 1. 提前初始化 WebView（App 启动时预热）
// Application.onCreate 中提前创建 WebView 实例

// 2. Service Worker 缓存（PWA）
// H5 端注册 Service Worker
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js');
}

// 3. 预渲染（下一个页面提前加载）
webView.loadUrl(url);  // 在真正展示前提前 load
// 展示时已经渲染完成，直接 attach 到 view
```

#### 关键渲染路径优化（H5 侧）

```html
<!-- 1. 首屏关键 CSS 内联 -->
<style>/* 首屏样式 */</style>

<!-- 2. 非关键 CSS 异步加载 -->
<link rel="preload" href="style.css" as="style" onload="this.rel='stylesheet'">

<!-- 3. JS 延迟加载 -->
<script defer src="app.js"></script>

<!-- 4. 图片懒加载 -->
<img loading="lazy" src="image.jpg">

<!-- 5. 预连接 -->
<link rel="preconnect" href="https://api.example.com">
<link rel="dns-prefetch" href="https://api.example.com">
```

---

## React Native WebView

### 基本使用

```tsx
import { WebView } from 'react-native-webview';

<WebView
  source={{ uri: 'https://example.com' }}
  style={{ flex: 1 }}
/>
```

### 渲染过程

```
RN WebView 组件挂载
  │
  ├─ 原生端创建 WebView 实例（Android WebView / iOS WKWebView）
  │
  ├─ 加载 URL / HTML
  │
  ├─ H5 渲染（走浏览器 CRP 流程）
  │
  ├─ JS Bridge 通信（RN ↔ H5 互相调用）
  │
  └─ 页面内容通过原生 View 系统渲染到屏幕
```

### JS Bridge 通信

```tsx
// RN → H5：postMessage
<WebView
  ref={webViewRef}
  source={{ uri: 'https://example.com' }}
  onMessage={(event) => {
    // H5 → RN：接收消息
    const data = JSON.parse(event.nativeEvent.data);
    console.log('来自 H5:', data);
  }}
  injectedJavaScript={`
    // RN → H5：注入 JS（页面加载后执行）
    document.body.style.backgroundColor = 'red';
    window.ReactNativeWebView.postMessage(JSON.stringify({
      type: 'PAGE_LOADED',
      payload: { url: window.location.href }
    }));
    true; // 必须返回
  `}
/>

// RN → H5（任意时机）
webViewRef.current.postMessage(JSON.stringify({ action: 'refresh' }));

// H5 监听 RN 消息
window.addEventListener('message', (event) => {
  console.log('来自 RN:', JSON.parse(event.data));
});
```

### 性能优化

```tsx
// 1. 缓存策略
<WebView
  source={{ uri: 'https://example.com' }}
  // Android 缓存
  androidLayerType="hardware"
  setSupportMultipleWindows={false}
  // iOS 配置
  allowsInlineMediaPlayback={false}
  // 缓存模式（Android）
  cacheEnabled={true}
/>

// 2. 预加载（提前创建 WebView 实例）
const [preloaded, setPreloaded] = useState(false);
const preloadedRef = useRef<WebView>(null);

useEffect(() => {
  // App 启动时预加载
  setPreloaded(true);
}, []);

// 3. 资源拦截（减少网络请求）
<WebView
  source={{ uri: 'https://example.com' }}
  onShouldStartLoadWithRequest={(request) => {
    // 拦截特定 URL，使用本地资源
    if (request.url.endsWith('.css')) {
      return false; // 阻止网络请求
    }
    return true;
  }}
/>

// 4. 注入 CSS/JS 减少渲染量
const injectedCSS = `
  .header, .footer { display: none; }
  img { max-width: 100%; height: auto; }
`;

<WebView
  source={{ uri: 'https://example.com' }}
  injectedJavaScript={`
    var style = document.createElement('style');
    style.textContent = \`${injectedCSS}\`;
    document.head.appendChild(style);
  `}
/>

// 5. 延迟加载（非首屏 WebView）
const [showWebView, setShowWebView] = useState(false);

return (
  <View>
    <Button title="加载网页" onPress={() => setShowWebView(true)} />
    {showWebView && <WebView source={{ uri: 'https://example.com' }} />}
  </View>
);
```

### 优化对比

| 优化手段 | 效果 | 实现难度 |
|---------|------|---------|
| WebView 池化 | 减少初始化时间（50ms→0） | 中 |
| 预加载 | 提前下载渲染，展示时已就绪 | 低 |
| 资源拦截 | 减少网络请求，本地加载 | 高 |
| 缓存策略 | 重复打开秒开 | 低 |
| 注入 CSS 精简内容 | 减少渲染量，提升 FCP | 低 |
| JS Bridge 通信优化 | 减少 RN ↔ H5 通信开销 | 中 |
| 非首屏懒加载 | 首屏不加载 WebView | 低 |

### Red Flags

- ❌ WebView 不设缓存 → 每次重新加载，白屏时间长
- ❌ 首屏就加载多个 WebView → 内存暴增、卡顿
- ❌ postMessage 频繁传递大对象 → JS Bridge 序列化开销
- ❌ 忽略 H5 侧 CRP 优化 → WebView 内部渲染慢
- ❌ HTML 内联大量 JS 阻塞 DOM → FCP 延迟
- ❌ iOS 用 UIWebView 替代 WKWebView → 内存泄漏、性能差
