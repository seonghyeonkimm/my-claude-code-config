---
name: code-dojo
description: >
  Interactive code learning through skeleton-based exercises. Use when a user wants to
  deeply learn a codebase, library, or programming concept by building it themselves.
  Triggers: "learn this codebase", "study this project", "teach me how this works",
  "I want to understand this library", "code dojo", "learn by building",
  "help me learn", "interactive coding exercise". Creates step-by-step exercises
  where the user fills in TODO implementations verified by tests or type checks.
---

# Code Dojo: Interactive Code Learning

Turn any codebase or concept into hands-on exercises where the learner writes the code.

## Core Principle

**The learner must write the code, not read it.** Claude provides:
- Skeleton files with `// TODO` blanks for core logic
- Tests or type checks that verify correctness
- Conceptual hints (never answers)

## Workflow

### Phase 1: Explore

Analyze the target codebase to identify teachable concepts. Use the Explore agent to understand:
- Architecture and key abstractions
- Dependency order between concepts (what must be understood first)
- Core algorithms vs. boilerplate

Produce a **learning path**: ordered list of concepts, smallest-first.

### Phase 2: Generate Exercises

For each step in the learning path, create two files:

**Skeleton file** (`mini/stepN.ts` or appropriate extension):
- Working surrounding code (imports, types, exports)
- `// TODO: ...` at each location the learner must implement
- A conceptual hint block above each TODO (see Hint Guidelines below)

**Test file** (`mini/stepN.test.ts` or appropriate):
- Covers both happy path and edge cases
- Tests are ordered from simple to complex
- Each test name describes the expected behavior in the learner's language

### Phase 3: Interactive Loop

```
1. Present the step: explain what concept this covers and why
2. Learner edits the skeleton
3. Run tests (or type check), show results
4. If failures: point to the failing test name and the relevant concept, not the fix
5. If all pass: give brief feedback on their approach, then present next step
```

## Hint Guidelines

Hints must teach the *concept*, not give the *answer*.

Bad hint (too direct):
```
// Hint: T extends string ? true : false
```

Good hint (teaches the tool):
```
// Key concept: conditional types use the same structure as ternary operators.
//   A extends B ? C : D
//   "If A is assignable to B, then C, else D"
```

Bad hint (gives the code):
```
// Hint: return Object.keys(pattern).every(k => k in value && matchPattern(...))
```

Good hint (points to the building blocks):
```
// You need to check every key in the pattern.
// Useful tools: Object.keys(), the `in` operator, Array.every()
```

Rules for hints:
- Name the relevant APIs/types/operators, but do not show how to compose them
- For type-level exercises, explain the *behavior* of a feature, not the syntax to use
- If a step builds on a previous step, reference that: "This has the same structure as Step N"
- Maximum 3 lines per hint

## Step Design Rules

1. **One concept per step.** Never combine unrelated ideas.
2. **Each step builds on the previous.** Import or copy from earlier steps when needed.
3. **Start with runtime, then types.** Concrete behavior before abstract type machinery.
4. **Skeleton compiles.** The TODO version must not have syntax errors. Use `return false`, `return undefined as any`, or `type X = unknown` as placeholders.
5. **Tests run against the skeleton.** They should fail (not error) so the learner sees red-to-green.
6. **3-8 TODOs per step.** Fewer than 3 is trivial; more than 8 is overwhelming.
7. **Edge case tests last.** Put the simplest, most illustrative test first.

## Feedback Style

When the learner submits their implementation:
- Run tests immediately, show the output
- If all pass: one sentence of specific feedback (not generic praise), then move on
- If some fail: quote the failing test name, explain what concept it is testing, let them try again
- If stuck (asked for help): give one more conceptual hint. If still stuck, show the approach in pseudocode (not real code). Only show real code as a last resort.

## Adapting Difficulty

- If the learner solves steps quickly with no failures: combine steps or skip ahead
- If the learner struggles: break the current step into smaller sub-steps
- If the learner asks "why": pause exercises and explain the design decision, then resume

## Exercise File Organization

Place all exercise files in a `mini/` directory within the project:

```
project/
  mini/
    step1.ts        # Skeleton
    step1.test.ts   # Tests
    step2.ts
    step2.test.ts
    ...
```

## Language Support

The skeleton/test format adapts to the project language:
- **TypeScript**: Jest tests + `tsc --noEmit` for type exercises
- **Python**: pytest tests
- **Go**: `go test` with table-driven tests
- **Rust**: `cargo test` with `#[test]` functions

For type-level exercises (TypeScript), use compile-time assertions:
```typescript
type Expect<T extends true> = T;
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false;
// Test: type _t = Expect<Equal<MyType<Input>, Expected>>;
```
Verify with `tsc --noEmit --strict` instead of Jest.
