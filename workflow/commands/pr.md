---
description: 현재 변경사항을 커밋하고 PR을 생성합니다. 인자 없으면 draft PR, "ready"면 ready-for-review PR.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - AskUserQuestion
---

# PR 생성 Command

현재 작업 브랜치의 변경사항을 커밋하고 GitHub PR을 생성합니다.

## 인자

- 인자 없음: draft PR 생성
- `ready`: ready-for-review PR 생성
- PR URL 또는 번호: 해당 PR에 변경사항 push (새 PR 생성하지 않음)

## Execution Flow

### Step 0: GitHub 계정 확인 (gh auth)

`gh auth status`로 현재 인증 상태를 확인하고, 대상 리포지토리에 접근 가능한 계정을 찾아 필요하면 `gh auth switch`로 전환한 뒤 다음 작업을 진행한다.

### Step 1: 상태 확인
1. `git status`로 변경사항 확인
2. `git diff --stat`로 변경 파일 확인
3. `git log --oneline -5`로 최근 커밋 스타일 확인
4. 변경사항이 없으면 "커밋할 변경사항이 없습니다." 출력 후 종료

### Step 1.5: Pre-flight Checks

변경사항을 커밋하기 전에 코드 품질 검사를 실행한다. 문제가 발견되면 자동 수정을 시도하고, 수정 불가 시 사용자에게 결정을 요청한다.

#### 1. 프로젝트 도구 감지

**패키지 매니저:**
- `pnpm-lock.yaml` 존재 → PM="pnpm"
- `yarn.lock` 존재 → PM="yarn"
- 그 외 → PM="npx"

**타입 체커:**
- `Glob("tsconfig.json")` 존재 → `{PM} tsc --noEmit`

**린터:**
- `Glob("biome.json")` 또는 `Glob("biome.jsonc")` → biome
  - 검사: `{PM} biome check .`
  - 자동수정: `{PM} biome check --write .`
- `Glob(".eslintrc.*")` 또는 `Glob("eslint.config.*")` → eslint
  - 검사: `{PM} eslint .`
  - 자동수정: `{PM} eslint --fix .`

**테스트 프레임워크:**
- `Glob("vitest.config.*")` → `{PM} vitest run`
- `Glob("jest.config.*")` 또는 package.json jest → `{PM} jest`
- `Glob("pytest.ini")` 또는 `Glob("pyproject.toml")` → `pytest`
- `Glob("go.mod")` → `go test ./...`

감지된 도구가 하나도 없으면 이 Step을 건너뛰고 Step 2/3으로 진행한다.

#### 2. 검사 실행 및 자동 수정

검사 순서: **typecheck → lint → tests** (앞 단계 수정이 뒷 단계 오류를 줄인다)

최대 재시도: **전체 수정 사이클 3회**

```
retry = 0
while retry < 3:
  1. TypeScript 타입 체크 (감지된 경우)
     → 실패 시: 에러 출력 분석, Read로 파일 확인, Edit로 수정 → retry++, 루프 처음부터

  2. 린트 (감지된 경우)
     → 실패 시 첫 시도: --write/--fix 자동수정 실행
     → 이후 시도: Read/Edit로 수동 수정
     → retry++, 루프 처음부터 (typecheck 재실행하여 회귀 방지)

  3. 테스트 (감지된 경우)
     → 실패 시: 소스 코드 수정 (테스트 파일은 건드리지 않음)
     → retry++, 루프 처음부터 (typecheck, lint 재실행하여 회귀 방지)

  모두 통과 → break
```

#### 3. 자동 수정 실패 시 사용자 결정

3회 재시도 후에도 실패하면:

```
AskUserQuestion:
  "Pre-flight check 실패: {실패한 검사}

  오류:
  {핵심 에러 메시지}

  선택:
  - 무시하고 진행: 현재 상태로 커밋 & PR 생성
  - 중단: PR 생성을 중단하고 수동 수정
  - 재시도: 추가 컨텍스트 제공 후 다시 시도"
```

- **무시하고 진행** → Step 2/3으로 진행 (자동 수정으로 변경된 파일도 함께 staging)
- **중단** → 명령어 종료
- **재시도** → 사용자 컨텍스트 반영하여 추가 3회 시도

#### 4. 검사 결과 기록

모든 검사가 완료되면 결과를 기록해 둔다. Step 3에서 PR 본문에 포함한다.

### Step 2: 기존 PR Push 모드 (PR URL/번호가 인자로 제공된 경우)
1. 변경된 파일을 staging
2. 변경 내용을 분석하여 커밋 메시지 작성
3. `git push`로 기존 PR 브랜치에 push
4. PR URL 출력 후 종료

### Step 3: 새 PR 생성 모드
1. 변경된 파일을 staging (.env, credentials 등 민감파일 제외)
2. 변경 내용을 분석하여 커밋 메시지 작성
3. 커밋 생성
4. 원격에 push (`git push -u origin HEAD`)
5. `gh pr create` 실행:
   - `--draft` (기본) 또는 ready 모드
   - 제목: 70자 이내, 변경 핵심 요약
   - 본문: Summary bullet points + Test plan
6. PR URL 출력

## 커밋 메시지 규칙
- 변경 성격을 정확히 반영 (add/update/fix/refactor)
- 1-2문장, "why" 중심
- Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## PR 본문 형식
```
## Summary
- {변경사항 1}
- {변경사항 2}

## Pre-flight Checks
- [x] TypeScript type check       ← 통과 시
- [x] Biome lint                   ← 통과 시
- [x] Tests (vitest)               ← 통과 시
- [ ] Tests (not detected)         ← 감지 안 된 항목
- ⚠️ Lint (skipped by user)        ← 사용자가 건너뛴 항목

## Test plan
- [ ] {테스트 항목}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
