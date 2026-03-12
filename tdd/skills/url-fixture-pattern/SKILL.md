---
name: url-fixture-pattern
description: Route Page Container에 URL 파라미터 기반 fixture 데이터를 주입하여 AI agent가 URL 한 번으로 특정 시나리오를 검증할 수 있게 하는 패턴. tdd-designer, tdd-visual, tdd-integrate에서 참조.
globs:
  - "app/**/page.tsx"
  - "app/**/page.ts"
  - "pages/**/*.tsx"
  - "pages/**/*.ts"
---

# URL Fixture Pattern

## 핵심 원리

`?fixture=scenario_name` URL 파라미터로 Route Page Container에 mock 데이터를 주입하여, 실제 route 컨텍스트에서 특정 Given 상태를 재현한다.

```
/cart?fixture=empty_cart     → 빈 장바구니 상태
/cart?fixture=network_error  → API 에러 상태
/cart?fixture=cart_with_items → 상품 3개 상태
```

## 적용 대상

| 대상 | 적용 | 이유 |
|------|------|------|
| Route Page Container | **O** | URL 파라미터로 시나리오 전환 가능 |
| Presentational 컴포넌트 | X | Props로 직접 주입 — fixture 불필요 |
| 도메인 로직 / Entity | X | UI가 아닌 순수 로직 |
| 라이브러리 / 공용 컴포넌트 | X | Storybook이 더 적합 |

**판별 기준**: Component가 Server-origin 데이터를 query hook으로 조회하고, 그 결과를 하위 Presentational에 전달하는 Container인가?

## 파일 구조

```
app/cart/
├── page.tsx                    ← FixtureProvider로 Container 래핑
├── _components/
│   └── CartContainer.tsx       ← useFixture()로 fixture 분기
├── _fixtures/
│   └── cart.fixtures.ts        ← Given 조건 → fixture data
└── cart.test.tsx               ← fixture import하여 테스트에서도 사용
```

- `_fixtures/` 디렉토리: underscore prefix로 라우팅 제외 (Next.js App Router 컨벤션)
- fixture 파일명: `{feature}.fixtures.ts`

## FixtureProvider 패턴

### Next.js App Router

```tsx
// app/_providers/FixtureProvider.tsx
"use client";

import { createContext, useContext, type ReactNode } from "react";
import { useSearchParams } from "next/navigation";

interface FixtureContextValue {
  fixtureName: string | null;
  getFixture: <T>(fixtures: Record<string, T>) => T | null;
}

const FixtureContext = createContext<FixtureContextValue>({
  fixtureName: null,
  getFixture: () => null,
});

export function FixtureProvider({ children }: { children: ReactNode }) {
  if (process.env.NODE_ENV === "production") {
    return <>{children}</>;
  }

  const searchParams = useSearchParams();
  const fixtureName = searchParams.get("fixture");

  const getFixture = <T,>(fixtures: Record<string, T>): T | null => {
    if (!fixtureName) return null;
    return fixtures[fixtureName] ?? null;
  };

  return (
    <FixtureContext.Provider value={{ fixtureName, getFixture }}>
      {children}
    </FixtureContext.Provider>
  );
}

export const useFixture = () => useContext(FixtureContext);
```

### 범용 React (Remix, Vite 등)

```tsx
// src/providers/FixtureProvider.tsx
import { createContext, useContext, type ReactNode } from "react";

interface FixtureContextValue {
  fixtureName: string | null;
  getFixture: <T>(fixtures: Record<string, T>) => T | null;
}

const FixtureContext = createContext<FixtureContextValue>({
  fixtureName: null,
  getFixture: () => null,
});

export function FixtureProvider({ children }: { children: ReactNode }) {
  if (process.env.NODE_ENV === "production") {
    return <>{children}</>;
  }

  const fixtureName = new URLSearchParams(window.location.search).get("fixture");

  const getFixture = <T,>(fixtures: Record<string, T>): T | null => {
    if (!fixtureName) return null;
    return fixtures[fixtureName] ?? null;
  };

  return (
    <FixtureContext.Provider value={{ fixtureName, getFixture }}>
      {children}
    </FixtureContext.Provider>
  );
}

export const useFixture = () => useContext(FixtureContext);
```

## Container에서 Fixture 분기

```tsx
// app/cart/_components/CartContainer.tsx
import { useFixture } from "@/providers/FixtureProvider";
import { cartFixtures } from "../_fixtures/cart.fixtures";
import { useCartQuery } from "@/hooks/useCartQuery";
import { CartView } from "./CartView";

export function CartContainer() {
  const { getFixture } = useFixture();
  const fixtureData = getFixture(cartFixtures);

  const { data, error, isLoading } = useCartQuery({
    enabled: !fixtureData, // fixture 있으면 실제 query 비활성화
  });

  const result = fixtureData ?? { data, error, isLoading };

  return <CartView {...result} />;
}
```

