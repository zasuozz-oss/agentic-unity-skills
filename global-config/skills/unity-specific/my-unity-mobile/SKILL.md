---
description: Unity mobile coding rules - performance, lifecycle, Inspector, DOTween, TextMeshPro
---

# Unity Mobile Coding Rules

## Performance
- No LINQ in Update or loops
- No allocations in Update/LateUpdate
- No GameObject.Find/FindObjectOfType at runtime
- Cache references in Awake
- Use object pooling for frequently spawned objects

---

## Lifecycle
- Awake: cache references only
- Start: scene-dependent init
- FixedUpdate: physics only
- OnEnable/OnDisable: register/unregister events

---

## Animation
- No hardcoded animator parameter names
- Use Animator.StringToHash
- Do not mix Rigidbody and CharacterController without intent

---

## Logging
- No log spam
- Format: [ClassName] message
- Release builds should not spam logs
- Guard hot path logs with `#if UNITY_EDITOR || DEVELOPMENT_BUILD`

---

## API Integrity Rule
- Do NOT invent Unity APIs, methods, attributes, packages, or settings
- Only use verified Unity APIs
- If unsure: state "cannot verify"

---

## Inspector Rule

Serialized fields are assumed REQUIRED by default:
- Missing null checks MUST NOT be reported as ERROR/WARNING
- Inspector-assignable issues MUST NOT generate fix_id
- Do NOT suggest null checks for serialized/public fields
- Fail-fast behavior is preferred

Allowed exceptions (may be WARNING):
- Runtime-injected dependencies without validation
- Explicitly optional references with fallback behavior
- Serialized fields overwritten at runtime

---

## Text & Typography
- All UI text MUST use TextMeshProUGUI
- Do NOT use UnityEngine.UI.Text
- Do NOT use generic TMP_Text for UI elements
- Legacy Text MUST NOT be introduced or refactored

---

## Animation & Tweening
- DOTween is the default tweening solution
- Use DOTween for: UI transitions, simple animations, timing feedback
- Do NOT introduce alternative tween systems

DOTween rules:
- Avoid per-frame allocations
- Reuse tweens when possible
- Kill tweens on disable/destroy
- Prefer DOTween over Animator for simple UI

---

## UI Button Binding Rule

- Do NOT use Button.onClick.AddListener()
- Button callbacks MUST be assigned via Inspector
- Runtime button binding is NOT allowed

Scripts MAY declare public methods for callbacks:
```
PlayButton -> OnPlayClicked()
CloseButton -> OnCloseClicked()
```

Allowed exceptions (if explicitly approved):
- Dynamically generated UI
- Reusable UI prefabs with documented lifecycle

---

## Awake Usage Restriction

Awake MUST NOT be used for:
- Gameplay logic
- State initialization depending on other objects
- Event registration
- Data loading

Allowed usage:
- Caching component references (GetComponent, transform)
- One-time self-contained internal setup

Preferred alternatives:
- Start: scene-dependent init
- OnEnable/OnDisable: events
- Explicit Init() methods

If Awake used beyond caching: state reason explicitly

---

## Rules
- Do NOT refactor existing Awake logic unless requested
- Do NOT move code between lifecycle methods automatically
- If lifecycle intent unclear: state "cannot verify"
