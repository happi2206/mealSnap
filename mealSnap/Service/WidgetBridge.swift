//
//  WidgetBridge.swift
//  MealSnap


import Foundation
import WidgetKit

enum WidgetBridge {
    static let suiteName = "group.com.advancediOS.mealsnap"
    static let widgetKind = "MealSnapWidget"
    private static let payloadKey = "WidgetPayload"
    
    static func update(with payload: WidgetPayload) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: payloadKey)
            defaults.set(Int(payload.consumedCalories.rounded()), forKey: "totalCalories")
            defaults.synchronize()
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        } catch {
            print("❌ Failed to encode widget payload: \(error.localizedDescription)")
        }
    }
    
    static func clear() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.removeObject(forKey: payloadKey)
        defaults.removeObject(forKey: "totalCalories")
        defaults.synchronize()
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
    
    static func currentPayload() -> WidgetPayload? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: payloadKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetPayload.self, from: data)
    }
}
