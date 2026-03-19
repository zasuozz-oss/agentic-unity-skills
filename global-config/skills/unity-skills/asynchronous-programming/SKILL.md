---
name: asynchronous-programming
description: "Async programming in Unity using Coroutines, async/await, and UniTask. Use this when the user implements async loading, sequential operations, cancellation, timeout patterns, lifecycle safety, or needs to choose between async approaches. Also trigger for: 'how to load assets async', 'coroutine vs async', 'UniTask tutorial', 'CancellationToken in Unity', 'await in MonoBehaviour', 'should I use coroutine or async', 'UniTask vs coroutine', 'which async pattern', 'timer implementation', or any question about asynchronous execution — even if they don't say 'async'."
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

## Lifecycle Safety Guards

### Null Check After Await
Every `await` in a MonoBehaviour may resume after the object is destroyed.
```csharp
// ❌ BAD: Accessing this after await without guard
var data = await APIManager.GetData();
UpdateUI(data); // MissingReferenceException if destroyed!

// ✅ GOOD: Guard after every await
var data = await APIManager.GetData();
if (this == null) return;  // Survival check
UpdateUI(data);
```

### Coroutine After Await
```csharp
// ❌ BAD: StartCoroutine on inactive/destroyed object
await LongTask();
StartCoroutine(AnimateDots()); // Crash if destroyed or inactive!

// ✅ GOOD: Guard both existence and active state
await LongTask();
if (this == null || !gameObject.activeInHierarchy) return;
_animateRoutine = StartCoroutine(AnimateDots());
```

### Stored Coroutine Reference
```csharp
// ❌ BAD: StopCoroutine(Method()) creates new instance
StopCoroutine(AnimateDots()); // Does NOT stop the running one!

// ✅ GOOD: Store and stop the exact reference
private Coroutine _routine;
_routine = StartCoroutine(AnimateDots());
// Later:
if (_routine != null) { StopCoroutine(_routine); _routine = null; }
```

## CancellationTokenSource Management

Always follow the **Cancel → Dispose → Recreate** pattern:
```csharp
private CancellationTokenSource _cts;

public void StartLoading()
{
    // 1. Cancel and dispose previous
    _cts?.Cancel();
    _cts?.Dispose();
    _cts = new CancellationTokenSource();

    // 2. Pass token to async method
    LoadData(_cts.Token).Forget();
}

private async UniTask LoadData(CancellationToken ct)
{
    await TaskA();
    if (ct.IsCancellationRequested || this == null) return;

    await UniTask.Delay(300, cancellationToken: ct);
    if (ct.IsCancellationRequested || this == null) return;

    ProcessData();
}

private void OnDestroy()
{
    _cts?.Cancel();
    _cts?.Dispose();
    _cts = null;
}
```

## Hybrid Safety Pattern (Recycled Views)

For pooled objects or OSA adapters where a MonoBehaviour survives but gets reassigned to different data:
```csharp
private CancellationTokenSource _cts;

public async void InitItem(ItemData itemData)
{
    // 1. Cancel previous
    _cts?.Cancel();
    _cts?.Dispose();
    _cts = new CancellationTokenSource();
    var token = _cts.Token;

    this.data = itemData;

    var sprite = await LoadSpriteAsync(itemData.path);

    // 2. Triple guard
    if (this == null) return;               // Destroyed?
    if (token.IsCancellationRequested) return; // Cancelled?
    if (this.data != itemData) return;      // Recycled?

    thumbImage.sprite = sprite;
}
```

## Error Handling

### Try-Finally for UI Cleanup
```csharp
// ✅ Guaranteed cleanup on all paths
public async UniTask Init(CancellationToken ct)
{
    loadingElement.ShowLoading();
    try
    {
        var data = await LoadData().AttachExternalCancellation(ct);
    }
    catch (OperationCanceledException) { /* Silent */ }
    catch (Exception e) { Debug.LogError($"Failed: {e.Message}"); }
    finally
    {
        loadingElement.HideLoading();  // ALWAYS runs
    }
}
```

### Fire-and-Forget Safety
```csharp
// ❌ BAD: Silent failure
_ = SomeAsyncOperation();

// ✅ GOOD: Conscious fire-and-forget
SomeAsyncOperation().Forget();
```

## Editor Play Mode Safety
```csharp
public async UniTask InitSDK(CancellationToken ct)
{
    #if UNITY_EDITOR
    if (!Application.isPlaying) return;
    #endif

    await PrepareConfig();

    #if UNITY_EDITOR
    if (!Application.isPlaying || ct.IsCancellationRequested) return;
    #endif

    ExternalSDK.Initialize(config); // May call DontDestroyOnLoad internally
}
```

## Cancellation Patterns

| Pattern | When |
|---------|------|
| `destroyCancellationToken` | MonoBehaviour lifetime |
| `CancellationTokenSource` | Manual control (Cancel → Dispose → Recreate) |
| `CreateLinkedTokenSource` | Combine multiple tokens |
| `CancelAfter(timeout)` | Timeout |

## Choosing the Right Async Model

| Need | Tool | Why |
|------|------|-----|
| Simple delay (one-off) | Coroutine / UniTask.Delay | Lightweight, lifecycle-managed |
| Sequential async chain | UniTask / async-await | Readable, cancellable |
| Periodic polling | Update + timer | No coroutine overhead |
| React to state changes | C# events / UnityEvent | No polling, zero-cost when idle |
| Frame-aligned updates | Update / LateUpdate | Deterministic, profiler-visible |

### Anti-Patterns

| Anti-Pattern | Risk |
|-------------|------|
| Coroutine started in Update | ⚠️ Leak |
| UniTask without CancellationToken | ⚠️ Ghost task |
| WaitForSeconds in tight loop | ⚠️ GC |
| async void (not UniTaskVoid) | 🔴 Silent failure |

## Related Skills
- `@addressables-asset-management` - Async asset loading
- `@backend-integration` - Async networking
- `@dotween-safety` - DOTween async patterns
- `@ui-state-safety` - UI cleanup and state consistency
