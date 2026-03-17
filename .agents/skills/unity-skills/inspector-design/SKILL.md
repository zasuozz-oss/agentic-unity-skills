---
name: inspector-design
description: "Unity Inspector design advisor. Use this when the user wants better SerializeField usage, Tooltip/Header organization, validation, CreateAssetMenu, RequireComponent, or cleaner authoring UX. Also trigger for: 'my inspector is messy', 'how to organize fields', 'OnValidate usage', 'custom attributes', 'SerializeReference', or any question about making scripts easier to configure in the Inspector — even if they don't say 'inspector'. Do NOT use for custom Editor windows or PropertyDrawers — use custom-editor-scripting instead."
---

# Inspector Design

Use this skill when scripts need to be easier to author, configure, and review in the Inspector.

## Default Rules

- Prefer `private` fields with `[SerializeField]` over unnecessary public fields
- Use `[Header]`, `[Tooltip]`, `[Space]`, `[Range]`, `[Min]`, `[TextArea]` when they clarify intent
- Use `[RequireComponent]` for mandatory sibling dependencies
- Use `[CreateAssetMenu]` for config/data assets designers should create directly
- Use `OnValidate` only for lightweight editor-time validation
- Use `SerializeReference` only when polymorphic serialized data is genuinely needed

## Inspector Quality Checklist

- [ ] Are defaults safe?
- [ ] Are required references obvious?
- [ ] Are fields grouped by responsibility?
- [ ] Are tuning values constrained?
- [ ] Are debug-only fields separated from authoring fields?
- [ ] Will another person understand this script from Inspector alone?

## Best Practices
- ✅ Group related fields with `[Header("Section")]`
- ✅ Add `[Tooltip("...")]` for non-obvious fields
- ✅ Use `[Range(min, max)]` for bounded values
- ✅ Use `[RequireComponent(typeof(T))]` to prevent missing deps
- ✅ Use `[CreateAssetMenu]` with hierarchical menuName for SO
- ❌ **NEVER** expose fields that should stay private
- ❌ **NEVER** leave serialized fields without sensible defaults
- ❌ **NEVER** use `OnValidate` for heavy operations (it runs every inspector change)

## Few-Shot Examples

### Example 1: Well-Organized Inspector Script
**User**: "My enemy script inspector is a mess, fields everywhere."

**Agent**:
```csharp
[RequireComponent(typeof(Rigidbody))]
public class Enemy : MonoBehaviour
{
    [Header("Stats")]
    [SerializeField, Min(1)] private int _maxHealth = 100;
    [SerializeField, Range(1f, 20f)] private float _moveSpeed = 5f;
    [SerializeField, Tooltip("Damage dealt per hit")] private int _attackDamage = 10;

    [Header("Combat")]
    [SerializeField, Range(0.1f, 3f)] private float _attackCooldown = 1f;
    [SerializeField] private LayerMask _targetLayers;

    [Header("References")]
    [SerializeField] private Transform _attackPoint;
    [SerializeField] private ParticleSystem _hitVFX;

    [Header("Audio")]
    [SerializeField] private AudioClip _attackSound;
    [SerializeField] private AudioClip _deathSound;

    private void OnValidate()
    {
        if (_attackPoint == null)
            Debug.LogWarning($"[{name}] Attack Point not assigned!", this);
    }
}
```

### Example 2: OnValidate for Live Feedback
**User**: "Warn me in editor if patrol points are too close."

**Agent**:
```csharp
public class PatrolRoute : MonoBehaviour
{
    [SerializeField] private Transform[] _waypoints;
    [SerializeField, Min(0.5f)] private float _minWaypointDistance = 2f;

    private void OnValidate()
    {
        if (_waypoints == null || _waypoints.Length < 2) return;

        for (int i = 0; i < _waypoints.Length - 1; i++)
        {
            if (_waypoints[i] == null || _waypoints[i + 1] == null) continue;
            float dist = Vector3.Distance(
                _waypoints[i].position, _waypoints[i + 1].position);
            if (dist < _minWaypointDistance)
            {
                Debug.LogWarning(
                    $"[PatrolRoute] Waypoints {i} and {i + 1} are only {dist:F1}m apart "
                    + $"(min: {_minWaypointDistance}m)", this);
            }
        }
    }
}
```

### Example 3: CreateAssetMenu for Designer-Friendly SO
**User**: "Let designers create weapon configs from the menu."

**Agent**:
```csharp
[CreateAssetMenu(fileName = "NewWeapon", menuName = "Game/Combat/Weapon Config")]
public class WeaponConfigSO : ScriptableObject
{
    [Header("Identity")]
    [SerializeField] private string _displayName;
    [SerializeField, TextArea(2, 4)] private string _description;

    [Header("Stats")]
    [SerializeField, Range(1, 100)] private int _baseDamage = 10;
    [SerializeField, Range(0.1f, 5f)] private float _attackSpeed = 1f;

    [Header("Visuals")]
    [SerializeField] private Sprite _icon;
    [SerializeField] private GameObject _modelPrefab;

    public string DisplayName => _displayName;
    public int BaseDamage => _baseDamage;
    public float AttackSpeed => _attackSpeed;
    public Sprite Icon => _icon;
}
```

## Output Format

- Field exposure strategy
- Recommended attributes
- Validation rules
- Authoring UX improvements
- Over-design to avoid

## Related Skills
- `@script-design-review` - Full script quality review
- `@custom-editor-scripting` - Custom inspectors and property drawers
- `@scriptableobject-architecture` - SO-based data containers
