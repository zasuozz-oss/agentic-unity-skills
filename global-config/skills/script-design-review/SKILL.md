---
name: script-design-review
description: "Unity script quality reviewer. Use this when the user wants script design feedback, responsibility analysis, coupling review, lifecycle safety checks, or inspector UX improvements."
---

# Script Design Review

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill to review a Unity C# script for quality, responsibility, and maintainability.

## Review Checklist

### 1. Responsibility
- Does the script have one clear reason to change?
- Is the class name accurate to what it actually does?
- Could any method live in a different class?

### 2. Coupling
- Are dependencies injected or hard-wired?
- Does this script use `Find`, `GetComponent` in Update loops?
- How many other scripts does this one know about?

### 3. Lifecycle Safety
- Are event subscriptions symmetric (OnEnable/OnDisable)?
- Are coroutines stopped in OnDisable/OnDestroy?
- Are async operations guarded against destroyed objects?

### 4. Inspector UX
- Are fields organized with `[Header]` and `[Tooltip]`?
- Are tuning values constrained with `[Range]` or `[Min]`?
- Will another developer understand this from Inspector alone?

### 5. Testability
- Can core logic run without Unity APIs?
- Can config be injected instead of hardcoded?
- Is the script thin enough to not need tests itself?

## Output Format

- Responsibility verdict
- Top 3 concerns
- Suggested changes (ranked by impact)
- What's already good (reinforce)

## Related Skills
- `@testability-advisor` - Deeper testability analysis
- `@inspector-design` - Inspector UX specifics
- `@design-patterns` - Pattern recommendations
