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

## Related Skills
- `@asynchronous-programming` - UniTask patterns
- `@save-load-serialization` - Local data persistence
- `@monetization-iap` - Server-validated purchases
