# Changelog

All notable changes to this project will be documented in this file.

---

## [5.2.0] - 2026-04-05

### Added
- **unity-ugui-layout**: Rules for building responsive uGUI layouts, constraints, Canvas Scaler setup, RectTransform anchors, Content Size Fitter and TMP text.

---

## [5.1.0] - 2026-03-20

### Changed — Phase 0.5 Evaluation Improvements
- **unity-code-audit**: Added Severity Classification Guide (CRITICAL/HIGH/MEDIUM/LOW with criteria)
- **unity-code-audit**: Added §34 Production Data Safety (+2 checklist items, now 243 total)
- **unity-code-audit**: Fixed PART C Addressables verification — manual release pattern now recognized as PASS
- **verify-code.md**: Added Accuracy Check Rule (precise language, full method context)
- **verify-code.md**: Findings Template now requires Suggested Fix + Priority columns
- **verify-code.md**: Added Count Reconciliation step for grouped violations
- **verify-code.md**: Added Priority Triage step before Fix phase
- **verify-code.md**: Findings format changed from table → checkbox list for interactive triage
- **verify-code.md**: Added User Review step — AI pauses, user marks `[x]` to skip items in VS Code, AI only fixes `[ ]` items

---

## [5.0.0] - 2026-03-20

### Changed — Audit Skills Redesign
- **BREAKING:** Replaced `unity-script-audit` + `unity-logic-audit` with unified `unity-code-audit`
- **BREAKING:** Replaced `verify-scripts.md` + `verify-logics.md` with unified `verify-code.md` (screen/deep modes)
- Updated INDEX.md — new "Audit & Verification" category
- Updated test suite with new assertions for screener + deep-audit
- Updated cross-references in `unity-csharp-standards`

### Added
- `unity-code-screener` — grep-level screening with patterns, exceptions, severity markers, and `[EDITOR-ONLY]`/`[CONTEXT-REQUIRED]` tags
- `unity-deep-audit` — multi-phase verified audit with hierarchical flow (Discovery → sub-phases → verify → final report)
- `verify-code.md` — unified workflow with `--mode=screen` (default) and `--mode=deep`

### Removed
- `unity-script-audit` — replaced by screener (grep items) + deep-audit (verification rules)
- `unity-logic-audit` — merged into screener + deep-audit
- `verify-scripts.md` — replaced by `verify-code.md`
- `verify-logics.md` — replaced by `verify-code.md`

---

## [4.0.0] - 2026-03-20

### Changed — Focused Skill Set
- **Reduced from 45 to 13 skills** (9 Unity + 4 QA) — removed generic/advisory skills, kept only project-specific essentials
- **Merged overlapping skills**: `canvas-performance` + `ui-state-safety` → `unity-ui-performance`; `mobile-optimization` + `script-design-review` + `my-csharp-conventions` → `unity-csharp-standards`
- **Renamed all skills to ASO standard** — added `unity-` prefix for searchability and global product branding
- **Fixed broken cross-references** in 6 SKILL.md files pointing to deleted skills
- Updated README, INDEX.md, package.json, gemini-extension.json to reflect 12 skills
- Reduced categories from 7 to 5

### Removed (Unity skills)
- Architecture: `design-patterns`, `interface-driven-development`, `scriptableobject-architecture`
- UI: `menu-navigation-flow`
- Performance: `memory-profiler-expert`, `object-pooling-system`
- Backend: `backend-integration`, `monetization-iap`
- Tools: `audio-systems`

### Renamed (ASO Standard)
- `addressables-asset-management` → `unity-addressables`
- `asset-verify-checklist` → `unity-asset-audit`
- `asynchronous-programming` → `unity-async-patterns`
- `csharp-quality` → `unity-csharp-standards`
- `custom-editor-scripting` → `unity-editor-tools`
- `dotween-safety` → `unity-dotween-safety`
- `scripts-verify-checklist` → `unity-script-audit`
- `ui-optimization` → `unity-ui-performance`
- `qa-doc-parser` → `unity-qa-parser`
- `qa-testcase-generator` → `unity-qa-generator`
- `qa-test-verifier` → `unity-qa-verifier`
- `qa-test-scorer` → `unity-qa-scorer`

