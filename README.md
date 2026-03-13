# Antigravity Unity Skills

70 Unity-specific skills for game development with Google Antigravity. Install skills directly into any Unity project.

> **📦 Public, read-only repository.** Install via npm or clone and run setup.

🌐 [Quick Start](#-quick-start) · [What's Inside](#-whats-inside) · [Full Skill List](global-config/skills/INDEX.md)

## 📋 Requirements

- [Google Antigravity](https://antigravity.google) (macOS / Windows / Linux)
- Node.js 18+

---

## ⚡ Quick Start

```bash
cd /path/to/your/unity-project
npx ag-unity
```

That's it. 70 skills installed.

<details>
<summary>Alternative: Clone + Run</summary>

```bash
git clone https://github.com/zasuozz-oss/antigravity-unity-skills.git
cd /path/to/your/unity-project
node /path/to/antigravity-unity-skills/bin/cli.mjs
```

</details>

### What Happens After Setup

```
your-project/
├── GEMINI.md                # Updated with unity-skills block
└── .agents/
    └── skills-unity/        # 70 Unity skills installed here
        └── INDEX.md
```

Open Antigravity in your project. Unity skills auto-load via `GEMINI.md`.

---

## 🎯 What Is This?

A collection of **70 Unity-specific skills** organized by category, designed to extend Google Antigravity with deep Unity game development knowledge.

Key features:
- ✅ **One-command install** — `npx ag-unity` from any project
- ✅ **Project-level install** — skills live in your project's `.agents/skills-unity/`
- ✅ **Cross-platform** — pure Node.js, no bash/powershell dependency
- ✅ **Non-destructive setup** — preserves existing `GEMINI.md` content
- ✅ **Block-based updates** — re-run setup to update without conflicts
- ✅ **Backup on update** — existing skills backed up before overwrite

---

## 📚 What's Inside

**70 skills** across **9 categories**:

| Category | Skills | Description |
|----------|--------|-------------|
| 01-architecture | 10 | Design patterns, DI, ECS, state machines |
| 02-gameplay | 11 | Character, AI, inventory, combat, save/load |
| 04-visuals-audio | 9 | Shaders, VFX, audio, Cinemachine, lighting |
| 05-ui-ux | 6 | UI Toolkit, Canvas, Input System, responsive |
| 06-performance | 5 | Addressables, pooling, profiling, mobile |
| 07-tools-pipeline | 6 | Editor scripting, testing, localization, MCP |
| 08-backend-monetization | 5 | Multiplayer, IAP, analytics, backend |
| 09-devops-automation | 2 | Build pipelines, CI/CD |
| unity-specific | 6 | General Unity development, C# conventions |

👉 See [INDEX.md](global-config/skills/INDEX.md) for the complete skill list with descriptions.

---

## 🔄 Updating Skills

```bash
cd /path/to/your/unity-project
npx ag-unity
```

Re-running the command updates skills without conflicts (block-based replacement). Existing skills are automatically backed up.

---

## 📁 Repo Structure

```
antigravity-unity-skills/
├── package.json             # npm package config
├── bin/
│   └── cli.mjs              # Cross-platform CLI (ESM)
├── global-config/
│   └── skills/              # 70 Unity skills
│       ├── 01-architecture/
│       ├── 02-gameplay/
│       ├── ...
│       └── INDEX.md
├── scripts/
│   └── update-unity-skills.sh
├── tests/
│   └── run-tests.sh         # Automated test suite
├── unity_context.md         # Extension context + rules
└── gemini-extension.json    # Extension metadata
```

---

## 🤝 Works With Superpowers

This extension is **independent** of [antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers), but they work great together. Both use separate block markers in `GEMINI.md` — no conflicts.

---

## 🔗 Links

- **npm:** [ag-unity](https://www.npmjs.com/package/ag-unity)
- **Superpowers (core skills):** [zasuozz-oss/antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers)
- **Google Antigravity:** [antigravity.google](https://antigravity.google)

## 📝 License

MIT

---

**Last Updated:** 2026-03-13
