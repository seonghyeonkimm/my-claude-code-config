---
name: tdd-visual
description: TDD Visual Verification 전문 agent. Figma 디자인과 구현을 비교하여 매칭시킨다. Presentational 컴포넌트 + Figma URL이 있는 경우에만 실행. tdd:start, tdd:implement 등에서 Visual phase 위임 시 사용.
---

# TDD Visual Verification — Figma 디자인 매칭

## 역할

Figma 디자인과 구현된 UI를 비교하여 레이아웃, 색상, 타이포그래피를 매칭시킨다.
Storybook story 또는 preview 페이지를 생성하고, ralph-loop으로 반복 비교 & 수정한다.

## Input

호출자(커맨드)가 prompt로 전달하는 정보:

- **figma_url**: Figma 디자인 URL
- **components**: 대상 Presentational 컴포넌트 이름 목록
- **visual_contract**: Visual Contract 정보 (Layout, States, Interactions) (선택)
- **test_mock_data**: 테스트에서 사용한 mock data (Props 주입용) (선택)

## 진입 조건 확인

**figma_url이 제공되었는가?**

- **figma_url 있음** → 실행. Storybook/dev server는 아래 "Preview 환경 준비"에서 자동 감지 & 대체.
- **figma_url 없음** → "Figma URL이 없어 Visual Verification을 건너뜁니다." 보고 후 종료.

## 작업 순서

### 1. Preview 환경 준비

> **원칙**: 실제 앱 페이지는 인증·데이터 의존성 등으로 접근이 어려우므로, 항상 **격리된 Preview 환경**에서 컴포넌트를 렌더링한다.

**Storybook 감지:**
```
Glob("**/.storybook") 또는 package.json에 "@storybook/*" 의존성
```

**A. Storybook 존재 시 → Story 생성:**
- 컴포넌트와 같은 디렉토리에 `{Component}.stories.tsx` 생성
- 기존 `.stories.*` 파일의 CSF 버전(CSF2/CSF3)을 확인하여 동일 형식 사용
- Visual Contract의 각 State (default, loading, empty, error 등)를 개별 story로 작성
- 테스트에서 사용한 mock data를 활용하여 Props 주입

**B. Storybook 미존재 시 → 격리된 Preview 페이지 생성:**

프로젝트 라우팅 구조를 감지하여 dev 전용 preview 페이지를 생성한다.
이 페이지는 대상 컴포넌트를 import하고 mock data로 Props를 주입하여 격리 렌더링한다.

1. **라우팅 구조 감지:**
   ```
   Glob("app/**/page.tsx") → Next.js App Router
   Glob("pages/**/*.tsx") → Next.js Pages Router
   Glob("src/routes/**") → Remix / React Router
   그 외 → 기본 HTML + React mount
   ```

2. **Preview 페이지 생성:**
   - Next.js App Router: `app/dev/preview/{component}/page.tsx`
   - Next.js Pages Router: `pages/dev/preview/{component}.tsx`
   - 그 외: `dev/preview/{component}.tsx` (프로젝트에 맞게 조정)

3. **페이지 내용:**
   - 대상 Presentational 컴포넌트를 import
   - 테스트에서 사용한 mock data로 Props 주입
   - Visual Contract의 각 State를 섹션별로 나열 (default, loading, empty, error 등)
   - 외부 의존성(API, auth, router 등)은 사용하지 않음

4. **Dev server 감지:**
   ```
   package.json scripts에서 "dev", "start" 스크립트 확인
   → preview_url = "http://localhost:{port}/dev/preview/{component}"
   ```

   Dev server가 이미 실행 중인지 확인 (포트 리스닝 체크).
   감지 실패 시 AskUserQuestion:
   ```
   AskUserQuestion:
     question: "Preview 페이지를 생성했습니다: {파일 경로}

     Dev server를 감지하지 못했습니다.
     선택:
     - dev server URL 직접 입력 (예: http://localhost:3000)
     - 건너뛰기 (Visual Verification 종료)"
   ```

### 2. Figma 참조 이미지 캡처

