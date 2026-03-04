---
description: Linear 프로젝트에 FE TechSpec 문서를 생성하고 테스트 케이스까지 작성
allowed-tools:
  - Read
  - Write
  - ToolSearch
  - AskUserQuestion
---

# TDD Spec Command

Linear 프로젝트에 FE TechSpec 문서를 생성한다. PRD와 Figma 컨텍스트를 기반으로 Solution, Acceptance Criteria, Test Cases를 자동 작성.

## Prerequisites

- **필수 스킬**: `fe-techspec` - 템플릿 구조와 섹션별 작성 가이드 참조
- **필수 MCP**: Linear plugin 활성화

## Execution Flow

### Phase 1: 입력 수집

1. 사용자로부터 Linear Project 링크 또는 이름을 받는다
2. PRD (Notion URL)가 제공되지 않은 경우, AskUserQuestion으로 명시적으로 묻는다:
   ```
   question: "PRD (Notion URL)가 있나요? 없으면 비워두세요."
   ```
3. Figma URL이 제공되지 않은 경우, AskUserQuestion으로 명시적으로 묻는다:
   ```
   question: "Figma 디자인 URL이 있나요? 없으면 비워두세요."
   ```

**PRD와 Figma가 모두 없는 경우**: 정말로 없는지 한 번 더 확인한다.

### Phase 2: 컨텍스트 수집

ToolSearch로 MCP 도구를 로드한 뒤 컨텍스트를 수집한다.

1. **Linear 프로젝트 조회**:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__get_project")
   → mcp__plugin_linear_linear__get_project(query: "{project identifier}")
   ```

2. **PRD 내용 조회** (URL 제공 시, ⚠️ 반드시 실행):
   ```
   ToolSearch(query: "select:mcp__plugin_Notion_notion__notion-fetch")
   → mcp__plugin_Notion_notion__notion-fetch(url: "{notion_url}")
   ```
   - PRD URL이 있으면 반드시 fetch하여 컨텍스트 수집
   - 핵심 요구사항, 유저 스토리, 성공 지표를 추출
   - fetch 실패 시에만 PRD 없이 진행

3. **Figma 디자인 컨텍스트** (URL 제공 시):
   ```
   ToolSearch(query: "select:mcp__plugin_figma_figma__get_design_context")
   → mcp__plugin_figma_figma__get_design_context(url: "{figma_url}")
   ```
   - 컴포넌트 구조, UI 흐름을 추출
   - ⚠️ **UI 표시 문구 검증**: 테이블 컬럼명, 버튼 라벨, 상태 표시 텍스트 확인
   - 가정하지 말고 피그마 variants에서 실제 문구 추출

### Phase 3: TechSpec 작성

1. `fe-techspec` 스킬의 섹션별 작성 가이드를 참조한다
2. `fe-techspec/references/template.md`에서 문서 구조를 로드한다

수집된 컨텍스트를 기반으로 전체 문서를 작성한다.

**작성 순서:**

1. **Summary**: 프로젝트 배경 + PRD/Figma 링크
2. **Solution**: ⚠️ 기술 용어 없이 비즈니스 관점에서 핵심 변경사항 요약
   - 번호 매기기 형식으로 3-5개 핵심 변경사항 나열
   - 코드, API, 타입명 사용 금지
3. **Acceptance Criteria**: PRD 유저 스토리에서 테스트 가능한 기준 도출
4. **Non-Functional Requirements**: 해당되는 경우에만 작성 (Performance, A11y, SEO)
5. **Functional Requirements (Given/When/Then)**:
   - ⚠️ Entity/Command 헤더 없이 테이블만 작성
   - 정상 → 에러 → 엣지 케이스 순서로 테스트 케이스 테이블 작성

### Phase 3.5: AC ↔ TC 추적성 검증

작성 완료 후 Acceptance Criteria와 Functional Requirements의 대응 관계를 검증한다.

- 각 AC 항목에 대응하는 TC(Given/When/Then 행)가 **최소 1개** 존재하는지 확인
- 대응 TC가 없는 AC → TC를 추가하거나 AC를 제거
- TC가 어떤 AC에도 속하지 않으면 → AC를 추가하거나 해당 TC의 필요성 재검토

### Phase 4: Linear 문서 생성

```
ToolSearch(query: "select:mcp__plugin_linear_linear__create_document")
→ mcp__plugin_linear_linear__create_document(
    title: "FE TechSpec: {Feature Name}",
    project: "{project ID or name}",
    content: "{full markdown content}"
  )
```

### Phase 5: 메타데이터 저장

`.claude/docs/{project-name}/meta.yaml`에 **메타데이터만** 저장한다. `{project-name}`은 Linear 프로젝트 이름을 kebab-case로 변환한 값.

⚠️ **TechSpec 전문은 저장하지 않는다** - Linear 문서가 Single Source of Truth.

```yaml
# .claude/docs/{project-name}/meta.yaml
project:
  id: "{project-id}"
  name: "{project-name}"
  url: "{linear-project-url}"
  tdd_label: "tdd"
document:
  id: "{document-id}"
  url: "{linear-document-url}"
  title: "FE TechSpec: {Feature Name}"
sources:
  prd: "{notion-url-or-null}"
  figma: "{figma-url-or-null}"
created_at: "{ISO-8601}"
```

이 파일은 후속 command (`/tdd:design` 등)에서 Linear 리소스를 참조하는 데 사용된다.

### Phase 6: 결과 보고

```
FE TechSpec 생성 완료!

Linear Document: {Linear Document URL}
Project: {Project Name}
Metadata: .claude/docs/{project-name}/meta.yaml

작성된 섹션:
- Summary (PRD/Figma 링크 포함)
- Solution (핵심 변경사항)
- Acceptance Criteria ({N}개)
- Non-Functional Requirements
- Functional Requirements ({N}개 테스트 케이스)

⚠️ TechSpec 전문은 Linear 문서에만 저장됩니다 (Single Source of Truth)

다음 단계:
1. Linear에서 문서를 리뷰하세요
2. /tdd:design 으로 Domain/Usecase/Component 설계를 추가하세요
```

### Phase 7: (Human) Review

사용자가 Linear에서 문서를 리뷰한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| Linear 프로젝트를 찾을 수 없음 | 프로젝트 목록을 보여주고 선택 요청 |
| Notion PRD fetch 실패 | PRD 없이 진행, Summary에 명시 |
| Figma fetch 실패 | Figma 없이 진행, Design 섹션 스킵 |
| Linear 문서 생성 실패 | 에러 메시지 출력, 재시도 안내 (로컬 저장 없음) |
| MCP 도구 로드 실패 | 에러 메시지와 함께 플러그인 활성화 방법 안내 |

## Example

```
사용자: /tdd:spec

Claude: Linear Project 링크 또는 이름을 알려주세요.
사용자: https://linear.app/daangn/project/my-feature-123

Claude: [AskUserQuestion] PRD (Notion URL)가 있나요?
사용자: https://www.notion.so/my-prd-page

Claude: [AskUserQuestion] Figma 디자인 URL이 있나요?
사용자: https://www.figma.com/file/xxx

Claude: [컨텍스트 수집 중...]
Claude: [TechSpec 작성 중...]
Claude: [Linear 문서 생성 중...]

Claude: FE TechSpec 생성 완료!
  Linear Document: https://linear.app/daangn/document/fe-techspec-xxx
  Metadata: .claude/docs/my-feature/meta.yaml
  ...
```
