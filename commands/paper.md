---
name: paper
description: 논문 탐색 → 목차/요약 제공 → Q&A 학습 → 학습 노트 저장까지 대화형 논문 학습 워크플로우
arguments:
  - name: context
    description: 논문 URL, DOI, 또는 검색 주제/키워드
    required: false
allowed-tools:
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - Read
  - Write
  - Bash
---

# Paper — 논문 학습 워크플로우

논문 발견 → 구조화된 요약 → 대화형 Q&A 학습 → 노트 저장.

```
Phase 0 ─ 입력 수집     URL/주제/없음 분기
Phase 1 ─ Discovery     WebSearch로 논문 탐색 → 선택
Phase 2 ─ Summary       목차 + 섹션별 요약 제공
Phase 3 ─ Q&A           인터랙티브 학습 루프
Phase 4 ─ Notes         학습 노트 마크다운 저장
```

## 핵심 원칙

1. **한 Phase씩 진행** — 이전 Phase 확인 후 다음으로
2. **사용자 수준에 맞춤** — 빠르면 심화, 어려우면 기초부터
3. **논문 내용 기반 답변** — 추측 금지, 모르면 WebSearch로 보충
4. **저작권 준수** — 논문 원문을 그대로 복사하지 않고 자신의 언어로 요약

## Input

- `$ARGUMENTS.context`: 논문 URL, DOI, 또는 검색 주제 (선택)

## Execution Flow

### Phase 0: 입력 수집

1. **입력 파싱**:

   | 입력 타입 | 감지 방법 | 처리 |
   |-----------|-----------|------|
   | 없음 | `$ARGUMENTS.context` 비어있음 | AskUserQuestion: "어떤 주제의 논문을 읽고 싶으세요?" |
   | 주제/키워드 | URL 패턴 아님 | Phase 1(Discovery)로 |
   | arXiv URL | `arxiv.org` 포함 | Phase 2(Summary)로 직행 |
   | Semantic Scholar | `semanticscholar.org` 포함 | Phase 2로 직행 |
   | DOI | `doi.org` 또는 `10.` 패턴 | WebFetch로 논문 페이지 접근 → Phase 2 |
   | 기타 URL | URL 패턴 | WebFetch 시도 → Phase 2 |

### Phase 1: Discovery (발견)

1. `WebSearch`로 관련 논문 검색:
   - 쿼리 전략: `{주제} research paper site:arxiv.org OR site:semanticscholar.org`
   - 추가 쿼리: `{주제} survey paper` (서베이 논문 포함)

2. 검색 결과에서 논문 5~8개 리스트 제시:

```
| # | 제목 | 저자 | 연도 | 출처 | 한 줄 요약 |
|---|------|------|------|------|------------|
| 1 | ... | ... | ... | arXiv | ... |
```

3. `AskUserQuestion`으로 읽을 논문 선택:

```
AskUserQuestion:
  questions:
    - question: "어떤 논문을 읽어볼까요?"
      multiSelect: true
      options:
        - "{제목 1}"
        - "{제목 2}"
        - ...
        - "다른 키워드로 다시 검색"
```

- "다른 키워드로 다시 검색" 선택 시 → Phase 0로 복귀
- 여러 논문 선택 시 → 첫 번째 논문부터 순서대로 Phase 2 진행

### Phase 2: Summary (요약)

1. `WebFetch`로 논문 페이지 내용 수집:
   - arXiv: `arxiv.org/abs/{id}` 페이지 fetch → abstract, 메타데이터 추출
   - arXiv HTML 버전이 있으면: `arxiv.org/html/{id}` 도 fetch하여 본문 구조 파악
   - Semantic Scholar: API 또는 페이지에서 abstract, citations 추출
   - 일반 URL: WebFetch로 본문 추출 시도
   - PDF만 있는 경우: abstract 페이지나 Semantic Scholar에서 메타데이터 수집, 본문은 제한적

2. 구조화된 요약 생성:

```markdown
## {논문 제목}

- **저자**: {저자 목록}
- **연도/학회**: {연도, 학회 또는 저널}
- **링크**: {URL}

### 핵심 요약 (3문장)
{논문의 목적, 방법, 결과를 각 1문장으로}

### 목차
1. {섹션명} — {한 줄 설명}
2. {섹션명} — {한 줄 설명}
...

### 주요 기여 (Contributions)
- {기여 1}
- {기여 2}
- {기여 3}

### 핵심 키워드
{키워드1}, {키워드2}, ...
```

3. `AskUserQuestion`으로 다음 단계 결정:

```
AskUserQuestion:
  questions:
    - question: "요약을 확인했습니다. 어떻게 진행할까요?"
      options:
        - "Q&A 학습 시작"
        - "특정 섹션을 더 자세히 보고 싶어요"
        - "다른 논문 선택"
```

