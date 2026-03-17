---
name: save-load-serialization
description: "Game save/load system implementation. Use this when the user needs game saves, player progress persistence, JSON/binary serialization, save slots, autosave, or cloud save integration. Also trigger for: 'save game', 'load progress', 'PlayerPrefs alternative', 'persist data', 'save slot', 'autosave', or any question about game persistence — even if they don't say 'save'. Do NOT use for runtime ScriptableObject data — use scriptableobject-architecture instead."
---

# Save Load Serialization

## Overview
Complete save/load system using ISaveable interface pattern. Automatically discovers saveable objects, serializes to JSON, supports multiple save slots, and optional encryption.

## When to Use
- Use when implementing save game functionality
- Use when persisting player progress
- Use when saving inventory, quests, world state
- Use when implementing cloud saves (with adapter)
- Use when autosave is needed

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SaveManager                             │
│              (Central Controller)                           │
├─────────────────────────────────────────────────────────────┤
│  Save() / Load() / SaveToSlot(n) / LoadFromSlot(n)          │
│  FindAllSaveables() → Collect ISaveable objects             │
│  Serialize to JSON → Write to persistentDataPath            │
└─────────────────────────────────────────────────────────────┘
                              ↓
           ┌──────────────────┼──────────────────┐
           ↓                  ↓                  ↓
   ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
   │ PlayerStats   │  │   Inventory   │  │   QuestLog    │
   │ : ISaveable   │  │  : ISaveable  │  │  : ISaveable  │
   └───────────────┘  └───────────────┘  └───────────────┘
         ↓                    ↓                    ↓
   CaptureState()      CaptureState()      CaptureState()
   RestoreState()      RestoreState()      RestoreState()
```

## Components

| Component | Purpose |
|-----------|---------|
| `ISaveable` | Interface for saveable objects |
| `SaveManager` | Central save/load controller |
| `SaveData` | Container for all save states |

## Best Practices
- ✅ Use unique SaveId (GUID or hierarchical path)
- ✅ Use LoadPriority for dependencies (Stats before Inventory)
- ✅ Use [Serializable] structs for save state
- ✅ Handle migration for version changes
- ✅ Validate data on load
- ❌ **NEVER** store MonoBehaviour references
- ❌ **NEVER** store ScriptableObject directly (use ID)
- ❌ **NEVER** assume save data exists

## Few-Shot Examples

### Example 1: ISaveable Implementation
**User**: "Save player stats."

**Agent**:
```csharp
public interface ISaveable
{
    string SaveId { get; }
    int LoadPriority { get; } // Lower = load first
    object CaptureState();
    void RestoreState(object state);
}

public class PlayerStats : MonoBehaviour, ISaveable
{
    [SerializeField] private int _level = 1;
    [SerializeField] private float _experience;
    [SerializeField] private int _gold;

    public string SaveId => "player_stats";
    public int LoadPriority => 0; // Load first

    [Serializable]
    private struct SaveState
    {
        public int Level;
        public float Experience;
        public int Gold;
    }

    public object CaptureState()
    {
        return new SaveState
        {
            Level = _level,
            Experience = _experience,
            Gold = _gold
        };
    }

    public void RestoreState(object state)
    {
        var data = JsonUtility.FromJson<SaveState>(JsonUtility.ToJson(state));
        _level = data.Level;
        _experience = data.Experience;
        _gold = data.Gold;
    }
}
```

### Example 2: SaveManager with Slots
**User**: "Implement save/load with 3 save slots."

**Agent**:
```csharp
public class SaveManager : MonoBehaviour
{
    private const int MaxSlots = 3;
    private const int AutosaveSlot = 99;

    public void SaveToSlot(int slot)
    {
        var saveables = FindObjectsOfType<MonoBehaviour>()
            .OfType<ISaveable>()
            .OrderBy(s => s.LoadPriority);

        var saveData = new Dictionary<string, string>();
        foreach (var saveable in saveables)
        {
            var state = saveable.CaptureState();
            saveData[saveable.SaveId] = JsonUtility.ToJson(state);
        }

        string json = JsonUtility.ToJson(new SaveFile
        {
            Version = Application.version,
            Timestamp = DateTime.UtcNow.ToString("o"),
            Data = saveData
        });

        string path = GetSavePath(slot);
        File.WriteAllText(path, json);
        Debug.Log($"[Save] Saved to slot {slot}: {path}");
    }

    public void LoadFromSlot(int slot)
    {
        string path = GetSavePath(slot);
        if (!File.Exists(path))
        {
            Debug.LogWarning($"[Save] No save file at slot {slot}");
            return;
        }

        string json = File.ReadAllText(path);
        var saveFile = JsonUtility.FromJson<SaveFile>(json);

        var saveables = FindObjectsOfType<MonoBehaviour>()
            .OfType<ISaveable>()
            .OrderBy(s => s.LoadPriority);

        foreach (var saveable in saveables)
        {
            if (saveFile.Data.TryGetValue(saveable.SaveId, out var stateJson))
            {
                var state = JsonUtility.FromJson<object>(stateJson);
                saveable.RestoreState(state);
            }
        }
    }

    public bool HasSave(int slot) => File.Exists(GetSavePath(slot));

    private string GetSavePath(int slot)
    {
        return Path.Combine(Application.persistentDataPath, $"save_{slot}.json");
    }
}

[Serializable]
public class SaveFile
{
    public string Version;
    public string Timestamp;
    public Dictionary<string, string> Data;
}
```

### Example 3: Autosave System
**User**: "Autosave every 5 minutes and on scene change."

**Agent**:
```csharp
public class AutosaveService : MonoBehaviour
{
    [SerializeField] private float _intervalSeconds = 300f; // 5 minutes
    [SerializeField] private SaveManager _saveManager;

    private float _timer;

    private void OnEnable()
    {
        SceneManager.sceneLoaded += OnSceneLoaded;
    }

    private void OnDisable()
    {
        SceneManager.sceneLoaded -= OnSceneLoaded;
    }

    private void Update()
    {
        _timer += Time.unscaledDeltaTime;
        if (_timer >= _intervalSeconds)
        {
            _timer = 0f;
            PerformAutosave();
        }
    }

    private void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        // Autosave when transitioning to a new scene
        if (mode == LoadSceneMode.Single)
        {
            PerformAutosave();
        }
    }

    private void PerformAutosave()
    {
        _saveManager.SaveToSlot(99); // Dedicated autosave slot
        Debug.Log("[Autosave] Saved.");
    }

    private void OnApplicationPause(bool paused)
    {
        if (paused) PerformAutosave(); // Mobile: save when app goes background
    }
}
```

## Related Skills
- `@backend-integration` - Cloud save sync
- `@advanced-game-bootstrapper` - Load on startup
- `@scriptableobject-architecture` - Data containers

## Template Files
- `templates/ISaveable.cs.txt` - Interface
- `templates/SaveManager.cs.txt` - Controller
