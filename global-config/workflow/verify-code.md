---
description: Deep verified code audit workflow for Unity C# projects. Feature-based phasing with GitNexus auto-detection. Each feature is fully audited + fixed before moving to the next. Uses unity-code-audit skill.
---

# Code Verification Workflow

Deep verified audit for Unity C# code quality. Every violation confirmed by reading code context (`view_file`). Phased by feature — completed features are 100% done even if interrupted.

> **CRITICAL RULE:** NEVER batch-grep. Every file MUST be `view_file` regardless of size.

> **CRITICAL RULE:** Before every pause for user input, write ALL findings and context to `audit-session.md`. Never rely on in-memory context across sessions. On resume, ALWAYS read `audit-session.md` + `phase-N-findings.md` before proceeding.

---

## Steps

### 1. Activate the skill

Read `.agents/skills/unity-code-audit/SKILL.md` — use PART A + PART B for checklist, PART C for verification rules.

### 2. Phase 0: Discovery — Feature Detection

**Step 2a: Try GitNexus MCP (preferred)**

Check if `gitnexus` MCP server is available. If yes:

```cypher
-- List indexed repos
gitnexus.list_repos()

-- If project is indexed, query feature communities
MATCH (s)-[:CodeRelation {type: 'MEMBER_OF'}]->(c:Community)
WHERE c.heuristicLabel IS NOT NULL
  AND s.filePath STARTS WITH '<scope>/'
WITH c.heuristicLabel AS feature,
     collect(DISTINCT s.filePath) AS files
ORDER BY size(files) DESC
RETURN feature, size(files) AS fileCount, files
```

GitNexus auto-detects features using Leiden community algorithm on the call graph.

**Grouping rules for GitNexus results:**
- Communities with similar names → merge (e.g., "Challenge & Submit" + "Challenge" → "Challenge System")
- Communities `Cluster_XXXX` (unnamed) → merge into "Misc"
- Communities ≤3 files → merge into "Misc" or nearest related feature
- Shared infrastructure files (APIManager, Data, GameManager, LoadController) → separate "Infrastructure" phase, audit FIRST

**Step 2b: Fallback — Folder-based (no GitNexus)**

If GitNexus is NOT available or project is NOT indexed, ask user:

> **GitNexus MCP is not available.** Cannot auto-detect features.
>
> Would you like to fallback to folder-based phasing?
> - **Yes** → Split phases by folder structure
> - **No** → Stop, user provides feature map manually

If user chooses folder-based fallback:
- `find <scope> -name "*.cs" -exec wc -l {} +`
- Group files by top-level folder
- Folder >5000 lines → split sub-phases (files >500 lines = 1 sub-phase each)
- Folders <1000 lines → merge into combined phase

**Step 2c: Create audit-plan.md**

Regardless of detection method, create `audit-plan.md`:

```
# Deep Audit Plan — <Project Name>

**Detection:** GitNexus community / Folder-based fallback
**Scope:** <path> — X lines | Y files

## Phase Order

| Phase | Feature        | Files | Lines | Status |
|-------|----------------|-------|-------|--------|
| 0.5   | Infrastructure | N     | N     | [ ]    |
| 1     | <Feature A>    | N     | N     | [ ]    |
| 2     | <Feature B>    | N     | N     | [ ]    |
...

## Phase Details

### Phase 0.5: Infrastructure
- [ ] APIManager.cs (1349 lines)
- [ ] Data.cs (1123 lines)
...

### Phase 1: <Feature A>
- [ ] file1.cs (XXX lines)
- [ ] file2.cs (XXX lines)
...
```

Present plan to user for approval before proceeding.

### 3. Phase N: Audit + Fix per Feature

Each phase = 1 complete feature. Within each phase:

**Step 3a: Audit (1+ sessions)**
- Read `audit-plan.md` to identify files for this phase.
- For each file — repeat until all files done:
  1. `view_file` the file — no exceptions
  2. Apply ALL rules from PART A + PART B + PART C verification rules
  3. Append findings of this file to `phase-N-findings.md` immediately
  4. Mark file `[x]` in `audit-plan.md`
- Never batch: do not read multiple files before writing findings

**Accuracy Check Rule:**
- Read ENTIRE relevant method/class, not just the flagged line.
- Check ALL code paths (success, error, cancellation) before writing description.
- Check if the class provides separate public methods for resource cleanup (manual release pattern).
- NEVER use absolute language ("NEVER", "NO", "ALL") unless verified ALL instances. Use precise language:
  - ❌ "NEVER releases handle" → ✅ "No release on success path (error paths have release)"
  - ❌ "ALL async methods lack CT" → ✅ "X/Y public async methods lack CancellationToken"

