---
description: Run the Scripts Verify Checklist against a Unity project to audit C# scripts for caching, GC allocations, coroutines, async/await safety, object pooling, DOTween, physics, UI code patterns, Addressables lifecycle, backend integration, debug logging, and ANR/crash prevention.
---

# Scripts Verify Workflow

Audit all code/scripting factors affecting Unity performance using the `scripts-verify-checklist` skill.

## Steps

1. **Activate the skill**
   - Read `.agents/skills/scripts-verify-checklist/SKILL.md` to load the full checklist.

2. **Identify scope**
   - Ask the user which scripts, namespaces, or folders to audit.
   - If unspecified, audit the entire `Assets/Scripts` directory.

3. **Copy checklist to task.md**
   - Copy all checklist items from the skill into `task.md` as a working checklist.
   - Mark all items `[ ]` initially.

4. **Execute audit — section by section**
   - Work through each section in order (1→21).
   - For each item:
     - Search the codebase for violations using `grep_search` and `view_file`.
     - Mark `[x]` if passed, `[!]` if violation found, `[~]` if not applicable.
     - For `[!]` items: note the specific file, line number, and recommended fix.

5. **Generate report**
   - Create an artifact `scripts-verify-report.md` summarizing:
     - Total items checked / passed / violations / N/A
     - All `[!]` violations grouped by section with file paths, line numbers, and fix recommendations
     - Priority ranking (most impactful fixes first)

6. **Present to user**
   - Use `notify_user` to share the report for review.
