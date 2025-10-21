//
//  CameraViewModel.swift
//  mealSnap
//
//  Created by Maher Parkar on 21/10/2025.
//


//
//  CameraViewModel.swift
//  MealSnap
//
//  Created by Farhan Khan on 21/10/2025.
//

import SwiftUI
import Combine
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var detectedItems: [FoodItem] = []
    @Published var isProcessing = false
    @Published var uploadSuccess = false
    @Published var errorMessage: String?

    private let visionManager = VisionManager()

    /// Called when a user selects or captures an image
    func handlePickedImage(_ image: UIImage) {
        Task {
            await analyzeAndUpload(image)
        }
    }

    private func analyzeAndUpload(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        uploadSuccess = false
        detectedItems.removeAll()
        
        // 🔍 Step 1: Run model inference
        let results = await visionManager.analyze(image: image)
        detectedItems = results
        
        guard !results.isEmpty else {
            errorMessage = "No food items detected."
            isProcessing = false
            return
        }
        
        // ☁️ Step 2: Upload scan to Firestore
        FirestoreService.shared.uploadScan(image: image, items: results) { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("❌ Upload failed: \(error.localizedDescription)")
                } else {
                    self?.uploadSuccess = true
                    print("✅ Scan uploaded successfully!")
                }
                self?.isProcessing = false
            }
        }
    }
}
