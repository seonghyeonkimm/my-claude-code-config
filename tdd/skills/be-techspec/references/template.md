# BE TechSpec Template

Linear 문서 생성 시 `create_document`의 content 파라미터에 아래 구조를 채워서 전달한다.

---

## Summary

Linear, PRD 등 프로젝트에 대한 배경, 프로젝트 맥락에서 다루는 목적과 할 수 있는 최대한의 요점을 적어주세요.

- **PRD**: {PRD_URL}
- **API Spec**: {SWAGGER_URL} (있으면)

## Solution

기술 용어 없이 비즈니스 관점에서 핵심 변경사항을 요약합니다.

### 핵심 변경사항

1. **{변경1}**: {설명}
2. **{변경2}**: {설명}
3. **{변경3}**: {설명}

## Acceptance Criteria

기능 동작 관련, 최소 기준을 작성해요. 측정 가능하고 검증 가능한 문장으로 작성.

1. {주어} 상태에서 {동작}하면 {결과}가 발생한다
2. ...

## Non-Functional Requirements

SLA/SLO를 준수하며 시스템 요구사항을 정의해요. 해당 없으면 생략 가능.

- **Performance**: 응답 시간 p95 < {N}ms, 처리량 > {N} RPS
- **Reliability**: 가용성 {N}%, RTO < {N}분, RPO < {N}분
- **Security**: {인증/인가 요구사항}
- **Scalability**: {확장 요구사항} (해당 시)

## Functional Requirements (Test cases / Given, When, Then)

Entity/Command 헤더 없이 테이블만 작성. 정상 → 에러 → 엣지 케이스 순서.

| # | Given | When | Then |
|---|-------|------|------|
| 1 | {DB/시스템 초기 상태} | {API 호출/이벤트} | {응답 + 상태 변경} |

## Design

아래 순서로 구조화하여 작성.

### 1. 데이터 모델

DB 스키마와 Domain Entity를 함께 정의. DB 스키마가 Primary이나, Domain Entity는 비즈니스 규칙을 표현하며 스키마와 다를 수 있다.

| 테이블명 | 컬럼 | 타입 | 제약조건 | 설명 |
|----------|------|------|----------|------|
| {table} | {column} | {type} | {PK/FK/NOT NULL/UNIQUE/INDEX} | {설명} |

**인덱스 전략:**

