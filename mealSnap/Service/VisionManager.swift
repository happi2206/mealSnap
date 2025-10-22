//
//  VisionManager.swift
//  MealSnap
//
//  Handles both food classification and packaged product detection using CoreML and Vision.
//

import SwiftUI
import Vision
import CoreML

@MainActor
final class VisionManager: ObservableObject {
    private let foodModel: VNCoreMLModel
    private let productModel: VNCoreMLModel

    init() {
        // Use CPU-only configuration to avoid “espresso context” crash
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly

        do {
            let foodClassifier = try food_classifier(configuration: config)
            foodModel = try VNCoreMLModel(for: foodClassifier.model)

            // If you use a different product model, load that instead.
            // For now, same model for demonstration:
            let productClassifier = try food_classifier(configuration: config)
            productModel = try VNCoreMLModel(for: productClassifier.model)
        } catch {
            fatalError("❌ Failed to initialize CoreML models: \(error)")
        }
    }

    func analyze(image: UIImage) async -> [FoodItem] {
        guard let ciImage = CIImage(image: image) else { return [] }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        // 1️⃣ Try detecting packaged products first
        let productReq = VNCoreMLRequest(model: productModel)
        try? handler.perform([productReq])

        if let products = productReq.results as? [VNRecognizedObjectObservation],
           !products.isEmpty {
            return products.map {
                FoodItem(
                    name: $0.labels.first?.identifier ?? "Unknown Product",
                    confidence: Double($0.confidence),
                    grams: 100,
                    calories: 180,
                    protein: 12,
                    carbs: 10,
                    fat: 5
                )
            }
        }

        // 2️⃣ Fall back to food classification
        let foodReq = VNCoreMLRequest(model: foodModel)
        try? handler.perform([foodReq])

        guard let obs = foodReq.results as? [VNClassificationObservation],
              let top = obs.first else { return [] }

        return [FoodItem(
            name: top.identifier.capitalized,
            confidence: Double(top.confidence),
            grams: 150,
            calories: 250,
            protein: 20,
            carbs: 30,
            fat: 8
        )]
    }
}
