---
name: axios-fetch-conventions
description: Use when writing HTTP request code with axios or fetch — enforces unified instance, interceptors, error handling, cancellation, and base URL patterns
---

# Axios / Fetch Conventions

## 1. Unified Instance

Never call `axios.get()` or `fetch()` directly. Create a single configured instance.

```ts
// lib/http.ts
import axios from 'axios';

export const http = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 15000,
  withCredentials: true,
});
```

## 2. Interceptors — Error Handling in One Place

```ts
// Response interceptor — normalize errors
http.interceptors.response.use(
  (res) => res,
  (error) => {
    if (error.response?.status === 401) {
      // redirect to login
    }
    if (error.code === 'ECONNABORTED') {
      throw new Error('Request timed out');
    }
    throw error;
  }
);
```

## 3. Request Cancellation

Every request must pass a signal for cleanup.

```ts
// ✅ AbortController
const controller = new AbortController();

useEffect(() => {
  http.get('/posts', { signal: controller.signal });
  return () => controller.abort(); // cleanup on unmount
}, []);
```

## 4. Retry on Transient Failures

```ts
async function fetchWithRetry<T>(url: string, retries = 2): Promise<T> {
  for (let i = 0; i <= retries; i++) {
    try {
      const { data } = await http.get<T>(url);
      return data;
    } catch (err) {
      if (i === retries) throw err;
      await new Promise((r) => setTimeout(r, 1000 * (i + 1)));
    }
  }
  throw new Error('unreachable');
}
```

## Red Flags

- `axios.get('http://...')` with hardcoded URL — use the shared instance
- `try/catch` around every call doing the same error handling — use interceptor
- No `AbortController` on requests made in `useEffect` — memory leak on fast navigation
- `fetch()` with no timeout wrapper — fetch has no built-in timeout
