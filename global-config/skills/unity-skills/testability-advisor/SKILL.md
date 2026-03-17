---
name: testability-advisor
description: "Unity testability advisor. Use this when the user wants to improve testability, isolate pure logic from Unity APIs, decide EditMode vs PlayMode tests, or reduce hard-to-test MonoBehaviour logic. Also trigger for: 'how to test this', 'can I unit test in Unity', 'this script is untestable', 'too coupled to test', or any question about making Unity code more testable — even if they don't say 'testability'. Do NOT use for writing actual test code — use automated-unit-testing instead."
---

# Testability Advisor

Use this skill when deciding what logic should stay in Unity-facing classes and what should move to pure C# code.

## Review Questions

- Can the rule/algorithm run without `Transform`, `GameObject`, or scene state?
- Can config be injected instead of read through static globals?
- Can runtime decisions move to a plain C# class called from a thin MonoBehaviour?
- Does this need PlayMode coverage, or is EditMode enough?

## Test Mode Selection

| Test Type | Use When | Speed |
|-----------|----------|-------|
| **EditMode** | Pure C# logic, ScriptableObject data, utility methods | Fast |
| **PlayMode** | MonoBehaviour lifecycle, physics, UI interaction, coroutines | Slow |

## Few-Shot Examples

### Example 1: Extract Testable Logic
**User**: "I can't test my damage calculation because it's inside a MonoBehaviour."

**Agent**:
```csharp
// ❌ BEFORE: Logic buried in MonoBehaviour — untestable without PlayMode
public class Weapon : MonoBehaviour
{
    [SerializeField] private float _baseDamage = 10f;
    [SerializeField] private float _critMultiplier = 2f;

    public void OnHit(Enemy enemy)
    {
        float damage = _baseDamage;
        if (Random.value > 0.8f) damage *= _critMultiplier;
        enemy.TakeDamage(damage);
    }
}

// ✅ AFTER: Pure C# logic — testable in EditMode without scene
public static class DamageCalculator
{
    public static float Calculate(float baseDamage, float critMultiplier, bool isCrit)
    {
        return isCrit ? baseDamage * critMultiplier : baseDamage;
    }
}

// Thin MonoBehaviour just delegates
public class Weapon : MonoBehaviour
{
    [SerializeField] private float _baseDamage = 10f;
    [SerializeField] private float _critMultiplier = 2f;

    public void OnHit(Enemy enemy)
    {
        bool isCrit = Random.value > 0.8f;
        float damage = DamageCalculator.Calculate(_baseDamage, _critMultiplier, isCrit);
        enemy.TakeDamage(damage);
    }
}

// EditMode test — no scene, no PlayMode, instant
[Test]
public void CritDamage_IsMultiplied()
{
    float result = DamageCalculator.Calculate(10f, 2f, isCrit: true);
    Assert.AreEqual(20f, result);
}
```

### Example 2: Inject Dependencies for Testing
**User**: "My manager reads from a static config — I can't mock it for tests."

**Agent**:
```csharp
// ❌ BEFORE: Static dependency — impossible to mock
public class ShopManager
{
    public bool CanBuy(string itemId)
    {
        int price = GameConfig.Instance.GetItemPrice(itemId); // Static!
        int gold = PlayerData.Instance.Gold;                   // Static!
        return gold >= price;
    }
}

// ✅ AFTER: Injected dependencies — fully testable
public class ShopManager
{
    private readonly IItemPriceProvider _prices;
    private readonly ICurrencyProvider _currency;

    public ShopManager(IItemPriceProvider prices, ICurrencyProvider currency)
    {
        _prices = prices;
        _currency = currency;
    }

    public bool CanBuy(string itemId)
    {
        return _currency.Gold >= _prices.GetPrice(itemId);
    }
}

// Test with mock
[Test]
public void CanBuy_WithEnoughGold_ReturnsTrue()
{
    var prices = new FakePriceProvider(itemPrice: 50);
    var currency = new FakeCurrencyProvider(gold: 100);
    var shop = new ShopManager(prices, currency);

    Assert.IsTrue(shop.CanBuy("sword"));
}
```

### Example 3: EditMode vs PlayMode Decision
**User**: "Should I write EditMode or PlayMode tests for my quest system?"

**Agent**:
```csharp
// EditMode candidates — pure logic, no Unity lifecycle needed:
public class QuestTracker  // Pure C#
{
    public bool IsComplete(Quest quest) => quest.CurrentCount >= quest.RequiredCount;
    public void AddProgress(Quest quest, int amount) { /* ... */ }
}
// → EditMode test: fast, no scene loading

// PlayMode candidates — needs MonoBehaviour lifecycle or scene:
public class QuestUI : MonoBehaviour  // Reads from VisualElement, needs UIDocument
{
    private void OnEnable() { /* query UI elements */ }
    public void ShowQuest(Quest quest) { /* update UI */ }
}
// → PlayMode test: needs scene with UIDocument

// Rule of thumb:
// If it compiles without UnityEngine → EditMode
// If it needs Awake/Start/Update or scene objects → PlayMode
```

## Output Format

- Logic that should move to pure C#
- Logic that should stay Unity-facing
- Suggested seams/interfaces
- Candidate EditMode tests
- Candidate PlayMode tests

## Guardrails

- Do not force test seams everywhere if the script is tiny and scene-bound
- Prefer a few meaningful seams over abstraction for its own sake
- A thin MonoBehaviour that delegates to testable C# is often enough

## Related Skills
- `@automated-unit-testing` - Test implementation patterns
- `@script-design-review` - Script quality review
