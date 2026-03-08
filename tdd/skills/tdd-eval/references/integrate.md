# tdd-integrate — QA Quality Rubric

**Threshold**: 80/100 · **Promise**: `QA_PASSED` (기존) · **Max iterations**: 5 (기존)

| Dimension | Weight | Type | Scoring | 방법 |
|-----------|--------|------|---------|------|
| AC 기준 통과율 | 30 | 카운팅 | `30 × (통과 AC / 전체 AC)` | AC 체크리스트 pass/fail |
| TC 시나리오 통과율 | 30 | 카운팅 | `30 × (통과 TC / 전체 TC)` | TC 체크리스트 pass/fail |
| 검증 깊이 | 20 | LLM 정성 | `4 × Likert(0-5)` | 실제 테스트 실행·브라우저 확인까지 했는가? 표면적 확인이 아닌 실질적 동작 확인인가? |
| 수정 안전성 | 20 | 카운팅 | `20 × (수정 후 테스트 통과 / 수정 후 전체 테스트)` (수정 없으면 20) | 테스트 결과 |

기존 ralph-loop의 결과 판정 단계에서 eval_result 산출.
`total >= 80 AND 모든 AC/TC 통과` → `<promise>QA_PASSED</promise>`.
