import Foundation

/// A protocol representing a view that can be tracked for analytics.
/// 
/// Implement this protocol to create trackable views that can be logged
/// to analytics providers. The view should have a unique name and optional
/// parameters for additional context.
/// 
/// Example:
/// ```swift
/// enum AppViews: ViewType {
///     case homeScreen
///     case profileScreen
///     
///     var name: String {
///         switch self {
///         case .homeScreen: return "home_screen"
///         case .profileScreen: return "profile_screen"
///         }
///     }
///     
///     var parameters: [String: AnyHashable]? {
///         switch self {
///         case .homeScreen: return ["user_type": "premium"]
///         case .profileScreen: return nil
///         }
///     }
/// }
/// ```
public protocol ViewType: Sendable {
	/// The unique name identifier for this view
	var name: String { get }
    
	/// Optional dictionary of additional parameters for context
	var parameters: [String: AnyHashable]? { get }
}

public extension ViewType {
    
	/// Default implementation returns nil for parameters
	var parameters: [String: AnyHashable]? { nil }
}

/// A protocol representing an event that can be tracked for analytics.
/// 
/// Implement this protocol to create trackable events that can be logged
/// to analytics providers. Events should have a descriptive name and optional
/// parameters for additional data.
/// 
/// Example:
/// ```swift
/// enum AppEvents: String, EventType {
///     case buttonClicked = "button_clicked"
///     case userLogin = "user_login"
///     
///     var name: String {
///         self.rawValue
///     }
///     
///     var parameters: [String: AnyHashable]? {
///         switch self {
///         case .buttonClicked: return ["button_id": "login", "screen": "home"]
///         case .userLogin: return ["method": "email"]
///         }
///     }
/// }
/// ```
public protocol EventType: Sendable {
	/// The unique name identifier for this event
	var name: String { get }
    
	/// Optional dictionary of additional parameters for context
	var parameters: [String: AnyHashable]? { get }
}

public extension EventType {
    
	/// Default implementation returns nil for parameters
	var parameters: [String: AnyHashable]? { nil }
}

/// A protocol representing a purchase transaction that can be tracked for analytics.
/// 
/// Implement this protocol to create trackable purchase transactions with all
/// necessary commerce data. This is useful for tracking revenue, conversion rates,
/// and purchase behavior.
/// 
/// Example:
/// ```swift
/// struct AppPurchase: PurchaseType {
///     let transactionId = "txn_123456"
///     let price = 9.99
///     let name = "Premium Subscription"
///     let currency = "USD"
///     let category = "subscription"
///     let sku = "premium_monthly"
///     let success = true
///     let coupon: String? = nil
/// }
/// ```
public protocol PurchaseType: Sendable {
    
	/// Unique identifier for this transaction
	var transactionId: String { get }
    
	/// Price amount for the purchase
	var price: Double { get }
    
	/// Human-readable name of the product or service
	var name: String { get }
    
	/// Currency code (e.g., "USD", "EUR")
	var currency: String { get }
    
	/// Product category for organization
	var category: String { get }
    
	/// Stock keeping unit identifier
	var sku: String { get }
    
	/// Whether the purchase was successful
	var success: Bool { get }
    
	/// Optional coupon code used for the purchase
	var coupon: String? { get }
}

public extension PurchaseType {
	/// Default implementation generates a random UUID for transaction ID
	var transactionId: String {
		UUID().uuidString
	}
	
	/// Default implementation returns nil for coupon
	var coupon: String? { nil }
}

/// A protocol that defines the interface for analytics providers.
/// 
/// Implement this protocol to create custom analytics providers that can
/// receive and process analytics data. Multiple providers can be registered
/// with the Analytics manager to send data to different analytics services.
/// 
/// Example:
/// ```swift
/// struct FirebaseProvider: AnalyticsProvider {
///     func log(_ view: ViewType) {
///         Analytics.logEvent("screen_view", parameters: ["screen_name": view.name])
///     }
///     
///     func log(_ event: EventType) {
///         Analytics.logEvent(event.name, parameters: event.parameters)
///     }
///     
///     // ... implement other methods
/// }
/// ```
public protocol AnalyticsProvider {
	/// Log a view tracking event
	/// - Parameter view: The view to track
	func log(_ view: ViewType)
	
	/// Log a custom event
	/// - Parameter event: The event to track
	func log(_ event: EventType)
	
	/// Log a purchase transaction
	/// - Parameter purchase: The purchase to track
	func log(_ purchase: PurchaseType)

	/// Set a user property for analytics
	/// - Parameters:
	///   - value: The property value (nil to remove)
	///   - key: The property key
	func setUserProperty(_ value: String?, for key: String)
}

/// The main analytics manager class that coordinates multiple analytics providers.
/// 
/// This class acts as a central hub for analytics tracking, allowing you to register
/// multiple analytics providers and broadcast analytics events to all of them simultaneously.
/// All methods are executed on the main actor for thread safety.
/// 
/// Example:
/// ```swift
/// let analytics = Analytics()
/// analytics.register(providers: [FirebaseProvider(), MixpanelProvider()])
/// analytics.log(AppEvents.buttonClicked)
/// analytics.log(AppViews.homeScreen)
/// ```
public class Analytics {
    
	/// Array of registered analytics providers
	private var providers = [AnalyticsProvider]()
	
	/// Initialize a new Analytics instance
	public init() {
		
	}
	
	/// Register one or more analytics providers
	/// 
	/// Providers will receive all subsequent analytics events. You can register
	/// providers multiple times to add more providers to the existing list.
	/// 
	/// - Parameter analyticsProviders: Array of providers to register
	public func register(providers analyticsProviders: [AnalyticsProvider]) {
		providers.append(contentsOf: analyticsProviders)
	}
	
	/// Log a view tracking event to all registered providers
	/// 
	/// This method broadcasts the view event to all registered analytics providers.
	/// Use this to track screen views or page visits.
	/// 
	/// - Parameter view: The view to track
	public func log(_ view: ViewType) {
		providers.forEach { $0.log(view) }
	}

	/// Log a custom event to all registered providers
	/// 
	/// This method broadcasts the event to all registered analytics providers.
	/// Use this to track user interactions, feature usage, or custom business events.
	/// 
	/// - Parameter event: The event to track
	public func log(_ event: EventType) {
		providers.forEach { $0.log(event) }
	}

	/// Log a purchase transaction to all registered providers
	/// 
	/// This method broadcasts the purchase event to all registered analytics providers.
	/// Use this to track revenue, conversion rates, and purchase behavior.
	/// 
	/// - Parameter purchase: The purchase transaction to track
	public func log(_ purchase: PurchaseType) {
		providers.forEach { $0.log(purchase) }
	}

	/// Set a user property on all registered providers
	/// 
	/// This method sets a user property on all registered analytics providers.
	/// User properties are attributes tied to users that persist across sessions.
	/// 
	/// - Parameters:
	///   - value: The property value (pass nil to remove the property)
	///   - key: The property key identifier
	public func setUserProperty(_ value: String?, for key: String) {
		providers.forEach { $0.setUserProperty(value, for: key) }
	}
}
