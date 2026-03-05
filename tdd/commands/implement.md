---
description: spec/design/issues 기반으로 단일 Task에 Red→Green→Refactor 전체 워크플로우를 포함하여 생성. Workspace가 자체적으로 phase를 순차 실행하며, 각 phase 사이에 인간 리뷰를 거침
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
  - ToolSearch
  - AskUserQuestion
  - Skill
---

# TDD Implement Command

`/tdd:spec`, `/tdd:design`, `/tdd:issues`의 결과물을 기반으로 구현을 시작한다.

**핵심 원칙: 단일 Task 생성 후 Workspace가 자율 실행, Phase 사이 Human Review**

각 issue당 하나의 vk task를 생성한다. Task description에 Red→Green→Refactor 전체 워크플로우와 Review Gate를 포함한다. Workspace agent가 이를 순차적으로 실행하며, 각 phase 완료 시 AskUserQuestion으로 인간 리뷰를 받는다.

```
Workspace 내부 흐름:
Red      → 테스트 작성 & commit                        → 🔍 Review Gate 1: 인간 리뷰
Green    → 구현 코드 commit                           → 🔍 Review Gate 2: 인간 리뷰
Visual   → Figma 비교 & Storybook/Preview (Figma URL 있을 시) → 🔍 Review Gate 2.5: 인간 리뷰
Refactor → 리팩토링 commit & push → Draft PR 생성 → Linear 동기화
Browser  → ralph-loop 브라우저 검증 (frontend 변경 시)    → 🔍 Review Gate 3: 최종 리뷰
최종 승인 → Draft PR → Ready for Review (open)
```

implement command는 task를 생성하고 session을 시작하는 역할만 한다.
재실행 시에는 vk issue 상태를 확인하여 다음 batch 진행 여부를 결정한다.

## Usage

```
/tdd:implement [--base <branch>]
```

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--base <branch>` | PR의 target branch를 직접 지정. implement.yaml 설정을 override함 | `--base feature/new-cart` |

### Examples

```bash
# 기본 실행 (첫 실행이면 Batch 1 task 생성, 재실행이면 상태 확인)
/tdd:implement

# base branch 직접 지정
/tdd:implement --base feature/checkout
```

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 `/tdd:design` 결과물 포함 (Design 섹션)
- **필수**: meta.yaml의 project.id로 Linear에서 "tdd" label issue 조회 가능 (`/tdd:issues`)
- **필수 MCP**: vibe_kanban, Linear plugin

## Execution Flow

### Phase 1: 메타데이터 로드 및 상태 확인

1. **파라미터 파싱**: `--base <branch>` 파라미터 저장

2. `.claude/docs/{project-name}/implement.yaml` 존재 여부 확인:
   - 파일이 없으면 → 첫 실행: Phase 2로 진행
   - 파일이 있으면 → **vk issue 상태 조회**:

   ```
   현재 batch의 모든 task_id에 대해:
     ToolSearch(query: "select:mcp__vibe_kanban__get_issue")
     get_issue(issue_id: "{task_id}")
     → status 확인

   모든 task completed →
     다음 batch 있으면 batch+1로 진행
     없으면 → qa_verified 필드 확인:
       - qa_verified: true → "done" (모든 구현 및 QA 완료)
       - qa_verified 없음 또는 false → Phase 6.5 (QA) 진행
   일부 task 미완료 → 진행 상황 보고:
     - 각 task의 현재 상태 표시
     - "진행 중인 워크스페이스를 완료시켜주세요" 안내
   ```

   - `--base` 파라미터가 있으면 implement.yaml의 base_branch override

3. `.claude/docs/{project-name}/meta.yaml`에서 project.id를 추출한다

4. Linear에서 issue를 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__list_issues")
   list_issues(project: "{project-id}", labels: ["tdd"])
   ```
   - 응답에서 각 issue의 `id` (Linear API용)와 `url`을 추출하여 저장

5. 조회된 issue 목록을 Blocker/Related로 분류한다

6. 병렬 실행 가능한 issue 배치를 결정한다:

**병렬화 규칙:**
- **Batch 1**: Blocker issues (서로 의존성 없는 Blocker끼리는 병렬 가능)
- **Batch 2**: Related issues (Blocker 완료 후 병렬 실행)

