---
name: asynchronous-programming
description: "Async programming in Unity using Coroutines, async/await, and UniTask. Use this when the user implements async loading, sequential operations, cancellation, timeout patterns, or needs to choose between async approaches. Also trigger for: 'how to load assets async', 'coroutine vs async', 'UniTask tutorial', 'CancellationToken in Unity', 'await in MonoBehaviour', or any question about asynchronous execution — even if they don't say 'async'. Do NOT use for choosing between async models — use async-strategy instead."
---

# Asynchronous Programming

## Overview
Asynchronous programming in Unity using Coroutines, async/await with Task, and UniTask. Covers loading, networking, sequential operations, cancellation, and error handling.

## Async Options Comparison

| Feature | Coroutine | Task | UniTask |
|---------|:---------:|:----:|:-------:|
| Cancellation | StopCoroutine | CancellationToken | CancellationToken |
| Return Value | ❌ | ✅ | ✅ |
| Error Handling | ❌ | try/catch | try/catch |
| Thread-safe | Main only | Any thread | Main (default) |
| GC Allocation | Some | Heavy | Zero |
| Recommendation | Simple delays | Server/PC | Production |

## Best Practices
- ✅ **Always** use CancellationToken with async/UniTask
- ✅ Use `destroyCancellationToken` for MonoBehaviour-bound tasks
- ✅ Use `UniTask.WhenAll` for parallel operations
- ✅ Guard against destroyed objects after await
- ✅ Use `async UniTaskVoid` for fire-and-forget (not `async void`)
- ❌ **NEVER** use `async void` (silent exception swallowing)
- ❌ **NEVER** await without CancellationToken in MonoBehaviour
- ❌ **NEVER** access `this` after await without null guard

## Few-Shot Examples

### Example 1: Sequential Loading with UniTask
**User**: "Load player data, then inventory, then start game."

**Agent**:
```csharp
public class GameLoader : MonoBehaviour
{
    [SerializeField] private Slider _progressBar;

    private async UniTaskVoid Start()
    {
        var ct = destroyCancellationToken;

        try
        {
            _progressBar.value = 0f;

            var playerData = await LoadPlayerDataAsync(ct);
            _progressBar.value = 0.33f;

            var inventory = await LoadInventoryAsync(playerData.Id, ct);
            _progressBar.value = 0.66f;

            var world = await LoadWorldAsync(playerData.LastScene, ct);
            _progressBar.value = 1f;

            InitializeGame(playerData, inventory, world);
        }
        catch (OperationCanceledException)
        {
            Debug.Log("Loading cancelled (scene unloaded)");
        }
        catch (Exception e)
        {
            Debug.LogError($"Loading failed: {e.Message}");
            ShowRetryDialog();
        }
    }

    private async UniTask<PlayerData> LoadPlayerDataAsync(CancellationToken ct)
    {
        var json = await File.ReadAllTextAsync(GetSavePath(), ct);
        return JsonUtility.FromJson<PlayerData>(json);
    }
}
```

### Example 2: Parallel Loading
**User**: "Load textures, audio, and config at the same time."

**Agent**:
```csharp
public class AssetPreloader : MonoBehaviour
{
    public async UniTask PreloadAsync(CancellationToken ct)
    {
        // All three load simultaneously
        var (textures, audioClips, config) = await UniTask.WhenAll(
            LoadTexturesAsync(ct),
            LoadAudioAsync(ct),
            LoadConfigAsync(ct)
        );

        Debug.Log($"Loaded {textures.Length} textures, {audioClips.Length} clips");
        ApplyConfig(config);
    }

    private async UniTask<Texture2D[]> LoadTexturesAsync(CancellationToken ct)
    {
        var handles = new List<UniTask<Texture2D>>();
        foreach (var key in _textureKeys)
        {
            handles.Add(Addressables.LoadAssetAsync<Texture2D>(key)
                .ToUniTask(cancellationToken: ct));
        }
        return await UniTask.WhenAll(handles);
    }
}
```

### Example 3: Timeout and Retry Pattern
**User**: "API call with timeout and retry."

**Agent**:
```csharp
public class ApiClient
{
    private const int MaxRetries = 3;
    private const float TimeoutSeconds = 10f;

    public async UniTask<T> RequestWithRetry<T>(string url, CancellationToken ct)
    {
        for (int attempt = 0; attempt < MaxRetries; attempt++)
        {
            try
            {
                return await RequestWithTimeout<T>(url, TimeoutSeconds, ct);
            }
            catch (TimeoutException)
            {
                Debug.LogWarning($"Attempt {attempt + 1}/{MaxRetries} timed out");
                if (attempt == MaxRetries - 1) throw;
                await UniTask.Delay(TimeSpan.FromSeconds(Math.Pow(2, attempt)), cancellationToken: ct);
            }
        }
        throw new InvalidOperationException("Should not reach here");
    }

    private async UniTask<T> RequestWithTimeout<T>(string url, float timeout, CancellationToken ct)
    {
        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(ct);
        timeoutCts.CancelAfter(TimeSpan.FromSeconds(timeout));

        using var request = UnityWebRequest.Get(url);
        await request.SendWebRequest().ToUniTask(cancellationToken: timeoutCts.Token);

        if (request.result != UnityWebRequest.Result.Success)
            throw new Exception(request.error);

        return JsonUtility.FromJson<T>(request.downloadHandler.text);
    }
}
```

## Cancellation Patterns

| Pattern | When |
|---------|------|
| `destroyCancellationToken` | MonoBehaviour lifetime |
| `CancellationTokenSource` | Manual control |
| `CreateLinkedTokenSource` | Combine multiple tokens |
| `CancelAfter(timeout)` | Timeout |

## Related Skills
- `@async-strategy` - Choosing between async models
- `@addressables-asset-management` - Async asset loading
- `@backend-integration` - Async networking
