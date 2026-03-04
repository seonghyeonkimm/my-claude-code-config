---
name: fe-techspec
description: |
  FE TechSpec 문서 작성 템플릿과 패턴. Linear 프로젝트의 기술 명세서를 작성할 때 참조.
  Use when: TechSpec 작성, 기술 명세서 생성, Given/When/Then 테스트 케이스 정의,
  Acceptance Criteria 작성, Solution 설계 문서 작성 시 사용.
---

# FE TechSpec

**관련 스킬:** `entity-object-pattern` - 구현 시 반복되는 도메인 로직을 Entity Object로 그룹화하는 패턴

FE TechSpec은 프로젝트의 기술적 구현 방향을 정의하는 문서. PRD(요구사항)와 Figma(디자인)를 기반으로 Solution, Acceptance Criteria, Test Cases를 도출한다.

## 문서 구조

```
Summary → Solution → Acceptance Criteria → Non-Functional Requirements → Functional Requirements (Given/When/Then) → Design → Component & Code → Verification
```

전체 템플릿은 `references/template.md` 참조.

## 섹션별 작성 가이드

### Summary

프로젝트 배경과 맥락. PRD/Figma 링크 포함.

```markdown
## Summary

{프로젝트 배경 1-3문장}

- **PRD**: {Notion URL}
- **Figma**: {Figma URL}
```

### Solution

비즈니스 관점에서 핵심 변경사항을 요약. 기술 용어 없이 "무엇이 어떻게 바뀌는가"에 집중.

```markdown
## Solution

### 핵심 변경사항

1. **{변경1}**: {설명}
2. **{변경2}**: {설명}
3. **{변경3}**: {설명}
```

**작성 규칙:**
- ❌ 코드, API명, 타입명 사용 금지
- ✅ 사용자/광고주 관점에서 서술
- 3-5개 핵심 변경사항을 번호 매기기 형식으로 나열

### Acceptance Criteria

기능 동작의 최소 기준. 테스트 가능한 형태로 작성.

```markdown
## Acceptance Criteria

1. {주어} 상태에서 {동작}하면 {결과}가 발생한다
2. ...
```

- 측정 가능하고 검증 가능한 문장으로 작성
- "빠르게", "잘" 같은 모호한 표현 금지
- 핵심 유저 플로우별 1개 이상

### Non-Functional Requirements

SLA/SLO 기준의 시스템 요구사항.

카테고리:
- **Performance**: LCP < 2.5s, FID < 100ms, CLS < 0.1
- **Accessibility**: WCAG AA
- **SEO**: 메타 태그, OG 태그, 시맨틱 마크업

해당 프로젝트에 관련 없는 카테고리는 생략 가능.

### Functional Requirements (Given/When/Then)

테스트 케이스를 구조화된 테이블로 정의.

**핵심 개념:**
- 기능 요구사항을 Test cases (Given, When, Then) 형태로 정의해요.

```markdown
## Functional Requirements (Test cases / Given, When, Then)

| # | Given | When | Then |
|---|-------|------|------|
| 1 | {초기 상태/조건} | {사용자 행동/이벤트} | {기대 결과} |
| 2 | ... | ... | ... |
```

작성 팁:
- 정상 케이스 → 에러 케이스 → 엣지 케이스 순서
- Given은 상태, When은 행동, Then은 검증 가능한 결과
- ⚠️ Entity/Command 식별은 Design 섹션에서 수행, FR에는 테이블만 작성

### Design

테스트 케이스 기반으로 도메인 설계를 진행.

**작성 순서:**
1. **데이터 모델**: API 응답 기반 interface 정의
   - API 응답 모델을 기반으로 interface를 정의하고, 컴포넌트는 이 interface에만 의존
   - 대부분 API 타입 참조로 충분. 별도 클라이언트 Entity는 정말 필요한 경우에만 추가
   - 필요한 경우: 여러 API 응답 조합, 클라이언트 고유 상태, API와 다른 구조가 필요한 경우