```
Batch 1 (병렬): [Blocker A] [Blocker B] [Blocker C]
  ↓ 완료 대기
Batch 2 (병렬): [Related D] [Related E] [Related F]
```

7. AskUserQuestion으로 실행할 배치를 확인:
   ```
   question: "다음을 실행합니다. 진행할까요?"

   Batch 1 (Red→Green→Refactor, 각 phase 후 리뷰)
   - {issue title} → workspace session
   - {issue title} → workspace session
   ```

### Phase 2: Vibe Kanban 프로젝트, Base Branch, 참여 Repo 설정

> 재실행(implement.yaml 존재) 시 이 Phase는 저장된 값을 사용하여 건너뜀

1. vibe kanban 프로젝트를 확인한다:
   ```
   ToolSearch(query: "select:mcp__vibe_kanban__list_projects")
   ```

2. 프로젝트가 없거나 매칭되지 않으면 AskUserQuestion으로 선택 요청

3. **Base Branch 지정** (우선순위: 파라미터 > implement.yaml > 대화형 입력):

   **3-1. 파라미터 확인 (최우선)**
   - `--base <branch>` 파라미터가 제공되었으면 → 해당 branch 사용

   **3-2. implement.yaml 존재 여부 확인**
   - 파일이 있으면 → `vibe_kanban.base_branch` 읽음 (재실행)

   **3-3. 첫 실행 시 사용자에게 base branch 물어보기**:
   ```
   question: "이 implementation의 base branch를 지정하세요."

   현재 git branch: feature/new-cart
   기본값: feature/new-cart
   또는 다른 branch: [main / develop / feature/new-api / ...]
   ```

4. **참여할 repo 선택**:
   ```
   ToolSearch(query: "select:mcp__vibe_kanban__list_repos")
   → list_repos(project_id: "{project_id}")
   ```

   AskUserQuestion으로 참여 repo 선택:
   ```
   question: "이 feature에 참여할 repo를 선택하세요. (복수 선택 가능)"

   [ ] Frontend (repo-1-id)
   [ ] Backend API (repo-2-id)
   ```

### Phase 3: Issue별 Repo & Package 매핑

Linear issue description의 "작업 대상" 섹션에서 패키지 정보를 추출한다:

1. **Repo 매핑**: Issue 설명의 패키지 경로로 repo 식별
2. **Package 정보 추출**: Linear issue의 "작업 대상" 섹션에서 `package_name`, `package_path`, `target_directory`, `reference_pattern` 추출
3. 정보가 없으면 TechSpec Design 섹션의 "Component & Code" 파일 구조에서 직접 추출
4. 명확하지 않으면 AskUserQuestion으로 확인

### Phase 3.5: 현재 Batch의 Base Branch 결정

현재 batch에 따라 workspace session과 PR의 base branch를 결정한다:

**Batch 1 (첫 배치)**:
- `base_branch` = implement.yaml의 `vibe_kanban.base_branch` (프로젝트 base branch)

**Batch 2+ (이전 배치 존재)**:
1. 이전 batch의 task_id들로 vk issue를 조회하여 관련 PR 정보 파악
2. 또는 `gh pr list` 등으로 GitHub에서 직접 branch 정보 조회
3. 이전 batch에 issue가 **1개**면: 해당 issue의 branch를 base로 사용
4. 이전 batch에 issue가 **여러 개**면: 프로젝트 base branch를 사용 (이전 batch PR들이 이미 merge되었어야 함)
5. ⚠️ 판단이 어려우면: AskUserQuestion으로 사용자에게 base branch 확인

결정된 base branch를 이후 모든 workspace session과 task description에 사용.

### Phase 4: Task 생성 및 Session 시작

현재 batch의 각 issue에 대해 vk task를 생성하고 workspace session을 시작한다.

**핵심: task를 한번 생성하면 update하지 않는다. Workspace agent가 Red→Green→Refactor를 자체 처리.**

각 issue에 대해:

1. **Task 생성** (배치당 1회):
   ```
   mcp__vibe_kanban__create_issue(
     project_id: "{project_id}",
     title: "{issue title}",
     description: "{아래 통합 Task Description}"
   )
   ```
   → `task_id`를 implement.yaml에 저장

