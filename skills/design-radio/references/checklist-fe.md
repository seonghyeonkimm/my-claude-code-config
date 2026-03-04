# Design RADIO — FE 체크리스트

각 RADIO 단계의 프론트엔드 특화 질문. 공통 질문은 `checklist-common.md` 참조.

---

## C — Context (FE, Gate In)

- [ ] 기존 컴포넌트 라이브러리에서 쓸 수 있는 것은?
- [ ] 상태 관리 패턴은 어떤 것을 쓰고 있는가? (zustand, context, react-query 등)
- [ ] API 클라이언트 구조는? (fetch wrapper, react-query hooks 등)
- [ ] 라우팅 패턴은?

---

## R — Requirements (FE)

- [ ] 지원 디바이스/브라우저 범위는?
- [ ] 오프라인 지원이 필요한가?
- [ ] 접근성 요구 수준은? (WCAG A/AA/AAA)
- [ ] 기존 디자인 시스템에서 사용할 컴포넌트는?
- [ ] Figma 디자인이 존재하는가? (있다면 URL 확보)

---

## A — Architecture (FE)

- [ ] Container(데이터 흐름)와 Presentational(순수 UI)을 구분했는가?
- [ ] 상태 관리 전략을 정했는가? (서버 상태 vs 클라이언트 상태)
- [ ] 라우팅 구조를 정했는가?
- [ ] 클라이언트/서버 경계를 정했는가? (SSR, SSG, CSR)

---

## D — Data Model (FE)

- [ ] **Server-origin**: API에서 오는 데이터 (여러 기기 공유)
- [ ] **Client-persistent**: localStorage, URL params, cookie에 저장되는 데이터
- [ ] **Client-ephemeral**: 폼 입력, UI 토글, 모달 상태 등 휘발성 데이터
- [ ] 캐시 전략은? (stale-while-revalidate, 수동 무효화 등)

### 산출물 예시

```typescript
interface Product {
  id: string;          // server-origin
  name: string;        // server-origin
  quantity: number;     // client-ephemeral (장바구니 수량)
}
```

---

## I — Interface Definition (FE)

- [ ] Component props interface를 정의했는가?
- [ ] Hook API를 정의했는가? (input params, return values)
- [ ] 이벤트 핸들러와 콜백을 정의했는가?
- [ ] Route params와 search params를 정의했는가?

### 산출물 예시

```typescript
interface ProductCardProps {
  product: Product;
  onAddToCart: (quantity: number) => void;
}
```

---

## O — Optimizations (FE)

- [ ] **성능**: 번들 사이즈 한도? 코드 스플리팅? 이미지 최적화?
- [ ] **UX**: 로딩 상태? 낙관적 업데이트? 스켈레톤?
- [ ] **네트워크**: 캐싱 전략? 요청 중복 제거? 오프라인 폴백?
- [ ] **접근성**: 키보드 내비게이션? 스크린 리더? 색 대비?

### 산출물 예시

```markdown
## Optimizations
- [성능] 상품 목록 초기 로딩 3초 이내 (NFR-1에서 도출)
- [접근성] 키보드만으로 전체 플로우 완료 가능 (NFR-3에서 도출)
- 그 외 해당 없음
```

---

## V — Verification (FE, Gate Out)

Given/When/Then 형식으로 **핵심 행위 3~5개**를 작성한다.
이것이 "완료의 정의"이며, 순서는 정상 → 에러 → 엣지.

```markdown
| # | Given | When | Then |
|---|-------|------|------|
| 1 | {초기 상태} | {유저 행동} | {기대 UI 결과} |
```

- [ ] 정상 케이스가 1개 이상 있는가? (유저 플로우 성공)
- [ ] 에러 케이스가 1개 이상 있는가? (네트워크 실패, 빈 상태, 에러 화면)
- [ ] 경계 조건이 1개 이상 있는가? (반응형 레이아웃, 접근성, 극단적 데이터)
- [ ] 각 TC가 고유한 경계 조건을 검증하는가? (중복 TC 제거)
- [ ] 이 TC를 통과하면 "완료"라고 말할 수 있는가?
