---
name: tdd/start
description: 버그 수정이나 간단한 기능 추가를 위한 경량 TDD 워크플로우 (Red-Green-Refactor with human review)
arguments:
  - name: task
    description: 작업 설명 (텍스트, Linear 이슈 URL, 또는 GitHub 이슈 URL)
    required: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - ToolSearch
  - Skill
  - Task
---

# TDD Start Command

간단한 버그 수정이나 작은 기능 추가를 TDD로 진행한다. 분석→설계→Red→Green→Refactor 전체 사이클을 한 세션에서 처리하며, 각 phase마다 사용자 리뷰를 받는다. Refactor 완료 후 Draft PR을 생성한다.

heavyweight flow(`/tdd:spec` → `/tdd:design` → `/tdd:issues` → `/tdd:implement`)와 달리 Linear, Notion, Figma, Vibe Kanban 등 외부 서비스가 불필요하다.

## Usage

```
/tdd:start [task description or URL]
```

### Examples

```bash
# 텍스트로 작업 설명
/tdd:start 장바구니에 수량 음수가 입력되는 버그 수정

# GitHub 이슈 URL
/tdd:start https://github.com/org/repo/issues/42

# Linear 이슈 URL
/tdd:start https://linear.app/team/issue/TEAM-123

# 인자 없이 실행 (대화형으로 입력)
/tdd:start
```

## Prerequisites

- **필수**: 프로젝트에 테스트 프레임워크가 설정되어 있어야 함 (자동 감지)
- **필수 아님**: Linear, Notion, Figma, Vibe Kanban (외부 서비스 불필요)

## 세션 상태 관리

`.claude/docs/{project_name}/tdd-session.yaml`에 세션 상태를 저장한다. context가 압축되거나 세션이 길어져도 상태를 유지할 수 있다.

### 상태 파일 구조

```yaml
# .claude/docs/{project_name}/tdd-session.yaml
task: "버그 수정: 장바구니 수량 음수 허용됨"
branch: "fix/cart-negative-quantity"
pr:
  number: 42
  url: "https://github.com/org/repo/pull/42"
phase: "plan"  # plan | red | green | visual | refactor | done
design:
  human_draft: |
    ### 핵심 결정
    - src/domain/cart.ts의 addItem()에 validation 추가
    ### 열린 질문
    - 에러 타입을 ValidationError로 할지 RangeError로 할지?
  test_cases:
    - "Given 수량 -1 / When 장바구니 추가 / Then 에러"
  approach:
    - file: "src/domain/cart.ts"
      change: "addItem()에 수량 validation 추가"
test_files:
  - src/domain/cart.test.ts
source_files:
  - src/domain/cart.ts
commits:
  red: null
  green: null
  visual: null
  refactor: null
visual_verification:
  enabled: false
  figma_url: null
  story_files: []
  iterations: 0
  status: null  # skipped | completed | partial
created_at: "2026-02-11T10:00:00Z"
updated_at: "2026-02-11T10:00:00Z"
```

### 상태 파일 규칙

- **Phase 전환 시마다 업데이트**: phase 필드, 파일 목록, 커밋 해시 등
- **커맨드 시작 시 존재 확인**: 있으면 이전 세션 이어서 진행
- **Phase 10 완료 후 삭제**: 워크플로우 정상 종료 시 정리
- **context 압축 후 복구**: 파일을 Read하여 현재 상태 복원

### project_name 결정

- 태스크 설명에서 핵심 키워드를 추출하여 kebab-case로 변환
- 예: "장바구니 수량 음수 버그" → `cart-negative-quantity`
- 기존 `.claude/docs/` 하위 디렉토리가 있으면 재사용 가능

## Execution Flow

### Phase 0: 세션 복구 확인

1. `Glob(".claude/docs/*/tdd-session.yaml")`로 기존 세션 파일 탐색

