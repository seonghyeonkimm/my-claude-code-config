# tdd-red — Test Quality Rubric

**Threshold**: 80/100 · **Promise**: `EVAL_PASSED_RED` · **Max iterations**: 3

| Dimension | Weight | Type | Scoring | 방법 |
|-----------|--------|------|---------|------|
| Assertion 구체성 | 20 | 카운팅 | `20 × (구체적 assertion / 전체 assertion)` | placeholder 패턴 grep |
| 행동 중심 네이밍 | 20 | 카운팅 | `20 × (행동 설명 테스트명 / 전체 테스트명)` | anti-pattern grep |
| TC 매핑 완전성 | 20 | 카운팅 | `20 × min(1, 실제테스트수 / 입력TC수)` | 개수 비교 |
| 실패 모드 | 20 | 카운팅 | assertion failure면 20, import/syntax error면 0 | 러너 출력 파싱 |
| 테스트 의도 읽힘성 | 20 | LLM 정성 | `4 × Likert(0-5)` | "무엇을 보호하는 테스트인지" 바로 이해? mock 과도하지 않은가? |

## 채점 로직

```pseudo
# Assertion 구체성
placeholder_patterns = ["expect(true).toBe(false)", "expect(1).toBe(2)", "TODO", "FIXME"]
total_assertions = 전체 expect/assert 호출 수
placeholder_count = placeholder_patterns 매칭 수
score_assert = 20 × ((total_assertions - placeholder_count) / total_assertions)

# 행동 중심 네이밍
anti_patterns = ["test 1", "test 2", "should work", "renders", "렌더링한다"]
total_tests = 전체 it/test 블록 수
bad_names = anti_patterns 매칭 수
score_naming = 20 × ((total_tests - bad_names) / total_tests)

# TC 매핑 완전성
input_tc_count = 입력으로 받은 TC 수
actual_test_count = 생성된 테스트 블록 수
score_mapping = 20 × min(1, actual_test_count / input_tc_count)

# 실패 모드
test_output = 테스트 러너 출력
if "SyntaxError" or "Cannot find module" or "import" error:
  score_fail_mode = 0
elif "AssertionError" or "expect" failure:
  score_fail_mode = 20
else:
  score_fail_mode = 10  # 불명확

# 테스트 의도 읽힘성 (LLM Likert)
likert = LLM이 0-5 채점 (근거 필수)
score_intent = 4 × likert
```
