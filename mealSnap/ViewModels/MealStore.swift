//
//  MealStore.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 14/10/2025.
//

import Combine
import SwiftUI
import UIKit
import Vision
import CoreML

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
    
    private var visionModel: VNCoreMLModel?

    // MARK: - Init
    init(
        meals: [MealEntry] = [],
        dailyGoal: Double = 2200,
        selectedUnits: Units = .metric,
        savePhotosLocally: Bool = true,
        syncHealthLater: Bool = false,
        detectedItems: [FoodItem] = []
    ) {
        self.meals = meals
        self.dailyGoal = dailyGoal
        self.selectedUnits = selectedUnits
        self.savePhotosLocally = savePhotosLocally
        self.syncHealthLater = syncHealthLater
        self.detectedItems = detectedItems
        loadMLModel()
    }

    // MARK: - Firestore + Plan Management
    func loadUserData() {
        FirestoreService.shared.fetchUserPlan { plan, onboardingComplete in
            DispatchQueue.main.async {
                self.plan = plan
                self.showingOnboarding = !onboardingComplete
                self.dailyGoal = plan.map { Double($0.targetCalories) } ?? self.dailyGoal
            }
        }
    }

    func updatePlan(_ plan: AppPlan) {
        self.plan = plan
        FirestoreService.shared.saveUserPlan(plan)
        self.showingOnboarding = false
    }
    
    // MARK: - Computed Values
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
    
    // MARK: - Utility Actions
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
    
    // ✅ Save detected food into diary
    func saveDetectedItemsToDiary() {
        guard !detectedItems.isEmpty else {
            errorMessage = "No items detected yet."
            self.softErrorHaptic()
            return
        }

        var photoPath: String? = nil
        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.8) {
            let filename = "\(UUID().uuidString).jpg"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try? data.write(to: url)
            photoPath = url.absoluteString
        }

        let newMeal = MealEntry(
            date: Date(),
            photoURL: photoPath,
            items: detectedItems
        )
        
        withAnimation(.spring(duration: 0.5)) {
            meals.insert(newMeal, at: 0)
//            detectedItems = Self.sampleDetections
            selectedImage = nil
        }
        self.successHaptic()
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
        FoodItem(name: "Chicken Breast", confidence: 0.93, grams: 120, calories: 198, protein: 37, carbs: 0, fat: 4),
        FoodItem(name: "Brown Rice", confidence: 0.81, grams: 180, calories: 216, protein: 5, carbs: 44, fat: 1.5),
        FoodItem(name: "Roasted Veggies", confidence: 0.76, grams: 140, calories: 110, protein: 3, carbs: 15, fat: 4)
    ]
}

// MARK: - ML Food Detection
extension MealStore {

    /// Load the CoreML model once at initialization
    private func loadMLModel() {
        do {
            // ✅ Use CPU-only to prevent “espresso context” error
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly

            let model = try food_classifier(configuration: config)
            visionModel = try VNCoreMLModel(for: model.model)

            print("✅ ML Model loaded successfully (CPU mode).")
        } catch {
            print("❌ Failed to load FoodClassifier model:", error.localizedDescription)
            visionModel = nil
        }
    }


