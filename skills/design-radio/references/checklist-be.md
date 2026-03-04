# Design RADIO — BE 체크리스트

각 RADIO 단계의 백엔드 특화 질문. 공통 질문은 `checklist-common.md` 참조.

---

## C — Context (BE, Gate In)

- [ ] 기존 DB 스키마에서 관련 테이블은?
- [ ] 레이어 구조는? (호출: Presentation→Application→Domain, 주입: Infrastructure→Port 구현)
- [ ] 공통 미들웨어/인터셉터는?
- [ ] 인프라 제약은? (DB 종류, 배포 환경 등)

---

## R — Requirements (BE)

- [ ] API 소비자는 누구인가? (웹, 모바일, 다른 서비스)
- [ ] 예상 트래픽/처리량은?
- [ ] 데이터 일관성 요구는? (강한 일관성 vs 최종 일관성)
- [ ] 인증/인가 모델은 무엇인가?
- [ ] 기존 API 컨벤션(버전 체계, 에러 형식)은?

---

## A — Architecture (BE)

- [ ] 서비스 경계를 정했는가?
- [ ] 호출 흐름이 명확한가? (Presentation → Application → Domain)
- [ ] 외부 의존(DB, 외부 API)이 Port interface로 추상화되는가?
- [ ] DB 선택 근거가 있는가?
- [ ] 캐싱 전략이 필요한가?
- [ ] 비동기 처리가 필요한 작업은?
- [ ] 외부 서비스 의존성은?

---

## D — Data Model (BE)

- [ ] 테이블/컬렉션 스키마를 정의했는가?
- [ ] 인덱스 전략은?
- [ ] 마이그레이션이 필요한가? (기존 데이터 변환)
- [ ] 데이터 밸리데이션 룰은?
- [ ] 소프트 삭제 vs 하드 삭제?

### 산출물 예시

```sql
-- products 테이블
CREATE TABLE products (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       VARCHAR(255) NOT NULL,
  price      DECIMAL(10,2) NOT NULL,
  deleted_at TIMESTAMP NULL,           -- soft delete
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_products_name ON products(name);
```

---

## I — Interface Definition (BE)

- [ ] 엔드포인트를 정의했는가? (method, path, 설명)
- [ ] Request 스키마를 정의했는가? (params, query, body)
- [ ] Response 스키마를 정의했는가? (성공, 에러)
- [ ] 상태 코드와 에러 코드를 정의했는가?
- [ ] 인증 헤더 요구사항은?

### 산출물 예시

```
POST /api/v1/cart/items
  Auth: Bearer token (required)
  Request:  { productId: string, quantity: number }
  Response 201: { cartItem: CartItem }
  Response 404: { error: "PRODUCT_NOT_FOUND", message: string }
  Response 409: { error: "OUT_OF_STOCK", message: string }
```

---

## O — Optimizations (BE)

- [ ] **성능**: 쿼리 최적화? N+1 방지? 인덱스?
- [ ] **신뢰성**: 재시도 로직? 서킷 브레이커? 타임아웃?
- [ ] **보안**: 입력 검증? SQL 인젝션? Rate limiting?
- [ ] **관측성**: 로깅? 메트릭? 알림?

### 산출물 예시

```markdown
## Optimizations
- [성능] 상품 목록 쿼리 p95 < 200ms (NFR-1에서 도출, 인덱스 추가)
- [보안] Rate limiting 100 req/min per user (NFR-2에서 도출)
- 그 외 해당 없음
```

---

## V — Verification (BE, Gate Out)

Given/When/Then 형식으로 **핵심 행위 3~5개**를 작성한다.
이것이 "완료의 정의"이며, 순서는 정상 → 에러 → 엣지.

```markdown
| # | Given | When | Then |
|---|-------|------|------|
| 1 | {초기 상태} | {API 요청} | {기대 응답 + 상태 코드} |
```

- [ ] 정상 케이스가 1개 이상 있는가? (성공 응답, 데이터 정합)
- [ ] 에러 케이스가 1개 이상 있는가? (4xx 클라이언트 에러, 5xx 서버 에러)
- [ ] 경계 조건이 1개 이상 있는가? (동시 요청, 데이터 정합성, 권한 경계)
- [ ] 각 TC가 고유한 경계 조건을 검증하는가? (중복 TC 제거)
- [ ] 이 TC를 통과하면 "완료"라고 말할 수 있는가?
