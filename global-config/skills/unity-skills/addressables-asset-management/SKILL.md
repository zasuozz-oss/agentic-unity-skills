---
name: addressables-asset-management
description: "Unity Addressables system specialist. Use this when the user needs async asset loading, AssetReference usage, memory-safe resource management, remote content delivery, or asset bundle modernization. Also trigger for: 'load asset at runtime', 'Resources.Load alternative', 'AssetReference', 'download content', 'memory leak from assets', 'unload assets', or any question about dynamic asset loading — even if they don't say 'Addressables'. Do NOT use for import settings — use asset-import-pipeline instead."
---

# Addressables Asset Management

## Overview
Unity Addressables for asynchronous, memory-safe asset loading. Replace direct references and Resources.Load with addressable keys and AssetReferences for scalable content management.

## When to Use
- Use when loading assets at runtime
- Use when replacing Resources.Load
- Use when managing remote/downloadable content
- Use when optimizing memory with load/release patterns
- Use when sharing assets across scenes

## Key Concepts

| Concept | Description |
|---------|-------------|
| **AssetReference** | Inspector-assignable addressable reference |
| **Address/Label** | String key or tag for loading |
| **Handle** | AsyncOperationHandle — tracks load state, MUST be released |
| **Release** | Free memory when done |
| **Catalog** | Index of all addressable assets |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   ADDRESSABLE FLOW                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  AssetReference               Handle                        │
│  (Inspector)    →  LoadAsync  →  Use Asset  →  Release      │
│                                                             │
│  ⚠️ EVERY LoadAsync MUST have a matching Release            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices
- ✅ **Always** release handles when done (`Addressables.Release(handle)`)
- ✅ Use `AssetReference` in Inspector for type safety
- ✅ Use labels for batch operations (preload by label)
- ✅ Track active handles for cleanup
- ✅ Use `WaitForCompletion()` only in synchronous contexts
- ❌ **NEVER** forget to release loaded assets (memory leak)
- ❌ **NEVER** release an already-released handle
- ❌ **NEVER** use `Resources.Load` for addressable assets

## Few-Shot Examples

### Example 1: Asset Loading Service
**User**: "Load and manage prefabs with Addressables."

**Agent**:
```csharp
public class AssetLoadingService : MonoBehaviour
{
    private readonly Dictionary<string, AsyncOperationHandle> _loadedAssets = new();

    public async UniTask<T> LoadAssetAsync<T>(string key, CancellationToken ct) where T : Object
    {
        if (_loadedAssets.TryGetValue(key, out var existing))
            return (T)existing.Result;

        var handle = Addressables.LoadAssetAsync<T>(key);
        await handle.ToUniTask(cancellationToken: ct);

        if (handle.Status == AsyncOperationStatus.Succeeded)
        {
            _loadedAssets[key] = handle;
            return handle.Result;
        }

        Debug.LogError($"Failed to load asset: {key}");
        Addressables.Release(handle);
        return null;
    }

    public void ReleaseAsset(string key)
    {
        if (_loadedAssets.TryGetValue(key, out var handle))
        {
            Addressables.Release(handle);
            _loadedAssets.Remove(key);
        }
    }

    private void OnDestroy()
    {
        foreach (var handle in _loadedAssets.Values)
            Addressables.Release(handle);
        _loadedAssets.Clear();
    }
}
```

### Example 2: Prefab Spawning with AssetReference
**User**: "Spawn enemies from AssetReference."

**Agent**:
```csharp
public class EnemySpawner : MonoBehaviour
{
    [SerializeField] private AssetReferenceGameObject _enemyPrefab;

    private readonly List<AsyncOperationHandle<GameObject>> _spawnedHandles = new();

    public async UniTask<GameObject> SpawnAsync(Vector3 position, CancellationToken ct)
    {
        var handle = _enemyPrefab.InstantiateAsync(position, Quaternion.identity);
        await handle.ToUniTask(cancellationToken: ct);

        if (handle.Status == AsyncOperationStatus.Succeeded)
        {
            _spawnedHandles.Add(handle);
            return handle.Result;
        }

        Debug.LogError("Failed to spawn enemy");
        return null;
    }

    public void Despawn(GameObject enemy)
    {
        var handle = _spawnedHandles.FirstOrDefault(h => h.Result == enemy);
        if (handle.IsValid())
        {
            _spawnedHandles.Remove(handle);
            Addressables.ReleaseInstance(enemy);
        }
    }

    private void OnDestroy()
    {
        foreach (var handle in _spawnedHandles)
        {
            if (handle.IsValid())
                Addressables.ReleaseInstance(handle);
        }
        _spawnedHandles.Clear();
    }
}
```

### Example 3: Preload by Label
**User**: "Preload all 'level-1' tagged assets."

**Agent**:
```csharp
public class LevelPreloader : MonoBehaviour
{
    private AsyncOperationHandle<IList<Object>> _preloadHandle;

    public async UniTask PreloadLevelAsync(string label, CancellationToken ct)
    {
        _preloadHandle = Addressables.LoadAssetsAsync<Object>(
            label, asset => Debug.Log($"Loaded: {asset.name}"));

        await _preloadHandle.ToUniTask(cancellationToken: ct);

        Debug.Log($"Preloaded {_preloadHandle.Result.Count} assets for '{label}'");
    }

    public void UnloadLevel()
    {
        if (_preloadHandle.IsValid())
        {
            Addressables.Release(_preloadHandle);
        }
    }

    private void OnDestroy() => UnloadLevel();
}
```

## Related Skills
- `@memory-profiler-expert` - Tracking asset memory usage
- `@mobile-optimization` - Performance optimization
- `@mobile-optimization` - Mobile asset loading strategies
