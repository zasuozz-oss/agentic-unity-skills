---
name: scene-contracts
description: "Scene composition contract advisor. Use this when the user needs to define required scene objects, component dependencies, bootstrap sequences, reference wiring, or scene validation rules."
---

# Scene Contracts

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill when scene setup needs to be explicit instead of relying on hidden runtime lookups.

## Define

- Required root objects and their components
- Which references are assigned in Inspector vs resolved at runtime
- Which objects act as bootstrap/installers
- Which objects are runtime-spawned
- Which assumptions should be validated early

## Output Format

- Scene object contract (table of required objects + components)
- Bootstrap sequence (ordered initialization)
- Inspector wiring rules
- Validation rules (`OnValidate`, runtime checks)
- Hidden dependency risks

## Guardrails

- Prefer explicit scene wiring over chains of runtime `Find`
- Keep bootstrap objects small and focused
- Validate early — fail fast with clear error messages
- Don't over-specify — only contract what actually matters

## Related Skills
- `@project-scout` - Inspect existing project structure
- `@architecture-advisor` - System-level architecture
