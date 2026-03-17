---
name: input-system-new
description: "Unity New Input System specialist. Use this when the user configures input actions, player input, input rebinding, multi-device support (gamepad, keyboard, touch), or input-driven gameplay. Also trigger for: 'gamepad support', 'touch controls', 'rebind keys', 'InputAction setup', 'player input component', 'input not working', or any question about handling player input — even if they don't say 'input system'."
---

# Input System (New)

## Overview
Unity's New Input System for multi-device, action-based input handling. Covers InputAction assets, Player Input component, runtime rebinding, and multi-device support.

## When to Use
- Use for any new project input setup
- Use for multi-platform (keyboard + gamepad + touch)
- Use for input rebinding UI
- Use for local multiplayer
- Use for custom input processors

## Input System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   INPUT SYSTEM STACK                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  INPUT ACTIONS ASSET (.inputactions)                         │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ Action Map: "Player"                                  │    │
│  │   Move    → WASD, Left Stick                          │    │
│  │   Jump    → Space, South Button                       │    │
│  │   Look    → Mouse Delta, Right Stick                  │    │
│  │ Action Map: "UI"                                      │    │
│  │   Navigate → Arrow Keys, D-Pad                        │    │
│  └──────────────────────────────────────────────────────┘    │
│         ↓                                                    │
│  PLAYER INPUT (Component)                                    │
│  Auto-switches Action Maps, handles device changes           │
└─────────────────────────────────────────────────────────────┘
```

## Best Practices
- ✅ Use InputAction assets (not hardcoded bindings)
- ✅ Enable/disable actions in OnEnable/OnDisable
- ✅ Use `performed` for buttons, `ReadValue<T>` for axes
- ✅ Support multiple control schemes (keyboard, gamepad, touch)
- ❌ **NEVER** use old `Input.GetKeyDown` with New Input System
- ❌ **NEVER** forget to enable the action map
- ❌ **NEVER** read input in FixedUpdate (use Update + apply in FixedUpdate)

## Few-Shot Examples

### Example 1: Action-Based Movement
**User**: "Move player with WASD and gamepad."

**Agent**:
```csharp
public class PlayerMovement : MonoBehaviour
{
    [SerializeField] private InputActionReference _moveAction;
    [SerializeField] private InputActionReference _jumpAction;
    [SerializeField] private float _speed = 5f;
    [SerializeField] private float _jumpForce = 10f;

    private Rigidbody _rb;
    private Vector2 _moveInput;

    private void Awake()
    {
        _rb = GetComponent<Rigidbody>();
    }

    private void OnEnable()
    {
        _moveAction.action.Enable();
        _jumpAction.action.Enable();
        _jumpAction.action.performed += OnJump;
    }

    private void OnDisable()
    {
        _moveAction.action.Disable();
        _jumpAction.action.Disable();
        _jumpAction.action.performed -= OnJump;
    }

    private void Update()
    {
        _moveInput = _moveAction.action.ReadValue<Vector2>();
    }

    private void FixedUpdate()
    {
        var move = new Vector3(_moveInput.x, 0, _moveInput.y);
        _rb.MovePosition(transform.position + move * (_speed * Time.fixedDeltaTime));
    }

    private void OnJump(InputAction.CallbackContext ctx)
    {
        _rb.AddForce(Vector3.up * _jumpForce, ForceMode.Impulse);
    }
}
```

### Example 2: Runtime Rebinding
**User**: "Let player rebind keys in settings."

**Agent**:
```csharp
public class RebindUI : MonoBehaviour
{
    [SerializeField] private InputActionReference _actionToRebind;
    [SerializeField] private TextMeshProUGUI _bindingText;
    [SerializeField] private GameObject _waitingOverlay;

    private InputActionRebindingExtensions.RebindingOperation _rebindOp;

    public void StartRebind()
    {
        _actionToRebind.action.Disable();
        _waitingOverlay.SetActive(true);

        _rebindOp = _actionToRebind.action.PerformInteractiveRebinding()
            .WithControlsExcluding("Mouse")
            .OnMatchWaitForAnother(0.1f)
            .OnComplete(operation =>
            {
                _bindingText.text = InputControlPath.ToHumanReadableString(
                    _actionToRebind.action.bindings[0].effectivePath);
                _waitingOverlay.SetActive(false);
                _actionToRebind.action.Enable();
                operation.Dispose();
            })
            .OnCancel(operation =>
            {
                _waitingOverlay.SetActive(false);
                _actionToRebind.action.Enable();
                operation.Dispose();
            })
            .Start();
    }

    private void OnDestroy() => _rebindOp?.Dispose();
}
```

### Example 3: Touch Controls
**User**: "Add virtual joystick for mobile."

**Agent**:
```csharp
public class TouchInputHandler : MonoBehaviour
{
    [SerializeField] private InputActionReference _moveAction;
    [SerializeField] private RectTransform _joystickBackground;
    [SerializeField] private RectTransform _joystickHandle;
    [SerializeField] private float _handleRange = 50f;

    private void OnEnable()
    {
        _moveAction.action.Enable();
    }

    private void Update()
    {
        Vector2 input = _moveAction.action.ReadValue<Vector2>();

        // Move joystick handle visually
        _joystickHandle.anchoredPosition = input * _handleRange;
    }

    // The InputAction asset should contain:
    // Control Scheme: "Touch"
    // Binding: On-Screen Stick → Gamepad/leftStick
    // The On-Screen Stick component handles touch → stick conversion
}
```

## Related Skills
- `@ui-toolkit-modern` - UI navigation input
- `@mobile-optimization` - Touch input optimization
- `@state-machine-architect` - Input-driven state transitions
