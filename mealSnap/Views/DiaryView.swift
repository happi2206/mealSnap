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
    @State private var showingShareSheet = false
    @State private var snapshotImage: UIImage?
    
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
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
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
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        shareDiary()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityLabel("Share diary")
                }
            }
            .navigationTitle("Diary")
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = snapshotImage {
                let text = "📖 Here's my meal diary for today — powered by MealSnap!"
                ShareSheet(items: [text, image])
            }
        }
    }
    
    /// Captures a screenshot of the diary view and triggers the iOS share sheet
    private func shareDiary() {
        let renderer = ImageRenderer(content: snapshotBody)
        if let uiImage = renderer.uiImage {
            snapshotImage = uiImage
            showingShareSheet = true
        } else {
            print("❌ Failed to generate snapshot image.")
        }
    }
    
    /// The snapshot layout for sharing (same as the main list but static)
    private var snapshotBody: some View {
        VStack(spacing: 12) {
            Text("📖 My Meal Diary")
                .font(.title2.bold())
                .padding(.top, 10)
            
            ForEach(groupedMeals, id: \.date) { day in
                VStack(alignment: .leading, spacing: 6) {
                    Text(day.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.headline)
                        .foregroundColor(.secondary)
                    ForEach(day.meals) { meal in
                        HStack {
                            Text(mealTitle(for: meal))
                                .font(.body)
                            Spacer()
                            Text("\(Int(meal.totalCalories)) kcal")
                                .font(.body.weight(.semibold))
                        }
                    }
                    Divider()
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .padding()
        .background(Color.appBackground)
    }
    
    private func mealTitle(for meal: MealEntry) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meal.date)
    }
}

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var activities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: activities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Weekly Trend Chart
private struct WeeklyTrendChart: View {
    let trend: [WeeklyIntake]
    
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

// MARK: - Meal Thumbnail
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

