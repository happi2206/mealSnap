//
//  mealSnapWidget.swift
//  mealSnapWidget
//
//  Created by Rujeet Prajapati on 21/10/2025.
//

import WidgetKit
import SwiftUI

// MARK: - Entry Model
struct MealEntry: TimelineEntry {
    let date: Date
    let totalCalories: Int
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MealEntry {
        MealEntry(date: Date(), totalCalories: 800)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MealEntry) -> Void) {
        let entry = MealEntry(date: Date(), totalCalories: loadTotalCalories())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MealEntry>) -> Void) {
        let entry = MealEntry(date: Date(), totalCalories: loadTotalCalories())
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    // MARK: - Load from UserDefaults
    func loadTotalCalories() -> Int {
        guard let userDefaults = UserDefaults(suiteName: "group.com.advancediOS.mealsnap") else {
            return 0
        }
        
        // Option A: If using just calories value
        return userDefaults.integer(forKey: "totalCalories")
    }
}

// MARK: - Widget View
struct MealSnapWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                Text("🍽️ MealSnap")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Today's Calories")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(entry.totalCalories)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration
struct mealSnapWidget: Widget {
    let kind: String = "MealSnapWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MealSnapWidgetEntryView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Meal Summary")
        .description("Shows your total calories logged today.")
        .supportedFamilies([.systemSmall, .systemMedium])
        
    }
}

#Preview(as: .systemSmall) {
    mealSnapWidget()
} timeline: {
    MealEntry(date: .now, totalCalories: 257)
    MealEntry(date: .now, totalCalories: 1056)
}