2. **Workspace Session 시작**:
   ```
   mcp__vibe_kanban__start_workspace_session(
     task_id: "{task_id}",
     executor: "CLAUDE_CODE",
     repos: [{ repo_id: "{task의-repo-id}", base_branch: "origin/{base_branch}" }]
   )
   ```

---

## 통합 Task Description 템플릿

하나의 task에 Red→Green→Visual→Refactor 전체 워크플로우를 포함한다. Workspace agent는 전문 agent에 위임하여 각 phase를 실행하고, Review Gate에서 AskUserQuestion으로 인간 리뷰를 받는다.

````
🚫 **금지 사항 — 아래 규칙을 반드시 준수하세요:**
- **작업 시작 전** 반드시 `git fetch origin {base_branch} && git merge origin/{base_branch}`를 실행하세요. local branch가 remote보다 뒤쳐져 있으면 이전 batch 작업물이 누락됩니다.
- PR 생성 시 `--base` 플래그를 반드시 아래 Context의 **Base Branch** 값으로 지정하세요. `main`을 base로 사용하지 마세요.
- 아래 Step 1부터 순서대로 실행하세요. 각 Step 완료 후 Review Gate에서 반드시 멈추고 인간의 리뷰를 받으세요.

## Context

- Linear Issue: {linear_issue_url}
- TechSpec Document: {meta.yaml의 document.url}
- **Base Branch**: `{base_branch}`
- **작업 대상 패키지**: `{package_name}` (`{package_path}`)
- **작업 디렉토리**: `{package_path}/{target_directory}`
- **기존 패턴 참조**: `{package_path}/{reference_pattern}` (같은 패키지 내 유사 모듈)
- **Linear Issue ID**: `{issue_id}` (Refactor 완료 시 Linear 동기화용)
- **Figma URL**: `{figma_url_or_null}` (TechSpec Summary에서 추출, Visual Verification용)

## 관련 테스트 케이스

{Linear TechSpec 문서에서 해당 issue의 Given/When/Then 테이블}

## 관련 설계

{Linear TechSpec 문서의 Design 섹션에서 해당 데이터 모델(Interface)/Usecase/Component 정보}

---

## Step 1: 🔴 RED — `tdd-red` agent에 위임

```
Task(subagent_type: "tdd-red", prompt: "
  ## Context
  - test_cases: {위 '관련 테스트 케이스' 전체}
  - target_files: {위 '관련 설계'에서 파일 경로}
  - branch_name: {issue title 기반 kebab-case}
  - base_branch: {base_branch}
  - existing_test_patterns: {package_path}/{reference_pattern} 참조
")
```

### 🔍 Review Gate 1

agent 완료 후, **반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

```
AskUserQuestion:
  question: "🔴 Red Phase 완료.

  브랜치: {branch_name}
  테스트 파일: {파일 경로 목록}
  실패하는 테스트: {N}개

  리뷰 포인트:
  - 테스트 이름이 구현이 아닌 행동을 설명하는가?
  - 엣지 케이스가 포함되어 있는가?
  - TechSpec TC와 일치하는가?

  선택: 진행 (Green으로) / 수정 요청 / 중단"
```

- **수정 요청** 시 → 피드백에 따라 테스트 수정 → 커밋 → 다시 Review Gate 1
- **진행** 시 → Step 2로
- **중단** 시 → 작업 중지

---

## Step 2: 🟢 GREEN — `tdd-green` agent에 위임

```
Task(subagent_type: "tdd-green", prompt: "
  ## Context
  - test_files: {Step 1에서 생성된 테스트 파일 경로}
  - failing_tests: {실패한 테스트 목록}
  - target_files: {관련 설계에서 파일 경로}
")
```

### 🔍 Review Gate 2

agent 완료 후, **반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

```
AskUserQuestion:
  question: "🟢 Green Phase 완료.

  변경 파일:
  - {file} - {변경 요약}

  테스트: {통과}/{전체} (신규 {N}개, 기존 {N}개)

  다음 단계: {Figma URL이 있으면 → Visual Verification / 없으면 → Refactor}

  선택: 진행 / 수정 요청 / Refactor 건너뛰기 / 중단"
```

