//
//  mealSnapWidgetLiveActivity.swift
//  mealSnapWidget
//
//  Created by Rujeet Prajapati on 21/10/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct mealSnapWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct mealSnapWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: mealSnapWidgetAttributes.self) { context in
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

extension mealSnapWidgetAttributes {
    fileprivate static var preview: mealSnapWidgetAttributes {
        mealSnapWidgetAttributes(name: "World")
    }
}

extension mealSnapWidgetAttributes.ContentState {
    fileprivate static var smiley: mealSnapWidgetAttributes.ContentState {
        mealSnapWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: mealSnapWidgetAttributes.ContentState {
         mealSnapWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: mealSnapWidgetAttributes.preview) {
   mealSnapWidgetLiveActivity()
} contentStates: {
    mealSnapWidgetAttributes.ContentState.smiley
    mealSnapWidgetAttributes.ContentState.starEyes
}
