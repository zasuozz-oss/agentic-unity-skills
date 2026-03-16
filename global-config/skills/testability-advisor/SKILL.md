---
name: testability-advisor
description: "Unity testability advisor. Use this when the user wants to improve testability, isolate pure logic from Unity APIs, decide EditMode vs PlayMode tests, or reduce hard-to-test MonoBehaviour logic."
---

# Testability Advisor

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill when deciding what logic should stay in Unity-facing classes and what should move to pure C# code.

## Review Questions

- Can the rule/algorithm run without `Transform`, `GameObject`, or scene state?
- Can config be injected instead of read through static globals?
- Can runtime decisions move to a plain C# class called from a thin MonoBehaviour?
- Does this need PlayMode coverage, or is EditMode enough?

## Test Mode Selection

| Test Type | Use When | Speed |
|-----------|----------|-------|
| **EditMode** | Pure C# logic, ScriptableObject data, utility methods | Fast |
| **PlayMode** | MonoBehaviour lifecycle, physics, UI interaction, coroutines | Slow |

## Output Format

- Logic that should move to pure C#
- Logic that should stay Unity-facing
- Suggested seams/interfaces
- Candidate EditMode tests
- Candidate PlayMode tests

## Guardrails

- Do not force test seams everywhere if the script is tiny and scene-bound
- Prefer a few meaningful seams over abstraction for its own sake
- A thin MonoBehaviour that delegates to testable C# is often enough

## Related Skills
- `@automated-unit-testing` - Test implementation patterns
- `@script-design-review` - Script quality review
