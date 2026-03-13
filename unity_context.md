# Unity Skills — Context Configuration

@.agents/skills-unity/INDEX.md

## ⚠️ FIRST ACTION — Read the Skill Index

Before doing ANY Unity-related work, you MUST read the skill index:

```
view_file(".agents/skills-unity/INDEX.md")
```

This file lists all 70 Unity skills with descriptions organized by category. **You MUST read it to know which skills are available.**

**This is non-negotiable. Do it NOW before writing any Unity code.**

## Mandatory Skill Discovery

**You MUST find and use the matching skill for every Unity task.**

### How It Works

1. **Read INDEX.md** — scan all 70 skills and their descriptions
2. **Match your task** — find the skill whose description best matches what the user is asking
3. **Read the SKILL.md** — `view_file` on it and follow its instructions exactly
4. **If multiple skills match** — read all relevant ones, combine their guidance

### Examples

| User asks... | You should search INDEX.md for... | Likely match |
|---|---|---|
| "Add dependency injection" | DI, container, dependency | `01-architecture/di-container-manager/` |
| "Optimize for mobile" | mobile, optimization, performance | `06-performance/mobile-optimization/` |
| "Create a save system" | save, load, serialization | `02-gameplay/save-load-serialization/` |
| "Add enemy AI" | AI, behavior tree, pathfinding | `02-gameplay/ai-behavior-trees/` |
| "Fix shader issue" | shader, visual, graph | `04-visuals-audio/shader-graph-expert/` |

These are examples, NOT a fixed mapping. **Always search INDEX.md yourself.**

### Red Flags — STOP if you think any of these

- "I know Unity well enough, no need for the skill" → **WRONG.** Skills contain project-specific conventions.
- "This is basic Unity, I'll just code it" → **WRONG.** Check INDEX.md for matches first.
- "No skill matches exactly" → **LOOK HARDER.** Check related categories. If truly no match, proceed without.
- "I'll use my own C# style" → **WRONG.** Check `my-csharp-conventions` for project standards.

### How to Use Unity Skills

After finding a match in INDEX.md, read the skill:

```
view_file(".agents/skills-unity/<category>/<skill-name>/SKILL.md")
```

**If you are writing Unity code and have NOT searched INDEX.md for a matching skill, you are violating this rule.**
