# Antigravity Unity Skills

70 Unity-specific skills for game development with Google Antigravity. Project-level extension — install skills directly into any Unity project.

🌐 [Quick Start](#-quick-start) · [Features](#-whats-inside) · [Report Bug](https://github.com/zasuozz-oss/antigravity-unity-skills/issues)

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

### 1. Clone Repository

```bash
git clone https://github.com/zasuozz-oss/antigravity-unity-skills.git
```

### 2. Setup Project

```bash
cd /path/to/your/unity-project
bash /path/to/antigravity-unity-skills/setup-project.sh
```

Windows (PowerShell):

```powershell
cd C:\path\to\your\unity-project
powershell -ExecutionPolicy Bypass -File C:\path\to\antigravity-unity-skills\setup-project.ps1
```

### 3. Start Using

Open Antigravity in your project. Unity skills auto-load via `GEMINI.md`.

## 📚 What's Inside

### Categories (9)

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

See [INDEX.md](global-config/skills/INDEX.md) for the full skill list.

## 📁 Structure

```
antigravity-unity-skills/
├── setup-project.sh         # Install script (macOS/Linux)
├── setup-project.ps1        # Install script (Windows)
├── GEMINI.md                # Project configuration template
├── gemini-extension.json    # Extension metadata
├── scripts/
│   └── update-unity-skills.sh  # Update script
├── global-config/
│   └── skills/              # 70 Unity skills
│       ├── 01-architecture/
│       ├── 02-gameplay/
│       ├── 04-visuals-audio/
│       ├── 05-ui-ux/
│       ├── 06-performance/
│       ├── 07-tools-pipeline/
│       ├── 08-backend-monetization/
│       ├── 09-devops-automation/
│       ├── unity-specific/
│       └── INDEX.md
└── tests/
    └── README.md            # 10 manual test cases
```

After setup in your project:

```
your-project/
├── GEMINI.md                # Updated with unity-skills block
└── .agents/
    └── skills-unity/        # 70 Unity skills installed here
```

## 🔄 Updating

```bash
cd /path/to/your/unity-project
bash /path/to/antigravity-unity-skills/scripts/update-unity-skills.sh
```

## 🤝 Works With Superpowers

This extension is **independent** of [antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers), but they work great together. Both use separate block markers in `GEMINI.md` — no conflicts.

## 🔗 Links

- Superpowers (core skills): [zasuozz-oss/antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers)
- Google Antigravity: [antigravity.google](https://antigravity.google)

## 📝 License

MIT

---

**Last Updated:** 2026-03-13