2. **파일이 존재하면** → Read하여 상태 로드 후 AskUserQuestion:
   ```
   question: "이전 TDD 세션이 발견되었습니다.

   작업: {task}
   브랜치: {branch}
   PR: {pr_url 또는 '아직 생성되지 않음'}
   현재 단계: {phase}
   상태 파일: .claude/docs/{project_name}/tdd-session.yaml

   선택:
   - 이어서 진행: 현재 단계부터 계속합니다
   - 처음부터 다시: 상태 파일을 삭제하고 새로 시작합니다
   - 취소: 아무것도 하지 않습니다"
   ```

3. **파일이 없으면** → Phase 1로 진행

### Phase 1: 입력 수집 및 컨텍스트 파악

1. **입력 파싱**: `$ARGUMENTS.task` 분석

   | 입력 타입 | 감지 방법 | 처리 |
   |-----------|-----------|------|
   | 없음 | `$ARGUMENTS.task` 비어있음 | AskUserQuestion: "어떤 작업을 TDD로 진행할까요?" |
   | 일반 텍스트 | URL 패턴 아님 | 그대로 작업 설명으로 사용 |
   | Linear URL | `linear.app` 포함 | ToolSearch로 Linear MCP fetch (best-effort) |
   | GitHub URL | `github.com/.*/issues/` 패턴 | `gh issue view {url} --json title,body` |

   - Linear/GitHub URL fetch 실패 시 → AskUserQuestion으로 텍스트 입력 요청

2. **프로젝트 컨텍스트 수집**:

   **테스트 프레임워크 감지:**
   ```
   Glob("vitest.config.*") → vitest
   Glob("jest.config.*") 또는 package.json의 jest 섹션 → jest
   Glob("pytest.ini") 또는 Glob("pyproject.toml") → pytest
   Glob("go.mod") → go test
   ```
   - 감지 실패 시 AskUserQuestion으로 질문

   **기존 테스트 패턴 파악:**
   - Grep로 `describe(`, `it(`, `test(` 등 검색하여 테스트 파일 위치, 네이밍 컨벤션 파악
   - 대표 테스트 파일 1-2개 Read하여 import 패턴, 구조 확인

   **린터/타입체커 감지:**
   ```
   Glob("biome.json") → biome
   Glob(".eslintrc.*") 또는 Glob("eslint.config.*") → eslint
   Glob("tsconfig.json") → tsc
   ```

   **Figma URL 확인:**
   - 작업 설명에 Figma URL (`figma.com` 포함)이 포함되어 있으면 추출하여 저장
   - 없으면 AskUserQuestion: "Figma 디자인 URL을 입력하세요. (Visual Verification에 사용됩니다. UI 작업이 아닌 경우 '없음'이라고 답해주세요)"
   - '없음' 응답 시 `null`로 저장 (Visual Verification 비활성화)

3. **스코프 판단**: 10개 이상의 테스트 케이스가 필요하거나 다수 모듈에 걸치는 작업이면 AskUserQuestion으로 heavyweight flow 추천

4. **세션 상태 파일 초기 생성**:
   - project_name 결정 (태스크에서 키워드 추출, kebab-case)
   - `.claude/docs/{project_name}/` 디렉토리가 없으면 생성
   - `.claude/docs/{project_name}/tdd-session.yaml` 작성 (phase: "plan")

### Phase 2: 분석 & 설계

`/tdd:spec`의 테스트 케이스 설계 + `/tdd:design`의 구현 방향을 경량화하여 하나의 phase로 합침.

1. **문제 분석**:
   - 버그인 경우: 원인 파악, 재현 조건 정리
   - 기능 추가인 경우: 요구사항 정리, 기존 코드와의 관계 파악
   - 영향 범위 파악 (어떤 파일/모듈에 영향)
   - 관련 코드 읽기 (Grep/Read로 현재 구현 확인)

