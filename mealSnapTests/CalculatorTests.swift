//
//  CalculatorTests.swift
//  mealSnapTests
//
//  Created by Happiness Adeboye on 24/10/2025.
//

import XCTest
@testable import mealSnap

final class CalculatorTests: XCTestCase {
    
    func testBMIComputation() {
        let bmi = Calculator.bmi(weightKG: 72, heightCM: 178)
        XCTAssertEqual(bmi, 22.72, accuracy: 0.01)
        XCTAssertEqual(Calculator.bmiCategory(bmi), "Normal")
    }
    
    func testBMRMifflinFormulaMale() {
        let bmr = Calculator.bmr(weightKG: 82, heightCM: 188, age: 32, sex: .male)
        XCTAssertEqual(bmr, 1860, accuracy: 1.0)
    }
    
    func testAdjustedCaloriesForGoals() {
        let tdee = 2500.0
        XCTAssertEqual(Calculator.adjustedCalories(tdee: tdee, goal: .loseWeight, pace: .moderate), 2075)
        XCTAssertEqual(Calculator.adjustedCalories(tdee: tdee, goal: .maintain, pace: .fast), tdee)
        XCTAssertEqual(Calculator.adjustedCalories(tdee: tdee, goal: .gainMuscle, pace: .slow), 2750)
    }
    
    func testMacroSplit() {
        let macros = Calculator.macroSplit(calories: 2200)
        XCTAssertEqual(macros.protein, 165)
        XCTAssertEqual(macros.carbs, 220)
        XCTAssertEqual(macros.fat, 73)
    }
}
