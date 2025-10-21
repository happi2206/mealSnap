//
//  OnboardingViewModel.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 11/10/2025.
//

import Foundation
import UIKit

enum OnboardingStep: Int, CaseIterable, Hashable, Identifiable {
    case welcome
    case profile
    case activity
    case goal
    case pace
    case review
    case permissions
    case done
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profile: return "Profile"
        case .activity: return "Activity Level"
        case .goal: return "Your Goal"
        case .pace: return "Preferred Pace"
        case .review: return "Review Plan"
        case .permissions: return "Stay Synced"
        case .done: return "Ready to Snap"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var sex: Sex = .female
    @Published var heightUnit: HeightUnit = .metric
    @Published var heightCM: String = ""
    @Published var heightFeet: String = ""
    @Published var heightInches: String = ""
    @Published var weightUnit: WeightUnit = .metric
    @Published var weightKG: String = ""
    @Published var weightLBS: String = ""
    @Published var activity: ActivityLevel = .moderate
    @Published var goal: Goal = .maintain
    @Published var pace: Pace = .moderate
    
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var resultingPlan: AppPlan?
    
    private let minimumAge = 13
    private let maximumAge = 90
    
    init(plan: AppPlan? = nil) {
        if let plan {
            apply(plan: plan)
        }
    }
    
    func apply(plan: AppPlan) {
        name = plan.name
        age = "\(plan.age)"
        sex = plan.sex
        activity = plan.activity
        goal = plan.goal
        pace = plan.pace
        heightUnit = .metric
        weightUnit = .metric
        heightCM = String(format: "%.0f", plan.heightCM)
        weightKG = String(format: "%.1f", plan.weightKG)
        let imperialHeight = Calculator.centimetersToFeetInches(plan.heightCM)
        heightFeet = "\(imperialHeight.feet)"
        heightInches = "\(imperialHeight.inches)"
        weightLBS = String(format: "%.1f", Calculator.kilogramsToPounds(plan.weightKG))
    }
    
    // MARK: - Derived values
    
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var ageValue: Int? {
        guard let value = Int(age.trimmingCharacters(in: .whitespacesAndNewlines)),
              value >= minimumAge, value <= maximumAge else {
            return nil
        }
        return value
    }
    
    var heightValueCM: Double? {
        let cm = Double(heightCM.replacingOccurrences(of: ",", with: ".")) ?? -1
        let feet = Double(heightFeet) ?? 0
        let inches = Double(heightInches) ?? 0
        let total = Calculator.heightInCentimeters(heightCM: cm, feet: feet, inches: inches, unit: heightUnit)
        return total > 0 ? total : nil
    }
    
    var weightValueKG: Double? {
        let kg = Double(weightKG.replacingOccurrences(of: ",", with: ".")) ?? -1
        let lbs = Double(weightLBS.replacingOccurrences(of: ",", with: ".")) ?? 0
        let total = Calculator.weightInKilograms(weightKG: kg, weightLBS: lbs, unit: weightUnit)
        return total > 0 ? total : nil
    }
    
    var bmi: Double {
        guard let weight = weightValueKG, let height = heightValueCM else { return 0 }
        return Calculator.bmi(weightKG: weight, heightCM: height)
    }
    
    var bmiCategory: String {
        Calculator.bmiCategory(bmi)
    }
    
    var bmr: Double {
        guard let weight = weightValueKG, let height = heightValueCM, let age = ageValue else { return 0 }
        return Calculator.bmr(weightKG: weight, heightCM: height, age: age, sex: sex)
    }
    
    var tdee: Double {
        Calculator.tdee(bmr: bmr, activity: activity)
    }
    
    var targetCalories: Double {
        Calculator.adjustedCalories(tdee: tdee, goal: goal, pace: pace)
    }
    
    var macroTargets: (protein: Int, carbs: Int, fat: Int) {
        Calculator.macroSplit(calories: targetCalories)
    }
    
    // MARK: - Validation
    
    var nameError: String? {
        trimmedName.isEmpty ? "Enter your name." : nil
    }
    
    var ageError: String? {
        guard !age.isEmpty else { return "Age is required." }
        return ageValue == nil ? "Enter an age \(minimumAge)-\(maximumAge)." : nil
    }
    
    var heightError: String? {
        guard let height = heightValueCM, height > 120 else {
            return "Add your height."
        }
        return height > 250 ? "Height looks too high." : nil
    }
    
    var weightError: String? {
        guard let weight = weightValueKG, weight > 30 else {
            return "Add your weight."
        }
        return weight > 300 ? "Weight looks too high." : nil
    }
    
    func isStepValid(_ step: OnboardingStep) -> Bool {
        switch step {
        case .welcome:
            return true
        case .profile:
            return nameError == nil && ageError == nil && heightError == nil && weightError == nil
        case .activity, .goal, .pace, .review, .permissions, .done:
            return true
        }
    }
    
    func buildPlan() -> AppPlan? {
        guard let height = heightValueCM,
              let weight = weightValueKG,
              let age = ageValue,
              nameError == nil else { return nil }
        
        let bmiValue = bmi
        let bmrValue = bmr
        let tdeeValue = tdee
        let target = Int(targetCalories.rounded())
        let macros = macroTargets
        
        return AppPlan(
            name: trimmedName,
            age: age,
            sex: sex,
            heightCM: height,
            weightKG: weight,
            activity: activity,
            goal: goal,
            pace: pace,
            bmi: bmiValue,
            bmr: bmrValue,
            tdee: tdeeValue,
            targetCalories: target,
            proteinG: macros.protein,
            carbsG: macros.carbs,
            fatG: macros.fat
        )
    }
    
    func complete() {
        guard let plan = buildPlan() else { return }
        resultingPlan = plan
        isComplete = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

extension OnboardingStep {
    var position: Int {
        guard let index = OnboardingStep.allCases.firstIndex(of: self) else { return 1 }
        return index + 1
    }
    
    static var totalSteps: Int {
        OnboardingStep.allCases.count
    }
    
    var next: OnboardingStep? {
        guard let index = OnboardingStep.allCases.firstIndex(of: self),
              index + 1 < OnboardingStep.allCases.count else { return nil }
        return OnboardingStep.allCases[index + 1]
    }
}