- "Q&A 학습 시작" → Phase 3
- "특정 섹션을 더 자세히 보고 싶어요" → 어떤 섹션인지 추가 질문 → 해당 섹션 심화 요약 → 다시 이 질문
- "다른 논문 선택" → Phase 1로 복귀

### Phase 3: Interactive Q&A (학습)

인터랙티브 학습 루프 진입. 아래를 반복한다:

```
AskUserQuestion:
  questions:
    - question: "논문에 대해 궁금한 점이 있으세요?"
      options:
        - "특정 섹션을 자세히 설명해줘"
        - "핵심 개념을 쉽게 풀어줘"
        - "이 논문의 한계점은?"
        - "관련 논문/후속 연구는?"
        - "실무에 어떻게 적용할 수 있을까?"
        - "학습 종료"
```

**답변 가이드라인:**

- 논문 내용을 기반으로 답변. 필요시 `WebSearch`로 추가 맥락 확보
- 비유와 예시로 복잡한 개념 설명
- 관련 섹션 번호 참조 표시 (예: "섹션 3.2에서 설명하는...")
- 한 번에 너무 많은 정보를 주지 않고, 단계적으로 설명

**난이도 적응:**

- 사용자가 빠르게 이해하면 → 더 심화된 질문 유도 ("이 부분을 더 깊이 파볼까요?")
- 사용자가 어려워하면 → 기초 개념부터 단계적 설명
- "왜?"라고 물으면 → 논문의 motivation과 배경부터 설명

**"학습 종료" 선택 시** → Phase 4로 이동

### Phase 4: Notes (학습 노트 저장)

학습 종료 시 자동으로 마크다운 파일 생성.

1. **파일 위치**: `.claude/docs/paper-notes/{논문-slug}.md`
   - slug: 논문 제목에서 kebab-case 변환 (예: `attention-is-all-you-need`)

2. **노트 구조**:

```markdown
# {논문 제목}

- **저자**: {저자 목록}
- **연도**: {연도}
- **링크**: {URL}
- **학습일**: {오늘 날짜, YYYY-MM-DD}

## 핵심 요약
{Phase 2에서 생성한 3문장 요약}

## 목차 & 섹션 요약
{Phase 2에서 생성한 목차 + 섹션별 설명}

## Q&A 학습 노트
### Q: {사용자 질문 1}
{답변 핵심 내용 요약}

### Q: {사용자 질문 2}
{답변 핵심 내용 요약}
...

## 핵심 인사이트
- {학습 세션에서 도출된 주요 깨달음 3~5개}

## 관련 논문 / 후속 학습
- {Q&A 중 언급된 관련 논문이나 키워드}
```

3. 파일 저장 후:

```
AskUserQuestion:
  questions:
    - question: "학습 노트를 저장했습니다. 다른 논문도 읽어볼까요?"
      options:
        - "네, 다른 논문 탐색"
        - "아니요, 종료"
```

- "네, 다른 논문 탐색" → Phase 1로 복귀
- "아니요, 종료" → 세션 종료

## Error Handling

| 상황 | 대응 |
|------|------|
| context 인자 없음 | AskUserQuestion으로 주제 요청 |
| WebSearch 결과 부족 | 키워드 변경 제안, 일반 웹 검색으로 대체 |
| WebFetch 실패 | Semantic Scholar API로 대체, 또는 다른 소스 시도 |
| PDF만 있고 HTML 없음 | abstract/메타데이터 위주로 요약, 본문 상세 분석 한계 안내 |
| 논문 내용 접근 불가 | 사용자에게 로컬 PDF 경로 제공 요청 (Read로 읽기) |

## Example

```
사용자: /paper attention mechanism in transformers

Claude: [Phase 1] WebSearch로 관련 논문을 검색합니다...

  | # | 제목 | 저자 | 연도 |
  |---|------|------|------|
  | 1 | Attention Is All You Need | Vaswani et al. | 2017 |
  | 2 | BERT: Pre-training of... | Devlin et al. | 2019 |
  | ...

  어떤 논문을 읽어볼까요? [AskUserQuestion, multiSelect]

사용자: 1번 선택

Claude: [Phase 2] 논문을 분석합니다...

  ## Attention Is All You Need
  - 저자: Vaswani et al.
  - 핵심 요약: ...
  - 목차:
    1. Introduction — 기존 seq2seq의 한계
    2. Background — attention 메커니즘 배경
    ...

  어떻게 진행할까요? [AskUserQuestion]

사용자: Q&A 학습 시작

Claude: [Phase 3] 논문에 대해 궁금한 점이 있으세요? [AskUserQuestion]

사용자: self-attention이 뭐야?

Claude: Self-attention은... (비유와 예시로 설명)
  논문에 대해 또 궁금한 점이 있으세요?

사용자: 학습 종료

Claude: [Phase 4] 학습 노트를 저장합니다...
  파일: .claude/docs/paper-notes/attention-is-all-you-need.md
  다른 논문도 읽어볼까요?
```
