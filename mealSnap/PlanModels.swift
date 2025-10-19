//
//  PlanModels.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 11/10/2025.
//

import Foundation

struct AppPlan: Codable, Equatable {
    var name: String
    var age: Int
    var sex: Sex
    var heightCM: Double
    var weightKG: Double
    var activity: ActivityLevel
    var goal: Goal
    var pace: Pace
    var bmi: Double
    var bmr: Double
    var tdee: Double
    var targetCalories: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
}

enum Sex: String, CaseIterable, Codable, Identifiable {
    case male
    case female
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable, Identifiable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Desk job, little exercise"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        case .veryActive: return "Physical job or intense training"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

enum Goal: String, CaseIterable, Codable, Identifiable {
    case loseWeight
    case maintain
    case gainMuscle
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .loseWeight: return "Lose Weight"
        case .maintain: return "Maintain"
        case .gainMuscle: return "Gain Muscle"
        }
    }
}

enum Pace: String, CaseIterable, Codable, Identifiable {
    case slow
    case moderate
    case fast
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .moderate: return "Moderate"
        case .fast: return "Fast"
        }
    }
    
    var description: String {
        switch self {
        case .slow: return "Balanced adjustments"
        case .moderate: return "Noticeable weekly change"
        case .fast: return "Aggressive approach"
        }
    }
}
