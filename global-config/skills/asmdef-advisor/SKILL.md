---
name: asmdef-advisor
description: "Assembly definition advisor. Use this skill whenever the user mentions asmdef, assembly definitions, compile times, circular dependencies, editor/runtime separation, or module boundaries in Unity. Also trigger for: 'my project compiles slowly', 'how do I isolate tests', 'editor scripts bleeding into runtime', or any question about structuring Unity assemblies."
---

# Assembly Definition Advisor

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
## Few-Shot Examples

### Example 1: Should I Add asmdef?
**User**: "My project has 200 scripts across 5 systems, compile times are slow."

**Agent**:
Justified: Yes — 5 domains + slow compile = clear asmdef benefit.
Proposed assemblies:
  - Game.Core (runtime, no dependencies)
  - Game.Audio (runtime, depends on Core)
  - Game.UI (runtime, depends on Core)
  - Game.Editor (editor only, depends on all runtime)
  - Game.Tests (test, depends on Core)
Dependency direction: Core ← Audio, UI ← Editor
Migration: Start with editor/runtime split first, then domain boundaries.

### Example 2: Circular Dependency
**User**: "I'm getting a circular assembly reference error."

**Agent**:
Problem: Assembly A depends on B, B depends on A — not allowed.
Fix options:
  1. Extract shared types into Game.Core (no dependencies)
  2. Use interfaces in Core, implementations in separate assemblies
  3. Merge A and B if boundary isn't meaningful
Recommended: Option 1 — move shared models/interfaces to Core assembly.

## Typical Assembly Structure

| Assembly | Type | Depends On |
|----------|------|------------|
| Game.Core | Runtime | (none) |
| Game.Audio | Runtime | Core |
| Game.UI | Runtime | Core |
| Game.Gameplay | Runtime | Core, Audio |
| Game.Editor | Editor | All runtime |
| Game.Tests | Test | Core |

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
