//
//  AnalyticsProvider.swift
//  AnalyticsProvider
//
//  Created by Mario Hahn on 19.12.17.
//  Copyright © 2017 Mario Hahn. All rights reserved.
//

import Foundation

public protocol ViewType: Sendable {
	var name: String { get }
	var parameters: [AnyHashable: AnyHashable]? { get }
}

public extension ViewType {
	var parameters: [AnyHashable: AnyHashable]? { nil }
}

public protocol EventType: Sendable {
	var name: String { get }
	var parameters: [AnyHashable: AnyHashable]? { get }
}

public extension EventType {
	var parameters: [AnyHashable: AnyHashable]? { nil }
}

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

public extension PurchaseType {
	var transactionId: String {
		UUID().uuidString
	}
	
	var coupon: String? { nil }
}

public protocol AnalyticsProvider: Sendable {
	func log(_ view: ViewType)
	func log(_ event: EventType)
	func log(_ purchase: PurchaseType)

	func setUserProperty(_ value: String?, for key: String)
}

@MainActor
public class Analytics {
	private var providers = [AnalyticsProvider]()
	
	public init() {
		
	}
	
	public func register(providers analyticsProviders: [AnalyticsProvider]) {
		providers.append(contentsOf: analyticsProviders)
	}
	
	public func log(_ view: ViewType) {
		providers.forEach { $0.log(view) }
	}

	public func log(_ event: EventType) {
		providers.forEach { $0.log(event) }
	}

	public func log(_ purchase: PurchaseType) {
		providers.forEach { $0.log(purchase) }
	}

	public func setUserProperty(_ value: String?, for key: String) {
		providers.forEach { $0.setUserProperty(value, for: key) }
	}
}
