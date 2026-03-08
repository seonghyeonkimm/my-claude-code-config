# tdd:issues — Issue Quality Rubric

**Threshold**: 80/100 · **Promise**: `EVAL_PASSED_ISSUES` · **Max iterations**: 3

| Dimension | Weight | Type | Scoring | 방법 |
|-----------|--------|------|---------|------|
| TC 커버리지 | 25 | 카운팅 | `25 × (이슈에 할당된 TC / 전체 TC)` | TC# 참조 확인 |
| 의존성 정합성 | 25 | 카운팅 | `25 × (올바른 Blocker / 전체 Blocker)` | Blocker 키워드 → Related 참조 확인 |
| 스코프 명확성 | 25 | 카운팅 | `25 × (메타데이터 완전한 이슈 / 전체 이슈)` | package_name, target_directory 존재 |
| 양방향 매핑 | 25 | 카운팅 | TC→이슈, 이슈→TC 모두 연결 | orphan 검출 |

## 채점 로직

```pseudo
# TC 커버리지
total_tc = 전체 TC 수
assigned_tc = 최소 1개 이슈에 할당된 TC 수
score_tc = 25 × (assigned_tc / total_tc)

# 의존성 정합성
total_blockers = 전체 Blocker 관계 수
valid_blockers = Blocker가 실제로 선행 필요한 관계인 수 (순환 없음, 논리적 순서)
score_dep = 25 × (valid_blockers / total_blockers)

# 스코프 명확성
total_issues = 전체 이슈 수
complete_issues = package_name AND target_directory가 있는 이슈 수
score_scope = 25 × (complete_issues / total_issues)

# 양방향 매핑
orphan_tc = 이슈에 할당되지 않은 TC 수
orphan_issue = TC 참조가 없는 이슈 수
total = total_tc + total_issues
mapped = total - orphan_tc - orphan_issue
score_bidir = 25 × (mapped / total)
```