---

## [3.0.0] - 2026-03-17

### Changed — Skill Cleanup & Standardization
- **Reduced from 67 to 45 skills** — removed game-genre-specific skills (RPG combat, loot, quests, inventory, AI behavior, VR/AR, etc.)
- **Merged `my-unity-mobile` into `mobile-optimization`** — coding rules + performance optimization in one skill
- **Standardized YAML frontmatter** — stripped extra fields (`version`, `tags`, `argument-hint`, `allowed-tools`, etc.) to match Antigravity standard (name + description only)
- **Fixed 19 trigger descriptions** — resolved overlaps, added disambiguation markers (FIRST/ONLY/BEFORE/DURING), expanded keyword coverage
- Updated README, package.json, gemini-extension.json to reflect 45 skills
- Updated category structure from 10 to 8 categories

### Removed (21 skills)
- Genre-specific: `damage-health-framework`, `status-effect-system`, `loot-rng-management`, `inventory-crafting-logic`, `dialogue-quest-system`, `advanced-character-controller`, `ai-behavior-trees`, `navmesh-pathfinding`, `procedural-animation-ik`
- Niche: `dots-system-architect`, `multiplayer-netcode`, `cinemachine-specialist`, `physics-logic`, `vr-ar`
- Redundant/thin: `game-audio` (merged into `audio-systems`), `kaizen` (TypeScript), `gameplay-blueprints`, `adr-records`, `game-design`, `juice-game-feel`, `analytics-heatmaps`

---

## [2.0.0] - 2026-03-13

### Changed — Modern CLI Architecture
- **Rewrote CLI** from CJS shell-delegate (`cli.js`) to ESM with inline Node.js logic (`cli.mjs`)
- Removed `setup-project.sh` and `setup-project.ps1` — all logic now in `cli.mjs`
- `npx ag-unity` now works natively on all platforms (no bash/powershell dependency)
- Added `"type": "module"` to `package.json`
- Added automatic backup before skill overwrite
- Updated `package.json` with `author`, `homepage`, `scripts` in `files`

### Added
- **Automated test suite** (`tests/run-tests.sh`) with 7 test cases
- **Enhanced update script** (`scripts/update-unity-skills.sh`) with backup, diff check, interactive menu
- Verification step with skill count and category count

### Removed
- `setup-project.sh` — logic moved to `cli.mjs`
- `setup-project.ps1` — logic moved to `cli.mjs`
- `bin/cli.js` — replaced by `bin/cli.mjs`

---

## [1.0.0] - 2026-03-13

### Added — Initial Release
- **70 Unity skills** organized in 9 categories
- `setup-project.sh` — Project-level installation script (macOS/Linux)
- `setup-project.ps1` — Project-level installation script (Windows)
- `scripts/update-unity-skills.sh` — Update script
- `gemini-extension.json` — Antigravity extension metadata
- Block-based non-destructive GEMINI.md updates
- `tests/README.md` — Manual test cases

### Structure
```
global-config/skills/
├── 01-architecture/      (10 skills)
├── 02-gameplay/          (11 skills)
├── 04-visuals-audio/     (9 skills)
├── 05-ui-ux/             (6 skills)
├── 06-performance/       (5 skills)
├── 07-tools-pipeline/    (6 skills)
├── 08-backend-monetization/ (5 skills)
├── 09-devops-automation/    (2 skills)
└── unity-specific/       (6 skills)
```

---

## Links

- **Repository:** [zasuozz-oss/antigravity-unity-skills](https://github.com/zasuozz-oss/antigravity-unity-skills)
- **Superpowers (core):** [zasuozz-oss/antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers)
- **Google Antigravity:** [antigravity.google](https://antigravity.google)
