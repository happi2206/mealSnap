//
//  CameraView.swift
//  mealSnap
//
//  Created by Maher Parkar on 21/10/2025.
//


//
//  CameraView.swift
//  MealSnap
//
//  Created by Farhan Khan on 21/10/2025.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    VStack {
                        Image(systemName: "camera.viewfinder")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.accentColor)
                        Text("Tap below to capture or select an image")
                            .foregroundColor(.secondary)
                    }
                }

                if viewModel.isProcessing {
                    ProgressView("Analyzing and uploading...")
                        .padding()
                } else if viewModel.uploadSuccess {
                    Label("Upload Complete!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.headline)
                } else if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }

                Button {
                    showPicker = true
                } label: {
                    Label("Select or Capture Image", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .navigationTitle("MealSnap Scanner")
            .sheet(isPresented: $showPicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage, sourceType: .camera) { image in
                    viewModel.handlePickedImage(image)
                }
            }
        }
    }
}
