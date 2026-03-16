---
name: gameplay-blueprints
description: "Mini-game architecture blueprint advisor. Use this when the user wants a starting structure for a platformer, shooter, runner, puzzle, tower defense, clicker, or card game prototype without dumping a huge framework."
---

# Gameplay Blueprints

> Adapted from [Besty0728/Unity-Skills](https://github.com/Besty0728/Unity-Skills) (MIT License)

Use this skill when starting a new mini-game or vertical slice and a lightweight architecture skeleton is more useful than raw code volume.

## Supported Blueprint Styles

- 2D platformer
- Top-down shooter
- Endless runner
- Puzzle / interaction game
- Tower defense
- Clicker / incremental
- Card / turn-based prototype

## Output Format

- **Core loop**: What the player does repeatedly
- **Recommended scenes**: Menu, Gameplay, Results
- **Recommended modules**: Input, GameManager, ScoreSystem, etc.
- **Initial script list**: With roles (MonoBehaviour, SO, pure C#)
- **Data/config assets**: ScriptableObjects for tuning
- **UI responsibilities**: What each panel does
- **What to keep simple**: Deliberately minimal areas

## Guardrails

- Provide the **smallest viable blueprint**, not a giant reusable framework
- Prefer a short script inventory over "future-proof" template sprawl
- Each blueprint should be implementable in 1-2 days

## Related Skills
- `@script-roles` - Assign class roles before coding
- `@architecture-advisor` - Scale up if project grows
- `@state-machine-architect` - Game state management
