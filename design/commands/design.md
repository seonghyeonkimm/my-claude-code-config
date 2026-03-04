---
name: design
description: RADIO 프레임워크 기반 설계. 작업 규모에 따라 깊이를 조절하고, D step에서 비즈니스 제품은 DDD로, 기술 라이브러리는 Library Design으로 딥다이브한다
arguments:
  - name: context
    description: 설계할 기능 설명, PRD, Linear 이슈 URL, 또는 기존 코드 경로
    required: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - Task
  - ToolSearch
  - Skill
---

# Design — C → RADIO → V

RADIO 프레임워크 기반 대화형 설계 도구.
C(Context)로 시작해 RADIO를 거쳐 V(Verification)로 마무리한다.
D step에서 비즈니스 제품은 DDD로, 기술 라이브러리는 Library Design으로 딥다이브한다.

```
Gate In ─ C  Context        기존 코드·패턴·컨벤션 파악

          R  Requirements   문제 정의 + 기능/비기능 + 스코프 아웃
 RADIO    A  Architecture   주요 컴포넌트 + 책임 할당
          D  Data Model     엔티티 + 딥다이브(제품→DDD / 라이브러리→Library Design)
          I  Interface      경계를 넘는 계약 (API, props, 이벤트)
          O  Optimizations  NFR에서 도출된 항목만 (YAGNI)

Gate Out ─ V  Verification  Given/When/Then 핵심 3~5개
```

## 참조 스킬

- `design-radio` — FE/BE별 RADIO 체크리스트
- `design-ddd` — DDD 판단 기준 (비즈니스 도메인이 복잡할 때)
- `design-library` — Library Design 판단 기준 (기술 라이브러리를 설계할 때)

## 핵심 원칙

1. **C(Gate In)와 V(Gate Out)는 항상 수행**
2. **RADIO 깊이는 작업 규모에 맞춘다** — 아래 표 참조
3. **한 단계씩 확정** — 이전 단계 합의 후 다음으로
4. **함께 토론** — Claude는 대안/트레이드오프를 제시하고, 사용자가 결정

| 작업 규모 | Gate (C/V) | RADIO 단계 |
|-----------|------------|------------|
| 소 (버그/1일) | C, V (항상) | R |
| 중 (기능/1주) | C, V (항상) | R, D, I |
| 대 (시스템/1달+) | C, V (항상) | R, A, D, I, O |

## Input

- `$ARGUMENTS.context`: 설계할 기능 설명 (선택)

## Execution Flow

### Phase 0: 입력 수집

1. **입력 파싱**:

   | 입력 타입 | 감지 방법 | 처리 |
   |-----------|-----------|------|
   | 없음 | `$ARGUMENTS.context` 비어있음 | AskUserQuestion: "어떤 기능을 설계할까요?" |
   | 텍스트 | URL 아님 | 그대로 작업 설명으로 사용 |
   | Linear URL | `linear.app` 포함 | ToolSearch로 Linear MCP fetch |
   | GitHub URL | `github.com` 포함 | `gh issue view` |
   | 파일 경로 | 로컬 경로 패턴 | Read로 기존 코드/문서 읽기 |

2. **트랙 판별**: FE / BE / 풀스택 — `design-radio` skill의 해당 체크리스트 참조에 사용

3. **작업 규모 판별**:

```
AskUserQuestion:
  "작업 규모는 어느 정도인가요?

  - 소 (버그 수정, 1일 작업) → C, R, V
  - 중 (기능 추가, 1주 작업) → C, R, D, I, V
  - 대 (시스템 설계, 1달+) → C, R, A, D, I, O, V 전체"
```

### Step C: Context (Gate In)

`design-explorer` agent에 위임하여 코드베이스를 자율 탐색한다.

```
Task(subagent_type: "general-purpose", prompt: "
  design-explorer agent로 동작한다.

  ## 작업
  {$ARGUMENTS.context 또는 사용자 입력}

  ## 탐색 항목
  1. 재사용 가능한 기존 모듈/함수/컴포넌트 (파일 경로 포함)
  2. 프로젝트의 기존 패턴과 컨벤션
  3. 변경이 필요한 기존 코드 범위
  4. 관련 테스트 파일과 테스트 패턴

  ## 출력 형식
  ### 재사용
  - {모듈명}: {파일 경로} — {설명}

  ### 컨벤션
  - {패턴 요약}

  ### 변경 대상
  - {파일}: {변경 이유}
")
```

agent 결과를 사용자에게 공유하고 확인:

```
AskUserQuestion:
  "코드베이스를 파악했습니다.

  ## Context
  {agent 결과}

  빠진 것이나 수정할 부분이 있나요?"
```

### Step R: Requirements

