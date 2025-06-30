import Foundation
import WidgetKit

class WidgetTelemetryHelper {
    private let telemetryService: TelemetryServiceProtocol
    private let userDefaults: UserDefaults?
    
    init() {
        self.userDefaults = UserDefaults(suiteName: AppConfiguration.appGroupIdentifier)
        self.telemetryService = TelemetryService(
            userDefaults: userDefaults ?? .standard
        )
    }
    
    func trackWidgetView(family: WidgetFamily) {
        Task {
            let event = WidgetInteractionEvent(
                timestamp: Date(),
                interactionType: .view,
                widgetFamily: family.description
            )
            await telemetryService.track(event)
        }
    }
    
    func trackWidgetTap(family: WidgetFamily) {
        Task {
            let event = WidgetInteractionEvent(
                timestamp: Date(),
                interactionType: .tap,
                widgetFamily: family.description
            )
            await telemetryService.track(event)
        }
    }
    
    func trackWidgetRefresh(family: WidgetFamily, success: Bool, error: String? = nil) {
        Task {
            let event = WidgetInteractionEvent(
                timestamp: Date(),
                interactionType: .refresh,
                widgetFamily: family.description
            )
            await telemetryService.track(event)
            
            // If there was an error, track it separately
            if !success, let errorType = error {
                let errorEvent = ErrorEvent(
                    timestamp: Date(),
                    source: .widget,
                    errorType: errorType,
                    errorCode: nil,
                    context: "widget_refresh"
                )
                await telemetryService.track(errorEvent)
            }
        }
    }
}

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