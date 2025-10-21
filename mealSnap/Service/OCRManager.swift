//
//  OCRManager.swift
//  mealSnap
//
//  Created by Maher Parkar on 21/10/2025.
//


//
//  OCRManager.swift
//  MealSnap
//
//  Uses Vision framework for text recognition on product labels or packaging.
//

import Foundation
import Vision
import UIKit

final class OCRManager {
    func extractText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }

            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
            completion(recognizedText)
        }

        // Configure recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
}
