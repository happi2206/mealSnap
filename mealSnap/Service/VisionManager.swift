//
//  VisionManager.swift
//  mealSnap
//
//  Created by Maher Parkar on 21/10/2025.
//


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
    private let foodModel = try! VNCoreMLModel(for: FoodClassifier().model)
    private let productModel = try! VNCoreMLModel(for: FoodClassifier().model)

    func analyze(image: UIImage) async -> [FoodItem] {
        guard let ciImage = CIImage(image: image) else { return [] }

        // Create a handler for the Vision requests
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

        // 2️⃣ Fall back to food classification if no products are found
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
