---
name: react-native-keyboard-safearea
description: React Native keyboard avoidance + SafeArea patterns — SafeAreaView, useSafeAreaInsets, KeyboardAvoidingView, KeyboardAwareScrollView, platform differences
---

# React Native — Keyboard & SafeArea

## SafeArea — `react-native-safe-area-context`

Always use `react-native-safe-area-context` (not the deprecated `SafeAreaView` from RN core).

### Setup

```tsx
// App.tsx — wrap root
import { SafeAreaProvider } from 'react-native-safe-area-context';

export default function App() {
  return (
    <SafeAreaProvider>
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </SafeAreaProvider>
  );
}
```

### SafeAreaView — Full Screen Safe Zone

```tsx
import SafeAreaView from 'react-native-safe-area-context';

// ❌ RN core SafeAreaView — deprecated, no edge control
import { SafeAreaView } from 'react-native';

// ✅ SafeAreaView from safe-area-context — edges prop
<SafeAreaView edges={['top', 'bottom']} style={{ flex: 1 }}>
  <YourContent />
</SafeAreaView>
```

| `edges` | Effect |
|---------|--------|
| `['top']` | Pads below status bar / notch / Dynamic Island |
| `['bottom']` | Pads above home indicator |
| `['top', 'bottom']` | Most common — both ends |
| `['left', 'right']` | Rare (iPad landscape split view) |
| `[]` | No padding (op-out specific edge) |

### useSafeAreaInsets Hook — Manual Control

Use when you need custom layout around SafeArea (e.g. a custom header).

```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context';

function CustomHeader() {
  const insets = useSafeAreaInsets();
  // insets = { top: 47, bottom: 34, left: 0, right: 0 }

  return (
    <View style={{ paddingTop: insets.top, height: 44 + insets.top }}>
      <Text>Header</Text>
    </View>
  );
}
```

```tsx
// ✅ Full-screen immersive layout — content under notch, no clipped zones
function FullScreenPage() {
  const insets = useSafeAreaInsets();

  return (
    <View style={{ flex: 1, paddingBottom: insets.bottom }}>
      <View style={{ paddingTop: insets.top }}>
        <Text>Safe title</Text>
      </View>

      <ScrollView style={{ flex: 1 }}>
        <Content />
      </ScrollView>
    </View>
  );
}
```

### Platform Differences

| Device | `insets.top` | `insets.bottom` |
|--------|-------------|-----------------|
| iPhone 14 Pro Max | 59 | 34 |
| iPhone SE (no notch) | 20 (status bar) | 0 |
| Android (status bar) | 24–48 | 0 |
| Android (gesture nav) | 24–48 | 24–48 |
| Android (3-button nav) | 24–48 | 0 |

---

## Keyboard — Avoidance Strategies

### 1. KeyboardAvoidingView (Built-in)

Simple forms where content sits above the input.

```tsx
import { KeyboardAvoidingView, Platform } from 'react-native';

function LoginForm() {
  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={Platform.select({ ios: 88, android: 0 })}
    >
      <ScrollView
        contentContainerStyle={{ flexGrow: 1, justifyContent: 'center' }}
        keyboardShouldPersistTaps="handled"
      >
        <TextInput placeholder="Email" />
        <TextInput placeholder="Password" />
        <Button title="Login" />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
```

| Prop | iOS | Android |
|------|-----|---------|
| `behavior` | `'padding'` (resize view) | `'height'` (resize view) |
| `keyboardVerticalOffset` | Header/NavBar height | 0 |

`keyboardVerticalOffset` is critical on iOS — it's the height of your navigation bar / header above the form, otherwise the keyboard pushes content too high.

### 2. KeyboardAwareScrollView (react-native-keyboard-aware-scroll-view)

Better for complex forms with multiple inputs — auto-scrolls to focused input.

```tsx
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

function LongForm() {
  return (
    <KeyboardAwareScrollView
      extraScrollHeight={20}
      enableOnAndroid
      keyboardShouldPersistTaps="handled"
    >
      <TextInput placeholder="Name" />
      <TextInput placeholder="Email" />
      <TextInput placeholder="Phone" />
      <TextInput placeholder="Address" />
      <Button title="Submit" />
    </KeyboardAwareScrollView>
  );
}
```

