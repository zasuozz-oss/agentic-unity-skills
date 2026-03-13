# Test Cases — Unity Skills

Manual test cases for verifying Unity skills setup works correctly.

---

## 🔵 Installation Tests

### TC-01: Fresh Project Setup
**Prompt:** Run `bash /path/to/setup-project.sh` in an empty directory
**Expected:**
- `.agents/skills-unity/` created with 9 category directories
- 70 `SKILL.md` files present
- `GEMINI.md` created with `<!-- BEGIN/END antigravity-unity-skills -->` block
- `INDEX.md` present in `.agents/skills-unity/`

### TC-02: Existing Project — Append Block
**Prompt:** Run setup in a project that already has `GEMINI.md` without unity block
**Expected:**
- Unity block appended to existing `GEMINI.md`
- Original `GEMINI.md` content preserved
- No duplicated blocks

### TC-03: Re-run — Update Block
**Prompt:** Run setup again in a project where it was already installed
**Expected:**
- Skills directory refreshed
- Unity block in `GEMINI.md` replaced (not duplicated)
- Block count remains 1

---

## 🟢 Skill Loading Tests

### TC-04: Skills Auto-Load
**Prompt:** Open Antigravity in a project after setup, ask "what Unity skills do you have?"
**Expected:**
- Agent references `INDEX.md`
- Agent can list Unity skill categories
- Agent knows about all 9 categories

### TC-05: Skill Invocation
**Prompt:** "I need help with object pooling in Unity"
**Expected:**
- Agent reads `06-performance/object-pooling-system/SKILL.md`
- Response uses skill's patterns and recommendations

### TC-06: Specific Skill Reference
**Prompt:** `view_file(".agents/skills-unity/01-architecture/di-container-manager/SKILL.md")`
**Expected:**
- File loads successfully
- Skill content is complete and readable

---

## 🟠 Cross-Platform Tests

### TC-07: Windows Setup
**Prompt:** Run `powershell -ExecutionPolicy Bypass -File setup-project.ps1`
**Expected:**
- Same results as TC-01 but on Windows
- `.agents\skills-unity\` created
- `GEMINI.md` updated

### TC-08: Update Script
**Prompt:** Run `bash scripts/update-unity-skills.sh`
**Expected:**
- Pulls latest from git (if remote configured)
- Re-installs skills to current project
- Existing GEMINI.md block updated

---

## 🔴 Edge Case Tests

### TC-09: Superpowers + Unity Skills Coexistence
**Prompt:** Install both superpowers and unity-skills in the same project
**Expected:**
- Both `<!-- BEGIN antigravity-superpowers -->` and `<!-- BEGIN antigravity-unity-skills -->` blocks present
- No conflicts between blocks
- Both sets of skills available

### TC-10: Missing Source Directory
**Prompt:** Run setup-project.sh from wrong directory
**Expected:**
- Error message: "global-config/skills/ not found"
- No partial installation
- Exit code 1

---

## Verification Checklist

- [ ] TC-01: Fresh setup works
- [ ] TC-02: Append to existing GEMINI.md
- [ ] TC-03: Idempotent re-run
- [ ] TC-04: Skills auto-load in Antigravity
- [ ] TC-05: Skill invocation works
- [ ] TC-06: Direct skill file access
- [ ] TC-07: Windows setup works
- [ ] TC-08: Update script works
- [ ] TC-09: Coexistence with superpowers
- [ ] TC-10: Error handling