    /// Detect food items using the MobileNetV2-based FoodClassifier model
//    func detectFoodItems(from image: UIImage) {
//        // 1️⃣ Prepare ML configuration
//        let config = MLModelConfiguration()
//        config.computeUnits = .cpuOnly // ✅ Ensures it works on the simulator (prevents espresso errors)
//
//        // 2️⃣ Load model safely with CPU fallback
//        guard let coreMLModel = try? food_classifier(configuration: config).model else {
//            self.errorMessage = "Failed to load FoodClassifier model."
//            print("❌ Could not load FoodClassifier.mlmodel.")
//            return
//        }
//
//        // 3️⃣ Wrap it for Vision
//        guard let visionModel = try? VNCoreMLModel(for: coreMLModel) else {
//            self.errorMessage = "Model not available for Vision."
//            print("❌ Model not available for Vision.")
//            return
//        }
//
//        // 4️⃣ Validate CIImage
//        guard let ciImage = CIImage(image: image) else {
//            self.errorMessage = "Invalid image."
//            print("❌ Could not create CIImage.")
//            return
//        }
//
//        print("✅ CIImage created for detection. Size: \(ciImage.extent.size)")
//
//        // 5️⃣ Create Vision request
//        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
//            guard let self = self else { return }
//
//            if let error = error {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Detection failed: \(error.localizedDescription)"
//                }
//                print("❌ VNCoreMLRequest error:", error.localizedDescription)
//                return
//            }
//
//            guard let results = request.results as? [VNClassificationObservation], !results.isEmpty else {
//                DispatchQueue.main.async {
//                    self.errorMessage = "⚠️ No classification results returned."
//                }
//                print("⚠️ No classification results returned.")
//                return
//            }
//
//            print("🔍 Found \(results.count) predictions")
//            for obs in results.prefix(5) {
//                print("→ \(obs.identifier) (\(Int(obs.confidence * 100))%)")
//            }
//
//            let topResults = results.filter { $0.confidence > 0.15 }.prefix(3)
//            if topResults.isEmpty {
//                DispatchQueue.main.async {
//                    self.errorMessage = "No confident matches found."
//                }
//                print("⚠️ All confidences below threshold.")
//                return
//            }
//
//            // 6️⃣ Map to FoodItem list with estimated macros
//            let mappedItems = topResults.map { obs in
//                FoodItem(
//                    name: obs.identifier.capitalized,
//                    confidence: Double(obs.confidence),
//                    grams: 100,
//                    calories: self.estimateCalories(for: obs.identifier),
//                    protein: self.estimateProtein(for: obs.identifier),
//                    carbs: self.estimateCarbs(for: obs.identifier),
//                    fat: self.estimateFat(for: obs.identifier)
//                )
//            }
//
//            DispatchQueue.main.async {
//                withAnimation(.easeInOut) {
//                    self.detectedItems = mappedItems
//                }
//                self.errorMessage = nil
//                print("✅ Updated detectedItems:", mappedItems.map { $0.name })
//            }
//        }
//
//        request.imageCropAndScaleOption = .scaleFit
//
//        // 7️⃣ Run Vision request
//        DispatchQueue.global(qos: .userInitiated).async {
//            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up)
//            do {
//                try handler.perform([request])
//                print("✅ Vision request performed successfully.")
//            } catch {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Failed to perform detection: \(error.localizedDescription)"
//                }
//                print("❌ Vision handler error:", error.localizedDescription)
//            }
//        }
//    }

    func detectFoodItems(from image: UIImage) {
        // 🔸 Static detection — always returns Pizza 🍕
        print("✅ Static detection mode active: Pizza")

        let pizzaItem = FoodItem(
            name: "Pizza",
            confidence: 1.0,
            grams: 150,
            calories: 285,
            protein: 12,
            carbs: 36,
            fat: 10
        )

        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                self.detectedItems = [pizzaItem]
                self.errorMessage = nil
                self.selectedImage = image
            }
            print("✅ Static Pizza result loaded.")
        }
    }


    // MARK: - Nutritional Estimates (placeholder logic)
    private func estimateCalories(for food: String) -> Double {
        switch food.lowercased() {
        case "pizza": return 285
        case "burger": return 354
        case "salad": return 120
        case "sushi": return 200
        default: return Double.random(in: 150...450)
        }
    }

    private func estimateProtein(for food: String) -> Double {
        switch food.lowercased() {
        case "chicken", "steak": return 30
        default: return Double.random(in: 5...30)
        }
    }

    private func estimateCarbs(for food: String) -> Double {
        switch food.lowercased() {
        case "rice", "pasta": return 40
        default: return Double.random(in: 10...60)
        }
    }

    private func estimateFat(for food: String) -> Double {
        switch food.lowercased() {
        case "pizza", "burger": return 15
        default: return Double.random(in: 2...20)
        }
    }
}

// MARK: - Haptic Helpers
extension MealStore {
    func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func softErrorHaptic() {
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

