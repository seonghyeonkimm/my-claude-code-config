---
description: PR 코드를 P1(결함)/P2(설계)/P3(컨벤션) 우선순위별로 리뷰하고 GitHub에 게시합니다.
arguments:
  - name: pr_url
    description: PR URL 또는 번호
    required: false
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
---

# Do Review Command

다른 사람의 PR을 P1/P2/P3 우선순위별로 코드 리뷰하고, 상호작용을 거쳐 GitHub에 리뷰를 게시한다.

- **P1 시스템 결함/오류**: 런타임 에러, 보안 취약점, 데이터 손실, 경쟁 조건, 누락된 에러 처리
- **P2 설계 피드백**: 아키텍처, 추상화(깊은 모듈/정보 누출), 인지 부하, 네이밍(오해 유발), 타입/API 설계, 성능
- **P3 컨벤션 피드백**: 스타일, 마이너 네이밍, import 순서, 파일 구조, 코멘트 품질

## Execution Flow

### Phase 0: GitHub 계정 확인

`~/.claude/rules/gh-auth.md`의 "gh 명령어 실행 전 필수 확인" 절차를 따른다.

### Phase 1: PR 입력 해석

`$ARGUMENTS.pr_url` 분석:

| 입력 | 감지 | 처리 |
|------|------|------|
| 없음 | 비어있음 | AskUserQuestion: "리뷰할 PR URL 또는 번호를 입력하세요." |
| 숫자만 | `^\d+$` | 현재 repo의 PR 번호로 사용 |
| 전체 URL | `github.com` 포함 | owner/repo/number 파싱 |

다른 repo의 PR인 경우 `--repo {owner}/{repo}` 플래그를 사용한다.

### Phase 2: PR 데이터 수집

1. PR 메타데이터 수집:
   ```bash
   gh pr view {number} --repo {owner/repo} --json title,body,author,baseRefName,headRefName,files,additions,deletions,commits,state
   ```

2. PR 상태 확인:
   - `MERGED` → AskUserQuestion: "이미 merge된 PR입니다. 리뷰를 계속할까요?"
   - `CLOSED` → "닫힌 PR입니다." 안내 후 종료

3. 전체 diff 수집:
   ```bash
   gh pr diff {number} --repo {owner/repo}
   ```

4. 변경 통계:
   ```bash
   gh pr diff {number} --repo {owner/repo} --stat
   ```

5. 기존 리뷰 코멘트 조회 (중복 피드백 방지):
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[].body'
   ```

6. 대규모 PR 처리 (변경 >5000줄):
   - "대규모 PR입니다 ({lines}줄). 핵심 파일 위주로 분석합니다." 안내
   - 생성 파일(lock, generated), 테스트 파일의 분석 우선순위를 낮추고 비즈니스 로직에 집중

7. PR 개요 출력:
   ```
   ## PR 개요

   - PR: #{number} - {title}
   - Author: @{author}
   - Base: {base} <- {head}
   - 변경: +{additions} -{deletions}, {file_count}개 파일
   - 커밋: {commit_count}개

   ### 변경 파일
   {파일 목록 + 변경 통계}
   ```

### Phase 3: 코드 분석 - P1/P2/P3 분류

diff와 변경 파일을 분석하여 발견 사항을 분류한다. 필요하면 변경 파일의 전체 컨텍스트를 Read로 확인한다.

각 finding 구조:
- `file`: 파일 경로
- `line`: 라인 번호 또는 범위 (diff 기준)
- `priority`: P1/P2/P3
- `title`: 한 줄 요약
- `body`: 상세 설명
- `suggestion`: (선택) 제안 코드

**P1 시스템 결함/오류 체크리스트:**
- 런타임 에러 가능성 (null/undefined 접근, 타입 불일치)
- 보안 취약점 (인젝션, 인증 우회, 노출된 시크릿)
- 데이터 손실/손상 위험
- 경쟁 조건, 데드락
- API 계약 위반 (breaking change)
- 핵심 경로의 누락된 에러 처리
- off-by-one, 무한 루프

**P2 설계 피드백 체크리스트:**
- 결합도/응집도 문제
- 정보 누출 (한 모듈 수정 시 관련 없는 다른 파일까지 변경이 필요한가?)
- 추상화 수준 — 얕은 모듈 (인터페이스 복잡도 > 내부 로직), 과도한 레이어 (단순 패스스루), 누수, YAGNI (이 추상화는 현재 문제를 위한 것인가, 혹시 모를 미래를 위한 것인가?)
- 인지 부하 — 변수/조건이 과도한가? 몰라도 되는 옵션이 기본값 없이 노출되어 있진 않은가? (의도적 생략: "이 파라미터를 몰라도 기본 동작이 안전한가?")
- 데이터 흐름 및 상태 관리
- 에러 복구 전략 — 에러 발생 시 시스템이 안전한 상태를 유지하는가? 사용자 피드백과 상태 롤백이 설계되어 있는가?
- 오해를 유발하는 네이밍 — 도메인 용어(Ubiquitous Language)와 코드 용어가 불일치하여 설계 문서 ↔ 코드 간 인지 전환 비용이 발생하는가?
- 타입 정의 누락/부정확
- API 설계 (함수 시그니처, 반환 타입)
- 테스트 용이성 — 구현 세부사항이 아닌 클라이언트에 노출된 공개 인터페이스를 테스트하는 구조인가?
- 도메인 순수성 — 도메인 로직이 UI/API/외부 의존성 없이 순수 함수로 분리되어 있는가?
- 성능 영향이 있는 설계 선택

**P3 컨벤션 피드백 체크리스트:**
- 코드 스타일 불일치
- 마이너 네이밍 선호도 (오해 유발은 아니지만 개선 가능)
- 코멘트 품질 (과도/부족)
- import 순서
- 파일 구조 선호도
- 마이너 리팩토링 제안 (틀리진 않지만 더 깔끔할 수 있음)

### Phase 4: P1 리뷰 - 시스템 결함/오류

```
AskUserQuestion:
  question: "## P1: 시스템 결함/오류 ({N}건)

  이 단계에서는 시스템 안정성에 직접 영향을 주는 문제에 집중합니다.

  {N > 0:}
  1. [{file}:{line}] {title}
     {body}
     ```suggestion (optional)
     {code}
     ```

  2. ...

  {N == 0:}
  P1 수준의 결함은 발견되지 않았습니다.

  선택:
  - 전체 승인: 모든 P1 코멘트 채택
  - 부분 승인: 번호 지정 (예: '1,3')
  - 수정: 특정 코멘트 수정 (예: '2번 톤 완화')
  - 추가: 직접 발견한 P1 항목 추가
  - 우선순위 변경: 항목을 P2/P3로 이동 (예: '3번 → P2')
  - P2로 건너뛰기: P1 전체 스킵"
