//
//  Sex.swift
//  mealSnap
//
//  Created by Maher Parkar on 21/10/2025.
//



import Foundation

// MARK: - User Profile Enums

enum Sex: String, CaseIterable, Codable, Identifiable {
    case male, female, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
       
        case .other:
            return "Other"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case sedentary
    case light
    case moderate
    case active

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .active: return "Very Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary:
            return "Little or no exercise, mostly sitting or desk work."
        case .light:
            return "Light exercise or activity 1–3 days per week."
        case .moderate:
            return "Moderate exercise 3–5 days per week."
        case .active:
            return "Intense exercise or physical job 6–7 days per week."
        }
    }

    /// 🔥 Multiplier used for TDEE calculation
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        }
    }
}



enum Goal: String, CaseIterable, Codable, Identifiable {
    case loseWeight, maintain, gainMuscle
    
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .loseWeight: return "Lose Weight"
        case .maintain: return "Maintain"
        case .gainMuscle: return "Gain Muscle"
        }
    }
}

enum Pace: String, Codable, CaseIterable, Identifiable {
    case slow = "Slow"
    case moderate = "Moderate"
    case fast = "Fast"
    case description = "description"
    var id: String { rawValue }

    var displayName: String {
        rawValue // directly returns "Slow", "Moderate", or "Fast"
    }
}

enum HeightUnit: String, Codable, CaseIterable, Identifiable {
    case centimeters
    case inches
    
    static let metric = HeightUnit.centimeters
    static let imperial = HeightUnit.inches

    var id: String { rawValue }
    
    /// A readable display label for UI (fixes your current error)
    var display: String {
        switch self {
        case .centimeters: return "cm"
        case .inches: return "in"
        }
    }
}


enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kilograms
    case pounds
    
    static let metric = WeightUnit.kilograms
    static let imperial = WeightUnit.pounds
    
    var id: String { rawValue }
    
    /// Display-friendly text for the UI
    var display: String {
        switch self {
        case .kilograms:
            return "kg"
        case .pounds:
            return "lb"
        }
    }
}



enum Units: String, Codable, CaseIterable, Identifiable {
    case grams = "Grams"
    case kilograms = "Kilograms"
    case pounds = "Pounds"
    case ounces = "Ounces"
    case metric = "Metric"
    case imperial = "Imperial"

    var id: String { rawValue }
}

