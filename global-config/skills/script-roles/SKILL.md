---
name: script-roles
description: "Script role planner. Use this when the user needs to decide which scripts should be MonoBehaviour bridges, ScriptableObject configs, pure C# services, presenters, or installers before batch code generation."
---

# Script Roles

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill before creating a batch of gameplay scripts. Turn a rough script list into explicit roles so AI does not generate everything as MonoBehaviour.

## Common Roles

| Role | When to Use |
|------|-------------|
| **MonoBehaviour bridge** | Needs Transform, collisions, or Unity lifecycle |
| **ScriptableObject config** | Authored data, shared between instances |
| **Pure C# service** | Stateless logic, testable without Unity |
| **Presenter / Controller** | Bridges domain logic to UI or visuals |
| **State / FSM node** | Discrete state in a state machine |
| **Installer / Bootstrap** | Scene setup, dependency wiring |

## Output Format

- Script name
- Recommended role
- Main responsibility
- Main dependencies
- Why this role fits better than alternatives

## Guardrails

- Do not make every class a MonoBehaviour
- Do not force ScriptableObject onto runtime state that should stay in memory-only objects
- Prefer the simplest role that satisfies the requirement

## Related Skills
- `@architecture-advisor` - Project-level architecture
- `@design-patterns` - Pattern implementations
- `@testability-advisor` - Testability considerations
