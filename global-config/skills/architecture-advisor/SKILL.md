---
name: architecture-advisor
description: "Unity architecture decision advisor. Use this FIRST when the user asks how to structure a project, design system boundaries, avoid over-engineering, or organize modules and folders. Also trigger for: 'how should I architect this', 'is this too complex', 'should I use DI', 'how many abstraction layers', or any question about project-level design decisions. Do NOT use for individual pattern choice — use pattern-selector instead."
---

# Architecture Advisor

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

## Few-Shot Examples

### Example 1: Jam Project Over-Engineering
**User**: "I'm making a 48h jam game, should I use Zenject for dependency injection?"

**Agent**:
Assessment: Prototype/Jam phase, 1 developer, 48h timeline.
Tier: MonoBehaviour + ScriptableObject config only.
Recommended: Direct references, no patterns.
Not recommended yet: DI container, event bus, interfaces.
Reason: Zenject adds 2-4h setup overhead. Zero ROI for a jam.

### Example 2: Growing Codebase
**User**: "Our 3-dev project is getting messy, managers are calling each other everywhere."

**Agent**:
Assessment: Small→Medium transition, 3 devs, scaling pain.
Tier: Medium — introduce interfaces at hot seams + asmdef boundaries.
Recommended: IEventBus for cross-manager communication, asmdef to enforce boundaries.
Not recommended yet: Full DI container (overhead not justified yet).
Migration path: Add interfaces first → enforce asmdef → evaluate DI at 5+ devs.

## Output Format

- Current project size/phase assessment
- Recommended architecture tier
- Specific patterns justified for THIS project
- Patterns explicitly NOT recommended yet
- Migration path if scope grows

## Related Skills
- `@pattern-selector` - Which specific pattern to use
- `@project-scout` - Inspect existing project before advising
- `@asmdef-advisor` - Assembly definition boundaries
