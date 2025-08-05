# AnalyticsProvider

A unified Swift package for analytics tracking across iOS, watchOS, macOS, and visionOS platforms.


## Overview

AnalyticsProvider provides a clean, protocol-based interface for analytics tracking that supports multiple analytics providers simultaneously. It includes built-in SwiftUI integration for seamless view and event tracking.

## Features

- 📊 **Multi-provider support** - Register multiple analytics providers
- 🎯 **Type-safe tracking** - Protocol-based view, event, and purchase tracking
- 📱 **SwiftUI integration** - Built-in view modifiers for automatic tracking
- 🔄 **Thread-safe** - All APIs designed for concurrent usage
- 🌐 **Multi-platform** - iOS 15+, watchOS 8+, macOS 12+, visionOS 1+

## Installation

Add this package to your Xcode project using Swift Package Manager:

```
https://github.com/diamirio/AnalyticsProvider
```

## Quick Start

### 1. Create Analytics Providers

Implement the `AnalyticsProvider` protocol for your analytics services:

```swift
import AnalyticsProvider

struct FirebaseProvider: AnalyticsProvider {
    func log(_ view: ViewType) {
        // Firebase view tracking
    }
    
    func log(_ event: EventType) {
        // Firebase event tracking
    }
    
    func log(_ purchase: PurchaseType) {
        // Firebase purchase tracking
    }
    
    func setUserProperty(_ value: String?, for key: String) {
        // Firebase user properties
    }
}
```

### 2. Setup Analytics

```swift
let analytics = Analytics()
analytics.register(providers: [FirebaseProvider(), MixpanelProvider()])
```

### 3. Track Events

```swift
// Define your events
struct ButtonClickEvent: EventType {
    let name = "button_clicked"
    let parameters = ["button_id": "login"]
}

// Log events
analytics.log(ButtonClickEvent())
```

### 4. SwiftUI Integration

```swift
struct ContentView: View {
    var body: some View {
        Button("Login") {
            // Action
        }
        .analyticsOnTap(ButtonClickEvent())
        .analyticsView(HomeView())
        .environment(\.analytics, analytics)
    }
}
```

## API Reference

### Core Protocols

#### `ViewType`
Protocol for trackable views:
```swift
public protocol ViewType: Sendable {
    var name: String { get }
    var parameters: [AnyHashable: AnyHashable]? { get }
}
```

#### `EventType`
Protocol for trackable events:
```swift
public protocol EventType: Sendable {
    var name: String { get }
    var parameters: [AnyHashable: AnyHashable]? { get }
}
```

#### `PurchaseType`
Protocol for trackable purchases:
```swift
public protocol PurchaseType: Sendable {
    var transactionId: String { get }
    var price: Double { get }
    var name: String { get }
    var currency: String { get }
    var category: String { get }
    var sku: String { get }
    var success: Bool { get }
    var coupon: String? { get }
}
```

#### `AnalyticsProvider`
Protocol for implementing analytics providers:
```swift
public protocol AnalyticsProvider: Sendable {
    func log(_ view: ViewType)
    func log(_ event: EventType)
    func log(_ purchase: PurchaseType)
    func setUserProperty(_ value: String?, for key: String)
}
```

### Analytics Manager

#### `Analytics`
Main class for coordinating multiple providers:
```swift
@MainActor
public class Analytics {
    public init()
    public func register(providers: [AnalyticsProvider])
    public func log(_ view: ViewType)
    public func log(_ event: EventType)
    public func log(_ purchase: PurchaseType)
    public func setUserProperty(_ value: String?, for key: String)
}
```

### SwiftUI Extensions

#### View Modifiers
```swift
extension View {
    public func analyticsOnTap(_ event: EventType) -> some View
    public func analyticsOnTap(_ events: EventType...) -> some View
    public func analyticsView(_ view: ViewType) -> some View
}
```

#### Environment Values
```swift
extension EnvironmentValues {
    @Entry
    public var analytics: Analytics?
}
```

## Usage Examples

### Custom Event Tracking
```swift
struct ProductViewEvent: EventType {
    let name = "product_viewed"
    let parameters: [AnyHashable: AnyHashable]?
    
    init(productId: String, category: String) {
        parameters = [
            "product_id": productId,
            "category": category
        ]
    }
}

analytics.log(ProductViewEvent(productId: "123", category: "electronics"))
```

### Purchase Tracking
```swift
struct AppPurchase: PurchaseType {
    let transactionId: String
    let price: Double
    let name: String
    let currency = "USD"
    let category = "subscription"
    let sku: String
    let success: Bool
    let coupon: String?
}

let purchase = AppPurchase(
    transactionId: "txn_123",
    price: 9.99,
    name: "Premium Subscription",
    sku: "premium_monthly",
    success: true,
    coupon: nil
)

analytics.log(purchase)
```

### SwiftUI Automatic Tracking
```swift
struct ProductListView: View {
    var body: some View {
        List(products) { product in
            ProductRow(product: product)
                .analyticsOnTap(ProductTapEvent(productId: product.id))
        }
        .analyticsView(ProductListScreen())
    }
}
```

## Thread Safety

- All protocols conform to `Sendable` for safe concurrent usage
- `Analytics` class uses `@MainActor` for main thread execution
- Provider implementations should ensure thread-safe logging

## Requirements

- iOS 15.0+ / watchOS 8.0+ / macOS 12.0+ / visionOS 1.0+
- Swift 6.1+
- Xcode 15.0+