- **수정 요청** 시 → 피드백에 따라 구현 수정 → 테스트 재실행 → 커밋 → 다시 Review Gate 2
- **진행** 시 → Figma URL이 있으면 Step 2.5로, 없으면 Step 3로
- **Refactor 건너뛰기** 시 → Draft PR 생성 + Linear 동기화 (상태 "In Review" + PR 코멘트) + `gh pr ready` 실행
- **중단** 시 → 작업 중지

---

## Step 2.5: 🎨 VISUAL — `tdd-visual` agent에 위임

> **Figma URL이 있으면 반드시 실행한다.** Figma URL이 없는 경우에만 Step 3으로 건너뜀.
> 에러 발생 시 자동 건너뛰기 금지 — 반드시 AskUserQuestion으로 사용자에게 선택을 요청한다.

```
Task(subagent_type: "tdd-visual", prompt: "
  ## Context
  - figma_url: {Context의 Figma URL}
  - components: {관련 설계의 [Presentational] 컴포넌트 목록}
  - visual_contract: {관련 설계의 Visual Contract 정보}
  - test_mock_data: {Step 1 테스트의 mock data}
")
```

### 🔍 Review Gate 2.5

agent 완료 후, **반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

```
AskUserQuestion:
  question: "🎨 Visual Verification 완료.

  비교 결과:
  - {component}: Figma 매칭 상태

  ralph-loop: {N}회 반복

  선택: 진행 (Refactor로) / 수정 요청 / 중단"
```

- **수정 요청** 시 → 추가 수정 → 커밋 → 다시 Review Gate 2.5
- **진행** 시 → Step 3로
- **중단** 시 → 작업 중지

---

## Step 3: 🔵 REFACTOR — `tdd-refactor` agent에 위임

```
Task(subagent_type: "tdd-refactor", prompt: "
  ## Context
  - source_files: {Step 2에서 변경된 소스 파일}
  - test_files: {Step 1에서 생성된 테스트 파일}
  - branch_name: {현재 브랜치}
  - task_summary: {issue title}
  - base_branch: {base_branch}
  - test_cases_summary: {관련 테스트 케이스 요약}
  - linear_issue_id: {issue_id}
")
```

---

## Step 3.5: 🌐 BROWSER VERIFICATION — ralph-loop으로 반복 확인

> **frontend 파일(.tsx, .jsx, .css, .scss 등)이 변경된 경우 반드시 실행한다.**
> backend만 변경된 경우 Review Gate 3으로 건너뜀.

1. **frontend 변경 여부 확인**:
   - Step 2-3에서 변경된 파일 중 `.tsx`, `.jsx`, `.css`, `.scss`, `.less`, `.sass`, `.svelte`, `.vue` 확장자 확인
   - 없으면 Review Gate 3으로 건너뜀

2. **검증 체크리스트 작성**:
   관련 TC와 변경 파일을 기반으로 체크리스트 도출 (최소 3항목):
   - 페이지 렌더링: 변경된 페이지가 에러 없이 렌더링되는가?
   - 시각적 확인: 레이아웃, 색상, 타이포그래피가 정상인가?
   - 인터랙션: 주요 사용자 흐름(클릭, 입력, 네비게이션)이 동작하는가?
   - 엣지 케이스: 빈 상태, 에러 상태, 로딩 상태가 정상 표시되는가?
   - TC에서 UI 관련 항목을 추출하여 체크리스트에 추가

3. **playwright-cli 브라우저 열기**:
   - dev server URL을 모르면 먼저 AskUserQuestion으로 질문
   ```bash
   playwright-cli open {dev_url}
   ```

4. **ralph-loop 시작**:
   ```
   Skill(skill: "ralph-loop:ralph-loop", args: "--max-iterations 5 --completion-promise BROWSER_VERIFIED")
   ```

   각 iteration에서:
   a. `playwright-cli goto {page_url}` → `playwright-cli screenshot --filename=.claude/screenshots/browser-verify-{iteration}.png`
   b. 체크리스트 항목 검증 (snapshot, click, fill, console 확인)
   c. 전체 통과 시 `<promise>BROWSER_VERIFIED</promise>`, 미통과 시 수정 후 다음 iteration

   **모든 체크리스트 항목을 한 번 이상 확인하기 전에는 promise를 출력하지 않는다.**

