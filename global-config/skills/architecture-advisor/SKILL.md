---
name: architecture-advisor
description: "Unity architecture decision advisor. Use this when the user needs architecture guidance, wants to avoid over-engineering, needs to choose between patterns, or is designing system boundaries."
---

# Architecture Advisor

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill when architecture decisions need practical guidance with guardrails against over-engineering.

## Core Principle

**Right-size the architecture.** Do not default to the most sophisticated pattern. Match complexity to the actual problem.

## Decision Framework

1. **What is the actual problem?** Not the theoretical future problem.
2. **What is the simplest solution that works?** Start here.
3. **What evidence suggests more abstraction is needed?** Must be concrete.
4. **What is the cost of changing later?** Often lower than assumed.

## Architecture Tiers

| Project Size | Recommendation |
|-------------|----------------|
| Prototype / Jam | MonoBehaviour + SO config. No patterns. |
| Small (1-2 devs) | Events + simple services. Maybe 1 abstraction layer. |
| Medium (3-5 devs) | Interfaces for hot seams. asmdef boundaries. Clear folder structure. |
| Large (5+) | DI container, layered architecture, strict module boundaries. |

## Anti-Over-Engineering Guardrails

- ❌ Don't add DI container to a jam project
- ❌ Don't wrap every class in an interface "just in case"
- ❌ Don't create 5 abstraction layers for 3 scripts
- ❌ Don't use event bus when 2 scripts talk to each other
- ❌ Don't architect for "someday maybe" requirements

## Output Format

- Current project size/phase assessment
- Recommended architecture tier
- Specific patterns justified for THIS project
- Patterns explicitly NOT recommended yet
- Migration path if scope grows

## Related Skills
- `@pattern-selector` - Which specific pattern to use
- `@project-scout` - Inspect existing project before advising
- `@adr-records` - Document architecture decisions
