//
//  TodayView.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI
import WidgetKit

struct TodayView: View {
    @EnvironmentObject private var store: MealStore
    @Binding var selectedTab: AppTab
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }
    
    private var displayName: String? {
        guard let name = store.plan?.name.split(separator: " ").first else { return nil }
        return String(name)
    }
    
    private var greetingTitle: String {
        if let displayName, !displayName.isEmpty {
            return "\(greeting), \(displayName)"
        } else {
            return greeting
        }
    }
    
    private var todayString: String {
        Date.now.formatted(.dateTime.weekday(.wide).month().day())
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                calorieSection
                macroSection
                PrimaryButton(title: "Add Meal", systemImage: "plus.circle.fill") {
                    store.lightImpact()
                    selectedTab = .add
                }
                .accessibilityHint("Switches to the Add tab")
                recentMeals
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Today")
        .scrollIndicators(.hidden)
        .refreshable {
            await store.refreshToday()
        }
        .onAppear{
            PlanStorage().saveTotalCalories(Int(store.consumedCaloriesToday))
            WidgetCenter.shared.reloadAllTimelines()
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingTitle)
                .font(.largeTitle.weight(.bold))
                .lineLimit(1)
            Text(todayString)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
    
    private var calorieSection: some View {
        Card {
            VStack(spacing: 16) {
                CalorieRing(
                    progress: store.calorieProgress,
                    calories: store.consumedCaloriesToday,
                    goal: store.dailyGoal
                )
                HStack(spacing: 16) {
                    summaryRow(
                        label: "Remaining",
                        value: max(store.dailyGoal - store.consumedCaloriesToday, 0),
                        systemImage: "flame.fill"
                    )
                    summaryRow(
                        label: "Goal",
                        value: store.dailyGoal,
                        systemImage: "target"
                    )
                }
                if let targets = store.macroTargets {
                    Divider()
                        .overlay(Color.white.opacity(0.08))
                    VStack(spacing: 6) {
                        Text("Daily macros")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(targets.protein)g protein • \(targets.carbs)g carbs • \(targets.fat)g fat")
                            .font(.footnote.weight(.medium))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func summaryRow(label: String, value: Double, systemImage: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.accentPrimary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(value)) kcal")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
    
    private var macroSection: some View {
        let macros = store.macroTotalsToday
        let targets = store.macroTargets
        return Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Macros today")
                    .font(.headline)
                HStack(spacing: 12) {
                    MacroPill(
                        label: "Protein",
                        value: macros.protein,
                        unit: "g",
                        tint: .accentPrimary,
                        secondaryText: targets.map { "of \($0.protein) g target" }
                    )
                    MacroPill(
                        label: "Carbs",
                        value: macros.carbs,
                        unit: "g",
                        tint: .accentSecondary,
                        secondaryText: targets.map { "of \($0.carbs) g target" }
                    )
                    MacroPill(
                        label: "Fat",
                        value: macros.fat,
                        unit: "g",
                        tint: .accentTertiary,
                        secondaryText: targets.map { "of \($0.fat) g target" }
                    )
                }
            }
        }
    }
    
    private var recentMeals: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent meals")
                .font(.title2.weight(.semibold))
            if store.todayMeals.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(Color.accentSecondary)
                        Text("No meals logged yet.")
                            .font(.headline)
                        Text("Capture your first meal to see it here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(store.todayMeals) { meal in
                            NavigationLink {
                                MealDetailView(meal: meal)
                            } label: {
                                mealCard(for: meal)
                                    .frame(width: 220)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Opens details")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func mealCard(for meal: MealEntry) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                mealImage(for: meal.photoURL)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(meal.date, style: .time)
                    .font(.headline)
                Text("\(Int(meal.totalCalories)) kcal · \(meal.items.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // ✅ Updated to handle URL-based images
    private func mealImage(for photoURL: String?) -> some View {
        Group {
            if let urlString = photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color(.tertiarySystemFill)
                            ProgressView()
                                .tint(.gray)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            Color(.tertiarySystemFill)
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundStyle(.secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

}

#Preview {
    NavigationStack {
        TodayView(selectedTab: .constant(.today))
            .environmentObject(MealStore())
            .preferredColorScheme(.dark)
    }
}