5. **결과를 Review Gate 3에 포함**

---

### 🔍 Review Gate 3

agent 완료 후, **반드시 여기서 멈추고 AskUserQuestion으로 인간에게 최종 리뷰를 요청하세요.**

```
AskUserQuestion:
  question: "🔵 Refactor Phase 완료. Draft PR을 생성했습니다.

  PR: {pr_url}
  tsc: ✅ 통과
  biome: ✅ 통과
  테스트: {통과}/{전체}
  Browser Verification: ralph-loop {N}회 / 체크리스트 {통과}/{전체} / {확인 URL}
  (또는: 건너뜀 — frontend 변경 없음)

  선택: 승인 (PR을 Ready for Review로 전환) / 수정 요청"
```

- **수정 요청** 시 → 피드백에 따라 수정 → 체크 재실행 → 커밋 & 푸시 → 다시 Review Gate 3
- **승인** 시 → `gh pr ready {pr_number}` 실행 → 작업 완료
````

---

### Phase 5: 실행 상태 저장

`.claude/docs/{project-name}/implement.yaml`에 실행 상태를 저장한다:

```yaml
# .claude/docs/{project-name}/implement.yaml
executor: "vibe_kanban"
project:
  id: "{project-id}"
  name: "{project-name}"
document:
  url: "{linear-document-url}"  # meta.yaml에서 참조
vibe_kanban:
  project_id: "{vibe-project-id}"
  base_branch: "{selected_base_branch}"  # Phase 2에서 선택한 base branch
  repos:
    - id: "{frontend-repo-id}"
      name: "frontend"
    - id: "{backend-repo-id}"
      name: "backend"
current_step:
  batch: 1                       # 현재 batch 번호만 추적
batches:
  - batch: 1
    type: blocker
    issues:
      - issue_id: "{linear-issue-id}"
        issue_url: "{linear-issue-url}"
        repo_id: "{frontend-repo-id}"
        title: "{title}"
        package_name: "{package-name}"          # Phase 3에서 추출
        package_path: "{package-path}"          # Phase 3에서 추출
        target_directory: "{target-dir}"        # Phase 3에서 추출
        reference_pattern: "{ref-path}"         # Phase 3에서 추출
        task_id: "{vibe-task-id}"  # Task 생성 시 기록, 상태 조회에 사용
  - batch: 2
    type: related
    issues:
      - issue_id: "{linear-issue-id}"
        issue_url: "{linear-issue-url}"
        repo_id: "{backend-repo-id}"
        title: "{title}"
        package_name: "{package-name}"
        package_path: "{package-path}"
        target_directory: "{target-dir}"
        reference_pattern: "{ref-path}"
        task_id: null              # 다음 batch 실행 시 생성됨
qa_verified: false                   # Phase 6.5 QA 통과 후 true
qa_report:                           # Phase 6.5 완료 시 기록
  total: null
  passed: null
  failed: null
  follow_up_issues: []
  verified_at: null
created_at: "{ISO-8601}"
```

**상태 저장 시점:**

- **Task 생성 후**: `issues[].task_id` 기록, `current_step.batch` 업데이트
- **Batch 완료 확인 후** (재실행 시): `current_step.batch` → 다음 batch 번호로 업데이트

> Phase별 상태(Red/Green/Refactor)는 workspace가 내부적으로 관리하므로 implement.yaml에서 추적하지 않는다.
> Branch, PR 정보도 workspace가 관리하므로 저장하지 않는다.

### Phase 6: 결과 보고

#### Batch 시작 시

```
Batch 1 시작

Project: {Project Name}
TechSpec: {document URL}

워크스페이스 생성됨:
- [Frontend] Cart UI Component → task 생성 + session 시작
- [Backend] Cart Interface → task 생성 + session 시작

각 워크스페이스가 Red→Green→Refactor를 순차 처리합니다.
각 Phase 사이에 Review Gate에서 리뷰 요청이 옵니다.
```

#### 재실행 시 (상태 확인)

