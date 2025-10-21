//
//  PlanStorage.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 11/10/2025.
//

import Foundation

struct PlanStorage {
    private static let key = "com.mealsnap.plan"
    
    static func load() -> AppPlan? {
        guard let data = UserDefaults(suiteName: "group.com.advancediOS.mealsnap")?.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(AppPlan.self, from: data)
    }
    
    static func save(_ plan: AppPlan) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(plan) else { return }
        UserDefaults(suiteName: "group.com.advancediOS.mealsnap")?.set(data, forKey: key)
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func loadTotalCalories() -> Int {
        return UserDefaults(suiteName: "group.com.advancediOS.mealsnap")?
            .integer(forKey: "totalCalories") ?? 0
    }
}
