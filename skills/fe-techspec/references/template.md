# FE TechSpec Template

Linear 문서 생성 시 `create_document`의 content 파라미터에 아래 구조를 채워서 전달한다.

---

## Summary

Linear, PRD, Figma 등 프로젝트에 대한 배경, 프로젝트 맥락에서 다루는 목적과 할 수 있는 최대한의 요점을 적어주세요.

- **PRD**: {PRD_URL}
- **Figma**: {FIGMA_URL}

## Solution

⚠️ 기술 용어 없이 비즈니스 관점에서 핵심 변경사항을 요약합니다.

### 핵심 변경사항

1. **{변경1}**: {설명}
2. **{변경2}**: {설명}
3. **{변경3}**: {설명}

## Acceptance Criteria

기능 동작 관련, 최소 기준을 작성해요. 측정 가능하고 검증 가능한 문장으로 작성.

1. {주어} 상태에서 {동작}하면 {결과}가 발생한다
2. ...

## Non-Functional Requirements (A/SEO)

SLA/SLO를 준수하며 시스템 요구사항을 정의해요. 해당 없으면 생략 가능.

## Functional Requirements (Test cases / Given, When, Then)

⚠️ Entity/Command 헤더 없이 테이블만 작성. 정상 → 에러 → 엣지 케이스 순서.

| # | Given | When | Then |
|---|-------|------|------|
| 1 | {초기 상태/조건} | {사용자 행동/이벤트} | {기대 결과} |

## Design

⚠️ 아래 순서로 구조화하여 작성.

### 1. 데이터 모델

API 응답 모델을 기반으로 interface를 정의. 대부분 API 타입 참조로 충분하며, 별도 클라이언트 Entity는 정말 필요한 경우에만 추가.

| 데이터 | 출처 | 데이터 성격 | 주요 필드 | interface 전략 |
|--------|------|-----------|----------|---------------|
| {데이터명} | API response / 클라이언트 조합 | Server-origin / Client-persistent / Client-ephemeral | `{field1}`, `{field2}` | API 타입 참조 / 별도 정의 (사유) |

### 2. Usecase

| Usecase | Input | Output |
|---------|-------|--------|
| {Usecase명} | {입력} | {출력} |

### 2.5. Interface Contract

⚠️ 모듈 경계를 형성하는 핵심 API 계약만 정의. 모든 Props를 나열하지 않는다.

#### Server-Client API

| Hook / Endpoint | Method | Params | Response Type | 캐시 전략 | TC# |
|-----------------|--------|--------|---------------|----------|-----|
| `{useQueryHookName}` | GET | `{params}` | `{ResponseType}` | {stale-while-revalidate / ...} | #1,#2 |
| `{useMutationHookName}` | POST/PUT/DELETE | `{params}` | `{ResponseType}` | {invalidation 대상} | #3 |

#### Client-Client API (핵심 인터페이스)

| Component | Props Interface | 핵심 Callbacks | 소비자 |
|-----------|----------------|---------------|--------|
| `{ComponentName}` | `{InterfaceName}` | `{onAction: (params) => void}` | {ParentComponent} |

### 3. Component & Visual Contract

컴포넌트 계층 + State + Visual Contract 설계.

> 📐 Design Tokens (Figma 기반, 없으면 생략)
> - Colors: {token: value}, ...
> - Spacing: {token: value}, ...
> - Typography: {token: value}, ...

⚠️ 렌더링 관계(부모→자식)만 표현. 파일 위치는 "파일 배치 가이드" 참조.

```
{FeatureName}
├── ContainerComponent [Container] → {Usecase}
│   ├── PresentationalComponent1 [Presentational]
│   └── PresentationalComponent2 [Presentational]
```

파일 배치 가이드:
- **Presentational (공용)**: 여러 도메인에서 재사용 → `src/components/` 등 공용 경로
- **Presentational (도메인 전용)**: 특정 도메인에서만 사용 → 해당 도메인 하위
- **Container**: 연결하는 Usecase가 속한 도메인 하위

**Container 컴포넌트:**
- **Usecase**: {connected usecase(s)}
- **데이터 흐름**: {서버 상태 → 가공 → Props로 하위 전달}
- **State**: { state: type }
- **하위 컴포넌트**: {Presentational 컴포넌트 목록}

**Presentational 컴포넌트:**
- **Props**: { prop: type }
- **Callbacks**: { onAction: (params) => void }
- **Visual Contract**:
  - **Layout**: {layout 패턴}
  - **States**: default, loading, empty, error 등 해당 상태만 기록
  - **Interactions**: {핵심 인터랙션}

### 4. Usecase-Component Integration

| Usecase | Component | 연결 방식 |
|---------|-----------|----------|
| {Usecase} | {Component} | {설명} |

### 5. Optimization Checklist (해당 항목만 기록)

⚠️ 모든 항목을 채울 필요 없음. TC 또는 NFR에서 도출된 항목만 기록.

| 카테고리 | 항목 | 적용 | 설계 결정 | TC/NFR# |
|----------|------|------|----------|---------|
| Performance | 초기 로딩 (lazy load, code split) | Y/N/해당없음 | {결정} | |
| Performance | 리렌더링 (memo, selector) | Y/N/해당없음 | {결정} | |
| UX | Optimistic update | Y/N/해당없음 | {결정} | |
| UX | 에러/로딩 상태 | Y/N/해당없음 | {결정} | |
| Network | 캐시 전략 | Y/N/해당없음 | {결정} | |
| A11y | 키보드 네비게이션 | Y/N/해당없음 | {결정} | |
| A11y | 스크린 리더 | Y/N/해당없음 | {결정} | |

## (Optional) Context & Container Diagram

## Component & Code - Client

- Test cases 기반으로 module, usecase, 컴포넌트 구조 추출
- 컴포넌트 분해, 파일 구조, Props 인터페이스. API 타입 기반 interface 정의.

## (Optional) Component & Code - Server

## Verification

⚠️ Integration Test 최우선.

### Integration Tests (필수)

| TC# | 테스트 명 | 검증 내용 |
|-----|----------|----------|
| TC1 | {테스트명} | {검증 내용} |

### Unit Tests (필요 시)

복잡한 파생 상태 로직만 대상.

### E2E Tests (필요 시)

전체 사용자 플로우 검증.
