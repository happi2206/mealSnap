//
//  ImagePicker.swift
//  MealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.
//

import SwiftUI
import UIKit
import PhotosUI

/// ImagePicker supports selecting or capturing an image for further processing,
/// such as ML object detection or calorie estimation.
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    /// Optional callback triggered after an image is picked
    var onImagePicked: ((UIImage) -> Void)? = nil
    
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Make UIViewController
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    // MARK: - Update UIViewController
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

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
            
            // ✅ Normalize image orientation
            let fixedImage = image.fixedOrientation()
            parent.selectedImage = fixedImage
            
            // ✅ Trigger callback for ML processing if provided
            parent.onImagePicked?(fixedImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - UIImage Orientation Fix Extension
extension UIImage {
    /// Returns a new image with orientation normalized (prevents rotated display in SwiftUI)
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}

