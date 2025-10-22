//
//  FoodClassificationManager.swift
//  mealSnap
//
//  Created by Maher Parkar on 21/10/2025.
//


//
//  FoodClassificationManager.swift
//  MealSnap
//
//  Handles dedicated food classification using Core ML’s Food101 model.
//

import Foundation
import Vision
import CoreML
import UIKit

final class FoodClassificationManager {
    private let model: VNCoreMLModel

    init() {
        do {
            // ✅ Use CPU-only to avoid espresso context errors
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly

            let foodModel = try food_classifier(configuration: config)
            self.model = try VNCoreMLModel(for: foodModel.model)

            print("✅ Food model loaded successfully (CPU mode).")
        } catch {
            fatalError("❌ Failed to load Food101.mlmodel: \(error.localizedDescription)")
        }
    }


    func classify(image: UIImage, completion: @escaping (FoodItem?) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion(nil)
            return
        }

        let request = VNCoreMLRequest(model: model) { request, _ in
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first else {
                completion(nil)
                return
            }

            let foodItem = FoodItem(
                name: top.identifier.capitalized,
                confidence: Double(top.confidence),
                grams: 150,
                calories: 250,
                protein: 20,
                carbs: 30,
                fat: 8
            )

            completion(foodItem)
        }

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try? handler.perform([request])
    }
}
