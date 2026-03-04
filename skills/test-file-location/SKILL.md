---
name: test-file-location
description: |
  테스트 파일 위치 컨벤션 (Co-location / Flat).
  Use when: 테스트 파일 생성, test file creation, 테스트 파일 위치 결정,
  새 테스트 추가, __tests__ 디렉토리 여부 판단.
globs:
  - "**/*.test.{ts,tsx,js,jsx}"
  - "**/*.spec.{ts,tsx,js,jsx}"
---

# 테스트 파일 위치 컨벤션 (Flat / Co-location)

## 규칙

테스트 파일은 대상 소스 파일과 **같은 디렉토리**에 배치한다.
`__tests__/` 또는 `__test__/` 디렉토리를 새로 만들지 않는다.

## 네이밍

- `{source}.test.ts` (또는 프로젝트의 테스트 확장자)
- 소스 파일명을 그대로 사용하고 `.test` 접미사만 추가

## 예시

| 소스 파일 | 테스트 파일 (O) | 테스트 파일 (X) |
|-----------|----------------|----------------|
| `src/domain/cart.ts` | `src/domain/cart.test.ts` | `src/__tests__/cart.test.ts` |
| `src/hooks/useCart.ts` | `src/hooks/useCart.test.ts` | `__tests__/hooks/useCart.test.ts` |
| `src/components/Button.tsx` | `src/components/Button.test.tsx` | `src/components/__tests__/Button.test.tsx` |

## 예외

프로젝트에 이미 `__tests__/` 컨벤션이 확립되어 있고 기존 테스트가 모두 해당 디렉토리에 있으면 기존 컨벤션을 따른다.
