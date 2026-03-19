---
name: backend-integration
description: "Unity backend integration specialist. Use this when the user needs REST API calls, JWT authentication, WebSocket connections, server communication, or online features. Also trigger for: 'call API from Unity', 'UnityWebRequest', 'authentication', 'login system', 'send data to server', 'realtime multiplayer backend', or any question about client-server communication — even if they don't say 'backend'."
---

# Backend Integration

## Overview
Connect Unity games to backend services via REST APIs, WebSockets, and authentication systems. Covers UnityWebRequest, JSON serialization, JWT auth, and error handling.

## When to Use
- Use for REST API communication
- Use for user authentication (login/register)
- Use for leaderboards, cloud saves
- Use for in-game stores with server validation
- Use for realtime data (WebSocket, SSE)

## API Communication Stack

```
┌─────────────────────────────────────────────────────────────┐
│                   REQUEST FLOW                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Unity Client                          Backend Server        │
│  ┌──────────────┐    HTTPS/WSS    ┌──────────────┐          │
│  │ ApiClient    │ ──────────────▶ │ REST API     │          │
│  │ (UniTask)    │ ◀────────────── │ (JSON)       │          │
│  └──────────────┘                 └──────────────┘          │
│                                                              │
│  Auth: JWT Bearer token in Authorization header              │
│  Format: JSON (System.Text.Json or Newtonsoft)               │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices
- ✅ Use `UniTask` for async requests (not coroutines)
- ✅ Centralize API calls in a service class
- ✅ Add retry logic with exponential backoff
- ✅ Cache auth tokens securely
- ✅ Handle offline/timeout gracefully
- ❌ **NEVER** store API keys in client code
- ❌ **NEVER** trust client-side validation alone
- ❌ **NEVER** block the main thread with synchronous requests

## Few-Shot Examples

### Example 1: REST API Client
**User**: "Call a REST API to fetch player profile."

**Agent**:
```csharp
public class ApiClient
{
    private readonly string _baseUrl;
    private string _authToken;

    public ApiClient(string baseUrl)
    {
        _baseUrl = baseUrl;
    }

    public void SetAuthToken(string token) => _authToken = token;

    public async UniTask<T> GetAsync<T>(string endpoint, CancellationToken ct)
    {
        using var request = UnityWebRequest.Get($"{_baseUrl}/{endpoint}");

        if (!string.IsNullOrEmpty(_authToken))
            request.SetRequestHeader("Authorization", $"Bearer {_authToken}");

        request.SetRequestHeader("Content-Type", "application/json");

        await request.SendWebRequest().ToUniTask(cancellationToken: ct);

        if (request.result != UnityWebRequest.Result.Success)
            throw new ApiException(request.error, request.responseCode);

        return JsonUtility.FromJson<T>(request.downloadHandler.text);
    }

    public async UniTask<T> PostAsync<T>(string endpoint, object body, CancellationToken ct)
    {
        string json = JsonUtility.ToJson(body);
        using var request = new UnityWebRequest($"{_baseUrl}/{endpoint}", "POST");
        request.uploadHandler = new UploadHandlerRaw(System.Text.Encoding.UTF8.GetBytes(json));
        request.downloadHandler = new DownloadHandlerBuffer();
        request.SetRequestHeader("Content-Type", "application/json");

        if (!string.IsNullOrEmpty(_authToken))
            request.SetRequestHeader("Authorization", $"Bearer {_authToken}");

        await request.SendWebRequest().ToUniTask(cancellationToken: ct);

        if (request.result != UnityWebRequest.Result.Success)
            throw new ApiException(request.error, request.responseCode);

        return JsonUtility.FromJson<T>(request.downloadHandler.text);
    }
}
```

### Example 2: JWT Authentication Flow
**User**: "Login with email/password and store token."

**Agent**:
```csharp
public class AuthService
{
    private readonly ApiClient _api;

    public AuthService(ApiClient api)
    {
        _api = api;
    }

    public async UniTask<bool> LoginAsync(string email, string password, CancellationToken ct)
    {
        try
        {
            var body = new LoginRequest { email = email, password = password };
            var response = await _api.PostAsync<LoginResponse>("auth/login", body, ct);

            _api.SetAuthToken(response.token);
            PlayerPrefs.SetString("auth_token", response.token);
            PlayerPrefs.Save();
            return true;
        }
        catch (ApiException e)
        {
            Debug.LogError($"Login failed: {e.Message} (HTTP {e.StatusCode})");
            return false;
        }
    }

