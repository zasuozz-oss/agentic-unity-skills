---
name: unity-equip-state-rules
description: "Use when working on item equipping/outfit/dress-up logic with cross-category rules (layers, slots, mutually-exclusive states), ownership checks before purchase prompts, or bugs mentioning items disappearing/unequipping when combining categories."
---

# Unity Equip & Outfit State Rules

## Overview
Equip systems (dress-up outfits, RPG gear slots) carry hidden cross-category state: equipping in one category can implicitly change another (a jacket forcing a shirt style, a style flag hiding a skirt). The canonical regression: a rule fixed for category A silently breaks combination A+B+C. **Every equip-rule change is a cross-category change.**

## When to Use
- Adding or changing rules about which items can be worn/equipped together.
- An item disappears or unequips when combining categories ("wear X + Y → Z disappears").
- An owned/granted item still prompts purchase in gameplay.
- Sort order of equipable items is wrong (especially tutorial/scripted flows).

## Key Concepts

| Concept | Description |
|---------|-------------|
| **Cross-category matrix** | The set of category combinations (e.g. shirt × skirt × jacket × style-state) that any rule change must be re-tested against. |
| **Style/state modifiers** | Flags like "tucked", "layered" that change how OTHER categories render — the usual hiding place for regressions. |
| **Ownership source of truth** | Purchase prompts must read the post-grant owned list, never the catalog price (free/bundle items break otherwise). |
| **Data-source confirmation** | Before "fixing" sort order or item lists, confirm whether the data comes from server or local config. |

## Best Practices
- ✅ **Always** write the affected combination as an STR and test it end-to-end after the change (e.g. `shirt + skirt + jacket + tucked -> shoes`).
- ✅ Search memory/history for the category pair before changing a rule — equip rules are the most regression-prone subsystem class.
- ✅ Centralize visibility decisions per category in one resolver; scattered `SetActive` calls across categories are how items "disappear".
- ✅ Use `TryGetValue` for item-type keyed dictionaries — type/filter maps grow and missing keys throw in production.
- ❌ **NEVER** gate purchase prompts on price/catalog data; gate on ownership.
- ❌ **NEVER** change a category rule without enumerating which OTHER categories read the same state flag.

## Few-Shot Examples

### Example 1: Cross-category visibility resolver
**User**: "[1.0.9 (75)] Lỗi bị mất chân váy khi phối đồ [STR: Mặc áo + Chân váy + Jacket + Sơ vin -> Đi giày -> Mất chân váy]"

**Agent**:
1. Recall history for "skirt jacket" — find the prior fix and what it protected.
2. Locate the single resolver deciding skirt visibility; trace which flags it reads (`tucked`, `hasJacket`).
3. The bug: equipping shoes re-runs the resolver with a stale `tucked` flag → skirt hidden. Fix the flag's lifecycle, not the skirt's `SetActive`.
4. Re-test the full STR plus the PREVIOUS regression's STR before closing.

## Related Skills
- `@unity-bug-regression-workflow` - Memory-first workflow for regression-prone rules.
- `@unity-tutorial-system` - Scripted dress flows and tutorial item data sources.
