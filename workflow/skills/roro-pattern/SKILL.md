---
name: roro-pattern
description: 함수 작성 시 RORO 패턴 우선, positional parameter 지양
globs:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# RORO Pattern (Receive an Object, Return an Object)

함수의 파라미터와 반환값에 객체를 사용하여 가독성, 확장성, 유지보수성을 높인다.

## 핵심 규칙

### 규칙 1: 파라미터 2개 이상이면 객체로 받기

```typescript
// ❌ positional parameters
function createUser(name: string, email: string, age: number, isAdmin: boolean) {
  // ...
}
createUser("Kim", "kim@example.com", 30, false);

// ✅ RORO pattern
function createUser({ name, email, age, isAdmin }: {
  name: string;
  email: string;
  age: number;
  isAdmin: boolean;
}) {
  // ...
}
createUser({ name: "Kim", email: "kim@example.com", age: 30, isAdmin: false });
```

### 규칙 2: 여러 값을 반환할 때 객체로 감싸기

```typescript
// ❌ tuple 반환
function parseConfig(raw: string): [Config, Error | null] {
  // ...
}
const [config, error] = parseConfig(rawText);

// ✅ 객체 반환
function parseConfig({ raw }: { raw: string }): { config: Config; error: Error | null } {
  // ...
}
const { config, error } = parseConfig({ raw: rawText });
```

### 규칙 3: 선택적 파라미터에 기본값 활용

```typescript
// ✅ destructuring + default values
function fetchUsers({ page = 1, limit = 20, sort = "createdAt" }: {
  page?: number;
  limit?: number;
  sort?: string;
} = {}) {
  // ...
}

fetchUsers(); // 모든 기본값 사용
fetchUsers({ limit: 50 }); // 필요한 것만 override
```

## 예외 (positional parameter 허용)

- **파라미터 1개**: `function greet(name: string)` — 객체로 감쌀 필요 없음
- **표준 콜백 시그니처**: `array.map((item, index) => ...)` — 런타임/프레임워크 규약 따름
- **수학/유틸 함수**: `Math.max(a, b)`, `clamp(value, min, max)` — 순서가 자명한 경우
