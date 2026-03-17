---
name: asynchronous-programming
description: "Async/await, UniTask, and Coroutine implementation specialist. Use this skill whenever the user needs to write, fix, or refactor async code in Unity — even if they don't mention UniTask or coroutines explicitly. Also trigger for: loading screens, scene transitions, network/API calls, file I/O, sequential or parallel async chains, cancellation tokens, destroyCancellationToken, coroutine-to-async conversion, 'how do I wait for X', 'how to cancel an operation', 'fire-and-forget pattern', or timeout handling. Even if they just say 'load something' or 'fetch data', this skill applies. Do NOT use for deciding which async approach to pick — use async-strategy instead."
---

# Asynchronous Programming

## Overview
Handle long-running operations (loading, network, file I/O) without blocking the main thread. Master async/await patterns adapted for Unity's unique lifecycle.

## When to Use
- Use when loading assets or scenes
- Use when making network/web requests
- Use when performing file I/O
- Use when waiting for user input with timeouts
- Use when orchestrating sequential or parallel async operations
- Use when converting coroutines to async/await
- Use when adding cancellation support to existing code

## Async Options in Unity

| Approach | Best For | Unity Integration |
|----------|----------|-------------------|
| **Coroutines** | Simple delays, legacy code | Native `yield return` |
| **async/await (Task)** | C# standard, complex flows | Requires care with main thread |
| **UniTask** | Zero-allocation, Unity-optimized | Recommended for production |

## Key Patterns

### Pattern 1: Coroutines (Legacy)
```csharp
IEnumerator LoadLevel()
{
    _loadingScreen.SetActive(true);

    yield return new WaitForSeconds(0.5f);

    var operation = SceneManager.LoadSceneAsync("Level1");
    while (!operation.isDone)
    {
        _progressBar.value = operation.progress;
        yield return null;
    }
}
```

### Pattern 2: async/await with Task
```csharp
async Task LoadLevelAsync(CancellationToken token)
{
    _loadingScreen.SetActive(true);

    await Task.Delay(500, token);

    var operation = SceneManager.LoadSceneAsync("Level1");
    while (!operation.isDone)
    {
        token.ThrowIfCancellationRequested();
        _progressBar.value = operation.progress;
        await Task.Yield();
    }
}
```

### Pattern 3: UniTask (Recommended)
```csharp
async UniTaskVoid LoadLevelAsync(CancellationToken token)
{
    _loadingScreen.SetActive(true);

    await UniTask.Delay(500, cancellationToken: token);

    await SceneManager.LoadSceneAsync("Level1").ToUniTask(
        Progress.Create<float>(p => _progressBar.value = p),
        cancellationToken: token
    );
}
```

## Best Practices
- ✅ Use `CancellationToken` for every async method that touches Unity objects
- ✅ Handle exceptions with try/catch in async methods
- ✅ Use `async void` ONLY for event handlers (prefer `async UniTaskVoid`)
- ✅ Check `destroyCancellationToken` for MonoBehaviour lifetime
- ✅ Consider UniTask for zero-allocation async
- ✅ Dispose `CancellationTokenSource` in `OnDestroy` or `finally`
- ❌ **NEVER** use `Task.Run` for Unity API calls (not thread-safe!)
- ❌ **NEVER** forget to await async calls (fire-and-forget = silent errors)
- ❌ **NEVER** block with `.Result` or `.Wait()` (causes deadlock)

## Anti-Pattern Examples

### ❌ Fire-and-Forget (Silent Errors)
```csharp
// BAD: Exception is silently swallowed, no way to know it failed
void Start()
{
    LoadDataAsync(); // not awaited — compiler warning CS4014
}

// GOOD: Use .Forget() with UniTask to explicitly acknowledge fire-and-forget
void Start()
{
    LoadDataAsync(this.destroyCancellationToken).Forget();
}
```

### ❌ Blocking with .Result / .Wait()
```csharp
// BAD: Deadlock on Unity main thread — the .Result call blocks
// the thread that the synchronization context needs to resume on
void Start()
{
    var data = LoadDataAsync().Result; // DEADLOCK!
}

// GOOD: Use async from the start
async UniTaskVoid Start()
{
    var data = await LoadDataAsync(this.destroyCancellationToken);
}
```

### ❌ Task.Run for Unity API
```csharp
// BAD: Unity APIs are NOT thread-safe
Task.Run(() =>
{
    transform.position = Vector3.zero; // CRASH!
});

// GOOD: Stay on main thread or switch back explicitly
await UniTask.SwitchToMainThread();
transform.position = Vector3.zero; // Safe
```