```
Batch 1 상태 확인

vk issue 상태:
- [Frontend] Cart UI Component → ✅ completed
- [Backend] Cart Interface → ⏳ in_progress

다음 단계:
- 진행 중인 워크스페이스의 Review Gate에 응답해주세요
- 모든 task 완료 후 /tdd:implement 로 Batch 2를 시작합니다
```

#### Batch 전환 시

```
Batch 1 모든 task 완료!

다음: Batch 2 (Related issues)
- [Frontend] Wishlist 저장 기능
- [Backend] Cart 미니 뷰

진행할까요?
```

#### 모든 Batch 완료 시 (QA 진입)

```
모든 batch 완료! QA Phase로 진입합니다.

QA를 진행하려면 모든 Draft PR을 base branch에 merge해주세요.
Base branch: {base_branch}
```

---

### Phase 6.5: QA (Integration Verification)

모든 batch가 완료된 후, TechSpec의 AC/TC를 평가기준으로 통합된 코드가 실제로 동작하는지 검증한다.

> **전제조건**: 사용자가 모든 Draft PR을 base branch에 merge한 상태에서 진행한다.
> Agent가 직접 브랜치를 merge하지 않는다.

#### Step 1: merge 상태 확인

사용자에게 merge 완료 여부를 확인한다:

```
AskUserQuestion:
  question: "모든 batch가 완료되었습니다. QA를 진행하려면 모든 Draft PR을 base branch에 merge해주세요.

  Base branch: {base_branch}

  merge 완료 후 '진행'을 선택해주세요.
  선택: 진행 / 중단"
```

진행 선택 시 `git fetch origin && git merge origin/{base_branch}`로 최신 코드 동기화.

#### Step 2: TechSpec 로드

```
ToolSearch(query: "select:mcp__plugin_linear_linear__get_document")
→ get_document(id: "{document.id from meta.yaml}")
```

#### Step 3: tdd-integrate agent 위임

```
Task(subagent_type: "tdd-integrate", prompt: "
  ## TechSpec
  {Linear 문서 전문}

  ## Base branch: {base_branch}
  ## Project ID: {project.id}
")
```

#### Step 4: Human Review Gate

agent 결과를 AskUserQuestion으로 사용자에게 보고한다:

```
AskUserQuestion:
  question: "🔍 QA 완료.

  {agent가 반환한 QA Report}

  선택:
  - 승인: 모든 평가기준 통과, 구현 완료
  - 바로 수정: 이 세션에서 바로 수정 후 QA 재진행
  - Follow-up issue 생성: 실패 항목을 Linear issue로 생성하여 추가 batch
  - 중단"
```

#### Step 5: Follow-up 처리

**승인 시:**

implement.yaml 업데이트:
```yaml
qa_verified: true
qa_report:
  total: {N}
  passed: {N}
  failed: 0
  verified_at: "{ISO-8601}"
```
→ "모든 QA 평가기준을 통과했습니다. 구현 완료!" 보고

**바로 수정 시:**

1. 실패 항목을 현재 세션에서 즉시 수정한다 (Red-Green-Refactor 없이 직접 수정)
2. 수정 완료 후 commit & push
3. **Step 3부터 다시 진행** (tdd-integrate agent 재위임 → QA 재실행)
4. 이 루프는 승인 또는 Follow-up issue 생성을 선택할 때까지 반복 가능

**Follow-up issue 생성 시:**

1. 각 실패 항목을 Linear issue로 생성:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__create_issue")
   → create_issue(
       title: "[QA] {평가기준에서 드러난 문제}",
       team: "{team}",
       labels: ["tdd"],
       project: "{project name or id}",
       description: "## QA에서 발견된 문제\n{상세}\n\n## 관련 평가기준\n{AC/TC 참조}"
     )
   ```

2. implement.yaml에 새 batch 추가:
   ```yaml
   - batch: {next_batch_number}
     type: qa-fix
     issues:
       - issue_id: "{new-linear-issue-id}"
         issue_url: "{url}"
         title: "[QA] {문제 설명}"
         package_name: "{package-name}"
         package_path: "{package-path}"
         target_directory: "{target-dir}"
         reference_pattern: "{ref-path}"
         task_id: null
   ```

3. `qa_verified` 필드는 false 유지
4. "QA fix batch가 생성되었습니다. `/tdd:implement`를 재실행하세요." 보고

**재실행 시 흐름:**
```
/tdd:implement → qa-fix batch의 task 생성 → Red-Green-Refactor
  → 완료 → 사용자가 PR merge → 다시 Phase 6.5 (QA) 진입
  → 통과 → 완료
