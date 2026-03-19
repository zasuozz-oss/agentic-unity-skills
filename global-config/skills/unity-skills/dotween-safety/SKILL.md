---
name: dotween-safety
description: "DOTween lifecycle and memory safety specialist. Use this when the user creates tweens, animates UI, reviews DOTween usage, or investigates tween leaks. Also trigger for: 'DOTween leak', 'tween not killed', 'SetLink', 'DOTween object leak warning', 'animation plays after destroy', 'tween fire-and-forget', 'DOTween.To leaking', or any question about DOTween cleanup — even if they don't say 'DOTween'. Do NOT use for general animation — use vfx-graph-shuriken instead."
---

# DOTween Safety

## Overview
DOTween memory safety and lifecycle management. Prevent leaks, crashes, and "Some objects were not cleaned up" warnings by following strict linking, killing, and cleanup patterns.

## When to Use
- Use when creating any DOTween animation
- Use when reviewing scripts that use DOTween
- Use when investigating DOTween leak warnings
- Use when objects animate after being destroyed
- Use when scene transitions cause tween warnings

## The Golden Rules
- ✅ **Always** `.SetLink(gameObject)` on virtual tweens (`DOTween.To`, `DOVirtual`)
- ✅ **Always** `.Kill()` tweens in `OnDestroy` or `OnDisable`
- ✅ `DOTween.Kill(target)` before manually resetting animated properties
- ✅ Await multi-stage tween sequences with `.ToUniTask()`
- ❌ **NEVER** start new tweens inside `OnDestroy` (DOTween singleton recreation leak)
- ❌ **NEVER** leave looping tweens (`.SetLoops(-1)`) without SetLink or explicit kill
- ❌ **NEVER** fire-and-forget tweens in async methods without awaiting

## Identification Checklist
Flag any of the following as **high risk**:
1. **Property Tweens on Scalars**: `DOTween.To(() => myInt, ...)` — global virtual tween, MUST have SetLink
2. **Lack of `.SetLink()`**: Especially for `DOTween.To`, `DOVirtual.Float`, `DOVirtual.DelayedCall`
3. **Tweens in Transitions**: Any tween that starts during scene/panel close
4. **Looping Tweens**: `.SetLoops(-1)` must ALWAYS have a link or explicit kill
5. **Tweens in OnDestroy**: Spawning animations during cleanup = recreation leak

## Few-Shot Examples

### Example 1: SetLink for Virtual Tweens
**User**: "Animate a number counter."

**Agent**:
```csharp
// ❌ BEFORE: Global virtual tween — survives scene transition = LEAK
public async UniTask AnimateCounter(int target, float duration)
{
    await DOTween.To(() => _currentValue, x =>
    {
        _currentValue = x;
        _counterText.text = x.ToString("0");
    }, target, duration).SetEase(Ease.Linear);
}

// ✅ AFTER: Linked to gameObject — auto-killed on destroy
public async UniTask AnimateCounter(int target, float duration, CancellationToken ct)
{
    await DOTween.To(() => _currentValue, x =>
    {
        _currentValue = x;
        _counterText.text = x.ToString("0");
    }, target, duration)
        .SetEase(Ease.Linear)
        .SetLink(gameObject)         // Auto-kill when destroyed
        .ToUniTask(cancellationToken: ct);
}
```

### Example 2: Kill Before Reset (Flicker Prevention)
**User**: "Reset UI state before showing panel."

**Agent**:
```csharp
// ❌ BEFORE: Active tween fights with manual reset → flickering
private void ResetUI()
{
    _shadow.color = Color.clear;     // Tween immediately overrides this!
    _content.alpha = 0f;
}

// ✅ AFTER: Kill active tweens, then reset
private void ResetUI()
{
    DOTween.Kill(_shadow);           // Stop any active color tween
    DOTween.Kill(_content);          // Stop any active alpha tween

    _shadow.color = Color.clear;     // Now safe — no tween fighting
    _content.alpha = 0f;
}
```

### Example 3: OnDestroy Cleanup (No New Tweens)
**User**: "Clean up loading animation when destroyed."

**Agent**:
```csharp
// ❌ BEFORE: OnDestroy triggers new tween → DOTween singleton recreation
private void OnDestroy()
{
    _loadingElement.HideLoading(); // Calls DOFade(0, 0.25f) internally!
    // DOTween manager may already be destroyed → creates new one → LEAK
}

// ✅ AFTER: Immediate cleanup without new animations
private void OnDestroy()
{
    // Kill existing tweens (safe even if DOTween gone)
    _loadingElement?.DOKill();

    // Direct state change — no new tweens
    _loadingElement?.HideLoadingImmediate(); // SetActive(false), no animation
}
```

### Example 4: Awaiting Sequential Tweens
**User**: "Button shrinks, then bot appears, then player moves."

**Agent**:
```csharp
// ❌ BEFORE: Fire-and-forget — all happen simultaneously
public async void SubmitAsync()
{
    btnSubmit.DOScale(0, 0.25f);     // Not awaited!
    MakeBot();                        // Runs while button still shrinking
    await playerModel.DOMoveX(-0.35f, 0.35f);
}

// ✅ AFTER: Sequential with proper cancellation
public async UniTask SubmitAsync(CancellationToken ct)
{
    await btnSubmit.DOScale(0, 0.25f)
        .SetEase(Ease.InBack)
        .ToUniTask(cancellationToken: ct);

    MakeBot();

    await playerModel.DOMoveX(-0.35f, 0.35f)
        .ToUniTask(cancellationToken: ct);
}
```

## Sequence vs Async Decision

| Use Case | Approach |
|----------|----------|
| Pure animation chain (no logic between) | `DOTween.Sequence()` |
| Logic between animation steps | `await tween.ToUniTask()` |
| Parallel animations, wait for all | `UniTask.WhenAll(a.ToUniTask(), b.ToUniTask())` |

## Output Format
- **Leak risks**: Virtual tweens without SetLink
- **Crash risks**: Tweens in OnDestroy
- **Flicker risks**: Missing Kill before reset
- **Race condition risks**: Un-awaited sequential tweens

## Related Skills
- `@asynchronous-programming` - Async/await with CancellationToken
- `@canvas-performance` - UI performance
- `@memory-profiler-expert` - Tracking tween memory
