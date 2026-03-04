---
name: entity-object-pattern
description: |
  Entity Object(companion object) 패턴. Entity interface와 같은 이름의 const 객체에 도메인 로직 함수를 그룹화.
  Use when: TDD Refactor 단계에서 반복되는 도메인 로직을 정리할 때,
  Entity 구현 시 도메인 로직 코드화, UI/API/테스트에서 동일 로직 재사용이 필요할 때.
globs:
  - "**/_models/**/*.ts"
  - "**/models/**/*.ts"
  - "**/domain/**/*.ts"
---

# Entity Object Pattern

> **사용 시점**: TDD Refactor 단계에서 참조합니다.
> Given/When/Then 테스트 케이스에서 반복되는 도메인 로직을 식별하고,
> 이 패턴을 적용하여 Entity Object로 그룹화합니다.

TypeScript의 companion object 패턴을 활용하여, Entity `interface`와 같은 이름의 `const` 객체에 도메인 로직 함수를 그룹화하는 패턴.

## 핵심 원리

TypeScript는 타입과 값이 별도 네임스페이스에 존재하므로, `interface`와 `const`에 같은 이름을 사용할 수 있다:

```typescript
export interface AdGroup { /* 타입 */ }
export const AdGroup = { /* 값 (도메인 로직 함수들) */ } as const;

// 사용처에서:
import { AdGroup } from './AdGroup';
const ag: AdGroup = ...;              // 타입으로 사용
AdGroup.canEditDailyBudget(ag);       // 값으로 사용
```

## 함수 유형

| 접두사 | 용도 | 반환 타입 | 예시 |
|--------|------|-----------|------|
| `is*` | 상태 조건 체크 | `boolean` | `AdGroup.isMaximizeConversionsBidding()` |
| `get*` | 파생값 계산 | 도메인 타입 | `AdGroup.getDailyBudget()` |
| `can*` | 행동 가능 여부 | `boolean` | `AdGroup.canEditDailyBudget()` |
| `should*` | 조건부 동작 체크 | `boolean` | `AdGroup.shouldShowBudgetWarning()` |
| `count*` | 집계 | `number` | `PostAdDisplayItem.countActive()` |

## Given/When/Then에서 추출

```
Given 분석 → is* (상태 조건)
When 분석  → can* (가능 조건)
Then 분석  → get*, should*, count* (파생값, 동작 조건, 집계)
```

**예시:**
| # | Given | When | Then | Entity Object 함수 |
|---|-------|------|------|---------------------|
| 1 | 입찰 전략이 "전환수 최대화" | 일예산 수정 시도 | 필드 비활성화 | `AdGroup.isMaximizeConversionsBidding`, `AdGroup.canEditDailyBudget` |
| 2 | 일예산 < 일소진액×3 | 대시보드 진입 | 경고 표시 | `AdGroup.shouldShowBudgetWarning` |

## 의존성 순서 (Layer)

```
Layer 1 (Base): is* 함수들 (의존성 없음)
    ↓
Layer 2 (Derived): can*, get* (is* 의존)
    ↓
Layer 3 (Composite): should* (여러 함수 조합)
```

## 파일 구조

Entity 파일 내부에 interface와 같은 이름의 const 객체를 정의:

```typescript
// src/domain/AdGroup.ts (또는 _models/AdGroup.ts)

// Entity 타입
export interface AdGroup {
  id: string;
  biddingType: BiddingType;
  dailyBudget: number;
}

// Entity Object — interface와 같은 이름
export const AdGroup = {
  // Layer 1: Base
  isMaximizeConversionsBidding: (adGroup: AdGroup): boolean =>
    adGroup.biddingType === 'MAXIMIZE_CONVERSIONS',

  // Layer 2: Derived (Layer 1 사용)
  canEditDailyBudget: (adGroup: AdGroup): boolean =>
    !AdGroup.isMaximizeConversionsBidding(adGroup),

  getDailyBudget: (adGroup: AdGroup): number | null =>
    AdGroup.isMaximizeConversionsBidding(adGroup) ? null : adGroup.dailyBudget,

  // Layer 3: Composite (Layer 1, 2 사용)
  shouldShowBidSettings: (adGroup: AdGroup, campaign: Campaign): boolean =>
    AdGroup.canEditDailyBudget(adGroup) && campaign.status !== 'PAUSED',
} as const;
```

## 사용 위치별 예시

### UI 렌더링

```tsx
import { AdGroup } from '../domain/AdGroup';

function DailyBudgetField({ adGroup }: { adGroup: AdGroup }) {
  const disabled = !AdGroup.canEditDailyBudget(adGroup);
  const value = AdGroup.getDailyBudget(adGroup);

  return (
    <NumberInput
      value={value}
      disabled={disabled}
      placeholder={disabled ? "자동 설정" : "금액 입력"}
    />
  );
}
```

### API 요청 Body

```typescript
import { AdGroup } from '../domain/AdGroup';

function buildUpdateRequest(adGroup: AdGroup): UpdateRequest {
  return {
    id: adGroup.id,
    dailyBudget: AdGroup.getDailyBudget(adGroup),
  };
}
```

### 테스트 코드

```typescript
import { AdGroup } from '../domain/AdGroup';

describe('AdGroup', () => {
  it('전환수 최대화 입찰이면 일예산 수정 불가', () => {
    const adGroup = createAdGroup({ biddingType: 'MAXIMIZE_CONVERSIONS' });

    expect(AdGroup.canEditDailyBudget(adGroup)).toBe(false);
    expect(AdGroup.getDailyBudget(adGroup)).toBeNull();
  });
});
```

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| 함수 중복 | UI/API에서 각각 구현 | Entity Object에 정의하여 재사용 |
| 조건 불일치 | 같은 규칙을 다르게 해석 | Single Source of Truth (Entity Object) |
| 테스트 누락 | Entity Object 함수를 테스트 안 함 | 함수별 단위 테스트 필수 |
| 의존성 순환 | is* 함수가 can* 함수 호출 | Layer 구조 준수 |
| 과도한 추상화 | 모든 조건을 Entity Object에 추출 | 2곳 이상 재사용되는 경우만 추출 |
| standalone 함수 산재 | Entity와 무관하게 함수 정의 | Entity Object에 그룹화하여 응집도 확보 |
