---
name: analytics-provider
description: Integrate and use the diamirio AnalyticsProvider Swift package (protocol-based, multi-provider analytics with SwiftUI modifiers). Use when adding AnalyticsProvider to an app via SPM, writing an `AnalyticsProvider` adapter for Firebase/Mixpanel/etc., defining `ViewType`/`EventType`/`PurchaseType` values, wiring the `Analytics` instance into SwiftUI with `.environment(\.analytics, …)`, using `.analyticsView` / `.analyticsOnTap`, handling consent with `setAnalyticsEnabled`, or writing tests against a spy provider.
---

# AnalyticsProvider

A small Swift package (`https://github.com/diamirio/AnalyticsProvider`, product `AnalyticsProvider`) that fans out analytics calls to any number of registered backends. The app talks only to one `Analytics` instance; each backend (Firebase, Mixpanel, a logger, …) is wrapped in a type conforming to `AnalyticsProvider`.

- Platforms: iOS 15+, watchOS 8+, macOS 12+, visionOS 1+
- Swift tools 6.1+
- Current major version: **2.x** (`Analytics(analyticsEnabled:)` is required — there is no parameterless init).

## 1. Add the dependency

`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/diamirio/AnalyticsProvider", from: "2.0.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [.product(name: "AnalyticsProvider", package: "AnalyticsProvider")]
    )
]
```

In Xcode: File → Add Package Dependencies… → paste the URL → "Up to Next Major" from `2.0.0`.

Then `import AnalyticsProvider`.

## 2. API at a glance

| Type | Kind | Purpose |
|---|---|---|
| `ViewType` | protocol, `Sendable` | Screen views: `name: String`, `parameters: [String: AnyHashable]?` (defaults to `nil`) |
| `EventType` | protocol, `Sendable` | Events: `name: String`, `parameters: [String: AnyHashable]?` (defaults to `nil`) |
| `PurchaseType` | protocol, `Sendable` | `transactionId`, `price: Double`, `name`, `currency`, `category`, `sku`, `success: Bool`, `coupon: String?` (`coupon` defaults to `nil`, `transactionId` defaults to a fresh UUID) |
| `AnalyticsProvider` | protocol | Backend adapter. **All five** methods are required: `setAnalyticsEnabled(_:)`, `log(_ view:)`, `log(_ event:)`, `log(_ purchase:)`, `setUserProperty(_:for:)` |
| `Analytics` | class | Facade: `init(analyticsEnabled:)`, `register(providers:)`, `setAnalyticsEnabled(_:)`, `analyticsEnabled` (read-only), `log(_:)` ×3, `setUserProperty(_:for:)` |
| `EnvironmentValues.analytics` | `Analytics?` | SwiftUI environment entry, `nil` by default |
| `View.analyticsView(_:)` | modifier | Logs a `ViewType` in `onAppear` |
| `View.analyticsOnTap(_:)` / `analyticsOnTap(_:...)` | modifier | Logs one or more `EventType`s on tap via a `simultaneousGesture` (doesn't block the button's own action) |

## 3. Write a provider adapter

One adapter per analytics backend. Translate the library's types into the SDK's calls:

```swift
import AnalyticsProvider
import FirebaseAnalytics

struct FirebaseAnalyticsProvider: AnalyticsProvider {
    func setAnalyticsEnabled(_ enabled: Bool) {
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(enabled)
    }

    func log(_ view: ViewType) {
        var params: [String: Any] = [AnalyticsParameterScreenName: view.name]
        view.parameters?.forEach { params[$0.key] = $0.value }
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
    }

    func log(_ event: EventType) {
        FirebaseAnalytics.Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func log(_ purchase: PurchaseType) {
        guard purchase.success else { return }
        var params: [String: Any] = [
            AnalyticsParameterTransactionID: purchase.transactionId,
            AnalyticsParameterValue: purchase.price,
            AnalyticsParameterCurrency: purchase.currency,
            AnalyticsParameterItemName: purchase.name,
            AnalyticsParameterItemCategory: purchase.category,
            AnalyticsParameterItemID: purchase.sku
        ]
        if let coupon = purchase.coupon { params[AnalyticsParameterCoupon] = coupon }
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventPurchase, parameters: params)
    }

    func setUserProperty(_ value: String?, for key: String) {
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: key)
    }
}
```

