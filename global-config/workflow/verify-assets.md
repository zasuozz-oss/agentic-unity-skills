---
description: Run the Asset Verify Checklist against a Unity project. Uses MCP for direct Editor inspection when available, falls back to reading .meta and .asset files. Supports multi-phase execution for large projects.
---

# Asset Verify Workflow

Audit all non-code asset factors affecting Unity performance using the `unity-asset-audit` skill.

## Step 1: Activate Skill + Detect MCP

1. Read `.agents/skills/unity-asset-audit/SKILL.md` to load the full checklist.
2. **Detect MCP availability:**
   - Try calling a Unity MCP tool (e.g., list scenes, get project settings).
   - **If MCP available:** Use MCP for direct Editor inspection (Mode A).
   - **If MCP unavailable:** Notify user: _"MCP không khả dụng. Chuyển sang đọc .meta + .asset files. Một số items [EDITOR-ONLY] sẽ không thể verify."_ Then use file-based fallback (Mode B).

---

## Mode A: MCP Available (Direct Editor Inspection)

Use MCP tools to directly inspect Unity Editor state:
- Project Settings (rendering, physics, quality)
- Import settings per asset
- Scene hierarchy and component configurations
- Material/shader properties

### Steps

1. **Identify scope** — ask user for scenes/folders to audit, or audit entire project.
2. **Phase 0: Discovery** — list all assets in scope, create `audit-plan.md` grouped by type (textures, models, materials, audio, scenes).
3. **Phase N: Audit** — for each sub-phase, use MCP to inspect settings and mark items.
4. **Phase N VERIFY** — aggregate sub-phase findings, cross-check.
5. **FINAL VERIFY** — generate `asset-verify-report.md`.

---

## Mode B: No MCP (File-Based Fallback)

Read `.meta` files and `ProjectSettings/*.asset` files for what's available via filesystem.

### What CAN be checked via files

| Check | File |
|-------|------|
| Texture import settings | `*.meta` files → `textureImporter` section |
| Model import settings | `*.meta` files → `modelImporter` section |
| Audio import settings | `*.meta` files → `audioImporter` section |
| Rendering pipeline | `ProjectSettings/GraphicsSettings.asset` |
| Quality settings | `ProjectSettings/QualitySettings.asset` |
| Physics settings | `ProjectSettings/DynamicsManager.asset` |
| Player settings (IL2CPP, arch) | `ProjectSettings/ProjectSettings.asset` |
| Tag/Layer setup | `ProjectSettings/TagManager.asset` |

### What CANNOT be checked via files

- Runtime batching behavior (SRP Batcher, GPU Instancing effectiveness)
- Overdraw visualization
- Frame Debugger results
- Memory Profiler snapshots
- LOD group effectiveness (visual quality vs performance)

Mark these items `[~] N/A — requires MCP or Unity Editor`.

### Steps

1. **Identify scope** — ask user for folders, or audit `Assets/` directory.
2. **Phase 0: Discovery**
   - `find <scope> -name "*.meta" | wc -l` — count total assets
   - Group by type: textures (`.png.meta`, `.jpg.meta`), models (`.fbx.meta`), audio (`.wav.meta`, `.mp3.meta`)
   - Create `audit-plan.md` with phases by asset type
   - Split sub-phases by count:
     - >50 assets of one type → split into sub-phases of ~20-30
     - <50 → 1 sub-phase per type
3. **Phase N: Audit sub-phase**
   - Read `.meta` files → check import settings against checklist
   - Read `ProjectSettings/*.asset` → check project-level settings
   - Output: `phase-Na-findings.md`
4. **Phase N VERIFY** — aggregate findings, cross-check related settings
5. **FINAL VERIFY** — generate `asset-verify-report.md`

---

## Output Format

Same as `verify-code.md`:

```
Total: X items checked / Y passed / Z violations / W N/A
🔴 Critical: N | 🟡 High: N | 🟢 Low: N
Mode: [MCP / File-Based Fallback]
```

For each violation:
```
🟡 §4.1 Texture Compression — ASTC not set
   File: Assets/Textures/bg_main.png
   Setting: textureCompression = 1 (Uncompressed)
   Fix: Set to ASTC 6x6 in Import Settings
```

---

## Resuming Interrupted Sessions

1. Read `audit-plan.md` → find unchecked `[ ]` asset groups.
2. Continue from the next unchecked sub-phase.
3. Previous findings files preserved — no data loss.