```

---

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear issue 조회 실패 | `/tdd:issues`를 먼저 실행하라고 안내 |
| "tdd" label issue 없음 | `/tdd:issues`를 먼저 실행하라고 안내 |
| Vibe Kanban 프로젝트 없음 | AskUserQuestion으로 프로젝트 선택 또는 생성 안내 |
| Repo 정보 없음 | AskUserQuestion으로 repo 선택 요청 |
| Session 시작 실패 | 에러 로그 출력, 수동 재시도 안내 |
| vk issue 상태 조회 실패 | 에러 로그 + 수동 확인 안내 |
| 모든 구현 + QA 완료 (done) | "모든 배치 및 QA가 완료되었습니다" 안내 |
| Visual Verification 에러 | tdd-visual agent가 자체 처리 (AskUserQuestion으로 사용자 확인) |
| TechSpec AC/TC 없음 (QA) | `/tdd:spec`을 먼저 실행하라고 안내 + 사용자에게 직접 평가기준 입력 요청 |
| ralph-loop 실패 (QA) | 재시도/건너뛰기 선택 |
| QA 평가기준 전체 통과 | qa_verified: true 마킹, 완료 보고 |

## Example: 첫 실행

```
사용자: /tdd:implement

Claude: [AskUserQuestion] base branch를 지정하세요. (추천: feature/new-cart)
사용자: feature/new-cart

Claude: [AskUserQuestion] 참여 repo를 선택하세요.
사용자: Frontend, Backend API

Claude: [AskUserQuestion] Batch 1 실행:
  - [Backend] Cart Interface 및 상수 정의
  - [Frontend] Cart UI Component
사용자: 진행

Claude: task 생성 + session 시작 완료. 각 workspace가 Red→Green→Refactor를 순차 처리합니다.
```

## Example: 재실행

```
사용자: /tdd:implement

Claude: Batch 1 상태: 모든 task completed ✅
Claude: [AskUserQuestion] Batch 2 시작할까요?
  - [Frontend] Wishlist 저장 기능
  - [Backend] Cart 미니 뷰
사용자: 진행

Claude: task 생성 + session 시작 완료.
```

## Example: QA Phase

```
사용자: /tdd:implement

Claude: 모든 batch 완료! QA Phase로 진입합니다.
Claude: [AskUserQuestion] 모든 Draft PR을 base branch에 merge해주세요.
  Base branch: feature/new-cart
  선택: 진행 / 중단
사용자: 진행

Claude: TechSpec에서 QA 평가기준을 도출합니다...
Claude: [AskUserQuestion] QA 평가기준 확인:
  1. [ ] 상품 추가 후 미니카트 수량 반영
  2. [ ] 빈 장바구니에서 상품 추가 시 아이템 표시
  3. [ ] 수량 변경 시 총액 실시간 갱신
  선택: 진행 / 수정
사용자: 진행

Claude: ralph-loop으로 QA 검증 중... (3회 반복)
Claude: [AskUserQuestion] 🔍 QA 완료.
  평가기준: 3개 중 2개 통과, 1개 실패
  실패: 수량 변경 시 총액 갱신 — CalculateTotal usecase 미연결
  선택: 승인 / 바로 수정 / Follow-up issue 생성 / 중단
사용자: 바로 수정

Claude: CalculateTotal usecase를 CartContainer에 연결합니다...
  commit & push 완료. QA를 재실행합니다.
Claude: ralph-loop으로 QA 검증 중... (1회 반복)
Claude: [AskUserQuestion] 🔍 QA 완료.
  평가기준: 3개 중 3개 통과 ✅
  선택: 승인 / 바로 수정 / Follow-up issue 생성 / 중단
사용자: 승인

Claude: 모든 QA 평가기준을 통과했습니다. 구현 완료!
```
