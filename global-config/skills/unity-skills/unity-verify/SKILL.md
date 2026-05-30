---
name: unity-verify
description: Use when editing, writing, or reviewing Unity C# scripts and needing to verify correctness — covers compile-check with dotnet build and Unity Test Runner execution order, lock-file safety, and when to skip tests.
---

# Unity Verification Workflow

Run these two steps **in order** after any Unity C# edit. Never invert them.

---

## Step 1 — Compile-Check with .NET (always, fast, lock-free)

**Run this first, every time.** It reads source only and does NOT conflict with an open Unity Editor.

### One-time setup (no Windows/Mono needed)

Match `net<ver>` to `<TargetFrameworkVersion>` in the csproj (e.g. `v4.7.1` → `net471`):

**macOS / Linux**
```bash
dotnet new classlib -o /tmp/refpack
dotnet add /tmp/refpack package Microsoft.NETFramework.ReferenceAssemblies.net471
```

**Windows (PowerShell)**
```powershell
dotnet new classlib -o $env:TEMP\refpack
dotnet add $env:TEMP\refpack package Microsoft.NETFramework.ReferenceAssemblies.net471
```

### Build command

**macOS / Linux**
```bash
REFDIR=$(find ~/.nuget/packages/microsoft.netframework.referenceassemblies.net471 \
  -type d -name v4.7.1 | head -1)
dotnet build Assembly-CSharp.csproj -nologo -v q \
  -p:FrameworkPathOverride="$REFDIR"
```

**Windows (PowerShell)**
```powershell
$refDir = (Get-ChildItem "$env:USERPROFILE\.nuget\packages\microsoft.netframework.referenceassemblies.net471" `
  -Recurse -Directory -Filter v4.7.1 | Select-Object -First 1).FullName
dotnet build Assembly-CSharp.csproj -nologo -v q -p:FrameworkPathOverride="$refDir"
```

Build takes ~4–8 s. Exits non-zero on any compile error.

### Known safe-to-ignore errors

| Error | Cause | Action |
|-------|-------|--------|
| `MSB3644` | Missing `FrameworkPathOverride` | Fix: re-run setup above |
| `CS0246` on 3rd-party plugin | csproj omits Firebase/etc. `<Reference>` — csproj-generation gap | Ignore — not your code |

### Stale or missing .csproj

If `.csproj`/`.sln` is missing or a file was added/renamed:
- **Regenerate:** Unity → Preferences → External Tools → Generate .csproj files
- **Or read** the Editor's auto-recompile result from `Editor.log`:
  - macOS: `~/Library/Logs/Unity/Editor.log`
  - Windows: `%LOCALAPPDATA%\Unity\Editor\Editor.log`
  - Linux: `~/.config/unity3d/Editor.log`

---

## Step 2 — Unity Test Runner (only when real logic exists)

Run **only** if the task carries real logic (business rules, calculations, state machines, edge cases).

**Skip tests for:** getters/setters, UI wiring, glue code. Do NOT create tests just to have coverage.

```bash
Unity -batchmode -runTests \
  -projectPath <project> \
  -testPlatform EditMode \
  -testResults results.xml \
  -logFile -
```

Parse `results.xml` (JUnit/NUnit) for pass/fail. **Never wait indefinitely** — set a finite timeout.

---

## Lock-File Safety Rule

**Never launch a second Unity instance on a project already open in the Editor.**

The project lock (`Temp/UnityLockfile`) blocks the second instance silently.

| Situation | Correct action |
|-----------|---------------|
| Editor open + batchmode test needed | Run tests via the open Editor's Test Runner window |
| Editor open + batchmode test needed (alt) | Ask the user to close the Editor first |
| Blocked instance detected | Stop immediately — do NOT wait silently |

---

## Quick Decision Table

| What changed? | Step 1 | Step 2 |
|---------------|--------|--------|
| Any C# edit | ✅ always | skip unless real logic |
| New business rule / state machine | ✅ | ✅ |
| Getter, setter, UI wiring | ✅ | ❌ |
| Rename / formatting only | ✅ | ❌ |

---

## Related Skills

- `@unity-csharp-standards` — Naming, field conventions, performance rules
- `@unity-event-safety` — Event subscription symmetry
- `@unity-async-patterns` — Async/await lifecycle and cancellation