2. **설계 초안 수집 (필수)**:

   문제 분석 결과를 공유한 뒤 인간의 설계 초안을 요청한다. 초안이 제공될 때까지 TC 설계로 진행하지 않는다.

   ```
   AskUserQuestion:
     question: "문제를 분석했습니다.

     ## 문제 분석
     {문제 요약}

     구현 방향에 대한 설계 초안을 공유해주세요.
     (컴포넌트 구조, 데이터 흐름, 기술 선택 등)

     예시:
     ### 핵심 결정
     - 컴포넌트: ...
     - 데이터: ...
     ### 열린 질문
     - ...?

     자유 형식도 괜찮습니다.

     설계 시 고려하면 좋은 포인트:
     - 모듈 경계: 이 구조에서 한 모듈을 수정할 때 다른 파일까지 함께 고쳐야 하진 않는가?
     - 추상화 깊이: 모듈이 내부 복잡성을 충분히 숨기는가, 아니면 인터페이스만 복잡한 얕은 모듈인가?
     - 인지 부하: 이 설계를 이해하려면 한 번에 기억해야 할 개념이 몇 개인가? 몰라도 되는 옵션은 기본값으로 숨겼는가?
     - 데이터 흐름: 상태가 어디서 생성되고, 어떻게 흘러가며, 누가 변경하는가?
     - 에러 복구: 에러 발생 시 사용자에게 어떤 피드백을 주고, 상태를 어떻게 안전하게 되돌리는가?
     - 도메인 순수성: 도메인 로직이 UI/API/외부 의존성 없이 순수 함수로 분리되는가?
     - 테스트 경계: 테스트가 구현 세부사항이 아닌, 클라이언트에 노출된 공개 인터페이스를 검증하는 구조인가?
     - 도메인 언어: 코드의 변수명/함수명이 팀의 비즈니스 용어와 일치하는가?
     - YAGNI: 이 구조에 현재 요구사항이 필요로 하지 않는 확장 포인트나 레이어가 있진 않은가?"
   ```

3. **테스트 케이스 설계** (← `/tdd:spec`의 경량 버전):
   - Given/When/Then 형식으로 테스트 케이스 목록 작성
   - 정상 → 에러 → 엣지 케이스 순서로 나열
   - **초안의 핵심 결정을 TC 설계에 반영**

4. **구현 접근 방식** (← `/tdd:design`의 경량 버전):
   - 어떤 파일을 수정/생성할지
   - 어떤 함수/컴포넌트를 변경할지
   - 주의할 점 (부작용, 호환성 등)
   - **초안의 기술 결정을 구현 접근에 반영**
   - **초안과 TC 분석이 충돌하면 충돌 사항을 기록**

5. **세션 상태 업데이트**: design 섹션에 테스트 케이스 & 구현 접근 & 초안 반영 기록

6. **AskUserQuestion으로 설계 리뷰 요청**:
   ```
   question: "분석 & 설계가 완료되었습니다.

   ## 초안 반영
   - 반영: {반영된 결정}
   - 충돌: {충돌 사항 + 권장안} (없으면 생략)

   ## 열린 질문 → 제안
   - Q: {인간의 질문} → A: {제안 + 근거} (없으면 생략)

   ## 테스트 케이스
   1. Given {조건} / When {행동} / Then {결과}
   2. Given {조건} / When {행동} / Then {결과}

   ## 구현 접근
   - {file}: {변경 내용}
   - {file}: {변경 내용}

   선택: 진행 / 수정 요청 / 중단"
   ```

   수정 요청 시 → 설계 수정 후 상태 파일 업데이트 → 다시 리뷰 요청 (루프)

### Phase 3: Red - 실패하는 테스트 작성

0. **작업 디렉토리 확인**: `git status`로 미커밋 변경사항 확인
   - 변경사항이 있으면 AskUserQuestion: "커밋되지 않은 변경이 있습니다. stash / commit / 중단 중 선택하세요"
   - stash 선택 시 `git stash push -m "tdd-start: before {task}"`

