---
name: unity-verify
description: Use when editing, writing, or reviewing Unity C# scripts and needing to verify correctness — compile-check via Unity MCP read_console and Unity Test Runner via MCP run_tests, the execution order, and when to skip tests.
---

# Unity Verification Workflow

Verify through **Unity MCP only.** Do NOT use `dotnet build`, `Unity -batchmode`, or launch a second Unity Editor instance. If Unity MCP is unavailable or not configured, **skip** verification and say so explicitly — there is no fallback path.

**All MCP calls below run inside a subagent** — the main (Opus) context never calls `mcpforunity__*` directly. See `@unity-mcp-delegation` for the dispatch + model rules.

Run the two steps **in order**. Never invert them.

---

## Step 1 — Compile-check (always, after any C# edit)

`create_script` and `script_apply_edits` auto-trigger import + compilation — no `refresh_unity` needed.

1. Poll `mcpforunity://editor/state` until `is_compiling == false` **and** `is_domain_reload_pending == false`.
2. `read_console(types=["error"], count=20, include_stacktrace=True)`.
3. No errors → compile clean. Errors → report `file:line` + message.

**Dispatch:** Haiku — the calls and expected output are fully specified.

### Known safe-to-ignore

| Console error | Cause | Action |
|---------------|-------|--------|
| `CS0246` on a 3rd-party plugin only | Package/asmdef not referenced in that assembly | Ignore — not your code |

---

## Step 2 — Unity Test Runner (only when real logic exists)

Run **only** if the change carries real logic (business rules, calculations, state machines, edge cases).

**Skip tests for:** getters/setters, UI wiring, glue code. Do NOT create tests just to have coverage.

1. `run_tests(mode="EditMode", test_names=[...])` → returns `job_id` (use `PlayMode` if the logic needs runtime).
2. `get_test_job(job_id=job_id, wait_timeout=60, include_failed_tests=True)`.
3. **Never wait indefinitely** — use a finite `wait_timeout`. If it is exceeded, report and stop (do not silently retry).

**Dispatch:** Haiku if you pass explicit `test_names`; Sonnet if the subagent must select which tests apply.

---

## Quick Decision Table

| What changed? | Step 1 | Step 2 |
|---------------|--------|--------|
| Any C# edit | ✅ always | skip unless real logic |
| New business rule / state machine | ✅ | ✅ |
| Getter, setter, UI wiring | ✅ | ❌ |
| Rename / formatting only | ✅ | ❌ |

---

## No Second Instance

Unity MCP talks to the **already-open** Editor. Never launch `Unity -batchmode` or a second Editor instance — the project lock (`Temp/UnityLockfile`) blocks it silently. If no Editor is open or MCP is not connected, **skip verification and say so** — do not fall back to batchmode or `dotnet build`.

---

## Related Skills

- `@unity-mcp-delegation` — run all MCP calls via subagent (mandatory) + model choice
- `@unity-mcp-operator-guide` — `read_console`, `run_tests`, `editor/state` schemas
- `@unity-csharp-standards` — Naming, field conventions, performance rules
- `@unity-event-safety` — Event subscription symmetry
- `@unity-async-patterns` — Async/await lifecycle and cancellation
