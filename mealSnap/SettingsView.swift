//
//  SettingsView.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MealStore
    @EnvironmentObject private var authViewModel: AuthViewModel
    @FocusState private var goalFieldFocused: Bool
    @State private var dailyGoalText: String = ""
    
    var body: some View {
        Form {
            Section("Nutrition plan") {
                if let plan = store.plan {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(plan.name)'s targets")
                            .font(.headline)
                        Text("Goal: \(plan.goal.displayName), pace \(plan.pace.displayName.lowercased())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Calories: \(plan.targetCalories) kcal")
                            .font(.subheadline.weight(.semibold))
                        Text("Macros • \(plan.proteinG)g protein • \(plan.carbsG)g carbs • \(plan.fatG)g fat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("Set up your personalized plan to tailor your dashboard.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button {
                    store.lightImpact()
                    store.presentPlanEditor()
                } label: {
                    Label("Recalculate Plan", systemImage: "wand.and.stars")
                }
            }
            .listRowBackground(Color.appSurface)
            
            Section("Calorie goal") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Daily goal", text: $dailyGoalText)
                            .keyboardType(.numberPad)
                            .focused($goalFieldFocused)
                            .onSubmit(applyGoalFromText)
                            .onChange(of: goalFieldFocused) { _, focused in
                                if !focused {
                                    applyGoalFromText()
                                }
                            }
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { store.dailyGoal },
                        set: { newValue in
                            store.updateDailyGoal(to: newValue)
                            dailyGoalText = String(Int(newValue))
                        }
                    ), in: 1200...4000, step: 50)
                    Text("Current goal \(Int(store.dailyGoal)) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.appSurface)
            
            Section("Units") {
                Picker("Preferred units", selection: $store.selectedUnits) {
                    ForEach(Units.allCases) { unit in
                        Text(unit.rawValue.uppercased())
                            .tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.appSurface)
            
            Section("Capture options") {
                Toggle(isOn: $store.savePhotosLocally) {
                    Label("Save photos locally", systemImage: "externaldrive.badge.timemachine")
                }
                Toggle(isOn: $store.syncHealthLater) {
                    Label("Sync Health later", systemImage: "heart.text.square")
                }
            }
            .listRowBackground(Color.appSurface)
            
            Section(header: Text("Account")) {
                Button("Sign Out") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
            }
            
            Section("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MealSnap 1.0")
                        .font(.headline)
                    Text("Designed for effortless meal logging with on-device intelligence.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("© 2025 MealSnap Studio")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.appSurface)
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            dailyGoalText = String(Int(store.dailyGoal))
        }
        .onChange(of: store.dailyGoal) { _, newValue in
            if !goalFieldFocused {
                dailyGoalText = String(Int(newValue))
            }
        }
    }
    
    private func applyGoalFromText() {
        let filtered = dailyGoalText.filter(\.isNumber)
        if let value = Double(filtered), value >= 1000 {
            let bounded = min(max(value, 1000), 6000)
            store.updateDailyGoal(to: bounded)
            dailyGoalText = String(Int(bounded))
        } else {
            dailyGoalText = String(Int(store.dailyGoal))
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(MealStore())
            .preferredColorScheme(.dark)
    }
}