1. **`tdd-red` agent에 위임**:

   ```
   Task(subagent_type: "tdd-red", prompt: "
     ## Context
     - test_cases: {Phase 2에서 설계한 Given/When/Then TC 목록}
     - target_files: {Phase 2에서 식별한 대상 소스 파일 경로}
     - branch_name: {branch 이름} (규칙: 버그 fix/{keywords}, 기능 feat/{keywords})
     - test_framework: {Phase 1에서 감지한 프레임워크}
     - existing_test_patterns: {Phase 1에서 파악한 기존 테스트 패턴 요약}
   ")
   ```

2. agent 결과에서 test_files, branch, commit, failing_tests 수집

3. **세션 상태 업데이트**: phase → "red", branch, test_files, commits.red 기록

### Phase 4: (Human) Red 리뷰

```
AskUserQuestion:
  question: "Red Phase 완료.

  브랜치: {branch-name}
  테스트 파일: {path}
  테스트 케이스:
  1. {test name} - {description}
  2. {test name} - {description}

  리뷰 포인트:
  - 테스트 이름이 구현이 아닌 행동을 설명하는가?
  - 엣지 케이스가 포함되어 있는가?
  - Phase 2 설계의 TC와 일치하는가?

  선택: 진행 / 수정 요청 / 중단"
```

수정 요청 시 → 테스트 수정 → 재실행(실패 확인) → commit → 다시 리뷰 요청 (루프)

### Phase 5: Green - 최소 구현

1. **`tdd-green` agent에 위임**:

   ```
   Task(subagent_type: "tdd-green", prompt: "
     ## Context
     - test_files: {Phase 3에서 생성된 테스트 파일 경로}
     - failing_tests: {실패한 테스트 목록}
     - target_files: {Phase 2에서 식별한 대상 소스 파일 경로}
   ")
   ```

2. agent 결과에서 source_files, test_result, commit 수집

3. **세션 상태 업데이트**: phase → "green", source_files, commits.green 기록

### Phase 6: (Human) Green 리뷰

```
AskUserQuestion:
  question: "Green Phase 완료.

  변경 파일:
  1. {file} - {변경 요약}
  2. {file} - {변경 요약}

  테스트: {통과}/{전체} (신규 {N}개, 기존 {N}개)

  리뷰 포인트:
  - 구현이 정말 최소한인가? (불필요한 추상화 없는가?)
  - 기존 테스트 회귀가 없는가?

  다음 단계: {Figma URL이 있으면 → Visual Verification / 없으면 → Refactor}

  선택: 진행 / 수정 요청 / Refactor 건너뛰기 / 중단"
```

- 수정 요청 시 → 구현 수정 → 테스트 재실행 → commit → 다시 리뷰 (루프)
- **진행** 시 → Figma URL이 있으면 Phase 5.5로, 없으면 Phase 7(Refactor)로
- **Refactor 건너뛰기** 선택 시 → Draft PR 생성 + `gh pr ready` 실행 후 Phase 8로 직행

### Phase 5.5: Visual Verification — Figma 디자인 매칭

> **Figma URL이 있으면 반드시 실행한다.** Figma URL이 없는 경우에만 Phase 7(Refactor)로 건너뜀.
> 에러 발생 시 자동 건너뛰기 금지 — 반드시 AskUserQuestion으로 사용자에게 선택을 요청한다.

1. **`tdd-visual` agent에 위임**:

   ```
   Task(subagent_type: "tdd-visual", prompt: "
     ## Context
     - figma_url: {Phase 1에서 수집한 Figma URL}
     - components: {Phase 2에서 식별한 Presentational 컴포넌트 이름 목록}
     - visual_contract: {Phase 2 설계의 Visual Contract 정보}
     - test_mock_data: {Phase 3 테스트에서 사용한 mock data}
   ")
   ```

2. agent 결과 확인:
   - Figma URL 미제공으로 건너뜀 → Phase 7(Refactor)로 이동
   - 완료 → story_files, iterations, match_status, commit 수집

