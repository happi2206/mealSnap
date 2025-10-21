//
//  PlanStorage.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 11/10/2025.
//

import Foundation

/// Local lightweight cache for storing and retrieving the user's AppPlan
/// This acts as a backup when offline or before Firestore sync.
struct PlanStorage {
    
    private static let key = "com.mealsnap.plan"
    private static let queue = DispatchQueue(label: "PlanStorageQueue", qos: .background)
    
    /// Loads the locally cached AppPlan from UserDefaults
    static func load() -> AppPlan? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            let decoder = JSONDecoder()
            let plan = try decoder.decode(AppPlan.self, from: data)
            return plan
        } catch {
            print("❌ Failed to decode AppPlan: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Saves the AppPlan locally for quick access and offline persistence
    static func save(_ plan: AppPlan) {
        queue.async {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(plan)
                UserDefaults.standard.set(data, forKey: key)
                UserDefaults.standard.synchronize()
                print("✅ AppPlan saved locally.")
            } catch {
                print("❌ Failed to encode AppPlan: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clears the locally saved plan data (used on logout or reset)
    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        print("🧹 Cleared stored AppPlan.")
    }
}
