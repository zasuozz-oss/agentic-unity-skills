# Test Cases — Unity Skills

Test thủ công và tự động để xác minh cơ chế cài Unity project skills.

---

## Automated Tests

Chạy `bash tests/run-tests.sh` để thực thi test suite.

Suite sẽ build local CLI trước, tạo một skill test tạm dưới `global-config/skills`, sau đó kiểm tra hành vi `ag-unity init` thông qua `node dist/cli/index.js init` trong các project tạm.

### TC-00: Build Surface
- `dist/cli/index.js` được generate và có quyền executable
- `package.json` expose `ag-unity` qua `dist/cli/index.js`
- `setup.sh` tồn tại và pass shell syntax check
- Lệnh `version` và `list` hoạt động
- `list` tự phát hiện skill trong nhóm mới dưới `global-config`

### TC-01: Fresh Project Init — Project Skill Targets
- Tạo project skill directories:
- `.agents/skills/` cho Antigravity/Codex
- `.claude/skills/`
- Skills được cài flat trong từng target
- Số skill cài ra bằng số `SKILL.md` được tìm thấy dưới `global-config`
- Không ghi global skills dưới `$HOME`
- Không tạo `.codex/skills/`

### TC-02: YAML Frontmatter Validation
- Mọi skill có `name` và `description` trong YAML frontmatter
- Mọi `description` bắt đầu bằng `Use when` để agent detect đúng trigger
- Không có extra YAML fields

### TC-03: Idempotent — No Duplication
- Chạy lại install không nhân bản skill
- Skill count giữ nguyên sau khi chạy lại

### TC-04: Existing Project — No Side Effects
- `GEMINI.md` có sẵn không bị sửa
- Skills được cài bên cạnh file sẵn có

### TC-05: Manifest File
- `.ag-unity-manifest.json` có package, version, installed_at, skills, groups

### TC-06: Legacy Migration
- Old group folders (`unity-skills/`, `qa-skills/`, nhóm mới) bị xóa trong lúc install
- Skills được migrate sang flat structure
- Skill cũ từng do manifest quản lý nhưng không còn trong `global-config` bị xóa

### TC-07: init Argument Rejection
- `ag-unity init <path>` exit non-zero
- Error hướng dẫn user `cd` vào project rồi chạy `ag-unity init`

---

## Manual Skill Loading Tests

### TC-09: Skills Auto-Load
**Prompt:** Mở Antigravity trong project sau setup, hỏi "what Unity skills do you have?"

**Expected:**
- Agent reference `INDEX.md`
- Agent list được Unity skill categories

### TC-10: Skill Invocation
**Prompt:** "I need help with DOTween safety in Unity"

**Expected:**
- Agent đọc `unity-dotween-safety/SKILL.md`
- Response dùng patterns và recommendations trong skill

---

## Verification Checklist

- [ ] TC-00: Build surface works (automated)
- [ ] TC-01: Fresh project init works (automated)
- [ ] TC-02: YAML frontmatter valid (automated)
- [ ] TC-03: Idempotent re-run (automated)
- [ ] TC-04: No side effects (automated)
- [ ] TC-05: Manifest file valid (automated)
- [ ] TC-06: Legacy migration works (automated)
- [ ] TC-07: Path argument rejection works (automated)
- [ ] TC-09: Skills auto-load in Antigravity
- [ ] TC-10: Skill invocation works