2. **Usecase**: 주요 사용 시나리오 테이블 (Input → Output)
2.5. **Interface Contract**: Server-Client API (hooks/endpoints) + Client-Client API (component props)
   - Server-Client: query hook, mutation hook, 파라미터, 응답 타입, 캐시 전략
   - Client-Client: 모듈 경계를 형성하는 핵심 Props Interface와 Callback 시그니처
   - TC 번호로 추적
3. **Component & Visual Contract**: 컴포넌트 계층 설계. 두 유형으로 분류:
   - **Container**: Usecase 연결, 서버 상태 구독, 데이터 가공 → 하위 Presentational에 전달. Visual Contract 없음
   - **Presentational**: Props/Callbacks 기반 순수 UI. Visual Contract 필수 (Layout, States, Interactions)
   - Figma가 있으면 `get_design_context`/`get_variable_defs`에서 추출, 없으면 테스트 케이스에서 도출
4. **Usecase-Component Integration**: 연결 지점 정의
5. **Optimization Checklist**: TC/NFR에서 도출된 최적화 항목만 기록
   - Performance, UX, Network, A11y 카테고리
   - 해당 없는 항목은 기록하지 않음

**데이터 모델 가이드:**
- ✅ API 응답 타입을 기반으로 interface 정의 → 컴포넌트는 interface만 의존
- ✅ enum/상수값은 `constants/`에 별도 정의 가능
- ❌ API 응답과 동일한 구조를 클라이언트 Entity로 재정의
- ⚠️ 별도 클라이언트 Entity가 필요하면 사유를 명시 (예: "여러 API 응답 조합 필요")

### Component & Code - Client
- Test cases 기반으로 module, usecase, 컴포넌트 구조 추출
- 컴포넌트 분해, 파일 구조, Props 인터페이스.
- interface는 API 타입 기반으로 정의하되, 컴포넌트가 API 모델에 직접 의존하지 않도록 레이어 분리

### (Optional) Context & Container Diagram / Component & Code - Server

필요한 경우에만 작성.

### Verification

테스트 케이스 검증 전략.

**우선순위:**
1. **Integration Tests (필수)**: TC 기반 컴포넌트 통합 테스트
2. **Unit Tests (필요 시)**: 복잡한 파생 상태 로직만
3. **E2E Tests (필요 시)**: 전체 사용자 플로우 검증

**Integration Test 테이블 형식:**
| TC# | 테스트 명 | 검증 내용 |
|-----|----------|----------|
| TC1 | ... | ... |

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| AC가 모호함 | "빠르게", "잘" 같은 추상적 표현 | 측정 가능한 기준 사용 (예: "3초 이내") |
| Given/When/Then 불명확 | 상태/행동/결과 구분 없음 | Given=상태, When=행동, Then=검증 가능한 결과 |
| Test Case 누락 | 정상 케이스만 작성 | 에러/엣지 케이스 반드시 포함 |
| NFR 생략 | 선택사항이라 무시 | 공개 페이지면 SEO/A11y 필수 검토 |
| Solution에 코드 포함 | "기술적 해결책"으로 오해 | 비기술 요약으로 작성 |
| 클라이언트 Entity 과잉 설계 | API 응답을 재정의하려 함 | API 타입 기반 interface로 충분. 별도 Entity는 사유 필요 |
| UI 문구 가정 | Figma 미확인 | variants에서 실제 문구 추출 |
| FR에 Entity/Command 헤더 | 지침 오해 | Design에서만 사용, FR은 테이블만 |
| Verification 누락 | 선택사항으로 오인 | Integration Test 필수 |
| 규칙 중복 구현 | UI/API에서 같은 규칙을 각각 구현 | 구현 시 `entity-object-pattern` 스킬 참조 |
| Container/Presentational 혼합 | 하나의 컴포넌트가 Usecase 호출 + UI 렌더링 | Container(데이터 흐름)와 Presentational(Props/Callbacks)을 분리 |
| 모든 Props를 Interface Contract에 기록 | 과잉 명세 | 모듈 경계를 형성하는 핵심 인터페이스만 정의. 내부 컴포넌트 Props는 Component 섹션에서 |
| Optimization Checklist 전부 채움 | RADIO 원칙 오해 | TC/NFR에서 도출된 항목만. "해당없음"이 대부분이어도 정상 |
