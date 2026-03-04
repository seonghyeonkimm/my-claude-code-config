---
name: design-radio
description: |
  RADIO 기반 FE/BE 설계 체크리스트.
  `/design` command가 각 Step에서 참조하는 판단 기준과 질문 목록.
---

# Design RADIO — 체크리스트

GreatFrontEnd의 RADIO Framework를 실무 확장한 설계 체크리스트.
`/design` command가 C → RADIO → V 각 단계에서 이 스킬을 참조한다.

**사용 방법:**
- `/design` command의 각 Step에서 자동 참조됨
- 단독 참조도 가능 (설계 리뷰, 체크리스트 확인 시)

## C → RADIO → V

```
Gate In ─ C  Context        기존 코드·패턴·컨벤션 파악

          R  Requirements   문제 정의 + 기능/비기능 + 스코프 아웃
 RADIO    A  Architecture   주요 컴포넌트 + 책임 할당
          D  Data Model     엔티티, 필드, 데이터 출처/생명주기
          I  Interface      경계를 넘는 계약 (API, props, 이벤트)
          O  Optimizations  NFR에서 도출된 항목만 (YAGNI)

Gate Out ─ V  Verification  Given/When/Then 핵심 3~5개
```

> 라디오를 켜기 전에 **주파수를 맞추고**(C), 끝나면 **수신을 확인한다**(V).

각 단계의 상세 체크리스트:
- **공통**: `references/checklist-common.md` (항상 참조)
- **FE 작업**: `references/checklist-fe.md` (공통 + FE)
- **BE 작업**: `references/checklist-be.md` (공통 + BE)

## 사용법

### 1. 항상 C부터 시작한다

기존 코드와 컨벤션을 먼저 파악한다. 그 다음 R에서 "X를 하면 Y가 된다"를
한 문장으로 적을 수 없으면, 아직 설계할 준비가 안 된 것.
PRD를 다시 읽거나 PM에게 질문한다.

### 2. 깊이를 작업 크기에 맞춘다

| 작업 크기 | Gate (C/V) | RADIO 단계 |
|-----------|------------|------------|
| 버그 수정 / 1일 작업 | C, V (항상) | R |
| 기능 추가 / 1주 작업 | C, V (항상) | R, D, I |
| 시스템 설계 / 1달+ | C, V (항상) | R, A, D, I, O |

Gate(C/V)는 항상 수행한다. RADIO 단계는 작업 크기에 맞춰 선택한다.

### 3. 각 단계의 핵심 질문 (요약)

**C — Context** (Gate In)
> "지금 코드베이스에서 재사용하거나 변경할 것은?"
- 재사용 가능한 기존 코드
- 기존 패턴과 컨벤션
- 변경이 필요한 기존 코드

**R — Requirements**
> "무엇을 해야 하고, 무엇을 하지 않는가?"
- 한 문장 문제 정의
- 기능 요구사항 (핵심 유저 플로우)
- 비기능 요구사항 (성능, 보안, 접근성)
- 스코프 아웃 (명시적으로 하지 않는 것)

**A — Architecture**
> "주요 조각은 무엇이고, 각각 무슨 책임을 가지는가?"
- 주요 컴포넌트 식별
- 컴포넌트 간 관계도
- 계산이 일어나는 위치 (서버 vs 클라이언트)

**D — Data Model**
> "어떤 데이터가 존재하고, 어디서 오고, 어디에 저장되는가?"
- 엔티티 정의 (필드, 타입, 제약조건)
- 데이터 출처 (서버/클라이언트)
- 엔티티 간 관계

**I — Interface Definition**
> "컴포넌트 간 경계에서 무엇이 오고 가는가?"
- 각 경계의 Input/Output 계약
- 에러 처리 계약
- 타입 정의

**O — Optimizations**
> "NFR에서 도출된 최적화는 무엇인가?"
- R 단계의 NFR에서 직접 도출된 항목만
- 추측성 최적화 금지

**V — Verification** (Gate Out)
> "이것이 완료되었다는 것을 어떻게 증명하는가?"
- Given/When/Then 핵심 3~5개
- 정상 → 에러 → 엣지 순서
- 이것이 "완료의 정의"

## 안티패턴

| 안티패턴 | 문제 | 해결 |
|----------|------|------|
| C 없이 R부터 시작 | 기존 코드를 모르고 요구사항부터 정의 | C(Gate In)부터 시작 |
| C를 건너뜀 | 이미 있는 걸 새로 만듦 | Gate는 항상 수행 |
| D와 I를 동시에 생각 | 데이터와 계약이 뒤섞임 | D(무엇이 존재하는가) 먼저, I(어떻게 주고받는가) 다음 |
| O에서 추측성 최적화 | YAGNI 위반 | R의 NFR에 없으면 안 함 |
| V 없이 구현 시작 | "완료"가 정의되지 않음 | 최소 3개 Given/When/Then |
| Domain이 Infrastructure를 import | Dependency Rule 위반 | Domain은 순수 비즈니스 규칙만. 외부 의존은 Port interface로 역전 |
