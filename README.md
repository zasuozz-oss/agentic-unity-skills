# Antigravity Unity Skills

45 Unity-specific skills for game development with Google Antigravity. Install skills directly into any Unity project.

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

That's it. 45 skills installed.

<details>
<summary>Alternative: Clone + Run</summary>

```bash
git clone https://github.com/zasuozz-oss/antigravity-unity-skills.git ~/AI-Tool/antigravity-unity-skills
cd /path/to/your/unity-project
node ~/AI-Tool/antigravity-unity-skills/bin/cli.mjs
```

> ⚠️ Replace `/path/to/your/unity-project` with your actual Unity project path.

</details>

### What Happens After Setup

```
your-project/
└── .agents/
    ├── skills/                # All skills installed flat here
    │   ├── architecture-advisor/
    │   ├── design-patterns/
    │   ├── qa-doc-parser/
    │   ├── ...
    │   └── .ag-manifest.json  # Tracks group membership
    └── workflows/             # Workflow files
        └── build-ui-mcp.md
```

Skills auto-trigger via YAML frontmatter `description` field — no `GEMINI.md` configuration needed.

---

## 🎯 What Is This?

A collection of **45 Unity-specific skills** organized by category, designed to extend Google Antigravity with deep Unity game development knowledge.

Key features:
- ✅ **One-command install** — `npx ag-unity` from any project
- ✅ **Self-triggering** — skills activate via YAML frontmatter, no manual config
- ✅ **Project-level install** — skills live in your project's `.agents/skills/`
- ✅ **Cross-platform** — pure Node.js, no bash/powershell dependency
- ✅ **Backup on update** — existing skills backed up before overwrite

---

## 📚 What's Inside

**45 skills** across **8 categories**:

| Category | Skills | Description |
|----------|--------|-------------|
| Advisory | 10 | Architecture, patterns, testability, performance advisors |
| Architecture | 8 | Design patterns, DI, state machines, event bus |
| Visuals & Audio | 4 | Shaders, VFX, audio, lighting |
| UI & UX | 5 | UI Toolkit, Canvas, Input System, responsive |
| Performance | 5 | Addressables, pooling, profiling, mobile |
| Tools & Pipeline | 6 | Editor scripting, testing, localization, MCP |
| Backend & Monetization | 2 | IAP, backend integration |
| DevOps + Project | 5 | Build pipelines, C# conventions, general Unity |

👉 See [INDEX.md](global-config/skills/INDEX.md) for the complete skill list with descriptions.

---

## 🔄 Updating Skills

```bash
cd /path/to/your/unity-project
npx ag-unity
```

Re-running the command updates skills. Existing skills are automatically backed up.

---

## 📁 Repo Structure

```
antigravity-unity-skills/
├── package.json             # npm package config
├── bin/
│   └── cli.mjs              # Cross-platform CLI (ESM)
├── global-config/
│   ├── skills/              # Source skills (grouped)
│   │   ├── unity-skills/    # 45 Unity skills
│   │   └── qa-skills/       # 4 QA skills
│   └── workflow/            # Source workflows
│       └── build-ui-mcp.md
├── scripts/
│   └── update-unity-skills.sh
├── tests/
│   └── run-tests.sh         # Automated test suite
└── CHANGELOG.md
```

---

## 🤝 Works With Superpowers

This extension is **independent** of [antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers), but they work great together.

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

**Last Updated:** 2026-03-17
