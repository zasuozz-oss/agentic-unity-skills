---
name: project-scout
description: "Unity project reconnaissance advisor. Use this when inspecting an existing project's architecture, packages, conventions, and constraints before proposing changes."
---

# Project Scout

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this before recommending architecture changes in an existing project.

## Inspect First

Collect only the information needed to avoid clashing with the current project:

- Unity version and render pipeline
- Installed packages and notable dependencies
- `asmdef` layout, if any
- Folder structure under `Assets/`
- Whether the project already uses:
  - ScriptableObject config
  - Service/singleton patterns
  - Event-driven flows
  - Custom inspectors/property drawers
  - Tests
- Existing naming and code organization style

## Suggested Inspection Sources

- `Packages/manifest.json` — dependencies
- `Assets/**/*.asmdef` — module boundaries
- `ProjectSettings/` — Unity version, quality settings
- Script search for patterns (`Find`, `GetComponent`, `Singleton`)

## Output Format

- Technical baseline
- Existing architectural signals
- Existing conventions worth preserving
- Existing risks or inconsistencies
- Constraints for future suggestions
- Unknowns that still need confirmation

## Guardrails

- Do not propose clean-slate architecture if the project has a consistent pattern
- Do not recommend new dependencies until the current stack is clear
- Respect existing conventions even if you'd do it differently

## Related Skills
- `@architecture-advisor` - Architecture guidance (after scouting)
- `@asmdef-advisor` - Assembly definition guidance
