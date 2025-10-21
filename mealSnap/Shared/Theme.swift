//
//  Theme.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI

extension Color {
    // MARK: - App Base Colors
    static let appBackground = Color(red: 11 / 255, green: 12 / 255, blue: 16 / 255)
    static let appSurface = Color(red: 22 / 255, green: 24 / 255, blue: 31 / 255)
    static let appSurfaceElevated = Color(red: 30 / 255, green: 32 / 255, blue: 41 / 255)
    
    // MARK: - Accent Colors
    static let accentPrimary = Color(red: 152 / 255, green: 116 / 255, blue: 255 / 255)
    static let accentSecondary = Color(red: 197 / 255, green: 131 / 255, blue: 255 / 255)
    static let accentTertiary = Color(red: 105 / 255, green: 87 / 255, blue: 255 / 255)
    static let accentQuaternary = Color(red: 233 / 255, green: 105 / 255, blue: 255 / 255)
    
    // MARK: - Semantic Colors
    static let success = Color(red: 76 / 255, green: 217 / 255, blue: 100 / 255)    // ✅ For correct detections
    static let warning = Color(red: 255 / 255, green: 204 / 255, blue: 0 / 255)    // ⚠️ For unclear images
    static let error = Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255)      // ❌ For failed detections
    static let info = Color(red: 90 / 255, green: 200 / 255, blue: 250 / 255)      // ℹ️ For general messages
    
    // MARK: - Gradient Presets (for reuse in detection overlays or buttons)
    static let accentGradient = LinearGradient(
        colors: [.accentPrimary, .accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let detectionGradient = LinearGradient(
        colors: [.accentTertiary, .accentQuaternary],
        startPoint: .top,
        endPoint: .bottom
    )
}
