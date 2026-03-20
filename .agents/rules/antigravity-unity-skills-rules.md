---
trigger: always_on
---

# Workspace Rules — Antigravity Unity Skills

## What is this project

This is a **skills + workflows toolkit** for AI agents (Google Antigravity/Gemini)
working on Unity projects. This is NOT a Unity project — it is a **meta-project**
that provides knowledge for AI agents.

## Goals

- Use AI to **create and optimize** skills and workflows — quantity changes based on project needs
- Each skill = 1 `SKILL.md` file containing checklists, rules, grep patterns
- Workflows (`.md`) coordinate how AI uses skills in a standardized process
- Working loop: **Create skill → Test on real Unity project → Receive feedback
  → Optimize skill/workflow → Repeat**

## Working Loop (IMPORTANT)
```
Create / edit skill  →  Test on real project  →  Send test results  →  Optimize skill
```

When receiving test results, the AI's job is to:
- **ANALYZE** results to identify which skill/workflow is performing incorrectly
- **OPTIMIZE** the content of `SKILL.md` or workflow `.md` based on those results
- **SUGGEST** adding/removing skills if issues are detected (see section below)
- **DO NOT** fix test results, **DO NOT** fix bugs in Unity projects

> Test results = input for improving skills, not something to be fixed.

## Add / Remove Skill Process

### AI detects and suggests — user decides — AI executes

**When AI should suggest adding a new skill:**
- Detects a pattern/violation in a Unity project not covered by any existing skill
- User-provided documentation describes rules/conventions not yet captured in a skill

**When AI should suggest removing a skill:**
- Skill consistently has high false positive/negative rate across multiple test runs
- Skill is completely overlapped by another skill

**When AI should suggest splitting a skill:**
- A skill covers too many different concerns, causing false positives

**Execution process after user approval:**

| Action | Required Steps |
|---|---|
| Add new skill | Create folder + `SKILL.md` → grep repo for places needing reference → update related workflows → run test suite |
| Remove skill | Grep repo for all cross-references → remove all refs → delete folder → update related workflows → run test suite |
| Split skill | Create new skill → move relevant items → verify item count → remove old skill if needed → update all refs |

> AI **must not add/remove skills** without user confirmation.

## Structure
```
global-config/
  skills/unity-skills/    # each skill = 1 folder + SKILL.md (quantity changes based on needs)
  workflow/               # each workflow = 1 .md file (quantity changes based on needs)
bin/                      # CLI installer (npx ag-unity)
scripts/                  # Setup scripts
tests/                    # Test suite (run-tests.sh)
docs/                     # Source references
```

## Editing Rules

1. **The only valid output** is changes to `SKILL.md` or workflow `.md`
   — no other output counts as task completion
2. **Do not merge/delete checklist items** — preserve item count when combining skills
3. **Verify item count** before and after every change — `grep -c "^\- \[" SKILL.md`
4. **Cross-reference update** — when renaming/removing/adding a skill, grep the entire repo to update refs
5. **Test suite** — run `tests/run-tests.sh` after every structural change
6. **CHANGELOG.md** — log every add/remove/split skill change

## Scope

| In scope ✅ | Out of scope ❌ |
|---|---|
| Write / edit `SKILL.md` | Fix bugs in Unity project |
| Write / edit workflow `.md` | Edit game C# code |
| Analyze test results to optimize skills | Fix test results |
| Suggest adding/removing skills based on test results | Add/remove skills without user confirmation |
| Analyze user-provided documentation to identify new skills | Change Unity project structure |

## Environment

- **OS:** macOS
- **Package manager:** npm (ESM modules)
- **Target users:** AI agents (Gemini/Antigravity) working on Unity C# projects
- **Test projects:** SDU (fashion game), DU02 (Unity project)
- **MCP available:** GitNexus (code graph), Figma Bridge