## Cancellation Pattern
```csharp
private CancellationTokenSource _cts;

void OnEnable()
{
    _cts = new CancellationTokenSource();
    LoadDataAsync(_cts.Token).Forget();
}

async UniTask LoadDataAsync(CancellationToken token)
{
    try
    {
        var data = await FetchFromServerAsync(token);
        token.ThrowIfCancellationRequested();

        await SaveToLocalAsync(data, token);
        Debug.Log("Data loaded and saved");
    }
    catch (OperationCanceledException)
    {
        Debug.Log("Operation cancelled");
    }
    catch (Exception ex)
    {
        Debug.LogError($"LoadData failed: {ex.Message}");
    }
}

void OnDisable()
{
    _cts?.Cancel();
}

void OnDestroy()
{
    _cts?.Cancel();
    _cts?.Dispose();
    _cts = null;
}
```

### Unity 2022+: Built-in Cancellation
```csharp
// destroyCancellationToken is auto-cancelled when MonoBehaviour is destroyed
// No manual CancellationTokenSource needed for destroy-scoped work
async UniTaskVoid LoadAsync()
{
    try
    {
        await DoWorkAsync(this.destroyCancellationToken);
    }
    catch (OperationCanceledException)
    {
        // Normal — MonoBehaviour was destroyed during async work
    }
}
```

## Coroutine vs Async Comparison

| Feature | Coroutine | async/await |
|---------|-----------|-------------|
| Return values | No | Yes |
| Exception handling | Limited | Full try/catch |
| Cancellation | Manual flags | CancellationToken |
| Composition | Difficult | Easy (await chain) |
| Unit testing | Hard | Easy |
| Allocations | WaitForSeconds allocates | Task allocates (UniTask = zero) |

## Few-Shot Examples

### Example 1: Sequential Loading with Error Recovery
**User**: "Load player data, then inventory, then spawn player."

**Agent**:
```csharp
public class GameInitializer : MonoBehaviour
{
    [SerializeField] private GameObject _loadingUI;

    async UniTaskVoid Start()
    {
        var token = this.destroyCancellationToken;
        _loadingUI.SetActive(true);

        try
        {
            var playerData = await LoadPlayerDataAsync(token);
            var inventory = await LoadInventoryAsync(playerData.Id, token);
            await SpawnPlayerAsync(playerData, inventory, token);

            Debug.Log("Game initialized!");
        }
        catch (OperationCanceledException)
        {
            Debug.Log("Initialization cancelled");
        }
        catch (Exception ex)
        {
            Debug.LogError($"Init failed: {ex.Message}");
        }
        finally
        {
            if (this != null)
                _loadingUI.SetActive(false);
        }
    }
}
```

### Example 2: Parallel Loading with Progress
**User**: "Load textures, sounds, and prefabs all at once with a progress bar."

**Agent**:
```csharp
public class AssetPreloader : MonoBehaviour
{
    [SerializeField] private Slider _progressBar;

    async UniTask PreloadAllAssets(CancellationToken token)
    {
        var progress = Progress.Create<float>(p => _progressBar.value = p);

        // WhenAll runs all three concurrently
        var (textures, sounds, prefabs) = await UniTask.WhenAll(
            LoadTexturesAsync(token),
            LoadSoundsAsync(token),
            LoadPrefabsAsync(token)
        );

        Debug.Log($"Loaded {textures.Length} textures, "
                + $"{sounds.Length} sounds, {prefabs.Length} prefabs");
    }

    async UniTaskVoid Start()
    {
        try
        {
            await PreloadAllAssets(this.destroyCancellationToken);
        }
        catch (OperationCanceledException) { }
    }
}
```

### Example 3: Timeout with Proper Cleanup
**User**: "Network request with 5 second timeout."

**Agent**:
```csharp
async UniTask<string> FetchWithTimeout(string url, CancellationToken externalToken)
{
    // Link external token so both timeout and external cancel work
    using var cts = CancellationTokenSource.CreateLinkedTokenSource(externalToken);
    cts.CancelAfter(TimeSpan.FromSeconds(5));

    try
    {
        return await FetchDataAsync(url, cts.Token);
    }
    catch (OperationCanceledException) when (!externalToken.IsCancellationRequested)
    {
        // Only the timeout fired, not external cancellation
        Debug.LogWarning($"Request to {url} timed out after 5s");
        return null;
    }
    // If externalToken was cancelled, let OperationCanceledException propagate
}
```

## Related Skills
- `@async-strategy` - Decide which async approach to use
- `@advanced-game-bootstrapper` - Async initialization
- `@addressables-asset-management` - Async asset loading
- `@backend-integration` - Async network operations

## Recommended Package
```
UniTask - https://github.com/Cysharp/UniTask
```
Zero-allocation async/await for Unity with full lifecycle integration.
