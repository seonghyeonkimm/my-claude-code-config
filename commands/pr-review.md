---
description: 현재 PR의 리뷰 코멘트를 확인하고, 반영할 것을 적용한 뒤 resolve까지 처리합니다.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Skill
---

# PR Review Command

현재 작업 브랜치에 연결된 PR의 리뷰 코멘트를 확인하고, 필요한 변경사항을 반영한 뒤 push하고, 처리된 코멘트를 resolve합니다.

## Execution Flow

### Step 0: GitHub 계정 확인 (gh auth)

`~/.claude/rules/gh-auth.md`의 "gh 명령어 실행 전 필수 확인" 절차를 따른다.

### Step 1: 현재 PR 식별

1. `gh pr view --json number,url,title,headRefName` 실행하여 현재 브랜치의 PR 정보 확인
2. PR이 없으면 에러 메시지 출력 후 종료

### Step 2: 리뷰 코멘트 수집

1. `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments` 로 PR review comments 수집
2. `gh pr view {pr_number} --json comments` 로 일반 코멘트도 수집
3. 이미 resolved된 코멘트는 제외 (outdated이거나 resolved인 것)
4. 수집된 코멘트 목록을 정리

### Step 3: 코멘트 분류

각 코멘트를 분석하여 두 그룹으로 분류:

**반영 필요 (actionable)**:
- 코드 수정을 요구하는 코멘트 (버그 지적, 로직 개선 제안, 네이밍 변경 등)
- 구체적인 변경사항이 명확한 코멘트
- suggestion 코드 블록이 포함된 코멘트

**반영 불필요 (non-actionable)**:
- 단순 질문이나 확인 요청 (코드 변경 없음)
- 칭찬/승인 코멘트
- 이미 반영된 내용에 대한 코멘트
- 의견 차이로 논의가 필요한 코멘트 (코드 변경보다 답변이 필요)
- 사소한 스타일 취향 차이 (프로젝트 컨벤션에 위배되지 않는 경우)

분류 결과를 사용자에게 표시:
```
## 리뷰 코멘트 분류 결과

### 반영 예정 (N건)
1. @reviewer - file.ts:42 - "변수명을 더 명확하게 변경해주세요" → 반영 이유: ...
2. ...

### 반영 불필요 (M건)
1. @reviewer - "LGTM!" → 사유: 승인 코멘트
2. ...
```

### Step 4: 코드 변경 반영

각 actionable 코멘트에 대해:
1. 해당 파일과 위치를 확인
2. 코멘트의 요청사항을 반영하여 코드 수정
3. suggestion 블록이 있으면 해당 내용을 그대로 적용

### Step 5: Push

모든 변경사항 반영 후 `/pr {pr_number}` command를 사용하여 커밋 & push

### Step 6: 코멘트 Resolve

반영 완료된 코멘트들을 resolve 처리:
1. 각 반영된 review comment의 thread를 `gh api` 를 사용하여 resolve
   - GraphQL mutation 사용: `resolveReviewThread`
   - `gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "..." }) { thread { isResolved } } }'`
2. resolve할 thread ID는 `gh api graphql` 쿼리로 PR의 review threads를 조회하여 획득

### Step 7: 완료 보고

```
## PR 리뷰 반영 완료

- PR: #{pr_number} - {title}
- 반영된 코멘트: N건
- 반영하지 않은 코멘트: M건
- 커밋: {commit_hash}
- PR URL: {url}

### 반영 상세
1. {파일}:{라인} - {변경 요약}
...

### 미반영 코멘트 (필요시 수동 확인)
1. @{reviewer} - "{코멘트 요약}" - 사유: {미반영 이유}
...
```