```

사용자가 **수정** 또는 **추가**를 선택하면:
- 수정: 해당 코멘트 내용을 변경 → 수정된 목록 다시 제시 → 승인 루프
- 추가: 사용자 입력 받기 → 목록에 추가 → 다시 제시 → 승인 루프

사용자가 **우선순위 변경**을 선택하면:
- 해당 항목을 지정된 우선순위로 이동 (Phase 5/6에서 표시됨)
- 현재 목록에서 제거 → 다시 제시

### Phase 5: P2 리뷰 - 설계 피드백

```
AskUserQuestion:
  question: "## P2: 설계 피드백 ({N}건)

  이 단계에서는 코드의 구조와 설계에 집중합니다:
  - 모듈이 복잡성을 충분히 숨기고 있는가? (깊은 모듈 지향)
  - 한 곳을 고칠 때 다른 곳까지 건드려야 하진 않는가?
  - 데이터 흐름이 명확한가?
  - 이름이 의도를 정확히 전달하는가?

  {findings list - Phase 4에서 이동된 항목 포함}

  선택:
  - 전체 승인 / 부분 승인 / 수정 / 추가 / 우선순위 변경 / P3로 건너뛰기"
```

Phase 4와 동일한 상호작용 패턴.

### Phase 6: P3 리뷰 - 컨벤션 피드백

```
AskUserQuestion:
  question: "## P3: 컨벤션 피드백 ({N}건)

  이 단계에서는 스타일과 일관성에 집중합니다.
  (참고: P3는 nit 수준이므로 게시 여부를 신중히 판단하세요)

  {findings list - 이전 Phase에서 이동된 항목 포함}

  선택:
  - 전체 승인 / 부분 승인 / 수정 / 추가 / 전체 건너뛰기"
```

### Phase 7: 리뷰 요약 및 게시

모든 우선순위 리뷰가 완료되면 최종 요약을 제시한다.

```
AskUserQuestion:
  question: "## 리뷰 요약

  ### 채택된 코멘트
  | 우선순위 | 건수 |
  |----------|------|
  | P1 시스템 결함 | {n}건 |
  | P2 설계 피드백 | {n}건 |
  | P3 컨벤션 피드백 | {n}건 |
  | 합계 | {total}건 |

  ### Review 이벤트 추천
  {P1 > 0: 'REQUEST_CHANGES 권장 — P1 결함이 있습니다.'}
  {P1 == 0 && P2 > 0: 'COMMENT 또는 REQUEST_CHANGES'}
  {P3만: 'COMMENT 또는 APPROVE'}
  {total == 0: '코멘트 없이 APPROVE 가능'}

  선택:
  - 일괄 게시 (REQUEST_CHANGES): 변경 요청과 함께 게시
  - 일괄 게시 (COMMENT): 코멘트로 게시
  - 일괄 게시 (APPROVE): 승인과 함께 게시
  - 저장만: 결과를 출력하고 게시하지 않음
  - 수정 후 게시: 전체 목록 재편집
  - 취소: 아무것도 하지 않음"
```

**일괄 게시** 선택 시 `gh api`로 단일 리뷰 이벤트를 생성한다:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/reviews \
  --method POST \
  -f event="{APPROVE|COMMENT|REQUEST_CHANGES}" \
  -f body="{review summary}" \
  --input comments.json
```

Review body 형식:
```
## Code Review

| Priority | Count |
|----------|-------|
| P1 | {n} |
| P2 | {n} |
| P3 | {n} |
```

각 인라인 코멘트 형식:
```
**[P1]** {title}

{body}
```

**저장만** 선택 시 전체 리뷰 내용을 콘솔에 출력한다.

### Phase 8: 완료 보고

```
## 리뷰 게시 완료

- PR: #{number} - {title}
- Review 이벤트: {event type}
- 게시 코멘트: P1({n}) + P2({n}) + P3({n}) = {total}건
- PR URL: {url}
```

## Error Handling

| 상황 | 대응 |
|------|------|
| PR 없음 | "PR #{number}을 찾을 수 없습니다. URL과 권한을 확인하세요." |
| 이미 merge/close된 PR | AskUserQuestion으로 계속 여부 확인 |
| 대규모 diff (>5000줄) | 핵심 파일 위주 분석, 안내 메시지 출력 |
| 발견 사항 없음 | "리뷰할 항목이 없습니다. Approve 하시겠습니까?" |
| gh api 실패 | 에러 표시, 재시도 또는 로컬 저장 제안 |
| 잘못된 PR URL 형식 | 파싱 실패 시 AskUserQuestion으로 재입력 요청 |
