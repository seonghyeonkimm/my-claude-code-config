---
name: design-library
description: |
  Library/API 설계 판단 기준.
  `/design` command의 D step에서 기술 라이브러리를 설계할 때 참조.
---

# Design Library — API/라이브러리 설계 판단 기준

`/design` command의 D step에서 기술 라이브러리를 설계할 때 참조하는 판단 기준.

**사용 방법:**
- `/design` command의 D step에서 자동 참조됨
- 단독 참조도 가능 (라이브러리 API 리뷰 시)

## Library Design 딥다이브 진입 조건

아래 중 **2개 이상** 해당하면 Library Design 딥다이브가 필요하다:

- 다른 개발자가 소비하는 코드이다 (패키지, SDK, 내부 공유 모듈)
- 공개 API surface를 설계해야 한다
- 하위 호환성/버전 관리를 고려해야 한다
- 추상화 레벨 선택이 설계의 핵심이다

## 설계 Phase 개요

```
Phase 1: 소비자의 멘탈 모델을 정의한다 (누가, 어떻게 쓰는가)
         ↓
Phase 2: 공개할 것과 숨길 것의 경계를 긋는다 (API Surface)
         ↓
Phase 3: 경계 안에서 구체적으로 설계한다
         - 타입으로 잘못된 사용을 막고 (Type Contract)
         - 확장 방법을 정하고 (Extension Point)
         - 안정성 약속을 정한다 (Stability Commitment)
```

---

## Phase 1: Consumer Mental Model (소비자 이해)

> "이 라이브러리를 쓰는 개발자가 머릿속에 가져야 할 개념은?"

### 1-1. 소비자 정의

| 질문 | 예시 |
|------|------|
| 누가 쓰는가? | 앱 개발자 / 라이브러리 개발자 / 내부 팀 |
| 숙련도는? | 초급 → 간결한 API, 상급 → 세밀한 제어 |
| 한 문장 정의 | "{X}를 하기 위한 라이브러리" |

**검증 질문:**
- "README의 한 줄 소개를 적을 수 있는가?"
- 적을 수 없으면 아직 범위가 명확하지 않은 것.

### 1-2. 핵심 개념 (Concept Glossary)

소비자가 알아야 할 개념을 3~5개로 정리한다.

| 개념 | 정의 | 코드에서의 표현 |
|------|------|----------------|
| {명사} | {한 문장 정의} | {class/type/function 이름} |

**검증 질문:**
- 이 개념들만 알면 기본 사용이 가능한가?
- 너무 많으면 → 추상화 경계를 재검토

### 1-3. 사용 예시 (README-Driven)

**구현 전에** 사용 예시를 먼저 작성한다.

```
Simple (1줄):  가장 흔한 사용법. 80%의 케이스.
Advanced:      설정을 바꾸거나 동작을 커스터마이즈. 19%.
Escape Hatch:  추상화를 우회해 내부에 직접 접근. 1%.
```

**검증 질문:**
- Simple 예시가 1줄(또는 최소한의 코드)인가?
- 잘못된 사용이 이 예시보다 더 쉽지는 않은가?

---

## Phase 2: API Surface (공개 경계)

> "무엇을 공개하고, 무엇을 숨기는가?"

### 2-1. Public vs Internal

```
Q: 이 심볼을 공개해야 하는가?
├─ 소비자의 use case에 필요하다 → Public
└─ 내부 구현 편의를 위한 것이다 → Internal
```

**핵심 원칙: "확신이 없으면 빼라"** (Bloch)
- 나중에 추가는 가능하지만, 제거는 breaking change
- Public으로 공개한 모든 심볼은 영원한 약속

### 2-2. Progressive Disclosure

3계층으로 API를 설계한다:

| 계층 | 설명 | 설계 기준 |
|------|------|----------|
| Layer 1: Simple | 가장 흔한 케이스 | 최소 파라미터, 좋은 기본값 |
| Layer 2: Configurable | 커스터마이즈 필요 | options object, 선택적 파라미터 |
| Layer 3: Escape Hatch | 추상화 우회 필요 | 내부 primitive 노출 |

**검증 질문:**
- Layer 1만으로 80%의 use case를 해결하는가?
- Layer 1을 배운 뒤 Layer 2로 자연스럽게 전환되는가? (호환되는가?)
- 추상화가 실패할 때 escape hatch가 존재하는가?

### 2-3. Naming

**판단 기준:**
- 이름 짓기가 어려우면 추상화 경계가 잘못된 것 (Bloch)
- 관련 메서드는 일관된 이름 패턴을 따르는가? (대칭성)
- 코드 샘플이 산문처럼 읽히는가?
- 파라미터 순서가 모든 메서드에서 일관적인가?

### 2-4. Module 구조

```
Q: import 경로가 깊은가?
├─ 3단계 이상 → flat하게 재구성 고려
└─ 2단계 이하 → OK
```

- Flat is better than nested (자동완성과 발견 용이)
- 단, 논리적으로 독립된 하위 모듈이면 분리 가능

