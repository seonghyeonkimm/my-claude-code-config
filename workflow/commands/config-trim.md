---
description: 프로젝트의 AI 설정 파일(CLAUDE.md, agents, commands, rules 등)에서 중복·불필요 콘텐츠를 분석하고 제거
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Config Trim Command

프로젝트의 AI 관련 설정 파일에서 중복·불필요 콘텐츠를 찾아 보고하고, 승인된 항목만 제거한다.

## Redundancy Pattern Catalog

분석 시 아래 8가지 패턴을 체크한다.

| ID | 패턴 | 감지 방법 |
|----|------|-----------|
| P1 | **Auto-loaded rule 중복** | `rules/` 내용이 agent/command에 반복됨. Rules는 세션 시작 시 자동 로드되므로 agent에서 반복하면 100% 중복 |
| P2 | **인라인 template 블록** | `skills/*/references/` 등의 참조 파일 내용이 agent에 인라인됨. Read 참조로 대체 가능 |
| P3 | **재요약 섹션** | "참고", "요약" 등 레이블의 섹션이 같은 파일 본문의 내용을 재서술 |
| P4 | **자명한 프로세스 단계** | "(Human) Review" 등 판단 기준 없이 "승인/거절"만 있는 phase |
| P5 | **Verbose 예시** | Example 섹션에서 결정 지점(AskUserQuestion/응답) 외 중간 trace가 과다 |
| P6 | **인라인 절차 복사** | rule 파일에 정의된 절차를 command에 통째로 복사 (1줄 참조로 대체 가능) |
| P7 | **하드코딩된 도구명** | 특정 MCP/CLI 도구명이 일반 설명으로 대체 가능한 경우 |
| P8 | **CLAUDE.md 코드베이스 설명** | 다른 설정 파일(skill 등)에 이미 있는 구조·형식 설명을 CLAUDE.md에서 반복. 또는 에이전트가 탐색으로 더 빠르게 파악할 수 있는 디렉토리 구조·파일 형식 설명 |

### 제외 조건 (정당한 중복)

다음은 분석 대상에서 **제외**한다:

- **Command의 task description template 내 내용**: workspace에 전달되므로 self-contained 필수
- **사람용 문서** (Linear issue template 등): 에이전트 지시와 다른 용도
- **Agent의 분석 방법론/설계 규칙**: agent는 skill을 직접 호출 불가 — 분석 로직은 agent에 필수

## Execution Flow

### Phase 1: 파일 탐색

프로젝트의 AI 설정 파일 구조를 탐색한다.

**1-1. 설정 파일 위치 감지:**

다음 경로를 순서대로 확인하여 설정 파일이 있는 위치를 파악한다:

| 구조 | 감지 방법 | 설명 |
|------|-----------|------|
| 프로젝트 `.claude/` | `Glob(".claude/agents/*.md")`, `Glob(".claude/commands/**/*.md")` 등 | 프로젝트 로컬 설정 |
| 플러그인 repo | `Glob("plugins/*/agents/*.md")`, `Glob("plugins/*/commands/**/*.md")` 등 | 플러그인 마켓플레이스 저장소 |
| `CLAUDE.md` | `Glob("**/CLAUDE.md")` | 프로젝트 루트 또는 하위 디렉토리 |

**1-2. 대상 파일 수집:**
```
agents/*.md
commands/**/*.md
CLAUDE.md (모든 위치)
```

**1-3. 비교 참조 파일 수집 (중복 감지용):**
```
rules/*.md
skills/*/references/*.md
skills/*/SKILL.md
```

모든 파일을 Read하여 내용을 파악한다.

### Phase 2: 분석

각 대상 파일에 대해 P1~P8 패턴을 순서대로 체크한다.

**P1/P2 (기계적 비교):**
- 각 rule 파일의 핵심 내용 블록을 추출
- agent/command 파일에서 동일·유사 블록을 Grep으로 탐색
- 각 reference 파일의 구조(테이블 헤더, 코드블록)를 agent 파일과 비교