**Findings Format** — 1 row per location in `phase-N-findings.md`:

Each row = 1 location. Issues with multiple locations = multiple rows sharing same #.
Location format: `FileName:Line` (short — NO full path to keep table readable).

```markdown
# Phase N Findings — <Feature Name>

**Files reviewed:** X | **Confirmed violations:** Y (Z unique issues)

## 🔴 Critical

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 1 | Motion:19 | DOTween without SetLink | `.SetLink(gameObject)` |
| 1 | Motion:25 | | |
| 1 | Motion:35 | | |
| 2 | Manager:174 | `throw e` loses stack trace | `throw;` |

## 🟡 High

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 3 | APIManager:151 | UnityWebRequest not Disposed | Wrap in `using` |

## 🟢 Low

| # | Location | Issue | Fix |
|---|----------|-------|-----|
| 4 | Data:3 | Unused import | Remove |

---

## Count Reconciliation
- Unique issues: Z | Total locations: Y
- Multi-location: #1 (3)
```

Rules:
- First row of each # shows Issue + Fix. Subsequent rows of same # leave those columns empty
- Severity levels: 🔴 Critical | 🟡 High | 🟡 Medium | 🟢 Low (from skill's Severity Classification Guide)
- **No checkbox column** — user marks skip via comments
- User adds `> skip #N — reason` below any table to skip issue #N
- AI reads comments: if `> skip #N` found → skip all rows with that #

**Triage example:**
```markdown
> skip #3 — test data for live event, remove after event ends
> skip #15 — will refactor entire async layer later
```

**Count Reconciliation** — at end of findings file:
- Total unique issues vs total locations
- List multi-location issues: "#N (count)"

- Update `audit-plan.md`: mark audited files `[x]`.

**Step 3b: User Review (REQUIRED)**

Before pausing, AI MUST update `audit-session.md`:

```markdown
# Audit Session State

## Current phase: N
## Status: WAITING_USER_REVIEW

## Files read this session
- [x] FileName.cs — X lines — fully read
- [ ] FileName.cs — pending
...

## Context notes
- <FileName.cs>: <key finding summary per file>
...

## Pending user action
Review `phase-N-findings.md` → add `> skip #N — reason` for issues to skip → reply `continue`
```

After writing `audit-session.md`, present to user for triage:

```
notify_user:
  PathsToReview: [phase-N-findings.md]
  Message: "Phase N audit complete. X violations found.
            Review findings → add `> skip #N — reason` for issues to skip.
            Say 'continue' when done."
  BlockedOnUser: true
```

User adds comments below any table to skip or annotate:
```markdown
> skip #3 — test data for live event, remove after event ends
> skip #15 — will refactor entire async layer later
> #22 only fix L103 and L152, other lines deferred to next phase
```

**Step 3c: Fix (respect user triage)**

On resume, AI MUST read in this order before proceeding:
1. `audit-session.md` — restore context (files read, key findings)
2. `phase-N-findings.md` — restore findings + user triage comments
3. `audit-plan.md` — restore phase status

Then proceed:
- No comment on # → fix as suggested
- `> skip #N` → skip all rows with that #
- `> #N partial note` → fix following user's instruction
- Record fixes in `phase-N-fixes.md`.

**Step 3d: Verify**
- Re-check fixed files — confirm no regressions.
- Cross-reference with other phases if needed.

**Step 3e: Mark Done**
- Update `audit-plan.md`: mark phase status `[x]`.
- Update `audit-session.md`: mark phase COMPLETE.
- ✅ This feature is now COMPLETE.

### 4. FINAL: Aggregate Report

After all phases complete:
- Read all phase findings + fixes.
- Generate `deep-audit-report.md`:
  - Summary per feature
  - Total violations found vs fixed
  - Remaining items (if any)
  - Overall project health score

### 5. Present to user

Use `notify_user` to share the final report.

---

## Resuming Interrupted Sessions

1. Read `audit-session.md` → restore context from last session.
2. Read `audit-plan.md` → find phases/files still marked `[ ]`.
3. Continue from the next unchecked phase.
4. **Completed phases = completed features** — no need to redo.
5. Previous findings/fixes files are preserved — no data loss.