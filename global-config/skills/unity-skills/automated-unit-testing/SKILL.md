---
name: automated-unit-testing
description: "Unity Test Framework specialist. Use this when the user writes unit tests, integration tests, learns EditMode/PlayMode testing, uses NUnit assertions, or sets up test infrastructure. Also trigger for: 'write tests for this', 'NUnit in Unity', 'test runner', 'mock dependencies', 'TDD in Unity', 'test fails but code works', or any question about automated testing — even if they don't say 'unit test'. Do NOT use for testability design — use testability-advisor instead."
---

# Automated Unit Testing

## Overview
Unity Test Framework for EditMode (fast, pure C#) and PlayMode (scene, lifecycle) testing. Uses NUnit with Unity extensions for assertions, setup, and test management.

## When to Use
- Use when implementing test infrastructure
- Use when writing tests for game logic
- Use when verifying refactored code
- Use when setting up CI/CD test pipelines
- Use when debugging flaky tests

## Test Types

| Type | Speed | Needs Scene | Use For |
|------|:-----:|:-----------:|---------|
| **EditMode** | Fast | ❌ | Pure C# logic, SO, utilities |
| **PlayMode** | Slow | ✅ | MonoBehaviour lifecycle, physics |

## Best Practices
- ✅ Test logic, not Unity internals
- ✅ Use `[SetUp]` and `[TearDown]` for test isolation
- ✅ Extract logic to pure C# classes for EditMode testing
- ✅ Use descriptive test names: `MethodName_Condition_ExpectedResult`
- ✅ Keep tests fast — mock external dependencies
- ❌ **NEVER** test Unity's API (Transform.Translate works, trust it)
- ❌ **NEVER** write tests that depend on frame timing
- ❌ **NEVER** skip [TearDown] cleanup in PlayMode tests

## Few-Shot Examples

### Example 1: EditMode Tests for Game Logic
**User**: "Write tests for a damage calculator."

**Agent**:
```csharp
[TestFixture]
public class DamageCalculatorTests
{
    [Test]
    public void Calculate_NormalHit_ReturnsBaseDamage()
    {
        float result = DamageCalculator.Calculate(
            baseDamage: 10f, critMultiplier: 2f, isCrit: false);
        Assert.AreEqual(10f, result);
    }

    [Test]
    public void Calculate_CriticalHit_ReturnsMultipliedDamage()
    {
        float result = DamageCalculator.Calculate(
            baseDamage: 10f, critMultiplier: 2f, isCrit: true);
        Assert.AreEqual(20f, result);
    }

    [Test]
    public void Calculate_ZeroDamage_ReturnsZero()
    {
        float result = DamageCalculator.Calculate(
            baseDamage: 0f, critMultiplier: 2f, isCrit: true);
        Assert.AreEqual(0f, result);
    }

    [TestCase(10f, 1.5f, true, 15f)]
    [TestCase(10f, 3f, true, 30f)]
    [TestCase(0f, 2f, false, 0f)]
    public void Calculate_Parameterized(float baseDmg, float mult, bool crit, float expected)
    {
        float result = DamageCalculator.Calculate(baseDmg, mult, crit);
        Assert.AreEqual(expected, result);
    }
}
```

### Example 2: PlayMode Test with Coroutine
**User**: "Test that health reaches zero after enough damage."

**Agent**:
```csharp
[TestFixture]
public class PlayerHealthPlayModeTests
{
    private GameObject _playerObj;
    private PlayerHealth _health;

    [SetUp]
    public void SetUp()
    {
        _playerObj = new GameObject("TestPlayer");
        _health = _playerObj.AddComponent<PlayerHealth>();
        // Need to call Start manually or wait a frame
    }

    [TearDown]
    public void TearDown()
    {
        Object.DestroyImmediate(_playerObj);
    }

    [UnityTest]
    public IEnumerator TakeDamage_ExceedsMaxHealth_Dies()
    {
        yield return null; // Wait for Start

        _health.TakeDamage(50f);
        Assert.IsTrue(_health.IsAlive, "Should still be alive at 50% health");

        _health.TakeDamage(60f);
        Assert.IsFalse(_health.IsAlive, "Should be dead after 110% total damage");
    }

    [UnityTest]
    public IEnumerator TakeDamage_RaisesEvent()
    {
        yield return null;

        bool eventFired = false;
        _health.OnHealthChanged += (_, _) => eventFired = true;

        _health.TakeDamage(10f);
        Assert.IsTrue(eventFired, "OnHealthChanged should fire on damage");
    }
}
```

### Example 3: Testing with Mocks
**User**: "Test shop purchases without real save system."

**Agent**:
```csharp
// Interface for dependency injection
public interface ICurrencyProvider
{
    int Gold { get; }
    void Spend(int amount);
}

// Fake for testing
public class FakeCurrencyProvider : ICurrencyProvider
{
    public int Gold { get; private set; }
    public FakeCurrencyProvider(int gold) => Gold = gold;
    public void Spend(int amount) => Gold -= amount;
}

[TestFixture]
public class ShopTests
{
    [Test]
    public void TryBuy_WithEnoughGold_ReturnsTrue()
    {
        var currency = new FakeCurrencyProvider(gold: 100);
        var shop = new ShopService(currency);

        bool result = shop.TryBuy(itemPrice: 50);

        Assert.IsTrue(result);
        Assert.AreEqual(50, currency.Gold);
    }

    [Test]
    public void TryBuy_WithInsufficientGold_ReturnsFalse()
    {
        var currency = new FakeCurrencyProvider(gold: 10);
        var shop = new ShopService(currency);

        bool result = shop.TryBuy(itemPrice: 50);

        Assert.IsFalse(result);
        Assert.AreEqual(10, currency.Gold); // Gold unchanged
    }
}
```

## Test Naming Convention
```
MethodName_StateUnderTest_ExpectedBehavior
```
Examples:
- `Calculate_CriticalHit_ReturnsDoubledDamage`
- `TryBuy_InsufficientGold_ReturnsFalse`
- `TakeDamage_LethalAmount_TriggersDeathEvent`

## Related Skills
- `@testability-advisor` - Making code testable
- `@asmdef-advisor` - Test assembly setup
- `@di-container-manager` - Injecting mocks