> "무엇을 해야 하고, 무엇을 하지 않는가?"

```
AskUserQuestion:
  "요구사항을 정리합시다.

  1. 한 문장 정의: 'X를 하면 Y가 된다'
  2. 기능 요구사항: 핵심 유저 플로우
  3. 비기능 요구사항: 성능, 보안, 접근성 중 해당 항목
  4. 스코프 아웃: 이번에 하지 않는 것

  이미 정리한 것이 있으면 공유해주세요."
```

**Claude의 역할** (`design-radio` skill 참조):
- 한 문장 정의를 적을 수 없으면 → "아직 설계 준비가 안 된 것. PRD를 다시 확인합시다"
- FE: 지원 디바이스/브라우저, 접근성 수준, Figma URL 확인
- BE: API 소비자, 예상 트래픽, 데이터 일관성, 인증 모델 확인
- 스코프 아웃 누락 시 → "이번에 하지 않는 것을 명시하지 않으면 범위가 늘어납니다"

> 작업 규모가 **소**이면 여기서 Step V로 건너뛴다.

### Step A: Architecture (대 규모만)

> "주요 조각은 무엇이고, 각각 무슨 책임을 가지는가?"

```
AskUserQuestion:
  "아키텍처를 잡아봅시다.

  주요 컴포넌트(3~7개)를 식별하고, 각 책임과 관계를 적어주세요.

  - {컴포넌트}: {한 줄 책임}
  - {컴포넌트} → {컴포넌트}: {통신 방식}

  이미 생각한 구조가 있으면 공유해주세요."
```

**Claude의 역할** (`design-radio` skill 참조):
- FE: Container/Presentational 구분, 상태 관리 전략, CSR/SSR 경계
- BE: 서비스 경계, 호출 흐름(Presentation→Application→Domain), Port 추상화

### Step D: Data Model

> "어떤 데이터가 존재하고, 어디서 오고, 어디에 저장되는가?"

```
AskUserQuestion:
  "데이터 모델을 정의합시다.

  핵심 엔티티, 필드, 타입, 제약조건을 적어주세요.
  엔티티 간 관계도 포함해주세요.

  이미 정의한 것이 있으면 공유해주세요."
```

**프로젝트 성격 판단** — 먼저 비즈니스 제품인지, 기술 라이브러리인지 판단한다:

```
Q: 이 코드의 주요 소비자는?
├─ 최종 사용자 (비즈니스 제품) → 도메인 복잡도 판단 → DDD 딥다이브
└─ 다른 개발자 (라이브러리/SDK/공유 모듈) → Library Design 딥다이브
```

#### 경로 A: DDD 딥다이브 (비즈니스 제품)

**도메인 복잡도 판단** — 아래 중 2개 이상 해당하면 DDD 딥다이브:
- 상태 전이가 있다 (예: Draft → Active → Expired)
- 비즈니스 규칙이 3개 이상이다
- 여러 엔티티 간 불변식이 존재한다
- "~할 수 없다" 형태의 제약이 많다

**DDD 딥다이브 시** (`design-ddd` skill 참조):

추가 질문을 순서대로 진행한다:

1. **Aggregate 경계**: "A를 변경할 때 B도 반드시 함께 변경되어야 하는가?"
2. **Entity vs Value Object**: "고유 ID가 필요하고 상태가 변하는가?"
3. **불변식**: "각 Aggregate가 항상 보장해야 하는 조건은?"
4. **책임 할당**: "이 판단에 필요한 정보를 누가 갖고 있는가?"
5. **Domain Event**: "A 성공 후 B가 알아야 할 때 어떤 이벤트?"

각 질문은 사용자와 AskUserQuestion으로 하나씩 확정한다.

#### 경로 B: Library Design 딥다이브 (기술 라이브러리)

**Library 복잡도 판단** — 아래 중 2개 이상 해당하면 Library Design 딥다이브:
- 다른 개발자가 소비하는 코드이다 (패키지, SDK, 내부 공유 모듈)
- 공개 API surface를 설계해야 한다
- 하위 호환성/버전 관리를 고려해야 한다
- 추상화 레벨 선택이 설계의 핵심이다

**Library Design 딥다이브 시** (`design-library` skill 참조):

추가 질문을 순서대로 진행한다:

1. **Consumer Mental Model**: "이 라이브러리의 소비자는 누구이고, 알아야 할 핵심 개념은?"
2. **API Surface**: "무엇을 공개하고, 무엇을 숨기는가? Progressive Disclosure 3계층은?"
3. **Type Contract**: "타입으로 잘못된 사용을 막을 수 있는가?"
4. **Extension Point**: "소비자가 동작을 확장해야 하는 지점과 패턴은?"
5. **Stability**: "하위 호환성, 의존성 관리, deprecation 정책은?"

