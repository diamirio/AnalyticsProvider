//
//  View+Analytics.swift
//  AnalyticsProvider
//
//  Created by Dominik Arnhof on 11.06.25.
//

#if canImport(SwiftUI)
import SwiftUI

extension View {
	public func analyticsOnTap(_ event: EventType) -> some View {
		modifier(AnalyticsOnTapModifier(events: [event]))
	}
	
	public func analyticsOnTap(_ events: EventType...) -> some View {
		modifier(AnalyticsOnTapModifier(events: events))
	}
	
	public func analyticsView(_ view: ViewType) -> some View {
		modifier(AnalyticsViewModifier(view: view))
	}
}

private struct AnalyticsOnTapModifier: ViewModifier {
	let events: [EventType]
	
	@Environment(\.analytics)
	private var analytics
	
	func body(content: Content) -> some View {
		content
			.simultaneousGesture(
				TapGesture()
					.onEnded {
						events.forEach { analytics?.log($0) }
					}
			)
	}
}

private struct AnalyticsViewModifier: ViewModifier {
	let view: ViewType
	
	@Environment(\.analytics)
	private var analytics
	
	func body(content: Content) -> some View {
		content
			.onAppear {
				analytics?.log(view)
			}
	}
}

extension EnvironmentValues {
	@Entry
	public var analytics: Analytics?
}
#endif
