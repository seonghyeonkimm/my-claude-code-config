# tdd:spec — Spec Quality Rubric

**Threshold**: 80/100 · **Promise**: `EVAL_PASSED_SPEC` · **Max iterations**: 3

| Dimension | Weight | Type | Scoring | 방법 |
|-----------|--------|------|---------|------|
| AC Completeness | 20 | 카운팅 | `20 × (AC가 커버하는 Solution항목 / 전체 Solution항목)` | Solution 번호 → AC 텍스트 매칭 |
| TC Coverage | 20 | 카운팅 | `20 × (TC가 있는 AC / 전체 AC)` | AC별 Given/When/Then 행 존재 여부 |
| Boundary Coverage | 20 | 카운팅 | `20 × (정상+에러+엣지 모두 있는 TC그룹 / 전체 TC그룹)` | When 기준 그룹핑 → 타입 태깅 |
| TC Specificity | 20 | 카운팅 | `20 × (구체적 Then / 전체 Then)` | vague 패턴 grep |
| TC 의도 명확성 | 20 | LLM 정성 | `4 × Likert(0-5)` | 각 TC가 하나의 행동만 검증? Given/When/Then 모호하지 않은가? |

## 채점 로직

```pseudo
# AC Completeness
solution_items = Solution 섹션의 번호 매겨진 항목 수
ac_covered = AC 텍스트에서 각 Solution 항목의 키워드가 1개 이상 매칭되는 수
score_ac = 20 × (ac_covered / solution_items)

# TC Coverage
total_ac = AC 항목 수
ac_with_tc = Given/When/Then 행이 1개 이상 있는 AC 수
score_tc_cov = 20 × (ac_with_tc / total_ac)

# Boundary Coverage
tc_groups = When 기준으로 TC를 그룹핑
for each group:
  has_happy = "정상" 시나리오 존재?
  has_error = "에러"/"실패" 시나리오 존재?
  has_edge = "엣지"/"경계"/"빈"/"최대" 등 존재?
complete_groups = has_happy AND has_error AND has_edge인 그룹 수
score_boundary = 20 × (complete_groups / len(tc_groups))

# TC Specificity
vague_patterns = ["표시된다", "보인다", "나타난다", "동작한다", "처리된다"]  # 구체적 값 없이 끝나는 Then
total_then = 전체 Then 절 수
specific_then = vague_patterns에 해당하지 않는 Then 수
score_specific = 20 × (specific_then / total_then)

# TC 의도 명확성 (LLM Likert)
likert = LLM이 0-5 채점 (근거 필수)
score_intent = 4 × likert
```
