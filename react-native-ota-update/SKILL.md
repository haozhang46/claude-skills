---
name: react-native-ota-update
description: React Native OTA update strategies — full bundle (CodePush, Expo Updates) vs partial chunk-based (Re.Pack code splitting), deployment workflow, rollback
---

# React Native — OTA 发布策略

## 全量发布 vs 部分发布

| | 全量发布 (Full Bundle) | 部分发布 (Chunk-Based) |
|------|----------------------|-----------------------|
| 更新内容 | 整个 JS bundle 替换 | 只下发变更的代码 chunk |
| 流量消耗 | 大（整个 app 的 JS） | 小（仅 diff） |
| 首次安装 | 全量下载 | 基础 chunk + 按需加载 |
| 工具 | CodePush, Expo Updates | Re.Pack + code splitting |
| Hermes 兼容 | 全量 bytecode 替换 | Hermes 不支持增量 bytecode |

---

## 方案 A: CodePush — 全量 Bundle 替换

> ⚠️ App Center 已于 2025 年 3 月退役，CodePush 仓库已归档。v9.0.1 为末版，
> 不支持 RN New Architecture（0.76+ 需 opt-out）。

```tsx
// 接入
import codePush from 'react-native-code-push';

let codePushOptions = {
  checkFrequency: codePush.CheckFrequency.ON_APP_RESUME,
  installMode: codePush.InstallMode.ON_NEXT_RESTART,
};

export default codePush(codePushOptions)(App);
```

```bash
# 发布更新
appcenter codepush release-react -a <owner>/<app> -d Production

# 分阶段灰度发布
appcenter codepush promote -a <owner>/<app> -s Staging -d Production -r 20

# 回滚
appcenter codepush rollback -a <owner>/<app> Production
```

### 自托管 CodePush 替代方案

- `react-native-update` (爱范儿开发)
- 自建 OTA 服务器 + `react-native-code-push` fork
- Expo Updates 自托管

---

## 方案 B: Expo Updates — 全量 Bundle 替换

Expo 生态的原生 OTA 方案，支持托管和自托管。

```tsx
// app.json
{
  "expo": {
    "runtimeVersion": "1.0.0",
    "updates": {
      "url": "https://u.expo.dev/<your-project-id>",
      "enabled": true,
      "checkAutomatically": "ON_LOAD"
    }
  }
}
```

```bash
# 发布
eas update --branch production --message "v1.2.0"

# 分批发布
eas update --branch production --rollout-percentage 30
```

| 特性 | Expo Updates | CodePush |
|------|-------------|----------|
| 托管服务 | Expo 官方 | App Center (已退役) |
| 自托管 | ✅ (自建 server) | ✅ (自建) |
| Hermes | ✅ | ✅ (v9+) |
| New Architecture | ✅ | ❌ |
| 灰度发布 | ✅ (rollout-percentage) | ✅ (promote -r) |
| 回滚 | ✅ eas update:rollback | ✅ codepush rollback |

---

## 方案 C: Re.Pack + Code Splitting — 部分发布

基于 webpack/rspack 的代码拆分，实现**只有改过的 chunk** 才下发。

```tsx
// repack.config.js — 配置 split chunks
module.exports = {
  mode: 'production',
  output: {
    // 每个页面/模块独立 chunk
    chunkFilename: '[name].[contenthash].chunk.bundle',
  },
  optimization: {
    splitChunks: {
      chunks: 'all',
      minSize: 0,
      cacheGroups: {
        // 基础框架（react, react-native）单独一个 chunk，很少更新
        framework: {
          test: /[\\/]node_modules[\\/](react|react-native|@react-native)[\\/]/,
          name: 'framework',
          chunks: 'all',
          priority: 40,
        },
        // 页面级 chunk
        screens: {
          test: /[\\/]src[\\/]screens[\\/]/,
          name: 'screens',
          chunks: 'async',
          priority: 30,
        },
      },
    },
  },
};
```

```tsx
// 动态加载页面 — 只在需要时下载对应 chunk
const HomeScreen = React.lazy(() => import('./screens/HomeScreen'));
const ProfileScreen = React.lazy(() => import('./screens/ProfileScreen'));

function AppNavigator() {
  return (
    <Suspense fallback={<Loading />}>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
      </Stack.Navigator>
    </Suspense>
  );
}
```

### 增量更新流程

```
v1.0.0 → 发布所有 chunks
v1.0.1 → 只修改了 HomeScreen → 只有 home.chunk.xxx.bundle 变更
        → 客户端下载新的 home chunk + 旧的 framework chunk 复用
```

### Re.Pack + OTA 更新方案

Re.Pack 本身不做 OTA 下发，需配合文件服务器或 CDN：

```tsx
// 自定义 OTA 检查 + chunk 下载
async function checkForUpdates() {
  const manifest = await fetch('https://cdn.example.com/manifest.json');
  const localVersion = AsyncStorage.getItem('app-version');

  if (manifest.version !== localVersion) {
    // 只下载变更的 chunks
    for (const chunk of manifest.chunks) {
      if (!chunk.isLocal) {
        await downloadChunk(chunk.url, chunk.filename);
      }
    }
    await AsyncStorage.setItem('app-version', manifest.version);
  }
}
```

---

## 方案对比总结

| | CodePush | Expo Updates | Re.Pack + Splitting |
|--|----------|-------------|-------------------|
| 模式 | 全量 bundle | 全量 bundle | 按需 chunk |
| 更新粒度 | 整体替换 | 整体替换 | 单个 chunk |
| 更新体积 | 大 | 大 | 小 |
| 生态状态 | ⛔ 已归档 | ✅ 活跃 | ✅ 活跃 |
| New Arch | ❌ | ✅ | ✅ |
| Hermes | ✅ (末版) | ✅ | ❌ (增量不兼容) |
| 灰度发布 | ✅ | ✅ | 需自建 |
| 回滚 | ✅ | ✅ | 需自建 |
| 学习成本 | 低 | 低 | 高 (webpack) |

### 建议

- **小型 app / 快速迭代** → Expo Updates（最简单）
- **中型 app / 纯 RN** → CodePush 自托管 或 Expo Updates 自托管
- **大型 app / 按需加载** → Re.Pack + code splitting + 自建 OTA 下发
- **金融/安全类** → 全量发布（不允许增量 bytecode）
