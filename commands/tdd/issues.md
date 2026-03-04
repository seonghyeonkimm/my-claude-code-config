---
name: tdd/issues
description: TechSpec과 Design 문서를 기반으로 Linear에 blocker/related issue를 분류하여 생성
allowed-tools:
  - Read
  - Write
  - Glob
  - ToolSearch
  - AskUserQuestion
  - Task
---

# TDD Issues Command

`/tdd:spec`과 `/tdd:design`의 결과물을 기반으로 Linear 프로젝트에 issue를 생성한다.

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 `/tdd:spec` 결과물 포함 (Functional Requirements 섹션)
- **필수**: Linear TechSpec 문서에 `/tdd:design` 결과물 포함 (Design, Component & Code, Verification 섹션)
- **필수 MCP**: Linear plugin 활성화

## Execution Flow

### Phase 1: 메타데이터 로드 및 Linear 문서 검증

1. `.claude/docs/` 하위에서 프로젝트 메타데이터 파일을 찾는다:
   ```
   Glob(pattern: ".claude/docs/*/meta.yaml")
   ```
2. 여러 프로젝트가 있으면 AskUserQuestion으로 선택 요청
3. meta.yaml에서 `document.id`, `project.id` 등 메타데이터를 읽는다
4. Linear에서 TechSpec 문서 내용을 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__get_document")
   → mcp__plugin_linear_linear__get_document(id: "{document.id}")
   ```
5. Linear 문서에서 **필수 섹션 존재 여부를 검증**한다:

**검증 체크리스트:**

| 섹션 | 출처 | 필수 여부 |
|------|------|----------|
| `## Functional Requirements` | `/tdd:spec` | 필수 |
| `## Design` | `/tdd:design` | 필수 |
| `### 1. 데이터 모델` | `/tdd:design` | 필수 |
| `### 2. Usecase` | `/tdd:design` | 필수 |
| `## Component & Code - Client` | `/tdd:design` | 필수 |
| `## Verification` | `/tdd:design` | 필수 |

**검증 실패 시:**
- `## Functional Requirements` 없음 → `/tdd:spec`을 먼저 실행하라고 안내
- `## Design` 없음 → `/tdd:design`을 먼저 실행하라고 안내

6. 검증 통과 시 Linear 문서에서 다음 정보를 추출한다:
   - Functional Requirements: Given/When/Then 테스트 케이스
   - Design: domain model, usecases, component tree

### Phase 2: Issue 분류 (tdd-issue-planner agent 위임)

TechSpec 문서를 분석하여 Blocker/Related 분류, 패키지 매핑, issue description 생성을 `tdd-issue-planner` agent에 위임한다.

```
Task(
  subagent_type: "tdd-issue-planner",
  prompt: """
  다음 TechSpec 문서를 분석하여 Blocker/Related issue를 분류하고 description을 생성해주세요.

  ## TechSpec 전체 내용
  {Linear 문서에서 조회한 전체 내용}

  ## Project Info
  - project_id: {project.id from meta.yaml}
  - team: {team from meta.yaml}
  """
)
```

**agent 반환 결과**: Blocker/Related issue 목록 (title, description, priority, package 매핑, TC 커버리지)

### Phase 3: 사용자 확인

분류 결과를 AskUserQuestion으로 제시하여 확인받는다:

```
question: "다음 issue 구조로 생성합니다. 수정할 항목이 있나요?"

Blocker Issues:
1. [Blocker] {issue title} - {description}
2. [Blocker] {issue title} - {description}

Related Issues:
3. [Related] {issue title} - {description}
4. [Related] {issue title} - {description}
```

사용자가 수정을 요청하면 반영 후 다시 확인.

### Phase 3.5: Label 확인/생성

Issue 생성 전에 "tdd" label을 확인한다:

```
ToolSearch(query: "select:mcp__plugin_linear_linear__list_issue_labels")
list_issue_labels(team: "{team}", name: "tdd")
```

**조회 결과:**
- `"tdd"` label 있음 → Phase 4로 진행
- `"tdd"` label 없음 → 사용자에게 안내:
  ```
  ⚠️ "tdd" label이 Linear에 없습니다.
  Linear에서 다음 단계를 수행하세요:
  1. Project Settings → Labels
  2. "tdd" label 생성 (또는 생성 확인)
  3. 다시 /tdd:issues 실행
  ```

### Phase 4: Linear Issue 생성

> **CRITICAL: 모든 issue 생성 시 반드시 `labels: ["tdd"]`를 포함해야 합니다.**
> - 이 label이 없으면 `/tdd:implement`에서 issue를 찾을 수 없습니다
> - label 누락 시 전체 TDD 워크플로우가 실패합니다
> - 절대 생략하지 마세요!

MCP 도구를 로드하고 Phase 2 agent 결과물의 issue 목록을 순서대로 생성한다.

