import Testing
@testable import AnalyticsProvider

// MARK: - Mock Types for Testing

enum AppViews: ViewType {
    case mock
    
    var name: String {
        switch self {
        case .mock:
            return "mock_view"
        }
    }
    
    var parameters: [String: AnyHashable]? {
        switch self {
        case .mock:
            [
                "user": "mock_user"
            ]
        }
    }
}

enum AppEvents: String, EventType {
    case mock
    
    var name: String {
        self.rawValue
    }
    
    var parameters: [String: AnyHashable]? {
        switch self {
        case .mock:
            [
                "user": "mock_user"
            ]
        }
    }
}

struct MockPurchase: PurchaseType {
    let transactionId: String
    let price: Double
    let name: String
    let currency: String
    let category: String
    let sku: String
    let success: Bool
    let coupon: String?
    
    init(
        transactionId: String = "test_txn_123",
        price: Double = 9.99,
        name: String = "Test Product",
        currency: String = "USD",
        category: String = "test",
        sku: String = "test_sku",
        success: Bool = true,
        coupon: String? = nil
    ) {
        self.transactionId = transactionId
        self.price = price
        self.name = name
        self.currency = currency
        self.category = category
        self.sku = sku
        self.success = success
        self.coupon = coupon
    }
}

final class MockAnalyticsProvider: AnalyticsProvider {
    var loggedViews: [ViewType] = []
    var loggedEvents: [EventType] = []
    var loggedPurchases: [PurchaseType] = []
    var userProperties: [String: String?] = [:]
    
    func log(_ view: ViewType) {
        loggedViews.append(view)
    }
    
    func log(_ event: EventType) {
        loggedEvents.append(event)
    }
    
    func log(_ purchase: PurchaseType) {
        loggedPurchases.append(purchase)
    }
    
    func setUserProperty(_ value: String?, for key: String) {
        userProperties[key] = value
    }
    
    func reset() {
        loggedViews.removeAll()
        loggedEvents.removeAll()
        loggedPurchases.removeAll()
        userProperties.removeAll()
    }
}

// MARK: - Analytics Class Tests

@Test("Analytics initialization")
func analyticsInitialization() {
    let analytics = Analytics()
    #expect(analytics != nil)
}

@Test("Register single provider")
func registerSingleProvider() {
    let analytics = Analytics()
    let provider = MockAnalyticsProvider()
    
    analytics.register(providers: [provider])
    
    analytics.log(AppEvents.mock)
    
    #expect(provider.loggedEvents.count == 1)
    #expect(provider.loggedEvents[0].name == "mock")
}


@Test("Register multiple providers")
func registerMultipleProviders() {
    let analytics = Analytics()
    let provider1 = MockAnalyticsProvider()
    let provider2 = MockAnalyticsProvider()
    
    analytics.register(providers: [provider1, provider2])
    
    analytics.log(AppEvents.mock)
    
    #expect(provider1.loggedEvents.count == 1)
    #expect(provider2.loggedEvents.count == 1)
    #expect(provider1.loggedEvents[0].name == "mock")
    #expect(provider2.loggedEvents[0].name == "mock")
}


@Test("Register providers multiple times")
func registerProvidersMultipleTimes() {
    let analytics = Analytics()
    let provider1 = MockAnalyticsProvider()
    let provider2 = MockAnalyticsProvider()
    
    analytics.register(providers: [provider1])
    analytics.register(providers: [provider2])
    
    analytics.log(AppEvents.mock)
    
    #expect(provider1.loggedEvents.count == 1)
    #expect(provider2.loggedEvents.count == 1)
}


@Test("Log view to all providers")
func logViewToAllProviders() {
    let analytics = Analytics()
    let provider1 = MockAnalyticsProvider()
    let provider2 = MockAnalyticsProvider()
    
    analytics.register(providers: [provider1, provider2])
    
    analytics.log(AppViews.mock)
    
    #expect(provider1.loggedViews.count == 1)
    #expect(provider2.loggedViews.count == 1)
    #expect(provider1.loggedViews[0].name == "mock_view")
    #expect(provider2.loggedViews[0].name == "mock_view")
    #expect(provider1.loggedViews[0].parameters?["user"] as? String == .some("mock_user"))
}


@Test("Log event to all providers")
func logEventToAllProviders() {
    let analytics = Analytics()
    let provider1 = MockAnalyticsProvider()
    let provider2 = MockAnalyticsProvider()
    
    analytics.register(providers: [provider1, provider2])
    
    analytics.log(AppEvents.mock)
 
    #expect(provider1.loggedEvents.count == 1)
    #expect(provider2.loggedEvents.count == 1)
    #expect(provider1.loggedEvents[0].name == "mock")
    #expect(provider2.loggedEvents[0].name == "mock")
    #expect(provider1.loggedEvents[0].parameters?["user"] as? String == "mock_user")
}


@Test("Log purchase to all providers")
func logPurchaseToAllProviders() {
    let analytics = Analytics()
    let provider1 = MockAnalyticsProvider()
    let provider2 = MockAnalyticsProvider()
    
    analytics.register(providers: [provider1, provider2])
    
    let testPurchase = MockPurchase(price: 19.99, name: "Premium Plan")
    analytics.log(testPurchase)
    
    #expect(provider1.loggedPurchases.count == 1)
    #expect(provider2.loggedPurchases.count == 1)
    #expect(provider1.loggedPurchases[0].price == 19.99)
    #expect(provider1.loggedPurchases[0].name == "Premium Plan")
    #expect(provider2.loggedPurchases[0].price == 19.99)
}


