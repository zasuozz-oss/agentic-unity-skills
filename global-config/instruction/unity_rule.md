<!-- AG-UNITY:BEGIN -->

# Unity Verification

When editing or writing C# scripts in a Unity project, verify with the **utk CLI** as follows:

**1. Use utk to compile-check.**
   - After editing a `.cs` file, run `utk editor refresh --compile` (recompiles and blocks until done), then `utk console --type error --lines 20` to read compilation errors.
   - If `utk` is unavailable or no Editor is connected (`utk status` fails / reports `not responding`), skip this verify/compile-check step.

**2. Use utk to run Unity Test Runner.**
   - Use `utk test [--mode EditMode|PlayMode] [--filter Ns.Class.Test]` to run the appropriate tests.
   - If `utk` is unavailable, skip Unity Test Runner.

*Note: Do not fallback to Unity batchmode commands, dotnet build, or launching another Unity Editor instance for Unity verification. If utk is unavailable, skip all Unity verification steps related to Unity Test Runner and Unity compile-checks.*

*For how to drive utk itself (exec, console, subagent delegation, etc.), follow utk's own rule and skill.*

# UI Button Wiring (NEVER wire onClick in script code)

**NEVER** wire UI Button handlers at runtime in C# scripts. Patterns like the following are FORBIDDEN:

```csharp
// ❌ FORBIDDEN — do not write this
if (closeButton != null)
{
    closeButton.onClick.RemoveAllListeners();
    closeButton.onClick.AddListener(Close);
}
```

This also applies to any `onClick.AddListener(...)`, `onClick.RemoveAllListeners()`, `onClick.RemoveListener(...)`, or equivalent runtime wiring in `Awake`/`OnEnable`/`Start` for UI Buttons.

**Instead, bind the handler as a persistent listener on the Button itself**, using one of:

1. **Edit the scene/prefab YAML directly** — add the target method to the Button's `m_OnClick.m_PersistentCalls.m_Calls` (set `m_Target` to the component's `fileID`, `m_MethodName` to the handler, `m_Mode` to match the signature, and `m_CallState: 2`).
2. **Use editor tooling** (e.g. `utk exec` running `UnityEventTools.AddPersistentListener` / `SerializedObject` edits) to register the handler on the Button's `onClick`, then save the asset.

After wiring, verify the binding exists in the serialized asset (the YAML shows the persistent call), not just that the code compiles.

<!-- AG-UNITY:END -->
