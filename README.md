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
// Define your events using enums
enum AppEvents: String, EventType {
    case buttonClicked = "button_clicked"
    case userLogin = "user_login"
    
    var name: String {
        self.rawValue
    }
    
    var parameters: [String: AnyHashable]? {
        switch self {
        case .buttonClicked: return ["button_id": "login"]
        case .userLogin: return ["method": "email"]
        }
    }
}

// Log events
analytics.log(AppEvents.buttonClicked)
```

### 4. SwiftUI Integration

```swift
struct ContentView: View {
    var body: some View {
        Button("Login") {
            // Action
        }
        .analyticsOnTap(AppEvents.buttonClicked)
        .analyticsView(AppViews.homeScreen)
        .environment(\.analytics, analytics)
    }
}
```

## Usage Examples

### Custom Event Tracking
```swift
enum AppEvents: String, EventType {
    case productViewed = "product_viewed"
    case userLogin = "user_login"
    case buttonClicked = "button_clicked"
    
    var name: String {
        self.rawValue
    }
    
    var parameters: [String: AnyHashable]? {
        switch self {
        case .productViewed: return ["product_id": "123", "category": "electronics"]
        case .userLogin: return ["method": "email"]
        case .buttonClicked: return ["button_id": "login"]
        }
    }
}

analytics.log(AppEvents.productViewed)
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
enum AppViews: ViewType {
    case productList
    case homeScreen
    
    var name: String {
        switch self {
        case .productList: return "product_list"
        case .homeScreen: return "home_screen"
        }
    }
    
    var parameters: [String: AnyHashable]? {
        switch self {
        case .productList: return ["item_count": products.count]
        case .homeScreen: return ["user_type": "premium"]
        }
    }
}

struct ProductListView: View {
    var body: some View {
        List(products) { product in
            ProductRow(product: product)
                .analyticsOnTap(AppEvents.productViewed)
        }
        .analyticsView(AppViews.productList)
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
