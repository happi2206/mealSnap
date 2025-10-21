//
//  Models.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI
import UIKit
import Vision // ✅ For CoreML object detection integration

// MARK: - Food Item Model
struct FoodItem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var confidence: Double
    var grams: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        confidence: Double = 1.0,
        grams: Double,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.grams = grams
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
    
    // MARK: - Vision Integration Initializer (For Object Detection)
    init?(observation: VNRecognizedObjectObservation, macros: (cal: Double, protein: Double, carbs: Double, fat: Double)? = nil) {
        guard let label = observation.labels.first else { return nil }
        self.id = UUID()
        self.name = label.identifier.capitalized
        self.confidence = Double(label.confidence)
        self.grams = 100 // Default estimated weight for new detection
        self.calories = macros?.cal ?? FoodItem.estimateCalories(for: name)
        self.protein = macros?.protein ?? 0
        self.carbs = macros?.carbs ?? 0
        self.fat = macros?.fat ?? 0
    }
    
    // MARK: - Computed Properties
    var caloriesPerGram: Double {
        grams.isZero ? 0 : calories / grams
    }
    
    func adjusted(grams newValue: Double) -> FoodItem {
        let multiplier = grams.isZero ? 1 : newValue / grams
        return FoodItem(
            id: id,
            name: name,
            confidence: confidence,
            grams: newValue,
            calories: calories * multiplier,
            protein: protein * multiplier,
            carbs: carbs * multiplier,
            fat: fat * multiplier
        )
    }
    
    // MARK: - Calorie Estimation Helper
    static func estimateCalories(for food: String) -> Double {
        switch food.lowercased() {
        case "apple": return 52.0
        case "banana": return 89.0
        case "chicken breast": return 165.0
        case "rice": return 130.0
        case "bread": return 265.0
        case "salmon": return 208.0
        case "broccoli": return 35.0
        case "avocado": return 160.0
        default: return 100.0 // Generic average per 100g
        }
    }
}

// MARK: - Meal Entry Model
struct MealEntry: Identifiable, Codable {
    let id: UUID
    var date: Date
    var photoURL: String? // ✅ Firebase-friendly (instead of UIImage)
    var items: [FoodItem]
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        photoURL: String? = nil,
        items: [FoodItem]
    ) {
        self.id = id
        self.date = date
        self.photoURL = photoURL
        self.items = items
    }
    
    // MARK: - Computed Totals
    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }
}

// MARK: - Weekly Intake Model
struct WeeklyIntake: Identifiable, Codable {
    let id: UUID
    var date: Date
    var calories: Double
}

// MARK: - Weekly Stats Extension
extension Array where Element == MealEntry {
    var weeklyStats: [WeeklyIntake] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        return grouped.map { (key, value) in
            WeeklyIntake(id: UUID(), date: key, calories: value.reduce(0) { $0 + $1.totalCalories })
        }
        .sorted { $0.date < $1.date }
    }
}

// MARK: - Mock Data (for previews)
extension MealEntry {
    static let mockMeals: [MealEntry] = {
        func image(named: String) -> String? {
            // ✅ Placeholder URL for local previews
            return "system://\(named)"
        }
        
        return [
            MealEntry(
                items: [
                    FoodItem(name: "Greek Yogurt", confidence: 0.94, grams: 180, calories: 190, protein: 18, carbs: 15, fat: 6),
                    FoodItem(name: "Granola", confidence: 0.87, grams: 55, calories: 210, protein: 5, carbs: 30, fat: 7)
                ]
            ),
            MealEntry(
                date: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
                items: [
                    FoodItem(name: "Salmon", confidence: 0.91, grams: 150, calories: 280, protein: 26, carbs: 0, fat: 18),
                    FoodItem(name: "Quinoa", confidence: 0.83, grams: 120, calories: 160, protein: 6, carbs: 27, fat: 3),
                    FoodItem(name: "Steamed Broccoli", confidence: 0.89, grams: 100, calories: 35, protein: 3, carbs: 7, fat: 0.5)
                ]
            ),
            MealEntry(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                items: [
                    FoodItem(name: "Avocado Toast", confidence: 0.86, grams: 140, calories: 290, protein: 8, carbs: 32, fat: 15),
                    FoodItem(name: "Cold Brew", confidence: 0.72, grams: 240, calories: 30, protein: 1, carbs: 7, fat: 0)
                ]
            )
        ]
    }()
}

#Preview {
    List(MealEntry.mockMeals) { meal in
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.date, style: .date)
            Text("Calories \(Int(meal.totalCalories)) kcal")
        }
    }
    .preferredColorScheme(.dark)
}

