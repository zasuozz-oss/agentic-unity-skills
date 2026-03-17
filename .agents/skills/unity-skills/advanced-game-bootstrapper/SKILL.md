---
name: advanced-game-bootstrapper
description: "Game bootstrapper and initialization system. Use this when the user needs deterministic initialization order, bootstrap scenes, manager registration, splash screen → gameplay flow, or race condition prevention at startup. Also trigger for: 'managers aren't ready when I need them', 'NullReference on game start', 'initialization order', 'loading screen before gameplay', 'DontDestroyOnLoad setup', or any startup/initialization problem — even if they don't say 'bootstrap'."
---

# Advanced Game Bootstrapper

## Overview
Controlled game startup using a Bootstrap scene pattern. Prevents race conditions by enforcing deterministic initialization order for all managers and services.

## When to Use
- Use when managers depend on each other's readiness
- Use when game has loading screens before gameplay
- Use when multiple scenes share persistent managers
- Use when experiencing NullReferenceExceptions at startup
- Use when initialization order matters (Auth → Profile → Inventory)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  BOOTSTRAP FLOW                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  BOOTSTRAP SCENE (loaded first, always)                      │
│  ┌─────────────────────────────────────────────────────┐     │
│  │ GameBootstrapper : MonoBehaviour                     │     │
│  │   1. Find all IInitializable                        │     │
│  │   2. Sort by Priority                               │     │
│  │   3. Initialize in order (await each)               │     │
│  │   4. Load first gameplay scene                      │     │
│  └─────────────────────────────────────────────────────┘     │
│         ↓              ↓               ↓                     │
│  ┌───────────┐  ┌───────────┐  ┌──────────────┐             │
│  │ AuthMgr   │  │ SaveMgr   │  │ AudioMgr     │             │
│  │ Priority 0│  │ Priority 1│  │ Priority 2   │             │
│  └───────────┘  └───────────┘  └──────────────┘             │
│                                                              │
│  GAMEPLAY SCENE (loaded after bootstrap completes)           │
│  All managers guaranteed ready                               │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices
- ✅ Use a dedicated Bootstrap scene (set as Build Index 0)
- ✅ Use `IInitializable` interface with priority ordering
- ✅ Mark bootstrap root as `DontDestroyOnLoad`
- ✅ Show a loading screen during initialization
- ✅ Use `async/await` for async initialization steps
- ❌ **NEVER** access managers before bootstrap completes
- ❌ **NEVER** use `Awake()` ordering for cross-manager dependencies
- ❌ **NEVER** scatter `DontDestroyOnLoad` across random scripts

## Few-Shot Examples

### Example 1: Bootstrapper with Ordered Initialization
**User**: "My AudioManager tries to load settings before SaveManager is ready."

**Agent**:
```csharp
public interface IInitializable
{
    int Priority { get; } // Lower = initialize first
    UniTask InitializeAsync(CancellationToken ct);
}

public class GameBootstrapper : MonoBehaviour
{
    private async void Start()
    {
        DontDestroyOnLoad(gameObject);

        var initializables = GetComponentsInChildren<IInitializable>()
            .OrderBy(i => i.Priority)
            .ToList();

        foreach (var init in initializables)
        {
            Debug.Log($"[Bootstrap] Initializing {init.GetType().Name} (priority {init.Priority})");
            await init.InitializeAsync(destroyCancellationToken);
        }

        Debug.Log("[Bootstrap] All systems ready. Loading main menu.");
        await SceneManager.LoadSceneAsync("MainMenu", LoadSceneMode.Additive);
    }
}

// SaveManager loads first (priority 0)
public class SaveManager : MonoBehaviour, IInitializable
{
    public int Priority => 0;
    public async UniTask InitializeAsync(CancellationToken ct)
    {
        _saveData = await LoadSaveDataAsync(ct);
    }
}

// AudioManager loads second (priority 1), can safely read SaveManager
public class AudioManager : MonoBehaviour, IInitializable
{
    public int Priority => 1;
    public async UniTask InitializeAsync(CancellationToken ct)
    {
        float volume = SaveManager.Instance.GetFloat("master_volume", 1f);
        _mixer.SetFloat("MasterVolume", Mathf.Log10(volume) * 20f);
    }
}
```

### Example 2: Loading Screen Integration
**User**: "Show progress bar during bootstrap."

**Agent**:
```csharp
public class BootstrapLoadingScreen : MonoBehaviour
{
    [SerializeField] private Slider _progressBar;
    [SerializeField] private TextMeshProUGUI _statusText;

    public async UniTask RunBootstrap(IInitializable[] systems, CancellationToken ct)
    {
        _progressBar.maxValue = systems.Length;

        for (int i = 0; i < systems.Length; i++)
        {
            _statusText.text = $"Loading {systems[i].GetType().Name}...";
            _progressBar.value = i;

            await systems[i].InitializeAsync(ct);
        }

        _statusText.text = "Ready!";
        _progressBar.value = systems.Length;

        await UniTask.Delay(500, cancellationToken: ct); // Brief pause for UX
    }
}
```

### Example 3: Shutdown with Reverse Order
**User**: "Clean up managers in reverse order on quit."

**Agent**:
```csharp
public interface IShutdownable
{
    int Priority { get; }
    void Shutdown();
}

public class GameBootstrapper : MonoBehaviour
{
    private List<IShutdownable> _shutdownables;

    private void OnApplicationQuit()
    {
        // Shutdown in reverse priority order
        var ordered = _shutdownables.OrderByDescending(s => s.Priority);
        foreach (var s in ordered)
        {
            Debug.Log($"[Bootstrap] Shutting down {s.GetType().Name}");
            s.Shutdown();
        }
    }
}
```

## Related Skills
- `@scene-contracts` - Scene validation and requirements
- `@di-container-manager` - DI-based service registration
- `@save-load-serialization` - Persistence during bootstrap