### 3. Manual Keyboard Listener

For custom animations or non-form layouts (e.g. chat input that slides up).

```tsx
import { Keyboard, KeyboardEvent } from 'react-native';

function ChatInput() {
  const [keyboardHeight, setKeyboardHeight] = useState(0);
  const insets = useSafeAreaInsets();

  useEffect(() => {
    const show = Keyboard.addListener('keyboardWillShow', (e: KeyboardEvent) => {
      setKeyboardHeight(e.endCoordinates.height);
    });
    const hide = Keyboard.addListener('keyboardWillHide', () => {
      setKeyboardHeight(0);
    });
    return () => {
      show.remove();
      hide.remove();
    };
  }, []);

  return (
    <View style={{ flex: 1 }}>
      <MessageList />
      <View style={{
        paddingBottom: keyboardHeight > 0 ? keyboardHeight : insets.bottom,
      }}>
        <TextInput placeholder="Type a message..." />
      </View>
    </View>
  );
}
```

> **Note**: `keyboardWillShow` / `keyboardWillHide` are iOS only. On Android use `keyboardDidShow` / `keyboardDidHide`.

### 4. Typing State & Completion — isTyping / Enter / Debounce

No native `isComplete` prop. Three complementary patterns for different "when has the user finished typing?" scenarios:

#### Pattern A: `isTyping` — 输入中状态

标准 JS API：`onChangeText` 时 `setIsTyping(true)` + `setTimeout` 延时复位。

```tsx
function useIsTyping(text: string, delay = 500): boolean {
  const [isTyping, setIsTyping] = useState(false);

  useEffect(() => {
    if (text.length === 0) {
      setIsTyping(false);
      return;
    }
    setIsTyping(true);                              // 每次按键 → true
    const timer = setTimeout(() => {
      setIsTyping(false);                           // 停笔 delay ms → false
    }, delay);
    return () => clearTimeout(timer);
  }, [text, delay]);

  return isTyping;
}
```

对于中文/日文/韩文输入法（IME），用 `onCompositionStart` / `onCompositionEnd` 避免拼字中途误判：

```tsx
function ChatInput() {
  const [text, setText] = useState('');
  const [isComposing, setIsComposing] = useState(false);
  const [isTyping, setIsTyping] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout>>();

  const clearTyping = () => {
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => setIsTyping(false), 500);
  };

  return (
    <TextInput
      value={text}
      onChangeText={(t) => {
        setText(t);
        if (!isComposing) {
          setIsTyping(true);
          clearTyping();
        }
      }}
      onCompositionStart={() => setIsComposing(true)}
      onCompositionEnd={(e) => {
        setIsComposing(false);
        setIsTyping(true);
        clearTyping();
      }}
    />
  );
}
```

| 场景 | `isTyping` 机制 |
|------|----------------|
| 英文/数字输入 | `onChangeText` → `setIsTyping(true)` + `setTimeout(..., 500)` |
| 中文拼音/日文假名输入 | `onCompositionStart` 时不触发，`onCompositionEnd` 才算一次 |
| 清空输入框 | `text.length === 0` → 立即 `setIsTyping(false)` |
| Chat "对方正在输入..." | 配合 WebSocket 在 `isTyping` 变化时发送 typing indicator |

#### Pattern B: `onSubmitEditing` — Enter / Done Key

当用户点击键盘的 **Enter / Search / Done / Send** 按钮时触发。
⚠️ **CJK 输入法（中文拼音/五笔、日文假名）选字按 Enter 也会触发 `onSubmitEditing`**，需要配合 composition 事件过滤。

