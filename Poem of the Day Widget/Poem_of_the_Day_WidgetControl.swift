//
//  Poem_of_the_Day_WidgetControl.swift
//  Poem of the Day Widget
//
//  Created by Stephen Reitz on 11/14/24.
//  Cleaned up - removed unused timer template, added poem-specific controls
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Poem Control Widget

/// Control Center widget for quick poem actions
@available(iOS 18.0, *)
struct Poem_of_the_Day_WidgetControl: ControlWidget {
    static let kind: String = "Stevereitz.Poem-of-the-Day.Poem of the Day Widget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: PoemControlProvider()
        ) { value in
            ControlWidgetButton(action: RefreshPoemControlIntent()) {
                Label {
                    Text(value.hasNewPoem ? "New Poem!" : "Get Poem")
                } icon: {
                    Image(systemName: value.hasNewPoem ? "book.fill" : "book")
                }
            }
        }
        .displayName("Daily Poem")
        .description("Quickly access or refresh your daily poem.")
    }
}

// MARK: - Control Provider

extension Poem_of_the_Day_WidgetControl {
    struct Value {
        var hasNewPoem: Bool
        var poemTitle: String?
    }

    @available(iOS 18.0, *)
    struct PoemControlProvider: AppIntentControlValueProvider {
        func previewValue(configuration: PoemControlConfiguration) -> Value {
            Value(hasNewPoem: false, poemTitle: nil)
        }

        func currentValue(configuration: PoemControlConfiguration) async throws -> Value {
            // Check if we have a poem for today
            let sharedDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday")
            let hasPoem = sharedDefaults?.string(forKey: "poemTitle") != nil
            let poemTitle = sharedDefaults?.string(forKey: "poemTitle")
            
            return Value(hasNewPoem: hasPoem, poemTitle: poemTitle)
        }
    }
}

// MARK: - Configuration Intent

struct PoemControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Poem Control Configuration"
    
    // No configuration needed for now, but can be extended
}

// MARK: - Refresh Control Intent

struct RefreshPoemControlIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Daily Poem"
    static var description: IntentDescription { "Opens the app to show your daily poem." }
    
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
