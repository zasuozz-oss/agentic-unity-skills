# Antigravity Unity Skills

Project skills for Unity game development with Antigravity, Claude Code, and Codex. Build the `ag-unity` CLI locally once, then install skills directly into each Unity project.

> Local build/link workflow. This repo does not install global skills.

[Quick Start](#-quick-start) · [What's Inside](#-whats-inside) · [Skill Index](global-config/skills/unity-skills/INDEX.md)

## Requirements

- Google Antigravity, Claude Code, or Codex
- Node.js 18+

---

## Quick Start

Build and link the CLI from this repo:

```bash
git clone https://github.com/zasuozz-oss/antigravity-unity-skills.git ~/AI-Tool/antigravity-unity-skills
cd ~/AI-Tool/antigravity-unity-skills
./setup.sh
```

Then run in the root of your Unity project:

```bash
cd /path/to/your/unity-project
ag-unity init
```

`ag-unity init` always uses the current working directory. This command does not accept a project path argument.

### After Init

```text
your-project/
├── .agents/
│   └── skills/                 # Project skills for Antigravity and Codex
│       ├── unity-addressables/
│       ├── unity-code-audit/
│       ├── unity-csharp-standards/
│       ├── unity-qa-parser/
│       ├── ...
│       └── .ag-unity-manifest.json
└── .claude/
    └── skills/                 # Project skills for Claude Code
        └── ...
```

Skills auto-activate via YAML frontmatter `description`. The installer does not create `GEMINI.md`, `.codex/skills`, nor write to `~/.codex`, `~/.claude`, or `~/.gemini`.

---

## What Is This?

A set of **Unity project skills** organized by group under `global-config`, giving AI coding agents specialized context when working with Unity.

Key features:

- **Local build/link workflow**: build once, use `ag-unity` across all projects
- **Project-level install**: skills live inside the current project's agent folders
- **Multi-agent project skills**: installs to `.agents/skills/` for Antigravity/Codex and `.claude/skills/` for Claude Code
- **Dynamic skill discovery**: copies every skill with a `SKILL.md` under `global-config` — no CLI changes needed when adding or splitting skill groups
- **Self-triggering**: skills activate via YAML frontmatter, no manual config required
- **Cross-platform**: pure Node.js, no bash/powershell dependency
- **Idempotent update**: re-running `ag-unity init` replaces managed skills without duplication

---

## What's Inside

The CLI automatically scans `global-config/**/SKILL.md` and installs them flat into the project. This means you can split groups or add new skills under `global-config/skills/<group>/<skill>/SKILL.md` without modifying the CLI.

Current groups include `unity-skills` for Unity advisory skills and `qa-skills` for QA workflow skills. Run `ag-unity list` to see the current packaged skills. See [INDEX.md](global-config/skills/unity-skills/INDEX.md) for the Unity skills group.

---

## Updating Skills

```bash
cd ~/AI-Tool/antigravity-unity-skills
git pull
./setup.sh

cd /path/to/your/unity-project
ag-unity init
```

Re-running `ag-unity init` updates managed skills without creating duplicates.

---

## CLI Commands

```bash
ag-unity init       # Install project skills into current project
ag-unity list       # List packaged skills
ag-unity version    # Show package version
ag-unity help       # Show help
```

---

## Repo Structure

```text
antigravity-unity-skills/
├── package.json             # npm package config
├── setup.sh                 # Autosetup: build + npm link ag-unity
├── src/
│   └── cli/
│       └── index.js         # CLI source
├── scripts/
│   └── build.js             # Build dist/cli/index.js
├── dist/
│   └── cli/
│       └── index.js         # Generated CLI used by ag-unity
├── global-config/
│   └── skills/              # Source skills by group
│       ├── unity-skills/
│       ├── qa-skills/
│       └── ...              # New groups are auto-discovered by CLI
├── docs/                    # Source references
├── tests/
│   └── run-tests.sh         # Automated test suite
└── CHANGELOG.md
```

---

## Works With Superpowers

This extension is independent of [antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers), but works well alongside it.

---

## Links

- npm: [ag-unity](https://www.npmjs.com/package/ag-unity)
- Superpowers: [zasuozz-oss/antigravity-superpowers](https://github.com/zasuozz-oss/antigravity-superpowers)
- Google Antigravity: [antigravity.google](https://antigravity.google)

## Credits

Advisory skills adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License).

## License

MIT