```tsx
function SearchField() {
  const [query, setQuery] = useState('');
  const isComposingRef = useRef(false);

  const handleSubmit = useCallback(() => {
    // ❌ 输入法选字时 Enter → 跳过，不是真正的提交
    if (isComposingRef.current) return;

    if (!query.trim()) return;
    searchAPI(query.trim());
    Keyboard.dismiss();
  }, [query]);

  return (
    <TextInput
      value={query}
      onChangeText={setQuery}
      onSubmitEditing={handleSubmit}
      returnKeyType="search"
      onCompositionStart={() => { isComposingRef.current = true; }}
      onCompositionEnd={() => { isComposingRef.current = false; }}
    />
  );
}
```

**为什么用 ref 不用 state？** `onSubmitEditing` 和 `onCompositionEnd` 的时序是：
```
onCompositionEnd → onSubmitEditing (几乎同时)
```
如果用 `setIsComposing(false)`，`onSubmitEditing` 读到的是**上一次的 state 值**（还是 true）。ref 确保实时读到最新值。

| `returnKeyType` | 键盘按钮 | 典型场景 |
|-----------------|---------|----------|
| `'search'` | 搜索 | 搜索栏 |
| `'done'` | 完成 | 单字段表单 |
| `'send'` | 发送 | 聊天 |
| `'go'` | 前往 | URL 输入 |
| `'next'` | 下一项 | 多表单跳转 |
| `'default'` | 换行 ↵ | 多行输入 |

多表单连续输入 — 按 "Next" 跳到下一个，同样防输入法误触：

```tsx
function LoginForm() {
  const emailRef = useRef<TextInput>(null);
  const passwordRef = useRef<TextInput>(null);
  const isComposingRef = useRef(false);

  return (
    <View>
      <TextInput
        ref={emailRef}
        placeholder="Email"
        returnKeyType="next"
        onSubmitEditing={() => {
          if (isComposingRef.current) return;
          passwordRef.current?.focus();
        }}
        onCompositionStart={() => { isComposingRef.current = true; }}
        onCompositionEnd={() => { isComposingRef.current = false; }}
      />
      <TextInput
        ref={passwordRef}
        placeholder="Password"
        returnKeyType="done"
        secureTextEntry
        onSubmitEditing={() => {
          if (isComposingRef.current) return;
          handleLogin();
        }}
        onCompositionStart={() => { isComposingRef.current = true; }}
        onCompositionEnd={() => { isComposingRef.current = false; }}
      />
    </View>
  );
}
```

#### Pattern B2: Chat 发送 — Enter 防输入法误触

聊天输入框既要支持多行（Enter 换行），又要支持 Enter 发送，还要防选中文字时误发：

```tsx
function ChatInput() {
  const [text, setText] = useState('');
  const isComposingRef = useRef(false);

  const sendMessage = () => {
    if (!text.trim()) return;
    send(text);
    setText('');
    Keyboard.dismiss();
  };

  const handleKeyPress = ({ nativeEvent }: NativeSyntheticEvent<TextInputKeyPressEventData>) => {
    // Enter（非输入法选字）→ 发送
    // Shift+Enter → 换行（由 multiline 自然处理）
    if (nativeEvent.key === 'Enter' && !isComposingRef.current) {
      sendMessage();
    }
  };

  return (
    <TextInput
      value={text}
      onChangeText={setText}
      multiline
      blurOnSubmit={false}          // ⚠️ 不让 Enter 自动失焦
      onKeyPress={handleKeyPress}
      onCompositionStart={() => { isComposingRef.current = true; }}
      onCompositionEnd={() => { isComposingRef.current = false; }}
    />
  );
}
```

> ⚠️ `multiline` 为 true 时 `returnKeyType` / `onSubmitEditing` 均不生效（RN 行为），Enter 由 `onKeyPress` 接管。

#### Pattern C: Debounce — Stopped Typing (Auto-Save / Search)

No built-in `isComplete` prop on TextInput. Use debounce to detect when the user **stops typing** for a defined pause.

```tsx
// Option 1: useDebounce (ahooks) — debounce the VALUE
import { useDebounce } from 'ahooks';
const debouncedQuery = useDebounce(query, { wait: 300 });
useEffect(() => { if (debouncedQuery) searchAPI(debouncedQuery); }, [debouncedQuery]);

// Option 2: useDebounceFn (ahooks) — debounce the ACTION
import { useDebounceFn } from 'ahooks';
const { run: autoSave } = useDebounceFn((t) => saveDraftAPI(t), { wait: 800 });

// Option 3: lodash.debounce — minimal deps
import debounce from 'lodash/debounce';
const search = useCallback(debounce((t) => searchAPI(t), 300), []);
```

