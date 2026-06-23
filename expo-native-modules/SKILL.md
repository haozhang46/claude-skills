---
name: expo-native-modules
description: Expo 原生模块方案 — Expo Go vs Development Build，Expo Modules API (Swift/Kotlin)，自定义原生方法调用
---

# Expo — 调用原生方法

## Expo 的两种架构

| | Expo Go | Development Build |
|--|---------|-----------------|
| 本质 | 官方预编译的通用 App | 你自己构建的原生 App |
| 自定义原生代码 | ❌ 不行（只能用 Expo SDK 内置模块） | ✅ 可以 |
| 社区 RN 库 | ❌ 只有 Expo SDK 白名单内的 | ✅ 全部可用 |
| 调试 | 扫码即用，最快 | 需 `eas build` 或本地编译 |
| 适用 | 原型/学习/纯 JS 项目 | 生产项目、需要原生能力 |

---

## 调用原生方法的三种方式

### 1. Expo Modules API（推荐）

Expo 官方的原生模块方案，Swift / Kotlin 编写，自动链接，Codegen 生成 TS 类型。

```bash
# 创建模块
npx create-expo-module my-module

# 链接到项目
npx expo install ../../modules/my-module
```

**iOS — Swift：**
```swift
// modules/my-module/ios/MyModule.swift
import ExpoModulesCore

public class MyModule: Module {
  public func definition() -> ModuleDefinition {
    Name("MyModule")

    // 同步
    Function("getDeviceName") {
      return UIDevice.current.name
    }

    // 异步
    AsyncFunction("getBatteryLevel") { (promise: Promise) in
      UIDevice.current.isBatteryMonitoringEnabled = true
      let level = UIDevice.current.batteryLevel
      if level >= 0 { promise.resolve(level) }
      else { promise.reject("ERR", "Unavailable") }
    }

    // 带参数
    AsyncFunction("showAlert") { (title: String, message: String, promise: Promise) in
      // ...
    }
  }
}
```

**Android — Kotlin：**
```kotlin
// modules/my-module/android/.../MyModule.kt
package expo.modules.mymodule
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class MyModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("MyModule")

    Function("getDeviceName") {
      return@Function android.os.Build.MODEL
    }

    AsyncFunction("getBatteryLevel") { promise: Promise ->
      val manager = appContext.reactContext?.getSystemService(
        android.content.Context.BATTERY_SERVICE
      ) as? android.os.BatteryManager
      promise.resolve(manager?.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY))
    }
  }
}
```

**TypeScript：**
```ts
import MyModule from './modules/my-module';

console.log(MyModule.getDeviceName());        // 同步
MyModule.getBatteryLevel().then(console.log); // 异步
```

### 2. Config Plugin + 原生代码

轻量场景，不需要完整模块，只修改原生项目配置。

```ts
// app.config.ts
const { withProjectBuildGradle } = require('@expo/config-plugins');

module.exports = function withMyPlugin(config) {
  return withProjectBuildGradle(config, (config) => {
    config.modResults.contents += `\n// 自定义配置\n`;
    return config;
  });
};
```

### 3. 社区 react-native-* 库

前提：使用 **Development Build**（Expo Go 不行）。

```bash
npx expo install react-native-webview react-native-firebase/app react-native-video

# 必须 development build
npx expo run:ios          # 本地编译
eas build --profile development  # 远程编译
```

---

## 选择路径

```
需要自定义原生方法？
├── 不需要 → Expo Go（纯 JS）
└── 需要 →
    ├── 轻量修改 → Config Plugin
    ├── 完整原生模块 → Expo Modules API
    └── 用社区库 → Development Build + npx expo install
```

## Red Flags

- ❌ **Expo Go 不能加自定义原生代码** — 必须用 Development Build
- ❌ Expo Modules API 的模块名不能重复，`Name("")` 需唯一
- ❌ 同步 `Function` 不能做耗时操作，会卡 JS 线程；耗时操作用 `AsyncFunction`
