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

# Unity MCP Usage

**Every Unity-MCP tool call MUST run inside a subagent — the main context never invokes an `mcpforunity__*` tool directly.** The main agent decides the exact calls and interprets the distilled result; the subagent executes the calls and reads the verbose output (console, hierarchy, `Editor.log`, test `results.xml`, screenshots) so the raw dump never floods the main context. This is mandatory — no exceptions for "just one quick call" or "only reading the console".

**Model choice — Sonnet executes, Opus plans:**
- **Sonnet** — runs **every** MCP execution and log/test read, whether you fully specified the calls (run a given `batch_execute`, `read_console` for errors only, poll `editor/state`, parse `results.xml`) or the subagent must locate/adapt (find the right GameObject/component, adjust a version-dependent payload, triage ambiguous console output).
- **Opus / main agent** — never runs MCP; reserved for architecture, root-cause reasoning, and writing the dispatch spec.

**Do not use Haiku for Unity-MCP work** — its output quality is too low (misread dumps, wrong params, bad distillations cost more in rework than they save). Sonnet is the floor. The subagent returns a distilled result (PASS/FAIL, deduped errors, the requested values) — never raw dumps or base64 images.

See the `unity-mcp-delegation`, `unity-mcp-operator-guide`, and `unity-mcp-ignore` skills for details.

<!-- AG-UNITY:END -->