---

## Phase 3: Contract & Extension (계약과 확장)

### 3-1. Type Contract

> "타입으로 잘못된 사용을 컴파일 타임에 막을 수 있는가?"

**결정 트리:**

```
Q: 유효하지 않은 상태가 타입으로 표현 가능한가?
├─ Yes → Q: 그 상태가 조용한 오동작을 유발하는가?
│         ├─ Yes → 타입으로 방지 (discriminated union, branded type)
│         └─ No  → 런타임 검증 + 명확한 에러 메시지로 충분
└─ No  → 문서화로 안내
```

**기법:**

| 기법 | 언제 | 예시 |
|------|------|------|
| Discriminated Union | 상호 배타적 상태 | `{ kind: "email"; email: string } \| { kind: "postal"; address: Address }` |
| Smart Constructor | 생성 시 검증 필요 | `EmailAddress.parse(raw)` → `Result<EmailAddress, Error>` |
| Branded Type | 같은 원시 타입이지만 의미가 다름 | `UserId` vs `OrderId` (둘 다 string이지만 혼용 방지) |
| Non-empty Collection | 빈 입력이 의미 없음 | `[T, ...T[]]` |

**적용하지 않을 때:**
- 타입 시그니처가 이해 불가능하게 복잡해질 때
- 제약이 문서로 충분히 전달될 때 ("양수여야 한다" 수준)

### 3-2. Error Model

```
Q: 호출자가 에러를 프로그래밍적으로 분기해야 하는가?
├─ Yes → typed exception 또는 Result type
└─ No  → 메시지만 포함된 일반 에러
```

**원칙:**
- 에러는 문자열이 아닌 머신 리더블 구조를 가져야 한다
- 에러는 잘못 사용한 지점에서 즉시 발생해야 한다 (fail fast)
- 정상 흐름에 예외를 사용하지 않는다

### 3-3. Extension Point

> "소비자가 동작을 확장해야 하는 지점은 어디인가?"

**패턴 선택:**

| 패턴 | 제어 흐름 | 결합도 | 적합한 경우 |
|------|----------|--------|------------|
| Plugin | 라이브러리가 호출 | 낮음 | 전체 기능 추가 (파서, 포매터, 백엔드) |
| Middleware | 체인, 각각 next() 호출 | 중간 | 요청/응답 파이프라인, 전후 처리 |
| Hook/Event | Pub-Sub, fire-and-forget | 매우 낮음 | 관찰만 필요, 동작 변경 불필요 |
| Adapter | 인터페이스 변환 | 낮음 | 외부 구현 주입 (HTTP 클라이언트, 로거) |

**판단 흐름:**

```
Q: 확장이 동작을 변경하는가, 관찰만 하는가?
├─ 관찰만 → Hook/Event
└─ 변경 → Q: 전후 처리 파이프라인인가?
            ├─ Yes → Middleware
            └─ No  → Q: 기능 단위로 교체 가능한가?
                      ├─ Yes → Plugin
                      └─ No  → Adapter (외부 의존 주입)
```

**Extension interface 설계 원칙:**
- interface는 최소화한다 (메서드 1~3개)
- Extension 간에 서로를 알 필요 없어야 한다
- 등록 방법이 명시적이어야 한다

### 3-4. Stability Commitment

> "공개한 모든 것은 영원한 약속이다"

**Hyrum's Law:** "충분한 사용자가 있으면, 문서화하지 않은 관측 가능한 행위에도 누군가 의존한다"

**체크리스트:**
- 관측 가능한 행위를 최소화했는가? (불필요한 정보 노출 금지)
- 의존성(dependency)은 최소한인가? (각 dep는 소비자의 짐)
- SemVer 전략은? (PATCH: 버그 수정 / MINOR: 추가 / MAJOR: 제거·변경)
- Deprecation 정책은? (MINOR에서 deprecated 표시 → 다음 MAJOR에서 제거)
- Tree-shaking / 모듈별 import가 가능한가?

---

## 흔한 실수

| 실수 | 문제 | 해결 |
|------|------|------|
| 구현부터 시작 | API가 내부 구조를 반영 | 사용 예시(README)를 먼저 작성 |
| 모든 것을 public | 모든 변경이 breaking change | 기본 private, 필요한 것만 공개 |
| string/any 파라미터 남용 | 런타임 에러, 문자열 파싱 | 전용 타입, enum, value object |
| nullable return | 호출자가 null 체크 누락 | 빈 컬렉션, Option/Result 타입 |
| 긴 positional 파라미터 | 인자 순서 실수 | options object 또는 builder |
| escape hatch 없음 | 추상화 실패 시 막힘 | Layer 3 raw access 제공 |
| 무거운 의존성 | 번들 비대, 버전 충돌 | dep 최소화, 주입 허용 |
| global mutable 설정 | 복수 인스턴스 간 간섭 | 인스턴스 기반 설정 (class/closure) |
| 에러에 문자열만 | 호출자가 에러 문자열 파싱 | typed exception + 머신 리더블 필드 |
