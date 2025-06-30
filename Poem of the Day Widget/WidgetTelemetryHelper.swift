import Foundation
import WidgetKit

// MARK: - Simplified Widget Telemetry Models

struct WidgetTelemetryEvent: Codable {
    let eventName: String
    let timestamp: Date
    let source: String
    let widgetFamily: String
    let interactionType: String
    let success: Bool?
    let errorType: String?
    
    init(eventName: String, widgetFamily: String, interactionType: String, success: Bool? = nil, errorType: String? = nil) {
        self.eventName = eventName
        self.timestamp = Date()
        self.source = "widget"
        self.widgetFamily = widgetFamily
        self.interactionType = interactionType
        self.success = success
        self.errorType = errorType
    }
}

// MARK: - Widget Telemetry Helper

class WidgetTelemetryHelper {
    private let userDefaults: UserDefaults
    private let appGroupIdentifier = "group.com.stevereitz.poemoftheday"
    
    init() {
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
    
    func trackWidgetView(family: WidgetFamily) {
        let event = WidgetTelemetryEvent(
            eventName: "widget_interaction",
            widgetFamily: family.description,
            interactionType: "view"
        )
        persistEvent(event)
    }
    
    func trackWidgetTap(family: WidgetFamily) {
        let event = WidgetTelemetryEvent(
            eventName: "widget_interaction",
            widgetFamily: family.description,
            interactionType: "tap"
        )
        persistEvent(event)
    }
    
    func trackWidgetRefresh(family: WidgetFamily, success: Bool, error: String? = nil) {
        let event = WidgetTelemetryEvent(
            eventName: "widget_interaction",
            widgetFamily: family.description,
            interactionType: "refresh",
            success: success,
            errorType: error
        )
        persistEvent(event)
    }
    
    private func persistEvent(_ event: WidgetTelemetryEvent) {
        guard let eventData = try? JSONEncoder().encode(event) else { return }
        
        var existingEvents = userDefaults.array(forKey: "widget_telemetry_events") as? [Data] ?? []
        existingEvents.append(eventData)
        
        // Keep only last 100 events to manage storage
        if existingEvents.count > 100 {
            existingEvents = Array(existingEvents.suffix(100))
        }
        
        userDefaults.set(existingEvents, forKey: "widget_telemetry_events")
    }
}

// MARK: - Widget Family Extension

extension WidgetFamily {
    var description: String {
        switch self {
        case .systemSmall:
            return "small"
        case .systemMedium:
            return "medium"
        case .systemLarge:
            return "large"
        case .systemExtraLarge:
            return "extra_large"
        @unknown default:
            return "unknown"
        }
    }
}