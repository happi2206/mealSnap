//
//  MealSnapWidget.swift
//  mealSnapWidget
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct MealWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload?
}

// MARK: - Provider
struct MealWidgetProvider: TimelineProvider {
    private let refreshInterval: TimeInterval = 30 * 60
    
    func placeholder(in context: Context) -> MealWidgetEntry {
        MealWidgetEntry(date: Date(), payload: .preview)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MealWidgetEntry) -> Void) {
        completion(MealWidgetEntry(date: Date(), payload: WidgetDefaultsReader.shared.loadPayload() ?? .preview))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MealWidgetEntry>) -> Void) {
        let payload = WidgetDefaultsReader.shared.loadPayload()
        let entry = MealWidgetEntry(date: Date(), payload: payload)
        let timeline = Timeline(
            entries: [entry],
            policy: .after(Date().addingTimeInterval(refreshInterval))
        )
        completion(timeline)
    }
}

// MARK: - Defaults reader
final class WidgetDefaultsReader {
    static let shared = WidgetDefaultsReader()
    
    private let suiteName = "group.com.advancediOS.mealsnap"
    private let payloadKey = "WidgetPayload"
    
    func loadPayload() -> WidgetPayload? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: payloadKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }
}

// MARK: - Widget View
struct MealSnapWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: MealWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(payload: entry.payload)
        case .systemMedium:
            MediumWidgetView(payload: entry.payload)
        case .accessoryInline:
            InlineAccessoryView(payload: entry.payload)
        case .accessoryCircular:
            CircularAccessoryView(payload: entry.payload)
        default:
            SmallWidgetView(payload: entry.payload)
        }
    }
}

// MARK: - Small Widget
private struct SmallWidgetView: View {
    let payload: WidgetPayload?
    
    private var consumed: Double { payload?.consumedCalories ?? 0 }
    private var target: Double { max(payload?.targetCalories ?? 2000, 1) }
    private var remaining: Double { max(target - consumed, 0) }
    
    var body: some View {
        VStack(spacing: 12) {
            WidgetProgressRing(progress: consumed / target)
                .frame(width: 90, height: 90)
                .accessibilityHidden(true)
            
            VStack(spacing: 4) {
                Text("\(Int(consumed)) kcal")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                Text("Remaining \(Int(remaining))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
            
            if payload == nil {
                Text("Open MealSnap to start logging")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(WidgetBackground())
    }
}

// MARK: - Medium Widget
private struct MediumWidgetView: View {
    let payload: WidgetPayload?
    
    private var consumed: Double { payload?.consumedCalories ?? 0 }
    private var target: Double { max(payload?.targetCalories ?? 2000, 1) }
    private var remaining: Double { max(target - consumed, 0) }
    private var macros: WidgetMacroSnapshot? { payload?.macro }
    
    var body: some View {
        HStack(spacing: 18) {
            VStack(spacing: 12) {
                WidgetProgressRing(progress: consumed / target)
                    .frame(width: 110, height: 110)
                    .accessibilityHidden(true)
                VStack(spacing: 2) {
                    Text("\(Int(consumed)) / \(Int(target))")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("kcal today")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer(minLength: 0)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                macroRow(
                    label: "Protein",
                    consumed: macros?.consumedProtein ?? 0,
                    goal: macros?.goalProtein
                )
                macroRow(
                    label: "Carbs",
                    consumed: macros?.consumedCarbs ?? 0,
                    goal: macros?.goalCarbs
                )
                macroRow(
                    label: "Fat",
                    consumed: macros?.consumedFat ?? 0,
                    goal: macros?.goalFat
                )
                Spacer()
                if let meal = payload?.lastMeal {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last meal")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(meal.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(Int(meal.calories)) kcal • Remaining \(Int(remaining))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                } else {
                    Text("Log your first meal to see progress.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(2)
                }
            }
        }
        .padding(16)
        .background(WidgetBackground())
    }
    
    private func macroRow(label: String, consumed: Double, goal: Double?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(Int(consumed))g")
                    .font(.caption)
                    .foregroundStyle(.white)
                if let goal {
                    Text("of \(Int(goal))g")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let progress = goal.map { min(consumed / max($0, 1), 1) } ?? 1
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        Capsule()
                            .fill(LinearGradient(colors: [.accentPrimary, .accentSecondary], startPoint: .leading, endPoint: .trailing))
                            .frame(width: width * progress),
                        alignment: .leading
                    )
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Accessories
private struct InlineAccessoryView: View {
    let payload: WidgetPayload?
    
    var body: some View {
        let consumed = Int(payload?.consumedCalories ?? 0)
        let target = Int(payload?.targetCalories ?? 0)
        Text("MealSnap \(consumed)/\(target) kcal")
    }
}

private struct CircularAccessoryView: View {
    let payload: WidgetPayload?
    
    var body: some View {
        let consumed = payload?.consumedCalories ?? 0
        let target = max(payload?.targetCalories ?? 2000, 1)
        let progress = consumed / target
        ZStack {
            Circle()
                .stroke(lineWidth: 4)
                .foregroundStyle(.white.opacity(0.15))
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(LinearGradient(colors: [.accentPrimary, .accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(consumed))")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
    }
}

// MARK: - Shared Components
private struct WidgetBackground: View {
    var body: some View {
        ContainerRelativeShape()
            .fill(
                LinearGradient(
                    colors: [
                        Color.appSurface,
                        Color.appSurfaceElevated,
                        Color.appBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                ContainerRelativeShape()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.accentPrimary.opacity(0.6), .accentSecondary.opacity(0.3), .clear]),
                            center: .center
                        )
                    )
                    .blur(radius: 80)
            )
            .overlay(
                ContainerRelativeShape()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
    }
}

private struct WidgetProgressRing: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(
                    LinearGradient(colors: [.accentPrimary, .accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: "sparkles")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Widget Configuration
struct MealSnapWidget: Widget {
    let kind: String = "MealSnapWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MealWidgetProvider()) { entry in
            MealSnapWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "mealsnap://today"))
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Meal Progress")
        .description("Track today’s calories and macros at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview Support
extension WidgetPayload {
    static var preview: WidgetPayload {
        WidgetPayload(
            consumedCalories: 1285,
            targetCalories: 2200,
            macro: WidgetMacroSnapshot(
                consumedProtein: 90,
                consumedCarbs: 150,
                consumedFat: 45,
                goalProtein: 150,
                goalCarbs: 220,
                goalFat: 70
            ),
            lastMeal: WidgetMealSnapshot(title: "Salmon, Quinoa", calories: 620),
            timestamp: Date()
        )
    }
}

#Preview(as: .systemMedium) {
    MealSnapWidget()
} timeline: {
    MealWidgetEntry(date: Date.now, payload: .preview)
    MealWidgetEntry(date: Date.now.addingTimeInterval(1800), payload: .preview)
}
