//
//  DiaryView.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 14/10/2025.
//

import Charts
import SwiftUI
import UIKit

struct DiaryView: View {
    @EnvironmentObject private var store: MealStore
    
    private var groupedMeals: [(date: Date, meals: [MealEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.meals) { meal in
            calendar.startOfDay(for: meal.date)
        }
        return grouped
            .map { (key, value) in
                (date: key, meals: value.sorted { $0.date > $1.date })
            }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        List {
            // ✅ Weekly Trend Chart
            if !store.weeklyTrend.isEmpty {
                Section {
                    Card {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weekly trend")
                                .font(.headline)
                            WeeklyTrendChart(trend: store.weeklyTrend)
                        }
                    }
                }
            }
            
            // ✅ Meals grouped by date
            ForEach(groupedMeals, id: \.date) { day in
                Section {
                    ForEach(day.meals) { meal in
                        NavigationLink {
                            MealDetailView(meal: meal)
                        } label: {
                            MealRow(meal: meal)
                        }
                    }
                } header: {
                    Text(day.date, format: .dateTime.weekday(.wide).month().day())
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listRowBackground(Color.appSurface.opacity(0.8))
        .navigationTitle("Diary")
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Weekly Trend Chart

private struct WeeklyTrendChart: View {
    let trend: [WeeklyIntake] // Replace WeeklyIntake with your actual type

    var body: some View {
        Chart(trend) { intake in
            BarMark(
                x: .value("Day", intake.date, unit: .day),
                y: .value("Calories", intake.calories)
            )
            .foregroundStyle(AnyShapeStyle(LinearGradient(
                colors: [.accentPrimary, .accentSecondary],
                startPoint: .top,
                endPoint: .bottom)
            ))
            .cornerRadius(6)
            .annotation(position: .top, alignment: .center) {
                Text("\(Int(intake.calories))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let _ = value.as(Date.self) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4))
        }
        .frame(height: 200)
    }
}

// MARK: - Meal Row

private struct MealRow: View {
    let meal: MealEntry
    
    var body: some View {
        HStack(spacing: 14) {
            MealThumbnail(photoURL: meal.photoURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mealTitle(for: meal))
                    .font(.headline)
                    .lineLimit(1)
                Text("\(Int(meal.totalCalories)) kcal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
    }
    
    private func mealTitle(for meal: MealEntry) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meal.date)
    }
}

// MARK: - Meal Thumbnail (loads from URL)

private struct MealThumbnail: View {
    let photoURL: String?
    
    var body: some View {
        Group {
            if let urlString = photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure(_):
                        placeholder
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }
    
    private var placeholder: some View {
        ZStack {
            Color.appSurface
            Image(systemName: "photo")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DiaryView()
            .environmentObject(MealStore())
            .preferredColorScheme(.dark)
    }
}

