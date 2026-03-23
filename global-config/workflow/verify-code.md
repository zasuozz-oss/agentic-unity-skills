---
description: Deep verified code audit workflow for Unity C# projects. Feature-based phasing with GitNexus auto-detection. Each feature is fully audited + fixed before moving to the next. Uses unity-code-audit skill.
---
# Code Verification Workflow

Deep verified audit for Unity C# code quality. Every violation confirmed by `view_file`. Phased by feature — completed features are 100% done even if interrupted.

> **CRITICAL RULES:**
> 1. NEVER batch-grep. Every file MUST be `view_file` regardless of size.
> 2. AI MUST write `audit-session.md` BEFORE every pause/notify_user — **#1 cause of context loss**.
> 3. Findings MUST use table format — NO heading-based prose (`### C01 — ...`).
> 4. ALL links MUST use `file:///` absolute paths for clickable artifact links.
> 5. **LANGUAGE:** Issue/Fix descriptions, summaries, section headers → Vietnamese. Code identifiers, variable names → English.
> 6. **FILE SUMMARY TABLE:** Findings header MUST include a table listing every reviewed file with columns: File, Lines, Lỗi (error count per file).
> 7. **LOCATION LINK FORMAT:** `[FileName.cs:Line](file:///absolute/path/to/FileName.cs#LLine)` — filename MUST include `.cs` extension.

---

## Context Preservation (OpenMemory / Fallback)

**Dual-layer:** File = structured source of truth, OpenMemory = semantic context (reasoning, decisions, patterns).

**At workflow start**, check if `openmemory` MCP is available:
- **Available** → use `openmemory_store` / `openmemory_query` with tags below
- **Not available** → append same content to `audit-context.md` with `[timestamp] [phase:N]` headers

**Tags** (OpenMemory mode): `project:<name>`, `workflow:verify-code`, `audit-phase:<N>`, `audit-scope:<path>`

**Store at 3 checkpoints** (keep ≤ 3 sentences, patterns only, NO full tables):

| When | Content |
|------|---------|
| After creating audit-plan | Scope, phase list, detection method, file counts |
| After auditing each file | Key patterns, violation count, notable insights |
| After completing each phase | Recurring patterns, health, triage summary |

**Query at 2 triggers:**

| When | Query |
|------|-------|
| Resuming session | `"verify-code audit <project>"` → restore context before reading files |
| Starting new phase | `"verify-code phase <N-1> patterns <project>"` → cross-phase patterns |

---

## Steps

### 1. Activate the skill

Read `.agents/skills/unity-code-audit/SKILL.md` — use PART A + PART B for checklist, PART C for verification rules.

### 2. Discovery — Feature Detection

**2a: Try GitNexus (preferred)**
```cypher
MATCH (s)-[:CodeRelation {type: 'MEMBER_OF'}]->(c:Community)
WHERE c.heuristicLabel IS NOT NULL
  AND s.filePath STARTS WITH '/'
WITH c.heuristicLabel AS feature, collect(DISTINCT s.filePath) AS files
ORDER BY size(files) DESC
RETURN feature, size(files) AS fileCount, files
```

**Grouping rules for GitNexus results:**
- Similar community names → merge (e.g., "Challenge & Submit" + "Challenge" → "Challenge System")
- `Cluster_XXXX` (unnamed) → merge into "Misc"
- Communities ≤3 files → merge into "Misc" or nearest related feature

**Phase 0.5 — Infrastructure:**
Include ONLY files that meet ALL conditions:
- Is a true singleton or static global manager (single instance for entire app)
- Contains NO feature-specific business logic
- Cannot be assigned to any single feature phase

**Phase 0.6 — Shared/Utilities (if needed):**
Files referenced by multiple features but NOT true infrastructure:
- Utility helpers used by ≥2 features
- Shared controllers with no single feature owner
- Base classes / extensions used across features
- Do NOT merge into Phase 0.5

**Everything else — assign by ownership:**
- Feature-specific controllers → phase of their feature
- Helpers used primarily by 1 feature → that feature's phase
- If uncertain which feature owns a file → assign to Phase 0.6, not Phase 0.5

**Phase size:**
- If a phase exceeds ~20 files or ~5,000 lines → split into sub-phases
- Sub-phase naming: 1a, 1b, 1c...

**2b: Fallback (no GitNexus)** — folder-based: group by top-level folder, split >5000 lines, merge <1000 lines.

**2c: Create `audit-plan.md`**
```markdown
# Deep Audit Plan — 

**Detection:** GitNexus / Folder-based | **Scope:**  — X lines | Y files

| Phase | Feature | Files | Lines | Status |
|-------|---------|-------|-------|--------|
| 0.5 | Infrastructure | N | N | [ ] |
| 0.6 | Shared/Utilities | N | N | [ ] |
| 1 |  | N | N | [ ] |

### Phase 0.5: Infrastructure
- [ ] APIManager.cs (1349 lines)
- [ ] Data.cs (1123 lines)

### Phase 0.6: Shared/Utilities
- [ ] file1.cs (XXX lines)
- [ ] file2.cs (XXX lines)

### Phase 1: 
- [ ] file1.cs (XXX lines)
- [ ] file2.cs (XXX lines)
```

Present plan to user for approval. **Store checkpoint** after approval.

### 3. Phase N: Audit + Fix per Feature

Each phase = 1 complete feature. Within each phase:

