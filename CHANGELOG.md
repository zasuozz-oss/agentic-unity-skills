# Changelog

All notable changes to this project will be documented in this file.

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