> **Name clash:** Firebase also has a type called `Analytics`. Inside an adapter file that imports both modules, qualify as `FirebaseAnalytics.Analytics` / `AnalyticsProvider.Analytics` where ambiguous.

Guidelines:
- Implement every method, even as an empty body — there are no default implementations on `AnalyticsProvider`.
- `setAnalyticsEnabled` should actually toggle the SDK's own collection (it is called on `register` and whenever the facade's flag changes).
- Keep adapters thread-safe; they may be called from any thread the app calls `Analytics` from.
- A `ConsoleAnalyticsProvider` that `print`s / uses `os.Logger` is handy for debug builds.

## 4. Create and configure the `Analytics` instance

Create **one** instance at app start and keep it alive (it's a reference type):

```swift
import AnalyticsProvider
import SwiftUI

@main
struct MyApp: App {
    let analytics: Analytics = {
        let analytics = Analytics(analyticsEnabled: UserDefaults.standard.bool(forKey: "analyticsConsent"))
        var providers: [AnalyticsProvider] = [FirebaseAnalyticsProvider()]
        #if DEBUG
        providers.append(ConsoleAnalyticsProvider())
        #endif
        analytics.register(providers: providers)
        return analytics
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.analytics, analytics)
        }
    }
}
```

Behavior to know:
- `analyticsEnabled` has **no default** — decide explicitly. For consent-gated apps start with `false`.
- `register(providers:)` appends (it can be called multiple times) and immediately calls `setAnalyticsEnabled(currentFlag)` on each newly registered provider.
- Providers are called in registration order.

## 5. Consent / opt-out

```swift
analytics.setAnalyticsEnabled(userGaveConsent)
```

- Updates `analytics.analyticsEnabled` and forwards to every provider's `setAnalyticsEnabled`.
- While disabled, `log(view)`, `log(event)`, `log(purchase)` **and `setUserProperty`** are dropped by the facade — nothing reaches providers. Events are not queued; anything logged while disabled is lost.
- Persist the user's choice yourself and pass it to `init` on next launch.

## 6. Define views, events, purchases

Model them as enums so names live in one place:

```swift
enum AppView: ViewType {
    case home
    case productList(count: Int)
    case settings

    var name: String {
        switch self {
        case .home: "home_screen"
        case .productList: "product_list"
        case .settings: "settings"
        }
    }

    var parameters: [String: AnyHashable]? {
        switch self {
        case .productList(let count): ["item_count": count]
        default: nil
        }
    }
}

enum AppEvent: EventType {
    case loginTapped(method: String)
    case productOpened(id: String)
    case logout

    var name: String {
        switch self {
        case .loginTapped: "login_tapped"
        case .productOpened: "product_opened"
        case .logout: "logout"
        }
    }

    var parameters: [String: AnyHashable]? {
        switch self {
        case .loginTapped(let method): ["method": method]
        case .productOpened(let id): ["product_id": id]
        case .logout: nil
        }
    }
}
```

`String`-raw-value enums with `var name: String { rawValue }` work too when no associated values are needed. `parameters` can be omitted entirely (defaults to `nil`).

Purchases:

```swift
struct SubscriptionPurchase: PurchaseType {
    let transactionId: String   // pass the StoreKit transaction id
    let price: Double
    let name: String
    let currency: String
    let category = "subscription"
    let sku: String
    let success: Bool
    let coupon: String?
}

analytics.log(SubscriptionPurchase(
    transactionId: String(transaction.id),
    price: NSDecimalNumber(decimal: product.price).doubleValue,
    name: product.displayName,
    currency: product.priceFormatStyle.currencyCode,
    sku: product.id,
    success: true,
    coupon: nil
))
```

> **Pitfall:** the default `transactionId` is a *computed* property returning `UUID().uuidString` — every read yields a different value. Always store a real `transactionId` when you have one.

## 7. Logging from code

```swift
analytics.log(AppEvent.logout)
analytics.log(AppView.settings)
analytics.setUserProperty("premium", for: "plan")
analytics.setUserProperty(nil, for: "plan") // clear
```

In SwiftUI views, read it from the environment (it's optional):

```swift
@Environment(\.analytics) private var analytics

func onLogout() {
    analytics?.log(AppEvent.logout)
}
```

In view models / services, inject the `Analytics` instance (or a protocol wrapping it) via your DI rather than reaching into SwiftUI's environment.

## 8. SwiftUI modifiers

```swift
struct ProductListView: View {
    let products: [Product]

    var body: some View {
        List(products) { product in
            ProductRow(product: product)
                .analyticsOnTap(AppEvent.productOpened(id: product.id))
        }
        .analyticsView(AppView.productList(count: products.count))
    }
}

Button("Log in") { login() }
    .analyticsOnTap(AppEvent.loginTapped(method: "email"))

// several events from one tap
Button("Buy") { buy() }
    .analyticsOnTap(AppEvent.buyTapped, AppEvent.checkoutStarted)
```

Notes:
- The modifiers read `\.analytics` from the environment; if no instance is injected upstream they silently do nothing. Inject once at the root (`.environment(\.analytics, analytics)`) and it propagates to all children, including sheets/navigation destinations in current SwiftUI (for older OS versions re-inject on presented sheets if events go missing).
- `analyticsView` fires on **every** `onAppear` (e.g., returning to a screen in a `NavigationStack`, tab switches). That is usually the desired screen-view semantics; if not, log manually.
- `analyticsOnTap` uses `simultaneousGesture(TapGesture())`, so the underlying button/action still runs. It only tracks taps, not other activations (keyboard, accessibility actions may not trigger it) — for critical events, log inside the action instead.
- Values captured in the event/view are evaluated when the modifier is created (at `body` time), not at tap time.

## 9. Testing

Use Swift Testing with a spy provider that records every call, and assert what was logged:

```swift
// TestSupport/AnalyticsProviderSpy.swift
import AnalyticsProvider

final class AnalyticsProviderSpy: AnalyticsProvider {
    private(set) var enabled: Bool?
    private(set) var views: [String] = []
    private(set) var events: [String] = []
    private(set) var purchases: [String] = []
    private(set) var userProperties: [String: String?] = [:]

    func setAnalyticsEnabled(_ enabled: Bool) { self.enabled = enabled }
    func log(_ view: ViewType) { views.append(view.name) }
    func log(_ event: EventType) { events.append(event.name) }
    func log(_ purchase: PurchaseType) { purchases.append(purchase.transactionId) }
    func setUserProperty(_ value: String?, for key: String) { userProperties[key] = value }
}
```

```swift
import AnalyticsProvider
import Testing
@testable import MyApp

struct AnalyticsTrackingTests {
    let provider = AnalyticsProviderSpy()

    @Test("Logout is tracked")
    func logoutIsTracked() {
        // Given
        let sut = Analytics(analyticsEnabled: true)
        sut.register(providers: [provider])

        // When
        sut.log(AppEvent.logout)

        // Then
        #expect(provider.events == ["logout"])
    }

    @Test("Nothing is tracked without consent")
    func nothingIsTrackedWithoutConsent() {
        // Given
        let sut = Analytics(analyticsEnabled: false)
        sut.register(providers: [provider])

        // When
        sut.log(AppEvent.logout)

        // Then
        #expect(provider.events.isEmpty)
        #expect(provider.enabled == false)
    }
}
```

- In feature code, test that a reactor or view model logs the right event: inject an `Analytics` with the spy registered and assert `provider.events`.
- Tracking from SwiftUI modifiers (`.analyticsView`, `.analyticsOnTap`) is not unit-testable; keep the event values in testable code and cover the modifiers with UI tests only if tracking is business-critical.

## 10. Thread safety

- `ViewType`, `EventType`, `PurchaseType` are `Sendable`; `AnalyticsProvider` and `Analytics` are **not** and `Analytics` is not actor-isolated.
- Call `Analytics` from one thread (normally the main thread / `@MainActor` code) or synchronize access yourself. Don't call `register` concurrently with logging.
- If a backend SDK requires a specific queue, dispatch inside the adapter.

## Checklist when integrating

1. Add SPM dependency `from: "2.0.0"`.
2. Write one `AnalyticsProvider` adapter per backend (all 5 methods).
3. Create a single `Analytics(analyticsEnabled:)` with an explicit consent value; `register(providers:)`.
4. Inject with `.environment(\.analytics, analytics)` at the root view.
5. Define `ViewType` / `EventType` enums (and `PurchaseType` structs with real transaction IDs).
6. Use `.analyticsView` for screens, `.analyticsOnTap` for taps, `analytics.log(...)` elsewhere.
7. Wire the consent UI to `setAnalyticsEnabled(_:)` and persist the choice.
8. Cover tracking with a spy provider in tests.
