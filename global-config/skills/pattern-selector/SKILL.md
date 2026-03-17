---
name: pattern-selector
description: "Unity pattern selector advisor. Use this when the user has a SPECIFIC decision between 2+ patterns (ScriptableObject vs events vs interfaces vs state machines vs object pools). Do NOT use for high-level architecture — use architecture-advisor instead."
---

# Pattern Selector

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill to decide whether a pattern is justified. **Recommend at most 1-3 patterns**, and explain why simpler options are not enough.

## Pattern Guide

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **ScriptableObject** | Authored config, shared data, event channels | Per-run mutable gameplay state |
| **C# events/delegates** | One-to-many notifications with clear ownership | Flows needing ordering or return values |
| **Global event bus** | Many systems need broad decoupled notifications | Default answer to coupling (hides ownership) |
| **Interfaces** | Multiple implementations or dependency boundaries | Wrapping every class without a real seam |
| **State machine** | Mutually exclusive states with explicit transitions | A few booleans or small command flow suffice |
| **Object pool** | Frequent spawn/despawn (bullets, VFX, UI) | Rare objects with simple lifetime |
| **Service layer** | Cross-scene systems with explicit bootstrap | Turning everything into hidden singletons |
| **Generics** | Removing repeated boilerplate with type safety | Making gameplay code harder to read |

## Output Format

- Recommended pattern(s) (max 3)
- Why they fit this case
- Why not the simpler alternative
- Minimal implementation boundary
- Known tradeoffs

## Related Skills
- `@architecture-advisor` - Project-level architecture guidance
- `@design-patterns` - GoF pattern implementations
- `@scriptableobject-architecture` - SO-specific patterns
