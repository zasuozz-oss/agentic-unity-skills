---
name: asmdef-advisor
description: "Assembly definition advisor. Use this when the user needs module boundaries, faster compile times, editor/runtime/test assembly separation, or asmdef dependency guidance."
---

# Assembly Definition Advisor

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill when the project is large enough that compile boundaries and dependency direction matter.

## Recommend Only When Worth It

`asmdef` is usually worth discussing when:
- The project has multiple domains/systems
- Editor code and runtime code are mixed
- Compile times are becoming noticeable
- Tests should be isolated cleanly

## Default Guidance

- Prefer a few meaningful assemblies over many tiny ones
- Split editor code from runtime first
- Keep the dependency graph directional and shallow

## Output Format

- Whether `asmdef` is justified now
- Proposed assemblies (with dependency direction)
- Editor/runtime/test split
- Migration steps
- Risks or churn to avoid

## Guardrails

- Do not introduce `asmdef` fragmentation for a tiny prototype
- Do not create circular dependencies
- Do not force everything through a shared dumping-ground assembly

## Related Skills
- `@architecture-advisor` - Project-level architecture
- `@project-scout` - Inspect existing structure
