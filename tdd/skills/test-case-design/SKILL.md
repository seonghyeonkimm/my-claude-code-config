---
name: test-case-design
description: |
  테스트 케이스 설계 규칙: 중복 방지, 경계 조건, Given/When/Then 작성, assertion 품질.
  Use when: 테스트 케이스 작성, test case design, 테스트 설계,
  Given/When/Then 작성, 테스트 코드 리뷰 시 중복 케이스 판단.
globs:
  - "**/*.test.{ts,tsx,js,jsx}"
  - "**/*.spec.{ts,tsx,js,jsx}"
---

# 테스트 케이스 설계 규칙

## 1. 중복 방지

각 케이스가 **고유한 경계 조건이나 행위**를 검증하는지 확인한다.
동일한 코드 경로를 통과하는 케이스가 여러 개면 대표 1개만 남긴다.

### 예시

`Math.ceil(value / 100) * 100` 올림 함수의 경우:

- `1 → 100`과 `99 → 100`은 동일 경계(0 < x < 100). 하나만 유지
- `101 → 200`과 `15432 → 15500`은 동일 경계(100의 배수가 아닌 값). 하나만 유지
- 유지할 케이스: `0 → 0` (항등), `99 → 100` (올림), `100 → 100` (경계 정확히), `15432 → 15500` (일반), `-50 → 0` (음수)

## 2. Given/When/Then 작성 순서

- **정상 케이스 → 에러 케이스 → 엣지 케이스** 순서로 나열
- Given은 **상태/조건**, When은 **행동/이벤트**, Then은 **검증 가능한 결과**
- Entity/Command 헤더 없이 테이블만 작성

## 3. Assertion 품질 규칙

### Placeholder 금지

각 assertion은 테스트 대상의 출력/상태/부수효과를 **직접 검증**해야 한다:
- ❌ `expect(true).toBe(false)`, `expect(1).toBe(2)` 등 placeholder
- ❌ `TODO`, `FIXME` 주석으로 assertion 대체
- ✅ `expect(result.error).toBeDefined()`, `expect(onSubmit).toHaveBeenCalledWith(...)`

### 행동 중심 네이밍

- ❌ `test 1`, `test 2`, `should work`, `renders`, `렌더링한다`
- ✅ 구체적 행동과 결과를 설명: `광고가 없을 때 클릭하면 onCreateAd가 호출된다`
- `describe`/`it`/`test` 설명은 **한국어**로 작성 (프로젝트 컨벤션에 따름)
- TC#, TC1 등 번호 접두사 금지 — 행동 설명만

### UI 테스트 가이드

- UI 렌더링 자체를 검증하는 테스트 지양. **사용자 행동**(클릭, 입력)과 그 **결과**(핸들러 호출, 상태 변경)를 검증하는 통합 테스트 위주
- ❌ `it('RecommendCreateAd를 렌더링한다')`
- ✅ `it('광고가 없을 때 클릭하면 onCreateAd가 호출된다')`

### Mocking 최소화

외부 API, 타이머 등 **제어 불가능한 의존성**만 mock:
- 가능하면 의존성 주입(DI)으로 실제 구현 활용
- 예: DB 대신 in-memory repository 주입, API client 대신 fake client 주입
