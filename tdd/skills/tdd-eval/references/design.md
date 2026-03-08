# tdd:design — Design Quality Rubric

**Threshold**: 75/100 · **Promise**: `EVAL_PASSED_DESIGN` · **Max iterations**: 3

| Dimension | Weight | Type | Scoring | 방법 |
|-----------|--------|------|---------|------|
| TC→Usecase 매핑 | 15 | 카운팅 | `15 × (Usecase에 매핑된 When / 고유 When수)` | When → Usecase 테이블 대조 |
| Data Model 커버리지 | 15 | 카운팅 | `15 × (interface가 있는 엔티티 / 고유 엔티티)` | Given/Then 명사 → 데이터 모델 대조 |
| Usecase-Component 연결 | 15 | 카운팅 | `15 × (Integration에 있는 Usecase / 전체 Usecase)` | Integration 테이블 대조 |
| Interface Contract | 15 | 카운팅 | `15 × (정의된 계약 / 기대 계약)` | hook/Props 존재 확인 |
| YAGNI | 15 | 카운팅 | `15 × (TC 근거가 있는 항목 / 전체 설계 항목)` | TC# 참조 확인 |
| 설계 응집도 | 25 | LLM 정성 | `5 × Likert(0-5)` | 단일 책임? Container↔Presentational 명확? 데이터 흐름 단방향? 순환 의존 없음? 인지 부하 적절? |

## 채점 로직

```pseudo
# TC→Usecase 매핑
unique_whens = TC의 고유 When 절 수
mapped_whens = Usecase 테이블에 대응되는 When 수
score_uc = 15 × (mapped_whens / unique_whens)

# Data Model 커버리지
entities = Given/Then에서 추출한 고유 명사(엔티티)
modeled = Design의 데이터 모델에 interface가 있는 엔티티 수
score_dm = 15 × (modeled / len(entities))

# Usecase-Component 연결
total_uc = 전체 Usecase 수
integrated_uc = Integration 테이블에 나열된 Usecase 수
score_int = 15 × (integrated_uc / total_uc)

# Interface Contract
expected_contracts = Usecase 수 + Presentational 컴포넌트 수 (hook + Props)
defined_contracts = 실제 정의된 hook/Props Interface 수
score_contract = 15 × (defined_contracts / expected_contracts)

# YAGNI
total_design_items = 데이터 모델 + Usecase + Component 수
tc_backed = TC에서 근거를 찾을 수 있는 설계 항목 수
score_yagni = 15 × (tc_backed / total_design_items)

# 설계 응집도 (LLM Likert)
likert = LLM이 0-5 채점 (근거 필수)
score_cohesion = 5 × likert
```
