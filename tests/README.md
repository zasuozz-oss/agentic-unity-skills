# Test Cases — Unity Skills

Manual and automated test cases for verifying Unity skills setup.

---

## 🔵 Automated Tests

Run `bash tests/run-tests.sh` to execute the automated test suite.

### TC-01: Fresh Install — Flat Structure
- Skills directory `.agents/skills/` created
- Skills installed flat (no nested group folders)
- 12+ skills installed (SKILL.md present)

### TC-02: YAML Frontmatter Validation
- All skills have `name` + `description` in YAML frontmatter
- No extra YAML fields

### TC-03: Idempotent — No Duplication
- Re-running install doesn't duplicate skills
- Skill count unchanged after re-run

### TC-04: Existing Project — No Side Effects
- Existing GEMINI.md untouched
- Skills installed alongside existing files

### TC-05: All Skills Have SKILL.md
- Every skill directory contains a SKILL.md file

### TC-06: Manifest File
- `.ag-manifest.json` exists with version, installed_at, groups, workflows

### TC-07: Legacy Migration
- Old group folders (`unity-skills/`, `qa-skills/`) removed during install
- Skills migrated to flat structure

### TC-08: Workflow Installation
- Workflows directory `.agents/workflows/` created
- `build-ui-mcp.md`, `verify-assets.md`, `verify-code.md` installed
- Workflow count unchanged after re-run

---

## 🟢 Manual Skill Loading Tests

### TC-09: Skills Auto-Load
**Prompt:** Open Antigravity in a project after setup, ask "what Unity skills do you have?"
**Expected:**
- Agent references INDEX.md
- Agent can list Unity skill categories

### TC-10: Skill Invocation
**Prompt:** "I need help with DOTween safety in Unity"
**Expected:**
- Agent reads `dotween-safety/SKILL.md`
- Response uses skill's patterns and recommendations

---

## Verification Checklist

- [ ] TC-01: Fresh setup works (automated)
- [ ] TC-02: YAML frontmatter valid (automated)
- [ ] TC-03: Idempotent re-run (automated)
- [ ] TC-04: No side effects (automated)
- [ ] TC-05: All skills have SKILL.md (automated)
- [ ] TC-06: Manifest file valid (automated)
- [ ] TC-07: Legacy migration works (automated)
- [ ] TC-08: Workflow installation (automated)
- [ ] TC-09: Skills auto-load in Antigravity
- [ ] TC-10: Skill invocation works
