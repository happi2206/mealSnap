//
//  ImagePicker.swift
//  MealSnap
//
//  Created by Farhan Khan on 20/10/2025.
//

import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIImagePickerController that supports camera and photo library.
/// It automatically normalizes image orientation and triggers an optional callback when an image is selected.
struct ImagePicker: UIViewControllerRepresentable {
    // MARK: - Properties
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    /// Optional callback for post-selection processing (e.g. ML prediction)
    var onImagePicked: ((UIImage) -> Void)? = nil
    
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Create Picker
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    // MARK: - Update
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No dynamic updates required
    }

    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            defer { parent.presentationMode.wrappedValue.dismiss() }

            guard let image = info[.originalImage] as? UIImage else { return }
            
            // Normalize orientation (important for camera images)
            let fixedImage = image.fixedOrientation()
            parent.selectedImage = fixedImage
            
            // Trigger callback for ML/detection if provided
            parent.onImagePicked?(fixedImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - UIImage Orientation Fix
extension UIImage {
    /// Fixes orientation issues from the camera (e.g. rotated images)
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}

