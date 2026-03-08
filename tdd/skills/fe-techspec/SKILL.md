---
name: fe-techspec
description: |
  FE TechSpec 문서 작성 템플릿과 패턴. Linear 프로젝트의 기술 명세서를 작성할 때 참조.
  Use when: TechSpec 작성, 기술 명세서 생성, Given/When/Then 테스트 케이스 정의,
  Acceptance Criteria 작성, Solution 설계 문서 작성 시 사용.
---

# FE TechSpec

**공통 가이드:** `techspec-common` 스킬 참조 (Summary, Solution, AC, FR, Verification, 공통 실수)
**관련 스킬:** `entity-object-pattern` - 구현 시 반복되는 도메인 로직을 Entity Object로 그룹화하는 패턴

FE TechSpec은 프로젝트의 기술적 구현 방향을 정의하는 문서. PRD(요구사항)와 Figma(디자인)를 기반으로 Solution, Acceptance Criteria, Test Cases를 도출한다.

## 문서 구조

```
Summary → Solution → Acceptance Criteria → Non-Functional Requirements → Functional Requirements (Given/When/Then) → Design → Component & Code → Verification
```

전체 템플릿은 `references/template.md` 참조.

## FE 전용 섹션

### Non-Functional Requirements

카테고리:
- **Performance**: LCP < 2.5s, FID < 100ms, CLS < 0.1
- **Accessibility**: WCAG AA
- **SEO**: 메타 태그, OG 태그, 시맨틱 마크업

해당 프로젝트에 관련 없는 카테고리는 생략 가능.

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
- ⚠️ 별도 클라이언트 Entity가 필요하면 사유를 명시

### Component & Code - Client
- Test cases 기반으로 module, usecase, 컴포넌트 구조 추출
- 컴포넌트 분해, 파일 구조, Props 인터페이스.
- interface는 API 타입 기반으로 정의하되, 컴포넌트가 API 모델에 직접 의존하지 않도록 레이어 분리

## FE 전용 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| 클라이언트 Entity 과잉 설계 | API 응답을 재정의하려 함 | API 타입 기반 interface로 충분. 별도 Entity는 사유 필요 |
| UI 문구 가정 | Figma 미확인 | variants에서 실제 문구 추출 |
| Container/Presentational 혼합 | 하나의 컴포넌트가 Usecase 호출 + UI 렌더링 | Container(데이터 흐름)와 Presentational(Props/Callbacks)을 분리 |
| 모든 Props를 Interface Contract에 기록 | 과잉 명세 | 모듈 경계를 형성하는 핵심 인터페이스만 정의 |
| 규칙 중복 구현 | UI/API에서 같은 규칙을 각각 구현 | 구현 시 `entity-object-pattern` 스킬 참조 |
| FR에 Entity/Command 헤더 | 지침 오해 | Design에서만 사용, FR은 테이블만 |
