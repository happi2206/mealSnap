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
        meals: [ MealEntry ] = [],
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
        getMeals()
    }

    // MARK: - Firestore + Plan Management
    func loadUserData() {
        FirestoreService.shared.fetchUserPlan { plan, onboardingComplete in
            DispatchQueue.main.async {
                self.plan = plan
                self.showingOnboarding = !onboardingComplete
                self.dailyGoal = plan.map { Double($0.targetCalories) } ?? self.dailyGoal
                self.syncWidgetData()
            }
        }
    }
    
    func getMeals(){
        FirestoreService.shared.fetchMeals { meals, error in
            DispatchQueue.main.async {
                self.meals = meals ?? []
                self.syncWidgetData()
            }
        }
    }

    func updatePlan(_ plan: AppPlan) {
        self.plan = plan
        FirestoreService.shared.saveUserPlan(plan)
        self.showingOnboarding = false
        syncWidgetData()
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
    
    private func syncWidgetData() {
        let targetCalories = plan.map { Double($0.targetCalories) } ?? dailyGoal
        let macros = macroTotalsToday
        let macroSnapshot = WidgetMacroSnapshot(
            consumedProtein: macros.protein,
            consumedCarbs: macros.carbs,
            consumedFat: macros.fat,
            goalProtein: plan.map { Double($0.proteinG) },
            goalCarbs: plan.map { Double($0.carbsG) },
            goalFat: plan.map { Double($0.fatG) }
        )
        
        let latestMeal = todayMeals.first
        let mealTitle: String? = {
            guard let meal = latestMeal else { return nil }
            let topItems = meal.items.prefix(2).map { $0.name }
            if !topItems.isEmpty {
                return topItems.joined(separator: ", ")
            }
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Meal at \(formatter.string(from: meal.date))"
        }()
        
        let mealSnapshot: WidgetMealSnapshot? = {
            guard let meal = latestMeal, let title = mealTitle else { return nil }
            return WidgetMealSnapshot(title: title, calories: meal.totalCalories)
        }()
        
        let payload = WidgetPayload(
            consumedCalories: consumedCaloriesToday,
            targetCalories: targetCalories,
            macro: macroSnapshot,
            lastMeal: mealSnapshot,
            timestamp: Date()
        )
        WidgetBridge.update(with: payload)
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
        
        let itemsToSave = detectedItems
        let mealDate = Date()
        
        func persistMeal(photoURL: String?) {
            let meal = MealEntry(
                date: mealDate,
                photoURL: photoURL,
                items: itemsToSave
            )
            FirestoreService.shared.saveMealEntry(meal) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.softErrorHaptic()
                    } else {
                        self?.selectedImage = nil
                        self?.successHaptic()
                        self?.getMeals()
                    }
                }
            }
        }
        
        if let image = selectedImage {
            FirestoreService.shared.uploadMealPhoto(image) { [weak self] result in
                switch result {
                case .success(let urlString):
                    persistMeal(photoURL: urlString)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.errorMessage = "Upload failed: \(error.localizedDescription)"
                        self?.softErrorHaptic()
                    }
                }
            }
        } else {
            persistMeal(photoURL: nil)
        }
    }
    
    func deleteMeal(_ meal: MealEntry) {
//        guard let index = meals.firstIndex(where: { $0.id == meal.id }) else { return }
//        withAnimation(.easeInOut) {
//            meals.remove(at: index)
//        }
        FirestoreService.shared.deleteMealEntry(meal.id)
        getMeals()
    }
    
    func updateItem(_ item: FoodItem, in meal: MealEntry, grams: Double) {
        guard let mealIndex = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        guard let itemIndex = meals[mealIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        meals[mealIndex].items[itemIndex] = meals[mealIndex].items[itemIndex].adjusted(grams: grams)
        syncWidgetData()
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
        syncWidgetData()
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
    func detectFoodItems(from image: UIImage) {
        guard let visionModel = visionModel else {
            self.errorMessage = "⚠️ ML model not loaded."
            print("❌ Model not loaded.")
            return
        }

        // 1️⃣ Resize image to 360×360 and prepare CIImage from it
        guard let resized = image.resizedToMLInput(size: CGSize(width: 360, height: 360)),
              let ciImage = CIImage(image: resized) else {
            self.errorMessage = "❌ Failed to prepare image."
            print("❌ Could not create CIImage from resized image.")
            return
        }

        print("✅ Prepared CIImage size: \(ciImage.extent.size)")

        // 2️⃣ Build Vision request
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Detection failed: \(error.localizedDescription)"
                }
                print("❌ VNCoreMLRequest error:", error.localizedDescription)
                return
            }

            guard let results = request.results as? [VNClassificationObservation], !results.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "⚠️ No classification results."
                }
                print("⚠️ No classification results returned.")
                return
            }

            // 🔍 Debug: Top 10 predictions
            print("\n🔍 Top 10 predictions:")
            for obs in results.prefix(10) {
                print("→ \(obs.identifier) (\(Int(obs.confidence * 100))%)")
            }

            let best = results.first!
            let confidence = best.confidence

            // Warn for low confidence
            if confidence < 0.10 {
                DispatchQueue.main.async {
                    self.errorMessage = "⚠️ Low confidence — may be inaccurate."
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = nil
                }
            }

            // 3️⃣ Create top detected FoodItem
            let topItem = FoodItem(
                name: best.identifier.capitalized,
                confidence: Double(confidence),
                grams: 100,
                calories: self.estimateCalories(for: best.identifier),
                protein: self.estimateProtein(for: best.identifier),
                carbs: self.estimateCarbs(for: best.identifier),
                fat: self.estimateFat(for: best.identifier)
            )

            // 4️⃣ Update UI
            DispatchQueue.main.async {
                withAnimation(.easeInOut) {
                    self.detectedItems = [topItem]
                    self.selectedImage = resized // ✅ Show resized image, not original
                }
                print("✅ Updated detectedItems:", topItem.name)
            }
        }

        // Match Create ML behavior
        request.imageCropAndScaleOption = .centerCrop
        request.usesCPUOnly = true

        // 5️⃣ Perform Vision request on the resized CIImage (⚠️ not the original image)
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
                print("✅ Vision request performed successfully.")
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Detection failed: \(error.localizedDescription)"
                }
                print("❌ Vision handler error:", error.localizedDescription)
            }
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

import UIKit
import ImageIO

// Helper 1: Resize image for model input (matches Create ML preprocessing)
extension UIImage {
    func resized(to size: CGSize = CGSize(width: 224, height: 224)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
}

// Helper 2: Convert UIImage.Orientation → CGImagePropertyOrientation (for Vision)
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// 👇 Add this once anywhere in your project (outside the class)
extension UIImage {
    func resizedToMLInput(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
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