@Test("Set user property on all providers")
func setUserPropertyOnAllProviders() {
    let analytics = Analytics()
    let provider1 = MockAnalyticsProvider()
    let provider2 = MockAnalyticsProvider()
    
    analytics.register(providers: [provider1, provider2])
    
    analytics.setUserProperty("premium", for: "user_tier")
    analytics.setUserProperty(nil, for: "temp_flag")
    
    #expect(provider1.userProperties["user_tier"] == .some("premium"))
    #expect(provider1.userProperties.keys.contains("temp_flag"))
    #expect(provider1.userProperties["temp_flag"] == .some(nil))
    #expect(provider2.userProperties["user_tier"] == .some("premium"))
    #expect(provider2.userProperties.keys.contains("temp_flag"))
    #expect(provider2.userProperties["temp_flag"] == .some(nil))
}

// MARK: - Protocol Conformance Tests

@Test("ViewType default parameters")
func viewTypeDefaultParameters() {
    struct SimpleView: ViewType {
        let name = "simple_view"
    }
    
    let view = SimpleView()
    #expect(view.name == "simple_view")
    #expect(view.parameters == nil)
}

@Test("EventType default parameters")
func eventTypeDefaultParameters() {
    struct SimpleEvent: EventType {
        let name = "simple_event"
    }
    
    let event = SimpleEvent()
    #expect(event.name == "simple_event")
    #expect(event.parameters == nil)
}

@Test("PurchaseType default transaction ID")
func purchaseTypeDefaultTransactionId() {
    struct SimplePurchase: PurchaseType {
        let price = 9.99
        let name = "Test Product"
        let currency = "USD"
        let category = "test"
        let sku = "test_sku"
        let success = true
    }
    
    let purchase = SimplePurchase()
    #expect(purchase.transactionId.isEmpty == false)
    #expect(purchase.coupon == nil)
    
    // Verify it generates different IDs
    let purchase2 = SimplePurchase()
    #expect(purchase.transactionId != purchase2.transactionId)
}

@Test("PurchaseType with all properties")
func purchaseTypeWithAllProperties() {
    let purchase = MockPurchase(
        transactionId: "custom_txn_456",
        price: 29.99,
        name: "Pro Subscription",
        currency: "EUR",
        category: "subscription",
        sku: "pro_monthly",
        success: true,
        coupon: "SAVE20"
    )
    
    #expect(purchase.transactionId == "custom_txn_456")
    #expect(purchase.price == 29.99)
    #expect(purchase.name == "Pro Subscription")
    #expect(purchase.currency == "EUR")
    #expect(purchase.category == "subscription")
    #expect(purchase.sku == "pro_monthly")
    #expect(purchase.success == true)
    #expect(purchase.coupon == "SAVE20")
}

// MARK: - Multiple Event Tests


@Test("Log multiple events in sequence")
func logMultipleEventsInSequence() {
    let analytics = Analytics()
    let provider = MockAnalyticsProvider()
    
    analytics.register(providers: [provider])
    
    analytics.log(AppEvents.mock)
    analytics.log(AppEvents.mock)
    analytics.log(AppEvents.mock)
    
    #expect(provider.loggedEvents.count == 3)
    #expect(provider.loggedEvents[0].name == "mock")
    #expect(provider.loggedEvents[1].name == "mock")
    #expect(provider.loggedEvents[2].name == "mock")
}


@Test("Mixed analytics calls")
func mixedAnalyticsCalls() {
    let analytics = Analytics()
    let provider = MockAnalyticsProvider()
    
    analytics.register(providers: [provider])
    
    analytics.log(AppViews.mock)
    analytics.log(AppEvents.mock)
    analytics.log(MockPurchase(name: "product1"))
    analytics.setUserProperty("test_value", for: "test_key")
    
    #expect(provider.loggedViews.count == 1)
    #expect(provider.loggedEvents.count == 1)
    #expect(provider.loggedPurchases.count == 1)
    #expect(provider.userProperties.count == 1)
    
    #expect(provider.loggedViews[0].name == "mock_view")
    #expect(provider.loggedEvents[0].name == "mock")
    #expect(provider.loggedPurchases[0].name == "product1")
    #expect(provider.userProperties["test_key"] == .some("test_value"))
}

// MARK: - Edge Cases


@Test("Analytics with no providers")
func analyticsWithNoProviders() {
    let analytics = Analytics()
    
    // Should not crash when no providers are registered
    analytics.log(AppViews.mock)
    analytics.log(AppEvents.mock)
    analytics.log(MockPurchase())
    analytics.setUserProperty("value", for: "key")
    
    // Test passes if no crashes occur
    #expect(analytics != nil)
}


@Test("Register empty provider array")
func registerEmptyProviderArray() {
    let analytics = Analytics()
    let provider = MockAnalyticsProvider()
    
    analytics.register(providers: [])
    analytics.register(providers: [provider])
    
    analytics.log(AppEvents.mock)
    
    #expect(provider.loggedEvents.count == 1)
}
