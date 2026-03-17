---
name: scene-contracts
description: "Scene composition contract advisor. Use this when the user needs to define required scene objects, component dependencies, bootstrap sequences, reference wiring, or scene validation rules. Also trigger for: 'missing reference in scene', 'NullReferenceException on scene load', 'required objects not found', 'how to validate scene setup', or any question about making scene composition explicit and safe — even if they don't say 'contract'."
---

# Scene Contracts

Use this skill when scene setup needs to be explicit instead of relying on hidden runtime lookups.

## Define

- Required root objects and their components
- Which references are assigned in Inspector vs resolved at runtime
- Which objects act as bootstrap/installers
- Which objects are runtime-spawned
- Which assumptions should be validated early

## Few-Shot Examples

### Example 1: Scene Validator
**User**: "My game crashes because Canvas isn't in the scene."

**Agent**:
```csharp
public class SceneValidator : MonoBehaviour
{
    [Header("Required Scene References")]
    [SerializeField] private Canvas _mainCanvas;
    [SerializeField] private Camera _mainCamera;
    [SerializeField] private EventSystem _eventSystem;

    private void Awake()
    {
        ValidateScene();
    }

    private void ValidateScene()
    {
        bool valid = true;

        if (_mainCanvas == null)
        {
            Debug.LogError("[SceneValidator] MainCanvas is missing!", this);
            valid = false;
        }
        if (_mainCamera == null)
        {
            Debug.LogError("[SceneValidator] MainCamera is missing!", this);
            valid = false;
        }
        if (_eventSystem == null)
        {
            Debug.LogError("[SceneValidator] EventSystem is missing!", this);
            valid = false;
        }

        if (!valid)
        {
            Debug.LogError("[SceneValidator] Scene contract violated! Check required objects.");
        }
    }
}
```

### Example 2: Scene Contract Table
**User**: "Document what must exist in the Gameplay scene."

**Agent**:
```csharp
/// <summary>
/// Gameplay Scene Contract:
/// ┌─────────────────────┬──────────────────────┬─────────────┐
/// │ Object              │ Required Components  │ Wiring      │
/// ├─────────────────────┼──────────────────────┼─────────────┤
/// │ GameManager         │ GameManager          │ Inspector   │
/// │ Player              │ PlayerController,    │ Inspector   │
/// │                     │ Rigidbody, Collider  │             │
/// │ MainCamera          │ Camera, Cinemachine  │ Inspector   │
/// │ UI_Canvas           │ Canvas, CanvasScaler │ Inspector   │
/// │ EventSystem         │ EventSystem          │ Auto        │
/// └─────────────────────┴──────────────────────┴─────────────┘
/// </summary>
[DefaultExecutionOrder(-100)]
public class GameplaySceneContract : MonoBehaviour
{
    [SerializeField] private PlayerController _player;
    [SerializeField] private Camera _mainCamera;
    [SerializeField] private Canvas _uiCanvas;

    private void Awake()
    {
        Debug.Assert(_player != null, "Player is required in Gameplay scene");
        Debug.Assert(_mainCamera != null, "MainCamera is required in Gameplay scene");
        Debug.Assert(_uiCanvas != null, "UI Canvas is required in Gameplay scene");
    }
}
```

### Example 3: Editor-Time Scene Validation
**User**: "Validate scene before entering play mode."

**Agent**:
```csharp
#if UNITY_EDITOR
[InitializeOnLoad]
public static class PlayModeSceneValidator
{
    static PlayModeSceneValidator()
    {
        EditorApplication.playModeStateChanged += OnPlayModeChanged;
    }

    private static void OnPlayModeChanged(PlayModeStateChange state)
    {
        if (state != PlayModeStateChange.ExitingEditMode) return;

        var scene = SceneManager.GetActiveScene();
        if (scene.name == "Gameplay")
        {
            if (GameObject.FindObjectOfType<PlayerController>() == null)
            {
                Debug.LogError("[SceneValidator] Gameplay scene requires a PlayerController!");
                EditorApplication.isPlaying = false;
            }
        }
    }
}
#endif
```

## Output Format

- Scene object contract (table of required objects + components)
- Bootstrap sequence (ordered initialization)
- Inspector wiring rules
- Validation rules (`OnValidate`, runtime checks)
- Hidden dependency risks

## Guardrails

- Prefer explicit scene wiring over chains of runtime `Find`
- Keep bootstrap objects small and focused
- Validate early — fail fast with clear error messages
- Don't over-specify — only contract what actually matters

## Related Skills
- `@project-scout` - Inspect existing project structure
- `@architecture-advisor` - System-level architecture
- `@advanced-game-bootstrapper` - Bootstrap scene pattern