| 테이블 | 인덱스명 | 컬럼 | 용도 (TC#) |
|--------|----------|------|-----------|
| {table} | {idx_name} | {columns} | {쿼리 패턴 설명} (#N) |

**마이그레이션** (기존 데이터 변환 필요 시):

| 단계 | 작업 | 롤백 전략 |
|------|------|----------|
| 1 | {마이그레이션 내용} | {롤백 방법} |

**Domain Entity** (비즈니스 규칙이 있는 경우):

| Entity | 핵심 필드 | 비즈니스 규칙 | DB 매핑 테이블 |
|--------|----------|-------------|--------------|
| {EntityName} | {fields} | {불변 조건/정책} | {table명} |

### 2. Usecase

| Usecase | Input | Output | 부수효과 |
|---------|-------|--------|----------|
| {Usecase명} | {입력} | {출력} | {DB 변경, 이벤트 발행 등} |

### 2.5. Interface Contract

#### External API (클라이언트 → 서버)

| Endpoint | Method | Params/Body | Response (성공) | Response (에러) | TC# |
|----------|--------|-------------|----------------|----------------|-----|
| `/api/v1/{resource}` | GET/POST/PUT/DELETE | `{params}` | `{200/201}: {ResponseType}` | `{4xx/5xx}: {ErrorType}` | #1,#2 |

#### Internal API (서비스 간, 해당 시)

| 호출자 → 피호출자 | 방식 | Payload | 설명 | TC# |
|-------------------|------|---------|------|-----|
| {ServiceA} → {ServiceB} | HTTP/gRPC/Queue | `{payload}` | {설명} | #3 |

#### 에러 코드 체계

| 에러 코드 | HTTP Status | 설명 | TC# |
|-----------|-------------|------|-----|
| {ERROR_CODE} | {4xx/5xx} | {설명} | #N |

### 3. Module & Layer Structure

Clean Architecture 기반. Domain은 아무것도 의존하지 않는다.

```
호출 흐름:  Presentation → Application → Domain
주입 (DI): Infrastructure가 Application의 Port를 구현

{FeatureName}
├── Presentation    [HTTP 진입점]
│   ├── {FeatureName}Controller    → UseCase 호출
│   └── {FeatureName}Dto (Request/Response)
├── Application     [비즈니스 흐름 조율]
│   ├── {FeatureName}UseCase       → Domain 사용
│   └── {FeatureName}Repository (Port interface)
├── Domain          [핵심 비즈니스 규칙, 외부 의존 없음]
│   ├── {FeatureName} (Entity)
│   └── {FeatureName}DomainService (해당 시)
└── Infrastructure  [Port 구현체, DI로 주입]
    ├── {FeatureName}RepositoryImpl implements Repository
    └── {ExternalService}Adapter (해당 시)
```

**Presentation** (프레임워크 결합 허용, 얇게 유지):
- **라우팅**: {엔드포인트 목록}
- **검증**: {Request DTO validation 규칙}
- **연결 UseCase**: {사용하는 UseCase}

**Application:**
- **유스케이스**: {핵심 로직 흐름}
- **트랜잭션 범위**: {트랜잭션 경계}
- **Port (interface)**: {Repository/외부 서비스 interface 목록}

**Domain:**
- **Entity**: {핵심 도메인 객체 + 비즈니스 규칙}
- **Value Object**: {값 객체} (해당 시)

**Infrastructure:**
- **Repository 구현체**: {사용 테이블 + 핵심 쿼리}
- **Adapter**: {외부 서비스 연동} (해당 시)

### 4. Usecase-Module Integration

| Usecase | Controller | UseCase | Domain | Repository (Impl) | TC# |
|---------|------------|---------|--------|-------------------|-----|
| {Usecase} | {Controller} | {UseCase클래스} | {Entity/DomainService} | {RepositoryImpl} | #N |

### 5. Optimization Checklist (해당 항목만 기록)

모든 항목을 채울 필요 없음. TC 또는 NFR에서 도출된 항목만 기록.

| 카테고리 | 항목 | 적용 | 설계 결정 | TC/NFR# |
|----------|------|------|----------|---------|
| Performance | 쿼리 최적화 (N+1, 인덱스) | Y/N/해당없음 | {결정} | |
| Performance | 커넥션 풀링 | Y/N/해당없음 | {결정} | |
| Performance | 캐싱 (Redis, 인메모리) | Y/N/해당없음 | {결정} | |
| Reliability | 재시도/서킷 브레이커 | Y/N/해당없음 | {결정} | |
| Reliability | 타임아웃 설정 | Y/N/해당없음 | {결정} | |
| Security | 입력 검증 / SQL 인젝션 방지 | Y/N/해당없음 | {결정} | |
| Security | Rate limiting | Y/N/해당없음 | {결정} | |
| Observability | 로깅 / 메트릭 / 알림 | Y/N/해당없음 | {결정} | |

## Component & Code - Server

- Test cases 기반으로 모듈, 서비스, 레포지토리 구조 추출
- 레이어 분리, 파일 구조, 인터페이스 정의

## Verification

Integration Test 최우선.

### Integration Tests (필수)

| TC# | 테스트 명 | 검증 내용 |
|-----|----------|----------|
| TC1 | {테스트명} | {API 호출 → 응답 + DB 상태 검증} |

### Unit Tests (필요 시)

복잡한 도메인 로직만 대상.

### E2E Tests (필요 시)

전체 API 플로우 검증 (여러 엔드포인트를 순차 호출하는 시나리오).
