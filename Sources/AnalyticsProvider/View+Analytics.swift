#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI extensions for analytics tracking
extension View {
	/// Track a single event when this view is tapped
	/// 
	/// This modifier adds tap gesture recognition to the view and logs the specified
	/// event to the analytics instance from the environment when tapped.
	/// 
	/// - Parameter event: The event to track on tap
	/// - Returns: A view that tracks the event on tap
	public func analyticsOnTap(_ event: EventType) -> some View {
		modifier(AnalyticsOnTapModifier(events: [event]))
	}
	
	/// Track multiple events when this view is tapped
	/// 
	/// This modifier adds tap gesture recognition to the view and logs all specified
	/// events to the analytics instance from the environment when tapped.
	/// 
	/// - Parameter events: Variable number of events to track on tap
	/// - Returns: A view that tracks the events on tap
	public func analyticsOnTap(_ events: EventType...) -> some View {
		modifier(AnalyticsOnTapModifier(events: events))
	}
	
	/// Track a view when it appears on screen
	/// 
	/// This modifier automatically logs the specified view to the analytics instance
	/// from the environment when the view appears. Use this for tracking screen views
	/// or page visits.
	/// 
	/// - Parameter view: The view to track when this view appears
	/// - Returns: A view that tracks the view on appear
	public func analyticsView(_ view: ViewType) -> some View {
		modifier(AnalyticsViewModifier(view: view))
	}
}

/// Internal view modifier for handling tap-based analytics events
private struct AnalyticsOnTapModifier: ViewModifier {
	/// Events to track when the view is tapped
	let events: [EventType]
	
	/// Analytics instance from the SwiftUI environment
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

/// Internal view modifier for handling view appearance analytics events
private struct AnalyticsViewModifier: ViewModifier {
	/// View to track when the modified view appears
	let view: ViewType
	
	/// Analytics instance from the SwiftUI environment
	@Environment(\.analytics)
	private var analytics
	
	func body(content: Content) -> some View {
		content
			.onAppear {
				analytics?.log(view)
			}
	}
}

/// Environment values extension for analytics integration
extension EnvironmentValues {
	/// Analytics instance available in the SwiftUI environment
	/// 
	/// Use this environment value to access the Analytics instance from within
	/// SwiftUI views. Set this value higher in the view hierarchy to make it
	/// available to child views.
	/// 
	/// Example:
	/// ```swift
	/// ContentView()
	///     .environment(\.analytics, analytics)
	/// ```
	@Entry
	public var analytics: Analytics?
}
#endif