3. **세션 상태 업데이트**: phase → "visual", visual_verification 섹션 업데이트 (story_files, iterations, status), commits.visual 기록

### Phase 5.6: (Human) Visual Verification 리뷰

```
AskUserQuestion:
  question: "🎨 Visual Verification 완료.

  비교 결과:
  - {component}: Figma 매칭 상태 (✅ 일치 / ⚠️ 잔여 차이: {목록})

  생성된 파일:
  - {story/preview file path}

  ralph-loop: {N}회 반복

  선택: 진행 (Refactor로) / 수정 요청 / 중단"
```

- **수정 요청** 시 → ralph-loop 재시작하여 추가 수정 → commit → 다시 리뷰
- **진행** 시 → Phase 7(Refactor)로
- **중단** 시 → 작업 중지

### Phase 7: Refactor - 코드 개선

1. **`tdd-refactor` agent에 위임**:

   ```
   Task(subagent_type: "tdd-refactor", prompt: "
     ## Context
     - source_files: {Phase 5에서 변경된 소스 파일 목록}
     - test_files: {Phase 3에서 생성된 테스트 파일 목록}
     - branch_name: {현재 작업 브랜치}
     - task_summary: {작업 설명}
     - base_branch: {현재 브랜치의 base (기본: main)}
     - test_cases_summary: {Phase 2의 Given/When/Then TC 요약}
   ")
   ```

2. agent 결과에서 pr_url, pr_number, precommit_result, refactoring_summary, commit 수집

3. **세션 상태 업데이트**: phase → "refactor", pr 정보, commits.refactor 기록

### Phase 8: 최종 보고

세션 상태 파일에서 정보를 읽어 최종 보고를 작성한다:

```
## TDD 완료 보고

### 작업: {task description}
### PR: {pr_url}

### 분석 & 설계
- 테스트 케이스: {N}개 설계
- 구현 접근: {summary}

### Red Phase
- 테스트 파일: {path}
- 커밋: {commit hash} - test: add failing tests

### Green Phase
- 변경 파일: {file list with summaries}
- 커밋: {commit hash} - feat: minimal implementation

### Visual Verification
- 상태: {완료/건너뜀/부분완료}
- Story 파일: {path} (해당 시)
- ralph-loop: {N}회 반복 (해당 시)
- 커밋: {commit hash} (해당 시)

### Refactor Phase
- 리팩토링: {items or "건너뛰기됨"}
- 커밋: {commit hash} (해당 시)

### 최종 검증
- 타입 체크: 통과/해당없음
- 린트: 통과/해당없음
- 테스트: {passed}/{total} 통과

### 변경된 파일 전체
- {file} (신규/수정)
```

### Phase 9: (Human) 최종 리뷰

```
AskUserQuestion:
  question: "TDD 워크플로우가 완료되었습니다.

  PR: {pr_url}

  선택: 승인 (PR을 Ready for Review로 전환) / 수정 요청"
```

수정 요청 시 → 수정 → commit & push → 다시 최종 리뷰 (루프)

### Phase 10: PR Ready for Review & 정리

1. 사용자 승인 후 Draft PR을 Ready for Review로 전환:
   ```bash
   gh pr ready {pr_number}
   ```

2. **세션 상태 파일 삭제**: `.claude/docs/{project_name}/tdd-session.yaml` 제거

3. 완료 메시지 출력:
   ```
   PR이 Ready for Review로 전환되었습니다: {pr_url}
   TDD 세션이 정리되었습니다.
   ```

## Error Handling