| Approach | Best for | Debounce target |
|----------|----------|----------------|
| `useDebounce` (ahooks) | Search, filter, derived state | **Value** — debounce the text value |
| `useDebounceFn` (ahooks) | Auto-save, API calls | **Action** — debounce the function call |
| `lodash.debounce` | Minimal deps, no ahooks | **Action** — debounce the callback |

#### Which pattern to use?

| Scenario | Pattern |
|----------|---------|
| "对方正在输入..." / typing indicator | **A** — `isTyping` |
| User pressed Search/Done/Send key | **B** — `onSubmitEditing` |
| Search-as-you-type / auto-save | **C** — Debounce |
| Chat send button + Enter key | **B + C** — `onSubmitEditing` sends immediately, debounce saves draft |

> **Native side (iOS/Android):** There is no native `isComplete` callback for "user stopped typing." The standard UIKit/Android approach is `textField(_:shouldChangeCharactersIn:)` / `onTextChanged` with a timer — which is exactly what the JS debounce pattern replicates. `onSubmitEditing` maps directly to `textFieldShouldReturn` (iOS) / `onEditorAction(IME_ACTION_DONE)` (Android).

### Platform-Specific Tips

### Platform-Specific Tips

---

## Combined Pattern — SafeArea + Keyboard

The most robust pattern for screens with both SafeArea and keyboard:

```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { KeyboardAvoidingView, Platform, Keyboard } from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

function FormScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View style={{ flex: 1, paddingBottom: insets.bottom }}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        keyboardVerticalOffset={Platform.select({ ios: 88, android: 0 })}
      >
        <KeyboardAwareScrollView
          keyboardShouldPersistTaps="handled"
          extraScrollHeight={20}
          enableOnAndroid
          contentContainerStyle={{
            paddingTop: insets.top,
            paddingHorizontal: 16,
          }}
        >
          <HeaderSection />
          <FormField label="Name" />
          <FormField label="Email" />
          <FormField label="Phone" />
          <Button title="Submit" />
        </KeyboardAwareScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}
```

**Layering logic:**
1. Outer `View` handles `insets.bottom` (SafeArea bottom padding is always respected)
2. `KeyboardAvoidingView` handles the keyboard push (iOS only)
3. `KeyboardAwareScrollView` handles auto-scroll to the focused input
4. Inner `contentContainerStyle` handles `insets.top` (SafeArea top padding)

---

## Red Flags — Immediate STOPS

- ❌ Using `SafeAreaView` from `react-native` core (deprecated, no edge control)
- ❌ Missing `SafeAreaProvider` wrapper → `useSafeAreaInsets()` returns `{ top: 0, bottom: 0, ... }`
- ❌ Forgetting `keyboardVerticalOffset` on iOS → content pushed too high by nav bar height
- ❌ Using `keyboardWillShow` on Android → event never fires, use `keyboardDidShow`
- ❌ `KeyboardAvoidingView` without `behavior` prop → no effect
- ❌ Ignoring gesture navigation bottom inset on Android (`insets.bottom > 0` on gesture nav devices)
- ❌ Waiting for a native `isComplete` callback — RN TextInput has no such prop, use JS debounce
- ❌ `onSubmitEditing` without `returnKeyType` — keyboard button shows default "return" instead of "Search"/"Done"/"Send"
- ❌ Missing `Keyboard.dismiss()` in `onSubmitEditing` — keyboard stays open after submit on some platforms
- ❌ CJK 输入法选字 Enter 误触 `onSubmitEditing` — 必须用 `isComposingRef` + `onCompositionStart/End` 过滤
- ❌ `multiline` 下用了 `onSubmitEditing` / `returnKeyType` — 这两个 prop 对 multiline TextInput 不生效，改用 `onKeyPress` 拦截 Enter
