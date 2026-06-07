<!-- AG-UNITY:BEGIN -->

# Unity Verification

When editing or writing C# scripts in a Unity project, verify with Unity MCP as follows:

**1. Use Unity MCP to verify and compile-check.**
   - Use Unity MCP as the default Unity verification path to check source compilation status.
   - If Unity MCP is unavailable or not configured in the current environment, skip this verify/compile-check step.

**2. Use Unity MCP to run Unity Test Runner.**
   - Use Unity MCP to trigger Unity Test Runner and run the appropriate tests (EditMode/PlayMode).
   - If Unity MCP is unavailable, skip Unity Test Runner.

*Note: Do not fallback to Unity batchmode commands, dotnet build, or launching another Unity Editor instance for Unity verification. If Unity MCP is unavailable, skip all Unity verification steps related to Unity Test Runner and Unity compile-checks.*

<!-- AG-UNITY:END -->
