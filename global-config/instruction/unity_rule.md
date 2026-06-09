<!-- AG-UNITY:BEGIN -->

# Unity Verification

When editing or writing C# scripts in a Unity project, verify with the **utk CLI** as follows:

**1. Use utk to compile-check.**
   - After editing a `.cs` file, run `utk editor refresh --compile` (recompiles and blocks until done), then `utk console --type error --lines 20` to read compilation errors.
   - If `utk` is unavailable or no Editor is connected (`utk status` fails / reports `not responding`), skip this verify/compile-check step.

**2. Use utk to run Unity Test Runner.**
   - Use `utk test [--mode EditMode|PlayMode] [--filter Ns.Class.Test]` to run the appropriate tests.
   - If `utk` is unavailable, skip Unity Test Runner.

*Note: Do not fallback to Unity batchmode commands, dotnet build, or launching another Unity Editor instance for Unity verification. If utk is unavailable, skip all Unity verification steps related to Unity Test Runner and Unity compile-checks.*

*For how to drive utk itself (exec, console, subagent delegation, etc.), follow utk's own rule and skill.*

<!-- AG-UNITY:END -->
