# GitHub CLI 계정 관리

## 계정 매핑
사용자는 두 개의 GitHub 계정을 사용한다:
- `seonghyeonkimm` — 개인 리포지토리 (seonghyeonkimm/*)
- `roger_karrot` — 회사 리포지토리 (karrot-emu/* 등 그 외 모든 org)

## gh 명령어 실행 전 필수 확인
`gh pr create`, `gh pr view`, `gh api` 등 gh CLI 명령어 실행 전:
1. **GITHUB_TOKEN 환경변수 확인 (최우선)**: `echo $GITHUB_TOKEN`으로 설정 여부 확인. 설정되어 있으면 gh CLI는 이 토큰만 사용하고 `gh auth switch`를 무시하므로, 이후 모든 `gh` 명령어 앞에 `unset GITHUB_TOKEN &&`를 붙여 실행
2. `git remote get-url origin`으로 리포 소유자 확인
3. 소유자가 `seonghyeonkimm`이면 → `seonghyeonkimm` 계정 필요
4. 그 외 → `roger_karrot` 계정 필요
5. `gh api user --jq '.login'`으로 현재 활성 계정 확인 (GITHUB_TOKEN이 있었다면 unset 후 확인)
6. 불일치 시 `gh auth switch -u {올바른_계정}` 실행 후 진행

## PR 기본 규칙
- PR 생성 시 명시적 요청이 없으면 **draft PR**로 생성
- 사용자가 "ready", "review open" 등을 명시하면 ready-for-review로 생성
- "기존 PR에 푸시"라고 하면 새 PR 생성하지 않고 해당 브랜치에 push
