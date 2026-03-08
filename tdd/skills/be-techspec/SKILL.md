---
name: be-techspec
description: |
  BE TechSpec 문서 작성 템플릿과 패턴. 백엔드 프로젝트의 기술 명세서를 작성할 때 참조.
  Use when: BE TechSpec 작성, API 설계 문서 생성, Given/When/Then 테스트 케이스 정의,
  DB 스키마 설계, 서비스 아키텍처 설계 문서 작성 시 사용.
---

# BE TechSpec

**공통 가이드:** `techspec-common` 스킬 참조 (Summary, Solution, AC, FR, Verification, 공통 실수)
**관련 스킬:** `entity-object-pattern` - 구현 시 반복되는 도메인 로직을 Entity Object로 그룹화하는 패턴
**대응 스킬:** `fe-techspec` - 프론트엔드 TechSpec (동일 구조, FE 관점)

BE TechSpec은 프로젝트의 백엔드 기술 구현 방향을 정의하는 문서. PRD(요구사항)와 API Spec을 기반으로 Solution, Acceptance Criteria, Test Cases를 도출한다.

## 문서 구조

```
Summary → Solution → Acceptance Criteria → Non-Functional Requirements → Functional Requirements (Given/When/Then) → Design → Component & Code - Server → Verification
```

전체 템플릿은 `references/template.md` 참조.

## BE 전용 섹션

### Non-Functional Requirements

카테고리:
- **Performance**: 응답 시간 p95 < 200ms, 처리량 > N RPS
- **Reliability**: 가용성 99.9%, 장애 복구 시간 (RTO/RPO)
- **Security**: 인증/인가, 입력 검증, OWASP Top 10
- **Scalability**: 수평 확장, DB 샤딩/파티셔닝 (해당 시)

해당 프로젝트에 관련 없는 카테고리는 생략 가능.

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

## BE 전용 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| 스키마 과잉 설계 | 미래 요구사항 예측 | YAGNI. 현재 TC에서 필요한 컬럼만 |
| 인덱스 누락 | 쿼리 패턴 미분석 | FR의 When/Then에서 조회 패턴 도출 → 인덱스 결정 |
| Controller에 비즈니스 로직 | 레이어 책임 혼재 | Presentation(검증/라우팅)과 Application UseCase(조율) 분리 |
| Infrastructure → Domain 의존 | Dependency Rule 위반 | Domain은 순수 비즈니스 규칙만. DB/프레임워크 타입 import 금지 |
