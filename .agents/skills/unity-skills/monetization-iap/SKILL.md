---
name: monetization-iap
description: "In-app purchases and monetization specialist. Use this when the user implements IAP, ad integration, virtual currency, reward systems, or store validation. Also trigger for: 'in-app purchase', 'buy coins', 'remove ads', 'ad monetization', 'receipt validation', 'premium currency', or any question about game monetization — even if they don't say 'IAP'."
---

# Monetization & IAP

## Overview
In-App Purchases (IAP) and monetization systems for Unity. Covers Unity IAP setup, product configuration, receipt validation, and ad integration patterns.

## When to Use
- Use for consumable/non-consumable IAP setup
- Use for subscription management
- Use for ad integration (rewarded, interstitial)
- Use for virtual currency systems
- Use for server-side receipt validation

## Product Types

| Type | Example | Restore |
|------|---------|:-------:|
| **Consumable** | 100 Coins, Energy pack | ❌ |
| **Non-Consumable** | Remove Ads, Character skin | ✅ |
| **Subscription** | VIP Pass, Season Pass | ✅ |

## Best Practices
- ✅ Validate receipts server-side
- ✅ Handle purchase failures gracefully
- ✅ Show loading indicator during purchase
- ✅ Implement restore purchases (required for iOS)
- ✅ Use deferred purchases for parental controls
- ❌ **NEVER** grant rewards before receipt validation
- ❌ **NEVER** store purchase state in PlayerPrefs only
- ❌ **NEVER** show ads during gameplay or important moments

## Few-Shot Examples

### Example 1: Unity IAP Setup
**User**: "Set up IAP for buying coins."

**Agent**:
```csharp
using UnityEngine.Purchasing;
using UnityEngine.Purchasing.Extension;

public class IAPManager : MonoBehaviour, IDetailedStoreListener
{
    private IStoreController _storeController;
    private const string Coins100 = "coins_100";
    private const string RemoveAds = "remove_ads";

    private void Start()
    {
        var builder = ConfigurationBuilder.Instance(StandardPurchasingModule.Instance());
        builder.AddProduct(Coins100, ProductType.Consumable);
        builder.AddProduct(RemoveAds, ProductType.NonConsumable);
        UnityPurchasing.Initialize(this, builder);
    }

    public void BuyCoins() => _storeController?.InitiatePurchase(Coins100);
    public void BuyRemoveAds() => _storeController?.InitiatePurchase(RemoveAds);

    public void OnInitialized(IStoreController controller, IExtensionProvider extensions)
    {
        _storeController = controller;
        Debug.Log("[IAP] Initialized successfully");
    }

    public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
    {
        if (string.Equals(args.purchasedProduct.definition.id, Coins100))
        {
            // Validate receipt server-side before granting
            ValidateAndGrant(args.purchasedProduct);
            return PurchaseProcessingResult.Pending; // Wait for server
        }

        if (string.Equals(args.purchasedProduct.definition.id, RemoveAds))
        {
            PlayerPrefs.SetInt("ads_removed", 1);
            return PurchaseProcessingResult.Complete;
        }

        return PurchaseProcessingResult.Complete;
    }

    public void OnPurchaseFailed(Product product, PurchaseFailureDescription desc)
    {
        Debug.LogError($"[IAP] Purchase failed: {product.definition.id} - {desc.reason}");
    }

    public void OnInitializeFailed(InitializationFailureReason error, string message)
    {
        Debug.LogError($"[IAP] Init failed: {error} - {message}");
    }

    // Required by IDetailedStoreListener
    public void OnInitializeFailed(InitializationFailureReason error) { }

    private async void ValidateAndGrant(Product product)
    {
        // Send receipt to your backend for validation
        // Only grant coins after server confirms
    }
}
```

### Example 2: Rewarded Ad Integration
**User**: "Show rewarded ad for bonus coins."

**Agent**:
```csharp
public class RewardedAdManager : MonoBehaviour
{
    private Action<bool> _onAdCompleted;

    public void ShowRewardedAd(Action<bool> onCompleted)
    {
        _onAdCompleted = onCompleted;

        // Using Unity Ads or AdMob — implementation varies by SDK
        // This shows the pattern:
        if (IsAdReady())
        {
            ShowAd();
        }
        else
        {
            Debug.LogWarning("[Ads] No ad available");
            _onAdCompleted?.Invoke(false);
        }
    }

    // Called by ad SDK callback
    public void OnAdWatched(bool completed)
    {
        if (completed)
        {
            // Grant reward ONLY if fully watched
            CurrencyManager.AddCoins(50);
            Debug.Log("[Ads] Reward granted: 50 coins");
        }
        _onAdCompleted?.Invoke(completed);
    }

    private bool IsAdReady() => true; // Check ad SDK
    private void ShowAd() { /* Show via ad SDK */ }
}
```

### Example 3: Restore Purchases
**User**: "Add restore purchases button for iOS."

**Agent**:
```csharp
public class PurchaseRestorer : MonoBehaviour
{
    [SerializeField] private Button _restoreButton;
    [SerializeField] private TextMeshProUGUI _statusText;

    private void Start()
    {
        // Only show on iOS (required by App Store guidelines)
        _restoreButton.gameObject.SetActive(
            Application.platform == RuntimePlatform.IPhonePlayer);

        _restoreButton.onClick.AddListener(RestorePurchases);
    }

    private void RestorePurchases()
    {
        _statusText.text = "Restoring...";

        var apple = IAPManager.Instance.Extensions
            .GetExtension<IAppleExtensions>();

        apple.RestoreTransactions(result =>
        {
            _statusText.text = result
                ? "Purchases restored!"
                : "Nothing to restore.";
        });
    }
}
```

## Related Skills
- `@backend-integration` - Server-side receipt validation
- `@save-load-serialization` - Local purchase persistence
- `@canvas-performance` - Store UI performance
