<!-- AG-UNITY:BEGIN -->

# Unity Verification (applies to all Unity projects)

When editing or writing C# scripts in a Unity project, verify in this order:

**1. Compile-check with .NET (always, fast, lock-free).**
   - macOS/Linux one-time setup (no Windows/Mono needed): cache the .NET Framework reference
     assemblies the project targets. Match the package to `<TargetFrameworkVersion>` in the csproj
     (e.g. v4.7.1 → `net471`): `dotnet new classlib -o /tmp/refpack && dotnet add /tmp/refpack package Microsoft.NETFramework.ReferenceAssemblies.net471`
   - Build the Unity-generated assembly, pointing MSBuild at those reference assemblies:
     `REFDIR=$(find ~/.nuget/packages/microsoft.netframework.referenceassemblies.net471 -type d -name v4.7.1 | head -1)`
     `dotnet build Assembly-CSharp.csproj -nologo -v q -p:FrameworkPathOverride="$REFDIR"`
   - Without `FrameworkPathOverride` the build fails immediately with `MSB3644` (reference
     assemblies not found). Build is ~4-8s and only reads source, so it does NOT conflict with an
     open Unity Editor.
   - Precompiled third-party plugins (e.g. Firebase) may surface `CS0246` when Unity's generated
     csproj omits their `<Reference>` — that is a csproj-generation gap, not your own code.
   - If the `.csproj`/`.sln` is missing or stale (e.g. a file was added/renamed), regenerate it
     (Unity → Preferences → External Tools → Generate .csproj files) or read `Editor.log`
     (`~/Library/Logs/Unity/Editor.log`) for the open Editor's auto-recompile result instead.

**2. Run tests with Unity Test Runner (only for tasks with real logic).**
   - Only test tasks that carry real logic (business rules, calculations, state machines,
     edge cases). Skip tests for trivial code (getters/setters, UI wiring, glue). Do NOT
     create tests just to have them — prefer a few focused tests over broad coverage.
   - Use Unity Test Runner (EditMode/PlayMode) to verify logic:
     `Unity -batchmode -runTests -projectPath <project> -testPlatform EditMode -testResults results.xml -logFile -`
   - Parse the JUnit/NUnit `results.xml` for pass/fail — never wait indefinitely on the run.

**Never launch a second Unity instance on a project that is already open in the Editor** — it is
blocked by the project lock (`Temp/UnityLockfile`). If the Editor is open and a batchmode test run
is needed, either run the tests through the open Editor's Test Runner window, or have the user close
the Editor first. Do NOT silently wait on a blocked instance.

<!-- AG-UNITY:END -->