**3a: Audit** — for each file:
1. `view_file` the file — no exceptions
2. Apply ALL rules from PART A + PART B + PART C
3. Append findings to `phase-N-findings.md` immediately
4. Mark file `[x]` in `audit-plan.md`
5. **Store checkpoint** — key patterns for this file
- Never batch: write findings after each file, not after reading multiple

**Accuracy Rules:**
- Read ENTIRE method/class, not just the flagged line
- Check ALL code paths (success, error, cancellation) before writing description
- Check for manual release patterns (separate public cleanup methods)
- Use precise language: ❌ "NEVER releases" → ✅ "No release on success path (error paths have release)"

**Cross-File Rule:** When finding involves factory/producer patterns:
1. Use `mcp_gitnexus_context()` to find all callers
2. Check if ≥1 caller disposes the returned resource
3. Document: "Cross-file: N callers, M dispose properly"
4. No caller disposes → escalate to 🔴 Critical

**Severity Convention:**
- 🔴 Critical — crash, memory leak, security, data corruption
- 🟡 High — performance drain, logic bug, resource misuse
- 🟡 Medium — code quality, maintainability, naming
- 🟢 Low — style, minor cleanup, documentation

**Location Link Rule:**
- Use `file:///` absolute paths for ALL links in findings — ensures clickable links in artifact viewer
- Format: `[FileName.cs:Line](file:///absolute/path/to/FileName.cs#LLine)`
- Correct:   `[APIManager.cs:19](file:///Users/zasuo/Unity/SDU/Assets/_Game/Scripts/Common/APIManager.cs#L19)`
- Incorrect: `[APIManager.cs:19](Assets/_Game/Scripts/Common/APIManager.cs#L19)` (not clickable)

**Findings Template** (`phase-N-findings.md`):
```markdown
# Phase N Findings — <Feature Name>

**Files đã review:** X | **Vi phạm xác nhận:** Y (Z vấn đề riêng biệt)

| File | Lines | Lỗi |
|------|-------|-----|
| [APIManager.cs](file:///Users/zasuo/Unity/SDU/Assets/_Game/Scripts/Common/APIManager.cs) | 1350 | 14 |
| [Data.cs](file:///Users/zasuo/Unity/SDU/Assets/_Game/Scripts/Data/Data.cs) | 1124 | 2 |

## 🔴 Critical

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 1 | [Motion.cs:19](file:///Users/zasuo/Unity/SDU/Assets/Scripts/Motion.cs#L19) | DOTween không có SetLink | `.SetLink(gameObject)` |
| 1 | [Motion.cs:25](file:///Users/zasuo/Unity/SDU/Assets/Scripts/Motion.cs#L25) | | |
| 2 | [Manager.cs:174](file:///Users/zasuo/Unity/SDU/Assets/Scripts/Manager.cs#L174) | `throw e` mất stack trace | `throw;` |

## 🟡 High

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 3 | [APIManager.cs:151](file:///Users/zasuo/Unity/SDU/Assets/_Game/Scripts/Common/APIManager.cs#L151) | UnityWebRequest không Dispose | Wrap trong `using` |

## 🟡 Medium

| # | Location | Issue | Fix |
|---|----------|-------|-----|

## 🟢 Low

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 4 | [Data.cs:3](file:///Users/zasuo/Unity/SDU/Assets/_Game/Scripts/Data/Data.cs#L3) | Import không cần thiết | Xoá |

---

## Thống kê
- Vấn đề riêng biệt: Z | Tổng locations: Y
- Multi-location: #1 (2)
```

**Findings rules:**
- First row of each # shows Issue + Fix, subsequent rows leave those empty
- User adds `> skip #N — reason` below table to skip. AI reads and respects these.

**3b: User Review (REQUIRED)**

Before pausing, write `audit-session.md`:
```markdown
# Audit Session State
## Current phase: N | Status: WAITING_USER_REVIEW

## Files read this session
- [x] FileName.cs — X lines — fully read
- [ ] FileName.cs — pending

## Context notes
- : 

## Pending user action
Review `phase-N-findings.md` → add `> skip #N — reason` → reply `continue`
```

Then `notify_user` with `phase-N-findings.md` for review.

**3c: Fix (respect triage)**

On resume, read in order: `audit-session.md` → `phase-N-findings.md` → `audit-plan.md`.
**Store checkpoint** with triage summary before starting fixes.
- No comment → fix as suggested
- `> skip #N` → skip all rows with that #
- `> #N partial note` → fix per user instruction
- Record in `phase-N-fixes.md`

**3d: Verify** — re-check fixed files, confirm no regressions.

**3e: Mark Done**
- Update `audit-plan.md`: Phase Order `[ ]` → `[x]`, Phase Details all files `[x]`
- Re-read `audit-plan.md` to verify — if any file still `[ ]`, fix immediately
- Update `audit-session.md`: mark phase COMPLETE
- **Store checkpoint** — phase summary with recurring patterns
- ✅ This feature is now COMPLETE.

### 4. Final Report

After all phases: generate `deep-audit-report.md` with summary per feature, total violations found/fixed, remaining items, health score. Present to user via `notify_user`.

---

## Resuming Interrupted Sessions

1. **Query OpenMemory** (or read `audit-context.md`) → restore semantic context FIRST
2. Read `audit-session.md` → restore structured state
3. Read `audit-plan.md` → find phases/files still `[ ]`
4. Read latest `phase-N-findings.md` → restore current progress
5. Continue from next unchecked file/phase
6. Completed phases = done — no redo needed