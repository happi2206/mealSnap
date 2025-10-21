//
//  Models.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI
import UIKit

struct FoodItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var confidence: Double
    var grams: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    
    var caloriesPerGram: Double {
        grams.isZero ? 0 : calories / grams
    }
    
    func adjusted(grams newValue: Double) -> FoodItem {
        let multiplier = grams.isZero ? 1 : newValue / grams
        var updated = self
        updated.grams = newValue
        updated.calories = calories * multiplier
        updated.protein = protein * multiplier
        updated.carbs = carbs * multiplier
        updated.fat = fat * multiplier
        return updated
    }
}

struct MealEntry: Identifiable {
    var id = UUID()
    var date: Date
    var photo: UIImage?
    var items: [FoodItem]
    
    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        items.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Double {
        items.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFat: Double {
        items.reduce(0) { $0 + $1.fat }
    }
}

struct WeeklyIntake: Identifiable {
    let id = UUID()
    var date: Date
    var calories: Double
}

enum Units: String, CaseIterable, Identifiable {
    case grams = "g"
    case ounces = "oz"
    
    var id: String { rawValue }
}

extension MealEntry {
    static let mockMeals: [MealEntry] = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        
        func image(named: String) -> UIImage? {
            UIImage(systemName: named)
        }
        
        return [
            MealEntry(
                date: Date(),
                photo: image(named: "takeoutbag.and.cup.and.straw"),
                items: [
                    FoodItem(
                        name: "Greek Yogurt",
                        confidence: 0.94,
                        grams: 180,
                        calories: 190,
                        protein: 18,
                        carbs: 15,
                        fat: 6
                    ),
                    FoodItem(
                        name: "Granola",
                        confidence: 0.87,
                        grams: 55,
                        calories: 210,
                        protein: 5,
                        carbs: 30,
                        fat: 7
                    )
                ]
            ),
            MealEntry(
                date: Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date(),
                photo: image(named: "fork.knife"),
                items: [
                    FoodItem(
                        name: "Salmon",
                        confidence: 0.91,
                        grams: 150,
                        calories: 280,
                        protein: 26,
                        carbs: 0,
                        fat: 18
                    ),
                    FoodItem(
                        name: "Quinoa",
                        confidence: 0.83,
                        grams: 120,
                        calories: 160,
                        protein: 6,
                        carbs: 27,
                        fat: 3
                    ),
                    FoodItem(
                        name: "Steamed Broccoli",
                        confidence: 0.89,
                        grams: 100,
                        calories: 35,
                        protein: 3,
                        carbs: 7,
                        fat: 0.5
                    )
                ]
            ),
            MealEntry(
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                photo: image(named: "cup.and.saucer.fill"),
                items: [
                    FoodItem(
                        name: "Avocado Toast",
                        confidence: 0.86,
                        grams: 140,
                        calories: 290,
                        protein: 8,
                        carbs: 32,
                        fat: 15
                    ),
                    FoodItem(
                        name: "Cold Brew",
                        confidence: 0.72,
                        grams: 240,
                        calories: 30,
                        protein: 1,
                        carbs: 7,
                        fat: 0
                    )
                ]
            )
        ]
    }()
}

extension Array where Element == MealEntry {
    var weeklyStats: [WeeklyIntake] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { entry in
            calendar.startOfDay(for: entry.date)
        }
        
        return grouped.map { (key, value) in
            WeeklyIntake(date: key, calories: value.reduce(0) { $0 + $1.totalCalories })
        }
        .sorted { $0.date < $1.date }
    }
}

#Preview {
    List(MealEntry.mockMeals) { meal in
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.date, style: .date)
            Text("Calories \(Int(meal.totalCalories))")
        }
    }
    .preferredColorScheme(.dark)
}