## Fixture 데이터 파일

```tsx
// app/cart/_fixtures/cart.fixtures.ts
import type { CartQueryResult } from "@/hooks/useCartQuery";

// Design의 데이터 모델 interface를 따른다
export const cartFixtures: Record<string, CartQueryResult> = {
  empty_cart: {
    data: { items: [], total: 0 },
    error: null,
    isLoading: false,
  },
  cart_with_items: {
    data: {
      items: [
        { id: "1", name: "상품 A", price: 10000, quantity: 2 },
        { id: "2", name: "상품 B", price: 10000, quantity: 1 },
      ],
      total: 30000,
    },
    error: null,
    isLoading: false,
  },
  network_error: {
    data: null,
    error: new Error("서버 연결에 실패했습니다"),
    isLoading: false,
  },
  loading_state: {
    data: null,
    error: null,
    isLoading: true,
  },
};
```

## Given → Fixture Name 변환 규칙

TC의 Given 조건에서 핵심 키워드를 추출하여 `snake_case`로 변환한다.

| Given 조건 | Fixture Name |
|-----------|-------------|
| 빈 장바구니 | `empty_cart` |
| 상품 3개, 총액 30,000원 | `cart_with_items` |
| 네트워크 에러 발생 | `network_error` |
| 로딩 중 | `loading_state` |
| 사용자가 로그인하지 않음 | `unauthenticated` |

**규칙:**
- 같은 Given을 공유하는 TC들은 하나의 fixture로 통합
- fixture name은 영어 snake_case
- fixture 데이터는 Design의 데이터 모델 interface를 따른다
- **YAGNI**: TC Given에 없는 시나리오 fixture는 추가하지 않는다

## Production 안전성 (3중 보호)

1. **Runtime 가드**: `process.env.NODE_ENV === "production"` → FixtureProvider가 children만 렌더링
2. **Build-time 제거**: Bundler tree-shaking이 production에서 fixture import와 FixtureProvider 로직 제거
3. **파일 컨벤션**: `_fixtures/` 디렉토리는 Next.js App Router에서 라우팅 대상 제외

## TDD Phase별 활용 가이드

각 phase의 agent가 이 skill을 **참조**하여 활용한다. Agent 파일 자체에는 fixture 로직을 하드코딩하지 않는다.

### tdd-designer (설계)

Phase 2.7에서 Fixture Map 테이블을 생성한다:
- Component Tree에 Route Page Container가 있는지 확인
- TC Given 조건에서 fixture scenario 도출
- 데이터 모델 interface에 맞는 fixture 데이터 요약

### tdd-red (테스트 작성)

Design의 Fixture Map이 있으면:
- `_fixtures/{feature}.fixtures.ts` 파일 생성
- mock data를 인라인이 아닌 fixture 파일에서 import
- 테스트와 fixture URL이 같은 데이터를 공유 (Single Source of Truth)

Fixture Map이 없으면 기존 인라인 mock 방식 유지.

### tdd-green (최소 구현)

테스트가 FixtureProvider를 import하면 최소한으로 구현. Agent 수정 불필요 — Green의 "테스트 통과하는 최소 코드" 원칙이 자연스럽게 적용된다.

### tdd-visual (시각적 검증)

`_fixtures/` 디렉토리와 Container 태그가 감지되면:
- fixture URL(`{route}?fixture={name}`)로 각 시나리오 스크린샷
- Storybook/Preview 페이지 생성 건너뜀
- 실제 route 컨텍스트에서 검증 (레이아웃, 네비게이션 포함)

감지 실패 시 기존 Storybook/Preview fallback.

### tdd-integrate (통합 검증)

`_fixtures/` 디렉토리가 감지되면:
- `playwright-cli goto "{route}?fixture={name}"` 으로 특정 Given 상태 결정적 재현
- 재현이 어려운 시나리오(빈 상태, 에러, 대량 데이터) 검증에 특히 유용

감지 실패 시 기존 브라우저 검증 방식 유지.

## 테스트에서 Fixture 사용

```tsx
// app/cart/cart.test.tsx
import { cartFixtures } from "./_fixtures/cart.fixtures";
import { CartView } from "./_components/CartView";
import { render, screen } from "@testing-library/react";

describe("CartView", () => {
  it("빈 장바구니일 때 안내 메시지를 표시한다", () => {
    render(<CartView {...cartFixtures.empty_cart} />);
    expect(screen.getByText("장바구니가 비어있습니다")).toBeInTheDocument();
  });

  it("상품이 있을 때 총액을 표시한다", () => {
    render(<CartView {...cartFixtures.cart_with_items} />);
    expect(screen.getByText("30,000원")).toBeInTheDocument();
  });
});
```
