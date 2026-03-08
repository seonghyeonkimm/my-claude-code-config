# tdd-visual — Visual Matching Quality Rubric

**Threshold**: 80/100 · **Promise**: `VISUAL_MATCH` (기존) · **Max iterations**: 5 (기존)

| Dimension | Weight | Type | Scoring | 방법 |
|-----------|--------|------|---------|------|
| 레이아웃 | 25 | LLM 정성 | `5 × Likert(0-5)` | 배치·정렬·크기가 Figma와 일치? |
| 색상 | 25 | LLM 정성 | `5 × Likert(0-5)` | 배경·텍스트·보더 색상 일치? |
| 타이포그래피 | 25 | LLM 정성 | `5 × Likert(0-5)` | 폰트·사이즈·weight 일치? |
| 간격 | 25 | LLM 정성 | `5 × Likert(0-5)` | padding·margin·gap 일치? |

기존 ralph-loop의 비교 분석 단계에서 4개 dimension을 Likert 채점.
모든 dimension Likert 4+ (total >= 80) → `<promise>VISUAL_MATCH</promise>`.
Likert 3 이하인 dimension → 해당 항목만 집중 수정.
