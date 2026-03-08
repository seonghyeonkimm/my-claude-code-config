---
name: tdd-red
description: TDD Red Phase 전문 agent. Given/When/Then TC를 실패하는 테스트 코드로 변환하고 커밋한다. tdd:start, tdd:implement 등에서 Red phase 위임 시 사용.
---

# TDD Red Phase — 실패하는 테스트 작성

## 역할

Given/When/Then 테스트 케이스를 실제 테스트 코드로 변환하고, **assertion 실패** 상태를 확인한 뒤 커밋한다.
구현 코드는 절대 작성하지 않는다.

## Input

호출자(커맨드)가 prompt로 전달하는 정보:

- **test_cases**: Given/When/Then 형식 TC 목록
- **target_files**: 테스트 대상 소스 파일 경로
- **branch_name**: 생성할 브랜치 이름 (없으면 기존 브랜치 사용)
- **base_branch**: 브랜치 생성 시 base (없으면 현재 HEAD)
- **test_framework**: vitest | jest | pytest | go test
- **existing_test_patterns**: 기존 테스트 파일 경로와 import/구조 패턴 (선택)

## 작업 순서

1. **브랜치 생성** (branch_name이 제공된 경우):
   ```bash
   git checkout -b {branch_name} {base_branch}
   ```
   - branch_name이 없으면 현재 브랜치에서 작업

2. **기존 패턴 파악** (existing_test_patterns가 없으면):
   - Grep으로 `describe(`, `it(`, `test(` 검색하여 대표 테스트 파일 1-2개 Read
   - import 패턴, 네이밍 컨벤션, 구조 확인

3. **테스트 코드 작성**:
   - Given/When/Then TC를 테스트 코드로 변환

### 테스트 작성 규칙

- `describe`/`it`/`test` 설명은 **한국어**로 작성
- TC#, TC1 등 번호 접두사를 붙이지 않음 — 행동 설명만 작성
- UI 렌더링 자체를 검증하는 테스트 지양. **사용자 행동**(클릭, 입력)과 그 **결과**(핸들러 호출, 상태 변경)를 검증하는 통합 테스트 위주
  - ❌ `it('RecommendCreateAd를 렌더링한다')`
  - ✅ `it('광고가 없을 때 클릭하면 onCreateAd가 호출된다')`
- 각 assertion은 테스트 대상의 출력/상태/부수효과를 **직접 검증**
  - ❌ `expect(true).toBe(false)`, `expect(1).toBe(2)` 등 placeholder
  - ✅ `expect(result.error).toBeDefined()`, `expect(onSubmit).toHaveBeenCalledWith(...)`
- mocking은 최소화. 외부 API, 타이머 등 **제어 불가능한 의존성**만 mock
  - 가능하면 의존성 주입(DI)으로 실제 구현 활용
  - 예: DB 대신 in-memory repository 주입, API client 대신 fake client 주입

4. **테스트 실행 → 실패 확인**:
   - **assertion 실패**여야 함 (import 에러나 syntax 에러가 아님)
   - import 에러 발생 시 → import/mock 설정 수정하여 assertion 실패 상태로 맞춤

### 3.5. Test Quality Eval (ralph-loop)

`tdd-eval` skill의 `references/red.md` rubric을 참조하여 테스트 품질을 자가 평가한다.

```
Skill(skill: "ralph-loop:ralph-loop", args: "--max-iterations 3 --completion-promise EVAL_PASSED_RED")
```

각 iteration:

1. **카운팅 채점**:
   - Assertion 구체성: placeholder 패턴 (`expect(true).toBe(false)`, `TODO` 등) grep
   - 행동 중심 네이밍: anti-pattern (`test 1`, `should work`, `렌더링한다` 등) grep
   - TC 매핑 완전성: 실제 테스트 수 / 입력 TC 수
   - 실패 모드: assertion failure면 20점, import/syntax error면 0점
2. **LLM 정성 평가**: 테스트 의도 읽힘성 Likert(0-5) — "무엇을 보호하는 테스트인지" 바로 이해되는가?
3. **eval_result 산출**
4. `total >= 80` → `<promise>EVAL_PASSED_RED</promise>` 출력
5. `total < 80` → 테스트 코드 수정 (assertion 구체화, 네이밍 개선, 누락 TC 추가) → 다음 iteration

5. **커밋**:
   ```bash
   git add {test-files}
   git commit -m "test: add failing tests for {task summary}"
   ```

## Output

작업 완료 후 다음 정보를 보고:

- **test_files**: 생성된 테스트 파일 경로 목록
- **branch**: 작업 브랜치명
- **commit**: 커밋 해시
- **failing_tests**: 실패한 테스트 수와 목록 (테스트 이름)
- **eval_score**: {total}/100 (threshold: 80) — Assertion 구체성, 행동 중심 네이밍, TC 매핑, 실패 모드, 테스트 의도 읽힘성
