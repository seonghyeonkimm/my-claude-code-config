---
name: techspec-common
description: |
  FE/BE TechSpec 공통 작성 가이드. Summary, Solution, AC, FR(GWT), Verification 등 공통 섹션의 작성 규칙.
  Use when: TechSpec 작성, 기술 명세서 생성, Acceptance Criteria 작성 시 공통 규칙 참조.
  FE 전용 가이드는 `fe-techspec`, BE 전용 가이드는 `be-techspec` 스킬 참조.
---

# TechSpec 공통 가이드

**관련 스킬:**
- `fe-techspec` - 프론트엔드 전용 (NFR, Design, Component)
- `be-techspec` - 백엔드 전용 (NFR, Design, Module & Layer)
- `entity-object-pattern` - 구현 시 반복되는 도메인 로직을 Entity Object로 그룹화
- `test-case-design` - Given/When/Then 작성 규칙, assertion 규칙

## 공통 섹션 작성 가이드

### Summary

프로젝트 배경과 맥락. PRD 링크 포함.

```markdown
## Summary

{프로젝트 배경 1-3문장}

- **PRD**: {Notion URL}
```

### Solution

비즈니스 관점에서 핵심 변경사항을 요약. 기술 용어 없이 "무엇이 어떻게 바뀌는가"에 집중.

**작성 규칙:**
- 코드, API명, 타입명, 테이블명 사용 금지
- 사용자/비즈니스 관점에서 서술
- 3-5개 핵심 변경사항을 번호 매기기 형식으로 나열

### Acceptance Criteria

기능 동작의 최소 기준. 테스트 가능한 형태로 작성.

- 측정 가능하고 검증 가능한 문장으로 작성
- "빠르게", "잘" 같은 모호한 표현 금지
- 핵심 플로우별 1개 이상

### Functional Requirements (Given/When/Then)

테스트 케이스를 구조화된 테이블로 정의. `test-case-design` 스킬의 규칙을 따른다.

- Entity/Command 헤더 없이 테이블만 작성

### Verification

테스트 케이스 검증 전략.

**우선순위:**
1. **Integration Tests (필수)**: TC 기반 통합 테스트
2. **Unit Tests (필요 시)**: 복잡한 로직만
3. **E2E Tests (필요 시)**: 전체 플로우 검증

## 흔한 실수와 해결책 (공통)

| 문제 | 원인 | 해결 |
|------|------|------|
| AC가 모호함 | "빠르게", "잘" 같은 추상적 표현 | 측정 가능한 기준 사용 |
| Given/When/Then 불명확 | 상태/행동/결과 구분 없음 | Given=상태, When=행동, Then=검증 가능한 결과 |
| Test Case 누락 | 정상 케이스만 작성 | 에러/엣지 케이스 반드시 포함 |
| NFR 생략 | 선택사항이라 무시 | 해당 프로젝트 특성에 맞게 필수 검토 |
| Solution에 코드 포함 | "기술적 해결책"으로 오해 | 비기술 요약으로 작성 |
| Optimization Checklist 전부 채움 | RADIO 원칙 오해 | TC/NFR에서 도출된 항목만 기록 |
| Verification 누락 | 선택사항으로 오인 | Integration Test 필수 |
