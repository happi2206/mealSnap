//
//  PlanModels.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 11/10/2025.
//

import Foundation

// MARK: - AppPlan Model
struct AppPlan: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var sex: Sex
    var heightCM: Double
    var weightKG: Double
    var activity: ActivityLevel
    var goal: Goal
    var pace: Pace
    
    // Calculated values
    var bmi: Double
    var bmr: Double
    var tdee: Double
    var targetCalories: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        sex: Sex,
        heightCM: Double,
        weightKG: Double,
        activity: ActivityLevel,
        goal: Goal,
        pace: Pace,
        bmi: Double = 0,
        bmr: Double = 0,
        tdee: Double = 0,
        targetCalories: Int = 0,
        proteinG: Int = 0,
        carbsG: Int = 0,
        fatG: Int = 0
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.sex = sex
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.activity = activity
        self.goal = goal
        self.pace = pace
        self.bmi = bmi
        self.bmr = bmr
        self.tdee = tdee
        self.targetCalories = targetCalories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}

// MARK: - Computation Extensions
extension AppPlan {
    
    /// Calculates the BMI based on height and weight.
    func calculateBMI() -> Double {
        let heightM = heightCM / 100
        return weightKG / (heightM * heightM)
    }
    
    /// Calculates the Basal Metabolic Rate (Mifflin-St Jeor Formula).
    func calculateBMR() -> Double {
        switch sex {
        case .male:
            return 88.362 + (13.397 * weightKG) + (4.799 * heightCM) - (5.677 * Double(age))
        case .female:
            return 447.593 + (9.247 * weightKG) + (3.098 * heightCM) - (4.330 * Double(age))
        case .other:
            // Average of male and female formulas
            let maleBMR = 88.362 + (13.397 * weightKG) + (4.799 * heightCM) - (5.677 * Double(age))
            let femaleBMR = 447.593 + (9.247 * weightKG) + (3.098 * heightCM) - (4.330 * Double(age))
            return (maleBMR + femaleBMR) / 2
        }
    }

    
    /// Calculates Total Daily Energy Expenditure (TDEE).
    func calculateTDEE() -> Double {
        calculateBMR() * activity.multiplier
    }
    
    /// Calculates calorie goal based on desired pace and goal type.
    func calculateTargetCalories() -> Int {
        let tdee = calculateTDEE()
        let adjustment: Double

        switch (goal, pace) {
        case (.loseWeight, .slow): adjustment = 0.90
        case (.loseWeight, .moderate): adjustment = 0.80
        case (.loseWeight, .fast): adjustment = 0.70
            
        case (.gainMuscle, .slow): adjustment = 1.10
        case (.gainMuscle, .moderate): adjustment = 1.20
        case (.gainMuscle, .fast): adjustment = 1.30
            
        case (.maintain, _): adjustment = 1.0

        // ✅ Handles any missing or unexpected combinations
        default:
            adjustment = 1.0
        }

        return Int(tdee * adjustment)
    }



    /// Calculates macronutrient breakdown (40% carbs, 30% protein, 30% fat).
    func calculateMacros(calories: Int) -> (protein: Int, carbs: Int, fat: Int) {
        let proteinCalories = Double(calories) * 0.30
        let carbCalories = Double(calories) * 0.40
        let fatCalories = Double(calories) * 0.30
        
        let protein = Int(proteinCalories / 4)
        let carbs = Int(carbCalories / 4)
        let fat = Int(fatCalories / 9)
        
        return (protein, carbs, fat)
    }
}

// MARK: - Enums







// MARK: - Mock Plan for Previews or Testing
extension AppPlan {
    static let mockPlan = AppPlan(
        name: "Happiness",
        age: 27,
        sex: .female,
        heightCM: 165,
        weightKG: 62,
        activity: .moderate,
        goal: .loseWeight,
        pace: .moderate,
        bmi: 22.8,
        bmr: 1420,
        tdee: 2200,
        targetCalories: 1760,
        proteinG: 132,
        carbsG: 176,
        fatG: 58
    )
}

