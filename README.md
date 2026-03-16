# Antigravity Unity Skills

67 Unity-specific skills for game development with Google Antigravity. Install skills directly into any Unity project.

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

That's it. 67 skills installed.

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
    └── skills/unity-skills/  # 67 Unity skills installed here
        └── INDEX.md
```

Open Antigravity in your project. Unity skills auto-load via `GEMINI.md`.

---

## 🎯 What Is This?

A collection of **67 Unity-specific skills** organized by category, designed to extend Google Antigravity with deep Unity game development knowledge.

Key features:
- ✅ **One-command install** — `npx ag-unity` from any project
- ✅ **Project-level install** — skills live in your project's `.agents/skills-unity/`
- ✅ **Cross-platform** — pure Node.js, no bash/powershell dependency
- ✅ **Non-destructive setup** — preserves existing `GEMINI.md` content
- ✅ **Block-based updates** — re-run setup to update without conflicts
- ✅ **Backup on update** — existing skills backed up before overwrite

---

## 📚 What's Inside

**67 skills** across **10 categories**:

| Category | Skills | Description |
|----------|--------|-------------|
| Advisory | 13 | Architecture, patterns, testability, performance advisors |
| Architecture | 8 | Design patterns, DI, ECS, state machines |
| Gameplay | 10 | Character, AI, inventory, combat, save/load |
| Visuals & Audio | 7 | Shaders, VFX, audio, Cinemachine, lighting |
| UI & UX | 5 | UI Toolkit, Canvas, Input System, responsive |
| Performance | 5 | Addressables, pooling, profiling, mobile |
| Tools & Pipeline | 6 | Editor scripting, testing, localization, MCP |
| Backend & Monetization | 4 | Multiplayer, IAP, analytics, backend |
| DevOps | 1 | Build pipelines |
| Project-Specific | 5 | General Unity development, C# conventions |

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
│   └── skills/              # 67 Unity skills (flat structure)
│       ├── architecture-advisor/
│       ├── design-patterns/
│       ├── ...
│       └── INDEX.md
├── tests/
│   └── run-tests.sh         # Automated test suite
└── CHANGELOG.md
```

---

## 🤝 Works With Superpowers

This extension is **independent** of [antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers), but they work great together. Both use separate block markers in `GEMINI.md` — no conflicts.

---

## 🔗 Links

- **npm:** [ag-unity](https://www.npmjs.com/package/ag-unity)
- **Superpowers (core skills):** [zasuozz-oss/antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers)
- **Google Antigravity:** [antigravity.google](https://antigravity.google)

## 🙏 Credits

Advisory skills adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License).

## 📝 License

MIT

---

**Last Updated:** 2026-03-16
