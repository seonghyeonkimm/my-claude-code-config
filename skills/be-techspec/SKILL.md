---
name: be-techspec
description: |
  BE TechSpec 문서 작성 템플릿과 패턴. 백엔드 프로젝트의 기술 명세서를 작성할 때 참조.
  Use when: BE TechSpec 작성, API 설계 문서 생성, Given/When/Then 테스트 케이스 정의,
  DB 스키마 설계, 서비스 아키텍처 설계 문서 작성 시 사용.
---

# BE TechSpec

**관련 스킬:** `entity-object-pattern` - 구현 시 반복되는 도메인 로직을 Entity Object로 그룹화하는 패턴
**대응 스킬:** `fe-techspec` - 프론트엔드 TechSpec (동일 구조, FE 관점)

BE TechSpec은 프로젝트의 백엔드 기술 구현 방향을 정의하는 문서. PRD(요구사항)와 API Spec을 기반으로 Solution, Acceptance Criteria, Test Cases를 도출한다.

## 문서 구조

```
Summary → Solution → Acceptance Criteria → Non-Functional Requirements → Functional Requirements (Given/When/Then) → Design → Component & Code - Server → Verification
```

전체 템플릿은 `references/template.md` 참조.

## 섹션별 작성 가이드

### Summary

프로젝트 배경과 맥락. PRD/API Spec 링크 포함.

```markdown
## Summary

{프로젝트 배경 1-3문장}

- **PRD**: {Notion URL}
- **API Spec**: {Swagger/OpenAPI URL} (있으면)
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
- 코드, 테이블명, 타입명 사용 금지
- 사용자/비즈니스 관점에서 서술
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
- 핵심 API 플로우별 1개 이상

### Non-Functional Requirements

SLA/SLO 기준의 시스템 요구사항.

카테고리:
- **Performance**: 응답 시간 p95 < 200ms, 처리량 > N RPS
- **Reliability**: 가용성 99.9%, 장애 복구 시간 (RTO/RPO)
- **Security**: 인증/인가, 입력 검증, OWASP Top 10
- **Scalability**: 수평 확장, DB 샤딩/파티셔닝 (해당 시)

해당 프로젝트에 관련 없는 카테고리는 생략 가능.

### Functional Requirements (Given/When/Then)

테스트 케이스를 구조화된 테이블로 정의.

```markdown
## Functional Requirements (Test cases / Given, When, Then)

| # | Given | When | Then |
|---|-------|------|------|
| 1 | {초기 상태/조건} | {API 호출/이벤트} | {기대 결과} |
| 2 | ... | ... | ... |
```

작성 팁:
- 정상 케이스 → 에러 케이스 → 엣지 케이스 순서
- Given은 DB/시스템 상태, When은 API 호출/이벤트, Then은 응답/상태 변경
- Entity/Command 식별은 Design 섹션에서 수행, FR에는 테이블만 작성

### Design

테스트 케이스 기반으로 백엔드 설계를 진행.

**작성 순서:**
1. **데이터 모델**: DB 스키마 중심 설계
   - 테이블, 컬럼, 타입, 제약조건, 인덱스 정의
   - 엔티티 간 관계 (FK, 1:N, N:M)
   - 마이그레이션 전략 (기존 데이터 변환 필요 시)
2. **Usecase**: 주요 사용 시나리오 테이블 (Input → Output)
2.5. **Interface Contract**: API 엔드포인트 + 서비스 간 계약
   - External API: method, path, params, body, response, 상태 코드, 에러 코드
   - Internal API: 서비스 간 호출, 메시지 큐, 이벤트
   - TC 번호로 추적
3. **Module & Layer Structure**: Clean Architecture (호출 흐름 + DI 주입)
   - 호출: **Presentation** → **Application** → **Domain**
   - 주입: **Infrastructure**가 Application의 Port를 구현 (DI)
   - **Presentation**: Controller, DTO — HTTP 진입점, UseCase 호출 (프레임워크 결합 허용, 얇게 유지)
   - **Application**: UseCase 조율, Port interface 정의, 트랜잭션 경계
   - **Domain**: Entity, Value Object, Domain Service — 외부 의존 없음
   - **Infrastructure**: Repository 구현체, Adapter — Port 구현, DI로 주입
4. **Usecase-Module Integration**: 연결 지점 정의
5. **Optimization Checklist**: TC/NFR에서 도출된 최적화 항목만 기록

**데이터 모델 가이드:**
- DB 스키마(테이블/컬럼)가 Primary. Domain Entity는 비즈니스 규칙을 표현하며 스키마와 분리될 수 있다 (규칙이 없으면 생략)
- enum/상수값은 DB enum 또는 애플리케이션 상수로 정의
- 인덱스는 쿼리 패턴에서 도출 (FR의 When/Then에서 어떤 조회가 필요한지)
- 마이그레이션: 기존 데이터가 있으면 zero-downtime 전략 고려

### Component & Code - Server

- Test cases 기반으로 모듈, 서비스, 레포지토리 구조 추출
- 레이어 분리, 파일 구조, 인터페이스 정의

### Verification

테스트 케이스 검증 전략.

**우선순위:**
1. **Integration Tests (필수)**: TC 기반 API 통합 테스트
2. **Unit Tests (필요 시)**: 복잡한 도메인 로직만
3. **E2E Tests (필요 시)**: 전체 API 플로우 검증

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| AC가 모호함 | "빠르게", "잘" 같은 추상적 표현 | 측정 가능한 기준 사용 (예: "p95 < 200ms") |
| Given/When/Then 불명확 | 상태/호출/결과 구분 없음 | Given=DB 상태, When=API 호출, Then=응답+상태 변경 |
| Test Case 누락 | 정상 케이스만 작성 | 에러/엣지 케이스 반드시 포함 |
| NFR 생략 | 선택사항이라 무시 | 공개 API면 Performance/Security 필수 검토 |
| Solution에 코드 포함 | "기술적 해결책"으로 오해 | 비기술 요약으로 작성 |
| 스키마 과잉 설계 | 미래 요구사항 예측 | YAGNI. 현재 TC에서 필요한 컬럼만 |
| 인덱스 누락 | 쿼리 패턴 미분석 | FR의 When/Then에서 조회 패턴 도출 → 인덱스 결정 |
| Controller에 비즈니스 로직 | 레이어 책임 혼재 | Presentation(검증/라우팅)과 Application UseCase(조율) 분리 |
| Infrastructure → Domain 의존 | Dependency Rule 위반 | Domain은 순수 비즈니스 규칙만. DB/프레임워크 타입 import 금지 |
| Optimization Checklist 전부 채움 | RADIO 원칙 오해 | TC/NFR에서 도출된 항목만. "해당없음"이 대부분이어도 정상 |
| Verification 누락 | 선택사항으로 오인 | Integration Test 필수 |
