---
description: Run the Asset Verify Checklist against a Unity project to audit textures, models, materials, shaders, audio, rendering settings, batching, UI canvas setup, overdraw, memory budgets, and mobile-specific asset configurations.
---

# Asset Verify Workflow

Audit all non-code asset factors affecting Unity performance using the `asset-verify-checklist` skill.

## Steps

1. **Activate the skill**
   - Read `.agents/skills/asset-verify-checklist/SKILL.md` to load the full checklist.

2. **Identify scope**
   - Ask the user which scenes, prefabs, or asset folders to audit.
   - If unspecified, audit the entire project.

3. **Copy checklist to task.md**
   - Copy all checklist items from the skill into `task.md` as a working checklist.
   - Mark all items `[ ]` initially.

4. **Execute audit — section by section**
   - Work through each section in order (1→14).
   - For each item:
     - Inspect the relevant project settings, import settings, or asset files.
     - Mark `[x]` if passed, `[!]` if violation found, `[~]` if not applicable.
     - For `[!]` items: note the specific file/setting and recommended fix.

5. **Generate report**
   - Create an artifact `asset-verify-report.md` summarizing:
     - Total items checked / passed / violations / N/A
     - All `[!]` violations grouped by section with file paths and fix recommendations
     - Priority ranking (most impactful fixes first)

6. **Present to user**
   - Use `notify_user` to share the report for review.