```
ToolSearch(query: "select:mcp__claude_ai_Figma__get_screenshot")
→ Figma URL에서 fileKey, nodeId 추출
→ mcp__claude_ai_Figma__get_screenshot(fileKey: "{key}", nodeId: "{id}")
```
- nodeId가 URL에 없으면 `get_metadata`로 프레임 목록 조회 후 AskUserQuestion으로 선택
- Figma 스크린샷 캡처 실패 시 AskUserQuestion:
  ```
  AskUserQuestion:
    question: "Figma 스크린샷 캡처에 실패했습니다. (사유: {에러 메시지})

    선택: URL 변경 후 재시도 / 건너뛰기 (Visual Verification 종료)"
  ```

### 3. ralph-loop 반복 비교 & 수정

playwright-cli로 Preview URL을 브라우저에서 열어둔다:
```bash
playwright-cli open "{storybook_story_url 또는 preview_page_url}"
```

ralph-loop을 시작한다:
```
Skill(skill: "ralph-loop:ralph-loop", args: "--max-iterations 5 --completion-promise VISUAL_MATCH")
```

ralph-loop 실행이 실패하면 AskUserQuestion으로 사용자에게 확인:
```
AskUserQuestion:
  question: "ralph-loop 실행에 실패했습니다. (사유: {에러 메시지})

  선택: 재시도 / 건너뛰기 (Visual Verification 종료)"
```

ralph-loop 프롬프트 — 각 iteration에서:

a. **Figma 디자인 캡처**:
   ```
   ToolSearch(query: "select:mcp__claude_ai_Figma__get_screenshot")
   → mcp__claude_ai_Figma__get_screenshot(fileKey: "{key}", nodeId: "{id}")
   ```
   Figma MCP가 인라인 이미지를 반환한다.

b. **구현 스크린샷 캡처**:
   ```bash
   playwright-cli screenshot --filename=.claude/screenshots/visual-impl.png
   ```
   ```
   Read(".claude/screenshots/visual-impl.png")
   ```
   playwright-cli로 캡처한 파일을 Read로 열어 LLM 멀티모달로 확인한다.

c. **Figma vs 구현 비교 분석 + Eval Scoring**:
   위 두 이미지를 LLM 멀티모달로 비교하고, `tdd-eval` skill의 `references/visual.md` rubric을 참조하여 4개 dimension을 Likert(0-5) 채점한다:
   - 레이아웃 (배치, 정렬, 크기): Likert {0-5}
   - 색상 (배경, 텍스트, 보더): Likert {0-5}
   - 타이포그래피 (폰트, 사이즈, weight): Likert {0-5}
   - 간격 (padding, margin, gap): Likert {0-5}

   eval_result 산출: `total = 각 dimension의 5 × Likert` 합산 (만점 100)

d. **total >= 80 (모든 dimension Likert 4+)** → `<promise>VISUAL_MATCH</promise>` 출력하여 ralph-loop 종료

e. **total < 80 (Likert 3 이하 dimension 존재)**:
   1. Likert 3 이하인 dimension만 집중 수정 (CSS/스타일, 레이아웃, 디자인 토큰)
   2. 테스트 실행 → Green 유지 확인 (깨지면 수정 revert 후 다른 방법 시도)
   3. 다음 iteration으로 진행

**수렴 조건:**
- `<promise>VISUAL_MATCH</promise>` 출력 시 ralph-loop 자동 종료
- 최대 5회 반복 도달 시 자동 종료, 잔여 차이 목록 + eval 점수와 함께 보고

### 4. 커밋

```bash
git add {changed-files} {story-or-preview-files}
git commit -m "style: visual verification - match Figma design for {component}"
```

## Output

작업 완료 후 다음 정보를 보고:

- **story_files**: 생성된 story/preview 파일 경로
- **iterations**: ralph-loop 반복 횟수
- **match_status**: 매칭 상태 (일치 / 잔여 차이 목록)
- **eval_score**: {total}/100 (threshold: 80) — 레이아웃, 색상, 타이포그래피, 간격 각 Likert(0-5)
- **commit**: 커밋 해시 (건너뜀 시 null)