각 질문은 사용자와 AskUserQuestion으로 하나씩 확정한다.

### Step I: Interface Definition

> "컴포넌트 간 경계에서 무엇이 오고 가는가?"

```
AskUserQuestion:
  "인터페이스를 정의합시다.

  각 경계의 Input/Output과 에러 처리를 적어주세요.

  이미 정의한 것이 있으면 공유해주세요."
```

**Claude의 역할** (`design-radio` skill 참조):
- FE: Component props, Hook API, 이벤트 핸들러, Route params
- BE: 엔드포인트, Request/Response, 상태 코드, 인증
- D와 일관성 검증

### Step O: Optimizations (대 규모만)

> "NFR에서 도출된 최적화는 무엇인가?"

```
AskUserQuestion:
  "R에서 식별한 NFR에서 최적화 항목을 도출합시다.

  형식: [{카테고리}] {항목} (NFR-{N}에서 도출)
  해당 없으면 '없음'."
```

- 추측성 최적화 차단 → "R의 NFR에 없었습니다. 정말 필요한가요?"

### Step V: Verification (Gate Out)

> "이것이 완료되었다는 것을 어떻게 증명하는가?"

```
AskUserQuestion:
  "완료 조건을 정의합시다.

  Given/When/Then 형식으로 핵심 3~5개.
  순서: 정상 → 에러 → 엣지

  | # | Given | When | Then |

  이 TC를 모두 통과하면 '완료'입니다."
```

**Claude의 역할** (`design-radio` skill 참조):
- 정상/에러 케이스 1개 이상 확인
- FE: 네트워크 실패, 빈 상태, 반응형, 접근성
- BE: 4xx/5xx, 동시 요청, 권한 경계
- 중복 TC 제거

### 설계 종합

모든 Step 완료 후 설계 문서를 생성한다.

1. **파일**: `.claude/docs/{project-name}/design.md`
2. **구조**: C → R → (A) → D → I → (O) → V 각 산출물 정리
3. **딥다이브 결과** (해당 시):
   - DDD: Aggregate 구조, 불변식, Domain Event
   - Library Design: API Surface, Type Contract, Extension Point, Stability

```
AskUserQuestion:
  "설계를 정리했습니다.

  파일: .claude/docs/{project-name}/design.md

  선택:
  - 완료
  - TDD로 구현 진행 (/tdd:start)
  - 수정 필요"
```

### 넘어가기 처리

모든 Step에서 사용자가 "넘어가자", "네가 해줘"면:
1. 지금까지 맥락으로 초안 작성
2. "이대로 갈까요?" 확인
3. 확인 후 다음 Step 진행

## 안티패턴

| 안티패턴 | 문제 | 해결 |
|----------|------|------|
| C 없이 R부터 시작 | 기존 코드를 모르고 설계 | C(Gate In)부터 |
| D와 I를 동시에 | 데이터와 계약 뒤섞임 | D 먼저, I 다음 |
| O에서 추측성 최적화 | YAGNI 위반 | R의 NFR에 없으면 안 함 |
| V 없이 구현 | "완료" 미정의 | 최소 3개 Given/When/Then |
| Domain이 Infra를 import | Dependency Rule 위반 | Port interface로 역전 |

## Error Handling

| 상황 | 대응 |
|------|------|
| context 인자 없음 | AskUserQuestion으로 작업 설명 요청 |
| Linear/GitHub fetch 실패 | 텍스트로 직접 입력 요청 |
| 새 프로젝트 (기존 코드 없음) | C에서 "컨벤션 없음" 기록 후 진행 |
| 한 문장 정의 불가 | PRD 재확인 안내 |

## Example

```
사용자: /design 게시글에 좋아요 기능 추가

Claude: 작업 규모는? [AskUserQuestion: 소/중/대]

사용자: 중

Claude: [C] 코드베이스를 탐색합니다... (design-explorer agent 위임)
  → 재사용: ArticleEntity, reaction-api-client
  → 컨벤션: Entity Object 패턴, react-query
  빠진 것이 있나요? [AskUserQuestion]

사용자: 없음

Claude: [R] 요구사항을 정리합시다. [AskUserQuestion]

사용자: "좋아요 토글, 좋아요 수 표시"
  스코프 아웃: 알림, 좋아요 사용자 목록

Claude: NFR도 확인합시다 — 낙관적 업데이트 필요? 동시성?
  ... (D, I 진행) ...

Claude: [D] 데이터 모델 — 복잡도 판단: 단순 (DDD 불필요)
  → 인라인으로 데이터 모델링

  ... (I, V 진행) ...

Claude: 설계 정리 완료.
  .claude/docs/article-like/design.md
  선택: 완료 / TDD / 수정
```