    public bool TryRestoreSession()
    {
        string token = PlayerPrefs.GetString("auth_token", "");
        if (string.IsNullOrEmpty(token)) return false;
        _api.SetAuthToken(token);
        return true;
    }
}

[Serializable]
public class LoginRequest { public string email; public string password; }
[Serializable]
public class LoginResponse { public string token; public string userId; }
```

### Example 3: Retry with Exponential Backoff
**User**: "Retry failed API calls."

**Agent**:
```csharp
public static class ApiRetry
{
    public static async UniTask<T> WithRetry<T>(
        Func<CancellationToken, UniTask<T>> operation,
        int maxRetries = 3,
        CancellationToken ct = default)
    {
        for (int i = 0; i < maxRetries; i++)
        {
            try
            {
                return await operation(ct);
            }
            catch (ApiException e) when (e.StatusCode >= 500 && i < maxRetries - 1)
            {
                float delay = Mathf.Pow(2, i); // 1s, 2s, 4s
                Debug.LogWarning($"Retry {i + 1}/{maxRetries} after {delay}s");
                await UniTask.Delay(TimeSpan.FromSeconds(delay), cancellationToken: ct);
            }
        }
        throw new Exception("Max retries exceeded");
    }
}

// Usage:
// var profile = await ApiRetry.WithRetry(ct => _api.GetAsync<Profile>("profile", ct));
```

## Component-Level Gating

### Why Not Global Blocking
A single global `_isRequestInProgress` flag blocks ALL requests. In multi-tab UIs, a slow load for Tab A prevents Tab B from loading.

```csharp
// ❌ BAD: Global block — breaks multi-tab usability
private static bool _isRequestInProgress;
public static async UniTask GetRequest(string url) {
    if (_isRequestInProgress) { Debug.LogWarning("Blocked"); return; }
    _isRequestInProgress = true;
    // ...
    _isRequestInProgress = false;
}

// ✅ GOOD: Each component owns its own guard
public class MyAdapter
{
    private bool _isFetching;

    public void TriggerLoad()
    {
        if (_isFetching) return;
        _isFetching = true;          // SET SYNCHRONOUSLY
        LoadAsync().Forget();
    }
}
```

### Synchronous State Principle
When triggering async from `Update()`, set guard flag **synchronously** before the async call:
```csharp
void Update()
{
    if (ReachThreshold()) TriggerLoad();
}

void TriggerLoad()
{
    if (_isFetching) return;
    _isFetching = true;   // IMMEDIATE — prevents race with next frame
    LoadAsync().Forget();
}
```

### Redundant Activation Guard
```csharp
public void ActivePage(string identifier)
{
    // Skip if already active and initialized for same context
    if (IsActive && IsInit && currentId == identifier) return;

    // Skip fetch if already fetching same context
    if (IsFetchingData && currentId == identifier) { IsActive = true; return; }

    currentId = identifier;
    IsActive = true;
    IsFetchingData = true;
    StartFetch(identifier).Forget();
}
```

## Throttling & Cooldown

### Post-Load Cooldown (Success Throttling)
Prevent rapid consecutive loads during aggressive scrolling:
```csharp
public async UniTask LoadAsync()
{
    _isFetching = true;
    var result = await FetchData();
    Process(result);

    // Cooldown: prevent next fetch for 800ms even though data is ready
    await UniTask.Delay(800);
    _isFetching = false;
}
```

### Failed Request Cooldown (Spam Prevention)
Without cooldown, `Update()` immediately retries on next frame:
```csharp
public async UniTask LoadAsync()
{
    _isFetching = true;
    var result = await FetchData();

    if (result == null)
    {
        // COOLDOWN: break infinite retry loop
        await UniTask.Delay(500);
        _isFetching = false;
        return;
    }

    Process(result);
    _isFetching = false;
}
```

## HTTP 429 Troubleshooting

| Symptom | Probable Cause | Fix |
|---------|---------------|-----|
| "Blocked Request" in Console | Global `_isRequestInProgress` too restrictive | Move gating to calling component |
| 429 on high page index (Page 3+) | Fast scrolling triggers rapid sequential hits | Add 800ms **success cooldown** after load |
| Actual HTTP 429 in Network Log | Component interval too short | Increase cooldown or find unthrottled rogue requests |
| Same-page request spam | User/system spamming same index | Skip redundant fetches for same index within 1s |
| 70+ request logs/sec | Guard flag reset immediately after failure | Add 500ms **failed request cooldown** |

## Related Skills
- `@asynchronous-programming` - UniTask patterns
- `@asynchronous-programming` - Async patterns
- `@monetization-iap` - Server-validated purchases
- `@ui-state-safety` - UI state consistency during network ops
