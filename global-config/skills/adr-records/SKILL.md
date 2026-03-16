---
name: adr-records
description: "Architecture decision record helper. Use this when the user needs to compare options, lock in a design choice, or keep decisions consistent across multiple sessions."
---

# Architecture Decision Records

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this when architecture choices may be revisited later or when multiple plausible options exist.

## Output Format

- **Decision**: What was decided
- **Context**: Why this decision is needed now
- **Options considered**: What alternatives were evaluated
- **Chosen option**: The selected approach
- **Why this option won**: Concrete justification
- **Consequences**: What this enables and constrains
- **Revisit triggers**: When to reconsider this decision

## Example Use Cases

- Coroutine vs UniTask
- Direct reference vs event-driven communication
- ScriptableObject config vs in-scene authoring
- One assembly vs multiple `asmdef`
- Runtime logic in MonoBehaviour vs pure C# service
- DI container vs manual injection

## Guardrails

- Keep ADRs short — one page maximum
- Record only decisions that materially affect code generation or architecture
- Include revisit triggers so future sessions know when to reconsider

## Related Skills
- `@architecture-advisor` - Architecture guidance
- `@pattern-selector` - Pattern comparison
