---
name: wrap
description: 대화에서 발견한 패턴을 시스템에 반영
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - AskUserQuestion
---

# Wrap Command

현재 대화에서 발견된 유용한 패턴, 워크플로우, 지식을 추출하여 `.claude/` 시스템에 반영합니다.

## Prerequisites

- **필수 스킬**: `claude-config-patterns` - 파일 구조, 템플릿, 식별 기준 참조

## Execution Flow

### Phase 1: 대화 분석

현재 대화 전체를 분석하여 Agent, Skill, Command, **Rules**, CLAUDE.md 후보를 식별합니다.

> **참조**: `claude-config-patterns` 스킬의 "식별 기준" 섹션

**분석 항목:**

#### 1. 실수 및 오류 패턴
- 반복적으로 수정한 코드
- 잘못된 가정으로 인한 버그
- 놓친 엣지 케이스
- 스타일/컨벤션 위반

#### 2. 학습한 패턴
- 코드베이스의 새로운 패턴 발견
- 효과적이었던 접근 방식
- 도메인 특화 규칙

#### 3. 사용자 선호도
- 코딩 스타일 선호
- 커뮤니케이션 스타일
- 작업 방식 선호

**Rules 식별 기준:**
- 세션 시작 시 자동 로드되어야 하는 지침인가?
- 프로젝트 전역에 적용되는 정책인가?
- 특정 파일 패턴에만 적용되어야 하는가? (조건부 규칙)

### Phase 2: 사용자 확인

AskUserQuestion 도구로 추출 항목 제시:

```
AskUserQuestion:
  questions:
    - question: "대화에서 다음 항목들을 추출할 수 있습니다. 반영할 항목을 선택하세요."
      header: "추출 항목"
      multiSelect: true
      options:
        - label: "[Agent] {name}"
          description: "{설명}"
        - label: "[Skill] {name}"
          description: "{설명}"
        - label: "[Command] {name}"
          description: "{설명}"
        - label: "[Rules] {name}"
          description: "{정책/지침 설명}"
        - label: "[CLAUDE.md] {내용 요약}"
          description: "{상세 설명}"
```

### Phase 3: 파일 반영

사용자가 선택한 항목만 반영:

#### 3.1 기존 파일 확인
선택된 각 항목에 대해:
1. 동일 이름의 파일이 이미 존재하는지 Glob으로 확인
2. 존재하면 → UPDATE 모드 (기존 내용과 병합/확장)
3. 없으면 → CREATE 모드 (신규 생성)

#### 3.2 충돌 처리
기존 파일과 이름이 같을 경우 AskUserQuestion으로 확인:
- **덮어쓰기**: 기존 내용 대체
- **병합**: 기존 내용에 새 내용 추가
- **다른 이름**: 새 이름으로 생성
- **건너뛰기**: 해당 항목 생략

#### 3.3 파일 생성/수정 실행
1. `claude-config-patterns` 스킬의 해당 템플릿 참조
2. 대화에서 추출한 내용으로 템플릿 채우기
3. 체크리스트로 검증
4. 파일 작성 (Write/Edit 도구 사용)

> **참조**: `claude-config-patterns` 스킬의 템플릿, 체크리스트, 디렉토리 구조

## 결과 보고

반영 완료 후 다음 정보 출력:
- 생성/수정된 파일 목록
- 각 파일의 변경 내용 요약

## Example

```
사용자: /wrap

Claude: 대화를 분석합니다...

[AskUserQuestion 호출]
Options:
□ [Agent] setup-project - 프로젝트 초기화 자동화
□ [Skill] api-error-handling - API 에러 처리 패턴
□ [Rules] security - 시크릿 관리 및 인증 규칙
□ [CLAUDE.md] 새로운 환경변수 추가

사용자: setup-project, security, CLAUDE.md 선택

Claude:
완료! 다음 파일이 업데이트되었습니다:
- .claude/agents/setup-project.md (신규 생성)
- .claude/rules/security.md (기존 파일에 규칙 추가)
- CLAUDE.md (환경변수 섹션 업데이트)
```

## Common Mistakes

| 실수 | 해결 |
|------|------|
| 너무 일반적인 규칙 | 구체적인 상황과 예시 포함 |
| 중복 규칙 생성 | 기존 규칙 먼저 확인 후 병합 |
| 프로젝트/개인 규칙 혼동 | 범용성 여부로 판단 |

## 주의사항

- 추출할 내용이 없으면 "이 대화에서 추출할 패턴을 찾지 못했습니다." 메시지 출력
- 기존 파일과 이름이 충돌하면 사용자에게 덮어쓰기 여부 확인
- 파일 생성 시 반드시 `claude-config-patterns` 스킬 참조
