---
name: tdd-eval
description: |
  TDD 산출물 자동 평가(Eval) 프레임워크.
  구조화된 루브릭으로 산출물 품질을 자가 평가하고 ralph-loop으로 threshold까지 반복 개선.
globs:
  - ".claude/docs/*/tdd-session.yaml"
---

# TDD Eval Framework

## 개요

각 TDD 단계의 산출물을 **구조화된 루브릭**으로 자가 평가하고, threshold 미달 시 ralph-loop으로 자동 반복 개선한다. Human Review에 도달하기 전에 기본 품질을 보장하는 것이 목표.

## 채점 방식

**Counting(카운팅)**: 비율 기반 점수. `weight × (충족 수 / 전체 수)`.
**LLM 정성 평가**: Likert 0-5 척도 기반. `weight × (Likert / 5)` 또는 `(weight/5) × Likert`.

## Likert 채점 기준 (0-5)

| 점수 | 의미 | 판단 기준 |
|------|------|----------|
| 0 | 완전 미달 | 기준을 전혀 충족하지 못함 |
| 1 | 심각한 결함 | 대부분의 항목에서 문제 |
| 2 | 부분적 충족 | 절반 이상 문제, 대폭 수정 필요 |
| 3 | 기본 충족 | 핵심은 맞지만 개선 여지 있음 |
| 4 | 양호 | 사소한 개선점만 존재 |
| 5 | 우수 | 개선할 것 없음 |

## 정성 평가 시 필수 규칙

1. **채점 근거 명시**: 점수와 함께 1-2문장 근거를 반드시 기록
2. **구체적 문제 지적**: 3점 이하일 때 수정해야 할 구체적 항목 나열
3. **일관성**: 같은 iteration 내에서 채점 기준이 바뀌지 않도록 rubric을 매 iteration 시작 시 re-read

## eval_result 스키마

```yaml
eval_result:
  stage: "tdd:spec"          # 단계 식별자
  iteration: 1               # 현재 iteration 번호
  dimensions:
    - name: "AC Completeness"
      score: 18
      max: 20
      type: "quantitative"   # quantitative | qualitative
      details: "9/10 Solution 항목 커버"
    - name: "TC 의도 명확성"
      score: 16
      max: 20
      type: "qualitative"
      likert: 4
      rationale: "대부분 단일 행동 검증, TC#5의 Then이 2개 결과 동시 확인"
      gap: "TC#5: Then 절 분리 필요"  # 3점 이하일 때만
  total: 85
  threshold: 80
  passed: true
  failing_dimensions:         # passed=false일 때만
    - name: "Boundary Coverage"
      gap: "엣지 케이스 누락: 빈 장바구니, 수량 오버플로우"
```

## 루브릭 참조

각 단계별 루브릭은 개별 reference 파일에 정의:

- `references/spec.md` — tdd:spec
- `references/design.md` — tdd:design
- `references/issues.md` — tdd:issues
- `references/red.md` — tdd-red
- `references/visual.md` — tdd-visual
- `references/integrate.md` — tdd-integrate