| 상황 | 대응 |
|------|------|
| 테스트 프레임워크 감지 실패 | AskUserQuestion으로 어떤 프레임워크를 사용하는지 질문 |
| Linear/GitHub URL fetch 실패 | 텍스트로 작업 내용 직접 입력 요청 |
| Red Phase에서 import 에러 | import/mock 설정 수정 후 assertion 실패 상태로 맞춤 |
| Green Phase 3회 시도 후 실패 | AskUserQuestion으로 접근 방법 논의 |
| 전체 테스트 회귀 | 어떤 기존 테스트가 깨졌는지 표시, 대응 방법 논의 |
| git push 실패 | 에러 표시, 수동 해결 안내 |
| 태스크가 너무 큰 경우 | `/tdd:spec` → `/tdd:design` → `/tdd:issues` → `/tdd:implement` 추천 |
| 사용자 중단 | 변경 파일 & PR URL 표시, tdd-session.yaml 유지 (나중에 재개 가능) |
| 세션 상태 파일 손상 | tdd-session.yaml 삭제 후 처음부터 시작 안내 |
| 작업 디렉토리에 미커밋 변경 있음 | AskUserQuestion으로 stash / commit / 중단 선택 |
| Visual Verification 에러 | tdd-visual agent가 자체 처리 (AskUserQuestion으로 사용자 확인) |

## Example

```
사용자: /tdd:start 장바구니에 수량 음수가 입력되는 버그 수정

Claude: 프로젝트 컨텍스트를 수집합니다...
  테스트 프레임워크: vitest
  린터: biome
  타입 체커: tsc

Claude: [Phase 2] 문제를 분석했습니다.

  ## 문제 분석
  Cart.addItem()에서 수량 validation이 없어 음수 입력이 가능

  구현 방향에 대한 설계 초안을 공유해주세요.
  [AskUserQuestion]

사용자:
  ### 핵심 결정
  - src/domain/cart.ts의 addItem()에 수량 validation 추가
  - ValidationError를 던지도록 처리
  ### 열린 질문
  - 수량 0도 에러로 처리해야 하는지?

Claude: [Phase 2 계속] 분석 & 설계가 완료되었습니다.

  ## 초안 반영
  - 반영: addItem()에 validation 추가, ValidationError 사용

  ## 열린 질문 → 제안
  - Q: 수량 0도 에러로 처리해야 하는지?
    → A: 장바구니에 수량 0인 아이템은 의미 없으므로 에러 처리 권장

  ## 테스트 케이스
  1. Given 수량 -1 / When addItem / Then ValidationError
  2. Given 수량 0 / When addItem / Then ValidationError
  3. Given 수량 1 / When addItem / Then 정상 추가

  ## 구현 접근
  - src/domain/cart.ts: addItem()에 수량 > 0 validation 추가

  선택: 진행 / 수정 요청 / 중단

사용자: 진행

Claude: [Phase 3] Red - 실패하는 테스트 작성
  branch 생성: fix/cart-negative-quantity
  테스트 파일 생성: src/domain/cart.test.ts
  테스트 실행: 3개 실패 (expected)
  commit 완료

Claude: [Phase 4] AskUserQuestion
  Red Phase 완료. 선택: 진행 / 수정 요청 / 중단

사용자: 진행

Claude: [Phase 5] Green - 최소 구현
  src/domain/cart.ts 수정: addItem()에 validation 추가
  테스트 실행: 3개 통과
  전체 테스트: 회귀 없음

Claude: [Phase 6] AskUserQuestion
  Green Phase 완료. 선택: 진행 / 수정 요청 / Refactor 건너뛰기 / 중단

사용자: Refactor 건너뛰기

Claude: [Phase 8] 최종 보고
  ## TDD 완료 보고
  작업: 장바구니 수량 음수 버그
  PR: https://github.com/org/repo/pull/42
  테스트: 3개 추가, 전체 통과
  Refactor: 건너뛰기됨

Claude: [Phase 9] AskUserQuestion
  선택: 승인 (Ready for Review) / 수정 요청

사용자: 승인

Claude: [Phase 10] PR Ready for Review
  PR이 Ready for Review로 전환되었습니다.
  https://github.com/org/repo/pull/42
  TDD 세션이 정리되었습니다.
```

