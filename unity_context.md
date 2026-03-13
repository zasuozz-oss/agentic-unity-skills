# Unity Skills — Context Configuration

@.agents/skills-unity/INDEX.md

## ⚠️ FIRST ACTION — Read the Skill Index

Before doing ANY Unity-related work, you MUST read the skill index:

```
view_file(".agents/skills-unity/INDEX.md")
```

This file lists all 70 Unity skills by category. **You MUST read it to know which skills are available.** If you skip this step, you will miss relevant skills and produce lower-quality code.

**This is non-negotiable. Do it NOW before writing any Unity code.**

## Mandatory Unity Skill Usage

**You MUST check and use Unity skills when working in a Unity project.**

### Skill Lookup Rule

After reading INDEX.md, find the matching skill for your task.
If a matching skill exists, `view_file` on its `SKILL.md` and follow it exactly.

### Mandatory Skill Triggers

| Task type | Look in category | Example skills |
|-----------|-----------------|----------------|
| Architecture / design patterns | `01-architecture/` | di-container-manager, state-machine-architect, event-bus-system |
| Gameplay systems | `02-gameplay/` | advanced-character-controller, ai-behavior-trees, save-load-serialization |
| Visual / audio / VFX | `04-visuals-audio/` | shader-graph-expert, vfx-graph-shuriken, cinemachine-specialist |
| UI implementation | `05-ui-ux/` | ui-toolkit-modern, canvas-performance, responsive-ui-design |
| Performance issues | `06-performance/` | object-pooling-system, mobile-optimization, addressables-asset-management |
| Editor tools / pipeline | `07-tools-pipeline/` | custom-editor-scripting, unity-mcp-connector |
| Backend / multiplayer | `08-backend-monetization/` | multiplayer-netcode, backend-integration |
| Build / CI/CD | `09-devops-automation/` | build-pipeline-manager |
| C# conventions / general | `unity-specific/` | my-csharp-conventions, unity-developer |

### Red Flags — STOP if you think any of these

- "I know Unity well enough, no need for the skill" → **WRONG.** Skills contain project-specific conventions.
- "This is basic Unity, I'll just code it" → **WRONG.** Check the skill for patterns and standards.
- "I'll figure out the architecture myself" → **WRONG.** Check `01-architecture/` skills first.
- "Performance isn't a concern now" → **WRONG.** Check `06-performance/` before implementation.
- "I'll use my own C# style" → **WRONG.** Check `my-csharp-conventions` for project standards.

### How to Use Unity Skills

```
view_file(".agents/skills-unity/01-architecture/di-container-manager/SKILL.md")
view_file(".agents/skills-unity/06-performance/object-pooling-system/SKILL.md")
view_file(".agents/skills-unity/unity-specific/my-csharp-conventions/SKILL.md")
```

**If you are writing Unity code and have NOT checked for a matching skill, you are violating this rule.**
