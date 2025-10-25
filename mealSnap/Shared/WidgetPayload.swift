//
//  WidgetPayload.swift
//  MealSnap
//

import Foundation

struct WidgetMacroSnapshot: Codable {
    var consumedProtein: Double
    var consumedCarbs: Double
    var consumedFat: Double
    var goalProtein: Double?
    var goalCarbs: Double?
    var goalFat: Double?
}

struct WidgetMealSnapshot: Codable {
    var title: String
    var calories: Double
}

struct WidgetPayload: Codable {
    var consumedCalories: Double
    var targetCalories: Double
    var macro: WidgetMacroSnapshot
    var lastMeal: WidgetMealSnapshot?
    var timestamp: Date
}