```
ToolSearch(query: "select:mcp__plugin_linear_linear__create_issue")
ToolSearch(query: "select:mcp__plugin_linear_linear__list_issue_labels")
```

**생성 순서:**

1. **Blocker issue 먼저 생성**
2. **Related issue 생성**

**생성 파라미터**: agent가 반환한 각 issue의 title, description, priority를 그대로 사용하되, 반드시 `labels: ["tdd"]`와 `project: "{project id}"` 포함.

### Phase 4.5: Label 검증 (필수)

Issue 생성 완료 후, 모든 issue에 "tdd" label이 붙었는지 검증한다:

```
ToolSearch(query: "select:mcp__plugin_linear_linear__list_issues")
list_issues(project: "{project-id}", labels: ["tdd"])
```

**검증:**
- 생성한 issue 수 == 조회된 issue 수 → Phase 5로 진행
- 불일치 시 → 누락된 issue 식별 후 label 추가:
  ```
  ToolSearch(query: "select:mcp__plugin_linear_linear__update_issue")
  update_issue(id: "{issue-id}", labels: ["tdd"])
  ```

### Phase 4.7: TC → Issue 커버리지 검증

Phase 2 agent 결과의 `tc_coverage` 요약을 확인한다. 미할당 TC가 있으면 관련 이슈에 추가하거나 새 이슈를 생성한다.

### Phase 5: 결과 보고

```
Issue 생성 완료!

Project: {Project Name}
Linear: {project url}
Label: tdd

Blocker Issues ({N}개):
- {issue title} ({linear url})

Related Issues ({N}개):
- {issue title} ({linear url})

Total: {total}개 issues

---

📋 TDD 안내:
- 각 issue에는 Red-Green-Refactor 워크플로우가 포함되어 있습니다
- 테스트 먼저 작성 → 최소 구현 → 리팩토링 순서로 진행하세요

조회: list_issues(project: "{project-id}", labels: ["tdd"])

다음 단계:
- /tdd:implement: 병렬 워크스페이스로 자동 구현 시작
- 또는 Linear에서 담당자 배정 후 수동 TDD 진행
```

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear 문서 조회 실패 | 사용자에게 Linear URL 안내, 수동 확인 요청 |
| `## Functional Requirements` 섹션 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| `## Design` 섹션 없음 | `/tdd:design`을 먼저 실행하라고 안내 |
| Linear team 식별 불가 | AskUserQuestion으로 팀 선택 요청 |
| Issue 생성 중 실패 | 성공한 issue 목록을 보고하고, 실패 건 재시도 안내 |
| Label 'tdd'가 없음 | label 생성 안내 |
| Issue 생성 시 label 누락 | `update_issue`로 "tdd" label 즉시 추가 |
| Phase 4.5 검증 실패 | 누락된 issue에 label 추가 후 재검증 |

## Example

```
사용자: /tdd:issues

Claude: .claude/docs/my-feature/ 에서 메타데이터를 로드합니다...
  → meta.yaml 로드 (document.id: abc123)

Claude: Linear에서 TechSpec 문서를 조회합니다...
  → Functional Requirements (12개 테스트 케이스)
  → Design (데이터 참조: Cart API, Product API / usecases: 4개 / components: 8개)

Claude: [AskUserQuestion] 다음 issue 구조로 생성합니다:

  Blocker Issues:
  1. [Blocker] Cart Interface 및 상수 정의
  2. [Blocker] Cart API 인터페이스 설계
  3. [Blocker] 공통 컴포넌트 (QuantitySelector, Button)

  Related Issues:
  4. [Related] CartPage 구현 (AddToCart, RemoveFromCart Usecase 포함)
  5. [Related] CartItem 컴포넌트 구현

  작업 대상: `@daangn/cart-ui` (`packages/cart-ui`)
  작업 디렉토리: `packages/cart-ui/src/modules/cart/`
  참조 패턴: `packages/cart-ui/src/modules/product/`

사용자: 좋습니다

Claude: Linear에 issue를 생성합니다...

Claude: Issue 생성 완료!

  Blocker Issues (3개):
  - [Blocker] Cart Interface 및 상수 정의 (https://linear.com/issue/PROJ-1)
  - [Blocker] Cart API 인터페이스 설계 (https://linear.com/issue/PROJ-2)
  - [Blocker] 공통 컴포넌트 (QuantitySelector, Button) (https://linear.com/issue/PROJ-3)

  Related Issues (2개):
  - [Related] CartPage 구현 (https://linear.com/issue/PROJ-4)
  - [Related] CartItem 컴포넌트 구현 (https://linear.com/issue/PROJ-5)

  Total: 5개 issues

  조회 방법: Linear에서 직접 확인하세요.
  다음 단계: /tdd:implement으로 병렬 워크스페이스 생성
```
