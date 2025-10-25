//
//  WidgetPayloadTests.swift
//  mealSnapTests
//
//  Created by Happiness Adeboye on 24/10/2025.
//

import XCTest
@testable import mealSnap

final class WidgetPayloadTests: XCTestCase {
    func testEncodingAndDecodingRoundTrip() throws {
        let payload = WidgetPayload(
            consumedCalories: 1234,
            targetCalories: 2200,
            macro: WidgetMacroSnapshot(
                consumedProtein: 90,
                consumedCarbs: 150,
                consumedFat: 45,
                goalProtein: 150,
                goalCarbs: 220,
                goalFat: 70
            ),
            lastMeal: WidgetMealSnapshot(title: "Salmon & Rice", calories: 620),
            timestamp: Date()
        )
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(WidgetPayload.self, from: data)
        XCTAssertEqual(decoded.consumedCalories, 1234)
        XCTAssertEqual(decoded.macro.goalProtein, 150)
        XCTAssertEqual(decoded.lastMeal?.title, "Salmon & Rice")
    }
}
