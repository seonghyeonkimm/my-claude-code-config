---
description: TechSpec의 테스트 케이스 기반으로 데이터 모델(interface), Usecase, Client Component를 설계
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - ToolSearch
  - AskUserQuestion
  - Task
---

# TDD Design Command

`/tdd:spec`의 결과물을 기반으로 데이터 모델(API 기반 interface)과 클라이언트 컴포넌트를 설계한다.

## Prerequisites

- **필수**: `/tdd:spec` 실행 완료 → `.claude/docs/{project-name}/meta.yaml` 존재
- **필수 스킬**: `fe-techspec` - 설계 패턴 참조
- **선택 스킬**: `entity-object-pattern` - 구현 시 Refactor 단계에서 참조
- **필수 MCP**: Linear plugin (문서 읽기/업데이트)
- **선택 MCP**: Figma plugin (컴포넌트 상세 분석 시)

## Execution Flow

### Phase 1: 메타데이터 로드 및 Linear 문서 조회

1. `.claude/docs/` 하위에서 프로젝트 메타데이터 파일을 찾는다:
   ```
   Glob(pattern: ".claude/docs/*/meta.yaml")
   ```
2. 여러 프로젝트가 있으면 AskUserQuestion으로 선택 요청
3. meta.yaml에서 `document.id`, `document.url`, `sources.figma` 등 메타데이터를 읽는다
4. Linear에서 TechSpec 문서 내용을 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__get_document")
   → mcp__plugin_linear_linear__get_document(id: "{document.id}")
   ```
   - 문서 내용에서 **Functional Requirements (Given/When/Then)** 섹션 추출
   - 문서 내용에서 **Non-Functional Requirements** 섹션 추출 (있는 경우)
   - `get_document` 도구가 없으면, 사용자에게 Linear URL을 안내하고 수동 확인 요청

### Phase 1.5: 설계 초안 수집 (필수)

tdd-designer agent에 위임하기 전에 인간의 설계 초안을 수집한다. 초안이 제공될 때까지 Phase 2-3으로 진행하지 않는다.

```
AskUserQuestion:
  question: "설계 초안을 공유해주세요. 이 초안을 기반으로 설계를 발전시킵니다.

  예시 형식:
  ### 핵심 결정
  - 컴포넌트: CartPage → CartList + CartItem으로 분리
  - 데이터: 기존 useCartQuery 훅 재사용

  ### 열린 질문
  - 수량 변경 UI를 인라인으로 할지 모달로 할지?

  자유 형식도 괜찮습니다.

  설계 시 고려하면 좋은 포인트:
  - 모듈 경계: 이 구조에서 한 모듈을 수정할 때 다른 파일까지 함께 고쳐야 하진 않는가?
  - 추상화 깊이: 모듈이 내부 복잡성을 충분히 숨기는가, 아니면 인터페이스만 복잡한 얕은 모듈인가?
  - 인지 부하: 이 설계를 이해하려면 한 번에 기억해야 할 개념이 몇 개인가? 몰라도 되는 옵션은 기본값으로 숨겼는가?
  - 데이터 흐름: 상태가 어디서 생성되고, 어떻게 흘러가며, 누가 변경하는가?
  - 에러 복구: 에러 발생 시 사용자에게 어떤 피드백을 주고, 상태를 어떻게 안전하게 되돌리는가?
  - 도메인 순수성: 도메인 로직이 UI/API/외부 의존성 없이 순수 함수로 분리되는가?
  - 테스트 경계: 테스트가 구현 세부사항이 아닌, 클라이언트에 노출된 공개 인터페이스를 검증하는 구조인가?
  - API 계약: 서버 데이터를 어떤 hook/endpoint로 조회하고, 어떤 hook으로 변경하는가?
  - 데이터 분류: 이 데이터는 서버에서 오는가, 클라이언트에서만 존재하는가? 영속적인가 휘발성인가?
  - 컴포넌트 계약: 이 컴포넌트의 Props Interface를 외부 소비자 관점에서 정의할 수 있는가?
  - 도메인 언어: 코드의 변수명/함수명이 팀의 비즈니스 용어와 일치하는가?
  - YAGNI: 이 구조에 현재 요구사항이 필요로 하지 않는 확장 포인트나 레이어가 있진 않은가?"
