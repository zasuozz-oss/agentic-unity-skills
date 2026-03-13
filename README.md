# Antigravity Unity Skills

70 Unity-specific skills for game development with Google Antigravity. Project-level extension — install skills directly into any Unity project.

> **📦 This is a public, read-only repository.** Clone it and use the setup scripts to install skills into your projects.

🌐 [Quick Start](#-quick-start) · [What's Inside](#-whats-inside) · [Full Skill List](global-config/skills/INDEX.md)

## 📋 Requirements

- [Google Antigravity](https://antigravity.google) (macOS / Windows / Linux)
- Git
- Bash (macOS/Linux) or PowerShell (Windows)

## 🎯 What Is This?

A collection of **70 Unity-specific skills** organized by category, designed to extend Google Antigravity with deep Unity game development knowledge.

Key features:
- ✅ **Project-level install** — skills live in your project's `.agents/skills-unity/`
- ✅ **No global dependency** — works independently of [antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers)
- ✅ **Non-destructive setup** — preserves existing `GEMINI.md` content
- ✅ **Block-based updates** — re-run setup to update without conflicts

## ⚡ Quick Start

### 1. Clone This Repository

```bash
git clone https://github.com/zasuozz-oss/antigravity-unity-skills.git
```

### 2. Run Setup in Your Unity Project

**macOS / Linux:**

```bash
cd /path/to/your/unity-project
bash /path/to/antigravity-unity-skills/setup-project.sh
```

**Windows (PowerShell):**

```powershell
cd C:\path\to\your\unity-project
powershell -ExecutionPolicy Bypass -File C:\path\to\antigravity-unity-skills\setup-project.ps1
```

### 3. Done — Start Using

Open Antigravity in your project. Unity skills auto-load via `GEMINI.md`.

### What Happens After Setup

```
your-project/
├── GEMINI.md                # Updated with unity-skills block
└── .agents/
    └── skills-unity/        # 70 Unity skills installed here
        └── INDEX.md
```

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

## 🔄 Updating Skills

To update skills in an existing project:

```bash
# 1. Pull latest from this repo
cd /path/to/antigravity-unity-skills
git pull

# 2. Re-run setup in your project
cd /path/to/your/unity-project
bash /path/to/antigravity-unity-skills/setup-project.sh
```

Or use the update script:

```bash
cd /path/to/your/unity-project
bash /path/to/antigravity-unity-skills/scripts/update-unity-skills.sh
```

## 📁 Repo Structure

```
antigravity-unity-skills/
├── setup-project.sh         # Install script (macOS/Linux)
├── setup-project.ps1        # Install script (Windows)
├── scripts/
│   └── update-unity-skills.sh  # Update script
├── global-config/
│   └── skills/              # 70 Unity skills
│       ├── 01-architecture/
│       ├── 02-gameplay/
│       ├── ...
│       └── INDEX.md
├── GEMINI.md                # Project config template
├── gemini-extension.json    # Extension metadata
└── tests/
    └── README.md            # Manual test cases
```

## 🤝 Works With Superpowers

This extension is **independent** of [antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers), but they work great together. Both use separate block markers in `GEMINI.md` — no conflicts.

## 🔗 Links

- **Superpowers (core skills):** [zasuozz-oss/antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers)
- **Google Antigravity:** [antigravity.google](https://antigravity.google)

## 📝 License

MIT

---

**Last Updated:** 2026-03-13
