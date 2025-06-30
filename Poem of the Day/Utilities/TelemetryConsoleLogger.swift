import Foundation
import OSLog
import Poem_of_the_Day

/// A simple console logger for telemetry data during development
class TelemetryConsoleLogger {
    static let shared = TelemetryConsoleLogger()
    private let telemetryService: TelemetryServiceProtocol
    
    private init() {
        self.telemetryService = await DependencyContainer.shared.makeTelemetryService()
    }
    
    /// Print telemetry summary to console
    func logSummaryToConsole() {
        Task {
            let summary = await telemetryService.getEventSummary()
            
            print("\n📊 TELEMETRY SUMMARY")
            print("=" * 40)
            print("Total Events: \(summary.totalEvents)")
            
            if let mostCommon = summary.mostCommonEvent {
                print("Most Common Event: \(mostCommon)")
            }
            
            print("Average Events/Day: \(String(format: "%.1f", summary.averageEventsPerDay))")
            
            if let dateRange = summary.dateRange {
                print("Date Range: \(DateFormatter.short.string(from: dateRange.start)) - \(DateFormatter.short.string(from: dateRange.end))")
            }
            
            print("\n📈 EVENT BREAKDOWN:")
            for (eventName, count) in summary.eventCounts.sorted(by: { $0.value > $1.value }) {
                print("  \(eventName): \(count)")
            }
            
            if summary.sourceBreakdown.count > 1 {
                print("\n📱 SOURCE BREAKDOWN:")
                for (source, count) in summary.sourceBreakdown.sorted(by: { $0.value > $1.value }) {
                    print("  \(source): \(count)")
                }
            }
            
            print("=" * 40)
        }
    }
    
    /// Print all events to console (useful for debugging)
    func logAllEventsToConsole() {
        Task {
            let events = await telemetryService.exportAllEvents()
            
            print("\n📋 ALL TELEMETRY EVENTS (\(events.count) total)")
            print("=" * 50)
            
            for event in events.suffix(20) { // Show last 20 events
                let timestamp = DateFormatter.timestamp.string(from: event.timestamp)
                print("[\(timestamp)] \(event.eventName) (\(event.source.rawValue))")
                
                if !event.parameters.isEmpty {
                    for (key, value) in event.parameters {
                        print("  - \(key): \(value.value)")
                    }
                }
                print("")
            }
            
            if events.count > 20 {
                print("... showing last 20 of \(events.count) events")
            }
            
            print("=" * 50)
        }
    }
    
    /// Export telemetry data as JSON string to console
    func exportToConsole() {
        Task {
            if let jsonString = await telemetryService.exportEventsAsJSON() {
                print("\n📄 TELEMETRY JSON EXPORT")
                print("=" * 30)
                print(jsonString)
                print("=" * 30)
            } else {
                print("❌ Failed to export telemetry data")
            }
        }
    }
}

// MARK: - Helper Extensions

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}