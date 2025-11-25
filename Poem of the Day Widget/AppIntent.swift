//
//  AppIntent.swift
//  Poem of the Day Widget
//
//  Created by Stephen Reitz on 11/14/24.
//  Cleaned up - removed unused template code
//

import WidgetKit
import AppIntents

// MARK: - Widget Configuration Intent

/// Configuration intent for the Poem of the Day widget
/// Currently minimal - can be extended for user preferences
struct PoemWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Poem Widget Configuration" }
    static var description: IntentDescription { "Configure your daily poem widget." }
    
    /// Display style for the poem
    @Parameter(title: "Display Style", default: .full)
    var displayStyle: PoemDisplayStyle
    
    /// Whether to show the author
    @Parameter(title: "Show Author", default: true)
    var showAuthor: Bool
    
    /// Whether to show the vibe indicator
    @Parameter(title: "Show Vibe", default: true)
    var showVibe: Bool
}

// MARK: - Display Style

enum PoemDisplayStyle: String, AppEnum {
    case full = "full"
    case compact = "compact"
    case titleOnly = "title_only"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Display Style")
    }
    
    static var caseDisplayRepresentations: [PoemDisplayStyle: DisplayRepresentation] {
        [
            .full: DisplayRepresentation(title: "Full Poem", subtitle: "Show title, content, and author"),
            .compact: DisplayRepresentation(title: "Compact", subtitle: "Show title and first few lines"),
            .titleOnly: DisplayRepresentation(title: "Title Only", subtitle: "Show only the poem title")
        ]
    }
}

// MARK: - Refresh Intent

/// Intent to manually refresh the widget
struct RefreshPoemIntent: AppIntent {
    static var title: LocalizedStringResource { "Refresh Poem" }
    static var description: IntentDescription { "Fetch a new poem for the widget." }
    
    func perform() async throws -> some IntentResult {
        // Trigger widget refresh
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
