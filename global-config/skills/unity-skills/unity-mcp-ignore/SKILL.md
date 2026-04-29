---
name: unity-mcp-ignore
description: "MANDATORY guardrails before any Unity scene, prefab, or Inspector modification. Enforces: persistent onClick wiring (never AddListener), SerializeField assignment completion, no unrequested editor scripts, scope confirmation for hierarchy changes."
---

# MCP Behavioral Guardrails for Unity

**Load this skill before touching any scene, prefab, or Inspector data.**

---

## Rule 1 — Button onClick: Persistent Wiring Only

Wire every Button's `onClick` as a **persistent UnityEvent** in the scene/prefab. Never use `AddListener` in code — not for static UI, not for dynamic UI, not for pooled buttons.

### ❌ Forbidden — never use AddListener on Button.onClick

```csharp
_button.onClick.AddListener(OnClicked);
_button.onClick.AddListener(delegate { Close(); });
_button.onClick.AddListener(() => Confirm(42));
```

### ✅ Required — persistent UnityEvent in Inspector

**Step 1:** The MonoBehaviour exposes a `public` handler method:

```csharp
public class ShopPresenter : MonoBehaviour
{
    // This method is the onClick target — wired in Inspector, not in code
    public void OnBuyClicked() { /* purchase logic */ }
}
```

**Step 2:** Wire the Button's `onClick` persistent event via MCP:
- Mode: `Runtime Only`
- Target: the GameObject holding `ShopPresenter`
- Method: `ShopPresenter.OnBuyClicked`

**Step 3:** Verify the wiring is correct before reporting done.

### Do NOT add a Button SerializeField just for onClick

### Dynamic / Pooled Buttons

Same rule: wire `onClick` **persistently in the prefab**. If MCP cannot create the persistent event, **stop and report the limitation**. Never fall back to AddListener.

### Cannot do it? Stop.

If MCP cannot safely create or update the persistent UnityEvent, **stop and report the limitation to the user**. Do not silently fall back to any runtime wiring.

---

## Rule 2 — SerializeField: Assign Before Done

Every `[SerializeField]` field added or modified by MCP **must be assigned** to a scene/prefab object before the task is complete.

### ❌ Never leave unassigned

```
HealthManager (Script)
  Max Health    100
  Health Bar    None (Slider)        ← WRONG — unassigned
  Damage VFX    None (GameObject)    ← WRONG — unassigned
```

### ✅ Required — all fields populated

```
HealthManager (Script)
  Max Health    100
  Health Bar    ● Slider (Slider)        ← assigned
  Damage VFX    ● DamageEffect (GameObject)  ← assigned
```

Steps:
1. Identify the correct scene/prefab object for each field.
2. Assign via MCP before reporting done.
3. Read back the component state to confirm — field must not show `None`.

**Cannot find the target?** Stop and ask the user — do not guess.

**User asks for partial script only?** Then unassigned fields are acceptable — but state this explicitly.

---

## Rule 3 — Editor Scripts: Never Create Unless Asked

Do not create Editor scripts (`[MenuItem]`, `EditorWindow`, `PropertyDrawer`) to wire buttons, assign fields, or automate Inspector operations — unless the user explicitly requests editor tooling.

### ✅ Correct approach

Use MCP's direct scene/prefab write capabilities. Editor scripts for wiring are a workaround that creates tooling debt.

**User explicitly says** "create an editor script" / "add a menu item" / "build an editor window" → use `@unity-editor-tools` skill.

---

## Rule 4 — Hierarchy Changes: Confirm Scope

Before structural changes to scene/prefab hierarchy, confirm with the user if the change goes beyond the single component being worked on.

| Needs confirmation | No confirmation needed |
|---|---|
| Adding new GameObjects | Assigning a SerializeField reference |
| Reparenting existing objects | Wiring a Button onClick |
| Deleting GameObjects or components | Updating property values (position, size, color) |
| Modifying shared prefabs (multi-scene) | |

---

## Quick Reference

| Action | Allowed? | Rule |
|--------|----------|------|
| Persistent onClick UnityEvent | ✅ Always | Wire in Inspector, not in code |
| `AddListener` on Button.onClick | ❌ Never | No exceptions — not even dynamic/pooled |
| `[SerializeField]` Button just for onClick | ❌ No | Only if script controls Button programmatically |
| Assign SerializeField references | ✅ Yes | Must complete before reporting done |
| Leave SerializeField as `None` | ❌ No | Unless user asks for partial script |
| Create editor script for wiring | ❌ No | Unless user explicitly requests |
| Structural hierarchy changes | ⚠️ Confirm | Ask if scope goes beyond current component |

---

## Boundary with Other Skills

- `@unity-event-safety` has an `AddListener ↔ RemoveListener` pairing rule. That rule applies to **C# events and non-Button UnityEvents only** — never to `Button.onClick`.
- `@unity-editor-tools` — use when user explicitly requests editor windows, menu items, or PropertyDrawers.
- `@unity-ugui-layout` — RectTransform, anchors, Canvas layout setup via MCP.