**P3~P8 (의미론적 판단):**
- 파일 내용을 읽고 각 패턴의 해당 여부를 판단
- 제외 조건에 해당하면 건너뜀

발견 항목마다 기록:
```
{번호, 파일명, 라인 범위, 패턴 ID, 설명, 제안 액션}
```

### Phase 3: 보고 & 승인

분석 결과를 파일별로 그룹화하여 AskUserQuestion으로 제시한다.

```
AskUserQuestion:
  question: "## Config Trim 분석 결과

  분석: {N}개 파일 / 발견: {M}건 (예상 제거: ~{lines}줄)

  ### {파일명}
  1. [P1 Rule Dup] L{start}-{end}: {설명} → {제안 액션}
  2. [P5 Verbose] L{start}-{end}: {설명} → {제안 액션}

  ### {파일명}
  3. [P6 Procedure] L{start}-{end}: {설명} → {제안 액션}

  선택: 전체 승인 / 부분 승인 (번호 지정) / 수정 요청 / 중단"
```

### Phase 4: 적용

승인된 항목만 Edit으로 적용한다.

**패턴별 변환 방법:**

| 패턴 | 변환 |
|------|------|
| P1 Rule Dup | 중복 블록 삭제 |
| P2 Template | 코드블록을 참조 파일 경로의 Read 참조 1줄로 교체 |
| P3 Restate | 섹션 전체 삭제 |
| P4 Self-evident | phase 삭제 또는 1줄로 축소 |
| P5 Verbose | 결정 지점(AskUserQuestion/응답)만 남기고 중간 trace 삭제 |
| P6 Procedure | 인라인 절차를 rule 파일 참조 1줄로 교체 |
| P7 Hardcode | 구체적 도구명을 일반 설명으로 교체 |
| P8 Description | 코드베이스 설명 삭제 또는 skill/문서 참조로 교체 |

### Phase 5: 동기화 & 보고

1. **sync 스크립트 감지**: `Glob("**/sync.sh")`로 동기화 스크립트가 있으면 실행하여 repo↔local 동기화
2. sync 스크립트가 없으면 이 단계를 건너뜀

3. 결과 보고:
   ```
   ## Config Trim 완료

   적용: {N}건 / 제거: ~{lines}줄

   변경된 파일:
   - {파일명} (-{N} lines)

   커밋은 생성하지 않았습니다. 확인 후 커밋하세요.
   ```

## Error Handling

| 상황 | 대응 |
|------|------|
| AI 설정 파일 없음 | "AI 설정 파일을 찾을 수 없습니다. (.claude/, CLAUDE.md 등)" 출력 후 종료 |
| 발견 항목 없음 | "모든 파일이 최적화되어 있습니다." 출력 후 종료 |
| 적용 중 Edit 실패 | 해당 항목 건너뛰고 실패 보고, 나머지 계속 적용 |

## Example

```
사용자: /config-trim

Claude: AI 설정 파일을 탐색합니다...
  → .claude/agents/ (7개), .claude/commands/ (10개), CLAUDE.md (1개)
  → .claude/rules/ (3개), .claude/skills/ (6개) — 비교 참조용

Claude: 8가지 중복 패턴으로 분석합니다...

Claude: [AskUserQuestion]
  ## Config Trim 분석 결과
  분석: 18개 파일 / 발견: 3건 (예상 제거: ~20줄)

  ### .claude/agents/tdd-red.md
  1. [P1 Rule Dup] L46-49: test-file-location.md 규칙 내용 중복 → 삭제

  ### .claude/commands/pr.md
  2. [P6 Procedure] L25-38: gh-auth.md 절차 인라인 복사 → 1줄 참조로 교체

  ### CLAUDE.md
  3. [P8 Description] L5-50: 디렉토리 구조 설명이 skill과 중복 → 행동 지침만 유지

  선택: 전체 승인 / 부분 승인 (번호) / 중단

사용자: 전체 승인

Claude: Config Trim 완료!
  적용: 3건 / 제거: ~20줄
  → 확인 후 커밋하세요
```
