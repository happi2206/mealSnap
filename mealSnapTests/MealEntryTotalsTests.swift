//
//  MealEntryTotalsTests.swift
//  mealSnapTests
//
//  Created by Happiness Adeboye on 24/10/2025.
//

import XCTest
@testable import mealSnap

final class MealEntryTotalsTests: XCTestCase {
    func testMealTotalsAccumulateMacros() {
        let items = [
            FoodItem(name: "Avocado Toast", grams: 120, calories: 260, protein: 8, carbs: 32, fat: 12),
            FoodItem(name: "Eggs", grams: 60, calories: 90, protein: 6, carbs: 1, fat: 7)
        ]
        let meal = MealEntry(items: items)
        XCTAssertEqual(meal.totalCalories, 350)
        XCTAssertEqual(meal.totalProtein, 14)
        XCTAssertEqual(meal.totalCarbs, 33)
        XCTAssertEqual(meal.totalFat, 19)
    }
}