```

### Phase 2-3: 설계 (tdd-designer agent 위임)

데이터 모델, Usecase, Component, Visual Contract 설계를 `tdd-designer` agent에 위임한다.

```
Task(
  subagent_type: "tdd-designer",
  prompt: """
  다음 설계 초안과 TechSpec을 기반으로 Domain Model + Interface Contract + Client Architecture를 설계해주세요.

  ## 설계 초안 (인간 제공, 필수)
  {Phase 1.5에서 수집한 인간의 설계 초안}

  ## TechSpec Functional Requirements
  {Linear 문서에서 추출한 Given/When/Then 섹션 전문}

  ## Non-Functional Requirements (있는 경우)
  {Linear 문서에서 추출한 NFR 섹션, 없으면 "없음"}

  ## Figma URL (있는 경우)
  {meta.yaml의 sources.figma 값, 없으면 "없음"}

  ## 기존 Design 섹션 (업데이트 시)
  {기존 Design 내용, 최초 생성이면 "없음"}
  """
)
```

**agent 반환 결과**: 아래 섹션이 포함된 마크다운
- `## Design` (데이터 모델, Usecase, Interface Contract, Component & Visual Contract, Usecase-Component Integration, Optimization Checklist)
- `## Component & Code - Client`
- `## Verification`

### Phase 4: Linear 문서 업데이트

⚠️ **로컬 파일 수정 없음** - Linear 문서만 업데이트한다 (Single Source of Truth)

meta.yaml의 `document.id`로 TechSpec 문서에 Design 섹션을 추가한다:

```
ToolSearch(query: "select:mcp__plugin_linear_linear__update_document")
→ mcp__plugin_linear_linear__update_document(
    id: "{document.id}",
    content: "{기존 내용 + 아래 섹션 추가}"
  )
```

tdd-designer agent가 반환한 마크다운(Design, Component & Code, Verification 섹션)을 Linear 문서에 그대로 업데이트한다.

### Phase 5: 결과 보고

```
Design 완료!

Domain Model:
- 데이터 모델: {interface list} (Server-origin: {N}개, Client-only: {N}개)
- Usecases: {usecase list}

Interface Contract:
- Server-Client: {N}개 hooks (query: {N}, mutation: {N})
- Client-Client: {N}개 핵심 Props Interfaces

Client Architecture:
- Pages: {page list}
- Components: {N}개
- Shared: {shared component list}

Optimization: {N}개 항목 적용 (해당 시)

Linear Document: {document URL} (Design 섹션 업데이트됨)
* 로컬 파일 수정 없음 - Linear가 Single Source of Truth

다음 단계:
1. Linear에서 설계를 리뷰하세요
2. /tdd:issues 로 Linear 이슈를 생성하세요
```

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml이 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear 문서 조회 실패 | 사용자에게 Linear URL 안내, 수동 확인 요청 |
| Linear 문서에 테스트 케이스가 없음 | 최소한의 데이터 모델/Usecase를 제안하고 확인 요청 |
| Figma URL이 없음 | 테스트 케이스만으로 컴포넌트 설계 진행 |
| Linear 문서 업데이트 실패 | 에러 메시지 출력, 재시도 안내 |

## Example

```
사용자: /tdd:design

Claude: .claude/docs/에서 메타데이터 파일을 찾고 있습니다...
  → .claude/docs/my-feature/meta.yaml 발견

Claude: Linear에서 TechSpec 문서를 조회합니다...
  → document.id: abc123

Claude: 설계 초안을 공유해주세요. 이 초안을 기반으로 설계를 발전시킵니다.
  [AskUserQuestion]

사용자:
  ### 핵심 결정
  - 컴포넌트: CartPage → CartContainer + CartList + CartItem으로 분리
  - 데이터: 기존 useCartQuery 훅 재사용, CartData는 API 타입 참조
  - 상태: React Query로 서버 상태, 수량 편집은 로컬 useState

  ### 열린 질문
  - QuantitySelector를 공용 컴포넌트로 뺄지 도메인 전용으로 둘지?

Claude: 초안을 기반으로 TC와 교차 검증하며 설계합니다...

Claude: Design 완료!
  Domain Model:
  - 데이터 모델: CartData (API 참조), ProductData (API 참조) (Server-origin: 2개, Client-only: 1개)
  - Usecases: AddToCart, RemoveFromCart, UpdateQuantity

  Interface Contract:
  - Server-Client: 3개 hooks (query: 1, mutation: 2)
  - Client-Client: 2개 핵심 Props Interfaces

  Client Architecture:
  - Pages: CartPage
  - Components: 8개
  - Shared: Button, QuantitySelector

  Optimization: 3개 항목 적용 (캐시 전략, Optimistic update, 에러/로딩 상태)

  초안 반영:
  - 반영: CartContainer/CartList/CartItem 분리, useCartQuery 재사용, React Query + useState
  - 충돌: 없음
  - 열린 질문 → 제안: QuantitySelector는 다른 도메인에서도 재사용 가능하므로 공용 추천

  Linear Document: https://linear.app/daangn/document/fe-techspec-xxx (Design 섹션 추가됨)
```
