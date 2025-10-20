//
//  MealStore.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 14/10/2025.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class MealStore: ObservableObject {
    @Published var meals: [MealEntry]
    @Published var dailyGoal: Double
    @Published var selectedUnits: Units
    @Published var savePhotosLocally: Bool
    @Published var syncHealthLater: Bool
    @Published var detectedItems: [FoodItem]
    @Published var selectedImage: UIImage?
    @Published var errorMessage: String?
    @Published var isRefreshing: Bool = false
    @Published var plan: AppPlan? {
        didSet {
            guard let plan else { return }
            dailyGoal = Double(plan.targetCalories)
        }
    }
    @Published var showingOnboarding: Bool = false
    
    init(
        meals: [MealEntry] = MealEntry.mockMeals,
        dailyGoal: Double = 2200,
        selectedUnits: Units = .grams,
        savePhotosLocally: Bool = true,
        syncHealthLater: Bool = false,
        detectedItems: [FoodItem] = MealStore.sampleDetections
    ) {
        self.meals = meals
//        let storedPlan = PlanStorage.load()
//        self.plan = storedPlan
//        self.dailyGoal = storedPlan.map { Double($0.targetCalories) } ?? dailyGoal
        self.dailyGoal = dailyGoal
        self.selectedUnits = selectedUnits
        self.savePhotosLocally = savePhotosLocally
        self.syncHealthLater = syncHealthLater
        self.detectedItems = detectedItems
//        self.showingOnboarding = storedPlan == nil
    }

    func loadUserData() {
        FirestoreService.shared.fetchUserPlan { plan, onboardingComplete in
            DispatchQueue.main.async {
                self.plan = plan
                self.showingOnboarding = !onboardingComplete
            }
        }
    }

    func updatePlan(_ plan: AppPlan) {
        self.plan = plan
        FirestoreService.shared.saveUserPlan(plan)
        self.showingOnboarding = false
    }
    
    var consumedCaloriesToday: Double {
        todayMeals.reduce(0) { $0 + $1.totalCalories }
    }
    
    var calorieProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(consumedCaloriesToday / dailyGoal, 1)
    }
    
    var todayMeals: [MealEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { Calendar.current.startOfDay(for: $0.date) == today }
            .sorted { $0.date > $1.date }
    }
    
    var weeklyTrend: [WeeklyIntake] {
        meals.weeklyStats
    }
    
    var macroTotalsToday: (protein: Double, carbs: Double, fat: Double) {
        todayMeals.reduce((0, 0, 0)) { result, meal in
            (
                result.0 + meal.totalProtein,
                result.1 + meal.totalCarbs,
                result.2 + meal.totalFat
            )
        }
    }
    
    var macroTargets: (protein: Int, carbs: Int, fat: Int)? {
        guard let plan else { return nil }
        return (plan.proteinG, plan.carbsG, plan.fatG)
    }
    
    func refreshToday() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 800_000_000)
        if Task.isCancelled {
            isRefreshing = false
            return
        }
        detectedItems.shuffle()
        isRefreshing = false
    }
    
    func updateDetectedItem(_ item: FoodItem, grams: Double) {
        guard let index = detectedItems.firstIndex(of: item) else { return }
        withAnimation(.easeInOut) {
            detectedItems[index] = item.adjusted(grams: grams)
        }
    }
    
    func saveDetectedItemsToDiary() {
        guard !detectedItems.isEmpty else {
            errorMessage = "No items detected yet."
            softErrorHaptic()
            return
        }
        
        let newMeal = MealEntry(
            date: Date(),
            photo: selectedImage ?? UIImage(systemName: "camera.viewfinder"),
            items: detectedItems
        )
        
        withAnimation(.spring(duration: 0.5)) {
            meals.insert(newMeal, at: 0)
            detectedItems = Self.sampleDetections
            selectedImage = nil
        }
        successHaptic()
    }
    
    func deleteMeal(_ meal: MealEntry) {
        guard let index = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        withAnimation(.easeInOut) {
            meals.remove(at: index)
        }
    }
    
    func updateItem(_ item: FoodItem, in meal: MealEntry, grams: Double) {
        guard let mealIndex = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        guard let itemIndex = meals[mealIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        meals[mealIndex].items[itemIndex] = meals[mealIndex].items[itemIndex].adjusted(grams: grams)
    }
    
    func clearError() {
        errorMessage = nil
    }
    
//    func updatePlan(_ plan: AppPlan) {
//        PlanStorage.save(plan)
//        withAnimation(.spring) {
//            self.plan = plan
//            self.dailyGoal = Double(plan.targetCalories)
//            showingOnboarding = false
//        }
//    }
    
    func presentPlanEditor() {
        showingOnboarding = true
    }
    
    func updateDailyGoal(to value: Double) {
        let bounded = min(max(value, 1000), 6000)
        dailyGoal = bounded
        guard var plan else { return }
        plan.targetCalories = Int(bounded.rounded())
        let macros = Calculator.macroSplit(calories: bounded)
        plan.proteinG = macros.protein
        plan.carbsG = macros.carbs
        plan.fatG = macros.fat
        self.plan = plan
        PlanStorage.save(plan)
    }
    
    static let sampleDetections: [FoodItem] = [
        FoodItem(
            name: "Chicken Breast",
            confidence: 0.93,
            grams: 120,
            calories: 198,
            protein: 37,
            carbs: 0,
            fat: 4
        ),
        FoodItem(
            name: "Brown Rice",
            confidence: 0.81,
            grams: 180,
            calories: 216,
            protein: 5,
            carbs: 44,
            fat: 1.5
        ),
        FoodItem(
            name: "Roasted Veggies",
            confidence: 0.76,
            grams: 140,
            calories: 110,
            protein: 3,
            carbs: 15,
            fat: 4
        )
    ]
}

// MARK: - Haptic Helpers

extension MealStore {
    private func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func softErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}

#Preview {
    let store = MealStore()
    return VStack(alignment: .leading) {
        Text("Progress \(store.calorieProgress.formatted(.percent.precision(.fractionLength(1))))")
        Text("Today meals \(store.todayMeals.count)")
        Text("Weekly points \(store.weeklyTrend.count)")
    }
    .padding()
    .preferredColorScheme(.dark)
}
