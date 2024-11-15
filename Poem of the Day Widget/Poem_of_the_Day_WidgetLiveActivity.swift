//
//  Poem_of_the_Day_WidgetLiveActivity.swift
//  Poem of the Day Widget
//
//  Created by Stephen Reitz on 11/14/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Poem_of_the_Day_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Poem_of_the_Day_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Poem_of_the_Day_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Poem_of_the_Day_WidgetAttributes {
    fileprivate static var preview: Poem_of_the_Day_WidgetAttributes {
        Poem_of_the_Day_WidgetAttributes(name: "World")
    }
}

extension Poem_of_the_Day_WidgetAttributes.ContentState {
    fileprivate static var smiley: Poem_of_the_Day_WidgetAttributes.ContentState {
        Poem_of_the_Day_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Poem_of_the_Day_WidgetAttributes.ContentState {
         Poem_of_the_Day_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Poem_of_the_Day_WidgetAttributes.preview) {
   Poem_of_the_Day_WidgetLiveActivity()
} contentStates: {
    Poem_of_the_Day_WidgetAttributes.ContentState.smiley
    Poem_of_the_Day_WidgetAttributes.ContentState.starEyes
}
