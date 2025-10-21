//
//  MealDetailView.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI
import UIKit

struct MealDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MealStore
    
    var meal: MealEntry
    @State private var showDeleteDialog = false
    
    private var currentMeal: MealEntry? {
        store.meals.first(where: { $0.id == meal.id })
    }
    
    var body: some View {
        Group {
            if let meal = currentMeal {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        photoSection(meal: meal)
                        summarySection(meal: meal)
                        itemsSection(meal: meal)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
                .background(Color.appBackground)
                .navigationTitle("Meal details")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showDeleteDialog = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Delete meal")
                    }
                }
                .confirmationDialog("Delete this meal?", isPresented: $showDeleteDialog, titleVisibility: .visible) {
                    Button("Delete Meal", role: .destructive) {
                        store.deleteMeal(meal)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                ContentUnavailableView(
                    "Meal removed",
                    systemImage: "tray.fill",
                    description: Text("This meal is no longer in your diary.")
                )
            }
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func photoSection(meal: MealEntry) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Photo")
                    .font(.headline)
                Group {
                    if let urlString = meal.photoURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 240)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                ZStack {
                                    Color.appSurface.opacity(0.6)
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        ZStack {
                            Color.appSurface.opacity(0.6)
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    
    private func summarySection(meal: MealEntry) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Summary")
                    .font(.headline)
                HStack(spacing: 12) {
                    MacroPill(label: "Calories", value: meal.totalCalories, unit: "kcal", tint: .accentPrimary)
                    MacroPill(label: "Protein", value: meal.totalProtein, unit: "g", tint: .accentSecondary)
                    MacroPill(label: "Carbs", value: meal.totalCarbs, unit: "g", tint: .accentTertiary)
                    MacroPill(label: "Fat", value: meal.totalFat, unit: "g", tint: .accentQuaternary)
                }
            }
        }
    }
    
    private func itemsSection(meal: MealEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Items")
                .font(.title2.weight(.semibold))
            ForEach(meal.items) { item in
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(item.name)
                                .font(.headline)
                            Spacer()
                            ConfidenceTag(confidence: item.confidence)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Grams")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Stepper(value: Binding<Double>(
                                get: { item.grams },
                                set: { newValue in
                                    store.updateItem(item, in: meal, grams: max(newValue, 1))
                                }
                            ), in: 1...800, step: 5) {
                                Text("\(Int(item.grams)) g")
                                    .font(.body.weight(.medium))
                            }
                        }
                        HStack {
                            Text("\(Int(item.calories)) kcal")
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                            Spacer()
                            Text("\(Int(item.protein))P \(Int(item.carbs))C \(Int(item.fat))F")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MealDetailView(meal: MealEntry.mockMeals.first!)
            .environmentObject(MealStore())
            .preferredColorScheme(.dark)
    }
}
