//
//  Calculator.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import Foundation

/// A centralized nutrition and health calculation engine
enum Calculator {
    
    // MARK: - Unit Conversions
    
    static func heightInCentimeters(heightCM: Double, feet: Double, inches: Double, unit: HeightUnit) -> Double {
        switch unit {
        case .metric, .centimeters:
            // Height is already in centimeters
            return max(heightCM, 0)
        case .imperial, .inches:
            // Convert feet + inches to centimeters
            let totalInches = (feet * 12) + inches
            return totalInches * 2.54
        }
    }

    static func weightInKilograms(weightKG: Double, weightLBS: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .metric, .kilograms:
            // Weight is already in kilograms
            return max(weightKG, 0)
        case .imperial, .pounds:
            // Convert pounds to kilograms
            return weightLBS / 2.205
        }
    }

    
    static func kilogramsToPounds(_ kilograms: Double) -> Double {
        kilograms * 2.205
    }
    
    static func centimetersToFeetInches(_ centimeters: Double) -> (feet: Int, inches: Int) {
        guard centimeters > 0 else { return (0, 0) }
        let totalInches = centimeters / 2.54
        var feet = Int(totalInches / 12)
        var inches = Int(round(totalInches - Double(feet) * 12))
        if inches == 12 {
            feet += 1
            inches = 0
        }
        return (feet, inches)
    }
    
    // MARK: - Health Metrics
    
    static func bmi(weightKG: Double, heightCM: Double) -> Double {
        let heightM = heightCM / 100
        guard heightM > 0 else { return 0 }
        return (weightKG / (heightM * heightM)).rounded(toPlaces: 2)
    }
    
    static func bmiCategory(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    
    static func bmr(weightKG: Double, heightCM: Double, age: Int, sex: Sex) -> Double {
        let base = (10 * weightKG) + (6.25 * heightCM) - (5 * Double(age))
        let sexOffset = (sex == .male) ? 5.0 : -161.0
        return (base + sexOffset).rounded(toPlaces: 2)
    }
    
    static func tdee(bmr: Double, activity: ActivityLevel) -> Double {
        max((bmr * activity.multiplier).rounded(toPlaces: 2), 0)
    }
    
    // MARK: - Goal Adjustments
    
    static func paceOffset(for goal: Goal, pace: Pace) -> Double {
        let offset: Double
        switch pace {
        case .slow: offset = 250
        case .moderate: offset = 425
        case .fast: offset = 650
        case .description: offset = 650
            
        }
        switch goal {
        case .loseWeight: return -offset
        case .maintain: return 0
        case .gainMuscle: return offset
        }
    }
    
    static func adjustedCalories(tdee: Double, goal: Goal, pace: Pace) -> Double {
        let offset = paceOffset(for: goal, pace: pace)
        return max((tdee + offset).rounded(toPlaces: 2), 1200)
    }
    
    // MARK: - Macronutrients
    
    static func macroSplit(calories: Double) -> (protein: Int, carbs: Int, fat: Int) {
        let proteinCalories = calories * 0.30
        let carbCalories = calories * 0.40
        let fatCalories = calories * 0.30
        
        let proteinG = Int((proteinCalories / 4).rounded())
        let carbsG = Int((carbCalories / 4).rounded())
        let fatG = Int((fatCalories / 9).rounded())
        
        return (proteinG, carbsG, fatG)
    }
}

// MARK: - Height & Weight Units



// MARK: - Rounding Helper

extension Double {
    /// Rounds the double to the specified number of decimal places.
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

