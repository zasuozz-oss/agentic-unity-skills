---
name: unity-mcp-connector
description: "Unity MCP integration specialist. Use this when the user connects Unity to external AI tools via Model Context Protocol, needs MCP server setup, editor automation, or remote control of Unity. Also trigger for: 'connect AI to Unity', 'MCP tools', 'control Unity from AI', 'telemetry ping', 'find game objects remotely', or any question about Unity–AI bridge via MCP."
---

# Unity MCP Connector

## Overview
Connects the file-based AI Brain with the live Unity Editor state. Allows the agent to "see" the scene hierarchy, inspect selected objects, and validate the existence of components dynamically.

## When to Use
- Use to check if Unity Editor is open and listening
- Use to find the currently selected GameObject context
- Use to validate scene contents that aren't serialized to disk yet
- Use to trigger Editor actions (Play, Pause, Refresh)
- Use to read console logs for errors

## Capabilities

| Capability | Tool | Description |
|------------|------|-------------|
| **Telemetry** | `manage_editor` | Check connection health (Ping) |
| **Selection** | `manage_editor` | Get/Set user selection |
| **Hierarchy** | `find_gameobjects` | Search active scene objects |
| **State** | `manage_editor` | Play/Pause/Stop mode control |
| **Scene** | `manage_scene` | Open/Save scenes |

## Procedure

### 1. Connection Check (First Step)
Always verify the bridge is active before attempting complex operations.
```json
{
  "tool": "mcp_unityMCP_manage_editor",
  "args": { "action": "telemetry_ping" }
}
```

### 2. Context Retrieval
If the user says "Add script to **this** object", fetch the selection.
```json
{
  "tool": "mcp_unityMCP_manage_editor",
  "args": { "action": "get_selection" }
}
```

### 3. Graceful Fallback
If MCP tools fails or returns "Not Connected":
1. **Log**: "Unity Editor not reachable. Proceeding in File-System Mode."
2. **Ask**: "Please specify the file path or GameObject name manually."
3. **Continue**: Do not halt the workflow.

## Best Practices
- ✅ **Ping First**: Always check `telemetry_ping` before deep operations
- ✅ **Read-Only Default**: Prefer reading state to modifying state unless explicitly requested
- ✅ **Error Handling**: Catch tool failures gracefully (Editor might be compiling)
- ❌ **NEVER** assume Editor is open
- ❌ **NEVER** rely solely on MCP for critical data (File System is truth)

## Few-Shot Examples

### Example 1: Connection Health Check
**User**: "Is Unity connected?"

**Agent**:
```csharp
// Agent flow:
// 1. Call mcp_unityMCP_manage_editor with action="telemetry_ping"
// 2. If response = "pong" → connected
// 3. If timeout/error → fallback to file-based mode

// Example response handling:
public class MCPConnectionChecker
{
    public static async UniTask<bool> IsConnectedAsync(CancellationToken ct)
    {
        try
        {
            // Simulates the MCP ping flow
            var response = await MCPBridge.SendAsync("telemetry_ping", ct);
            return response == "pong";
        }
        catch (TimeoutException)
        {
            Debug.LogWarning("[MCP] Unity Editor not reachable");
            return false;
        }
    }
}
```

### Example 2: Find and Inspect GameObject
**User**: "Where is the player in the scene?"

**Agent**:
```csharp
// Agent calls: mcp_unityMCP_find_gameobjects with search_term="Player"
// Returns: [{ name: "Player", instanceId: 1234, components: [...] }]

// In Unity, the equivalent code:
public class HierarchySearchHelper
{
    public static GameObject FindByName(string name)
    {
        var all = Object.FindObjectsOfType<GameObject>(true);
        return all.FirstOrDefault(go => go.name == name);
    }

    public static string[] GetComponentNames(GameObject go)
    {
        return go.GetComponents<Component>()
            .Where(c => c != null)
            .Select(c => c.GetType().Name)
            .ToArray();
    }
}
```

### Example 3: Safe Editor Action
**User**: "Enter play mode."

**Agent**:
```csharp
// Agent flow:
// 1. Ping first to confirm connection
// 2. Call mcp_unityMCP_manage_editor with action="play"
// 3. Wait for confirmation

// Equivalent editor script:
#if UNITY_EDITOR
public static class EditorPlayControl
{
    public static void SafeEnterPlayMode()
    {
        if (EditorApplication.isCompiling)
        {
            Debug.LogWarning("[MCP] Cannot enter play mode while compiling");
            return;
        }

        if (!EditorApplication.isPlaying)
            EditorApplication.isPlaying = true;
    }
}
#endif
```

## Related Skills
- `@custom-editor-scripting` - Build tools utilizing this connection
- `@automated-unit-testing` - Trigger tests via MCP
