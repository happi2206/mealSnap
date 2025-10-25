//
//  OnboardingViewModelTests.swift
//  mealSnapTests
//
//  Created by Happiness Adeboye on 24/10/2025.
//

import XCTest
@testable import mealSnap

final class OnboardingViewModelTests: XCTestCase {
    
    @MainActor
    func testValidationFailsWhenFieldsMissing() {
        let viewModel = OnboardingViewModel()
        XCTAssertFalse(viewModel.isStepValid(.profile))
        XCTAssertEqual(viewModel.nameError, "Enter your name.")
        XCTAssertEqual(viewModel.ageError, "Age is required.")
        XCTAssertEqual(viewModel.heightError, "Add your height.")
        XCTAssertEqual(viewModel.weightError, "Add your weight.")
    }
    
    @MainActor
    func testPlanBuildsWithValidInputs() {
        var viewModel = OnboardingViewModel()
        viewModel.name = "Taylor"
        viewModel.age = "29"
        viewModel.sex = .female
        viewModel.heightUnit = .metric
        viewModel.heightCM = "168"
        viewModel.weightUnit = .metric
        viewModel.weightKG = "64"
        viewModel.activity = .moderate
        viewModel.goal = .maintain
        viewModel.pace = .moderate
        
        XCTAssertTrue(viewModel.isStepValid(.profile))
        let plan = viewModel.buildPlan()
        XCTAssertEqual(plan?.name, "Taylor")
        XCTAssertEqual(plan?.age, 29)
        XCTAssertNotNil(plan?.targetCalories)
        XCTAssertNotNil(plan?.proteinG)
    }
    
    @MainActor
    func testImperialConversionProducesPlan() {
        var viewModel = OnboardingViewModel()
        viewModel.name = "Alex"
        viewModel.age = "31"
        viewModel.heightUnit = .imperial
        viewModel.heightFeet = "5"
        viewModel.heightInches = "9"
        viewModel.weightUnit = .imperial
        viewModel.weightLBS = "170"
        viewModel.activity = .light
        viewModel.goal = .loseWeight
        viewModel.pace = .slow
        
        XCTAssertTrue(viewModel.isStepValid(.profile))
        XCTAssertEqual((viewModel.heightValueCM ?? 0).rounded(), 175)
        XCTAssertEqual(viewModel.weightValueKG ?? 0, 77.11, accuracy: 0.05)
        let plan = viewModel.buildPlan()
        XCTAssertEqual(plan?.goal, .loseWeight)
        XCTAssertEqual(plan?.pace, .slow)
    }
}
