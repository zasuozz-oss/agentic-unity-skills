---
description: Run the Logic Audit Checklist against a Unity project to verify C# script logic correctness — state management, race conditions, null safety, resource pairing, async lifecycle guards, event symmetry, error handling, pagination flow, and data integrity.
---

# Logic Verify Workflow

Verify code logic correctness using the `unity-logic-audit` skill.

## Steps

1. **Activate the skill**
   - Read `.agents/skills/unity-logic-audit/SKILL.md` to load the full checklist.

2. **Identify scope**
   - Ask the user which scripts, namespaces, or folders to audit.
   - If unspecified, audit the entire `Assets/Scripts` directory.

3. **Copy checklist to task.md**
   - Copy all checklist items from the skill into `task.md` as a working checklist.
   - Mark all items `[ ]` initially.

4. **Execute audit — section by section**
   - Work through each section in order (1→12).
   - For each item:
     - Search the codebase for violations using `grep_search` and `view_file`.
     - Mark `[x]` if passed, `[!]` if violation found, `[~]` if not applicable.
     - For `[!]` items: note the specific file, line number, and recommended fix.

5. **Generate report**
   - Create an artifact `logic-verify-report.md` summarizing:
     - Total items checked / passed / violations / N/A
     - All `[!]` violations grouped by severity (🔴 Critical → 🟡 High → 🟢 Low)
     - File paths, line numbers, and fix recommendations for each violation
     - Priority ranking (crash/stuck-state risks first)

6. **Present to user**
   - Use `notify_user` to share the report for review.
