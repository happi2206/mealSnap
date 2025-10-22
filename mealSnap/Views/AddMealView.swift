//
//  AddMealView.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI
import UIKit

struct AddMealView: View {
    // Your MealStore environment object
    @EnvironmentObject var store: MealStore
    
    @State private var showErrorToast = false
    @State private var showImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceActionSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                captureControls
                scanBarcodeSection
                imagePreview
                detectedItemsSection
                
                PrimaryButton(title: "Save to Diary", systemImage: "tray.and.arrow.down.fill") {
                    store.saveDetectedItemsToDiary()
                    if store.errorMessage != nil {
                        showErrorToast = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .scrollContentBackground(.hidden)
        .navigationTitle("Add Meal")
        .scrollDismissesKeyboard(.immediately)
        .alert("Heads up", isPresented: $showErrorToast) {
            Button("OK", role: .cancel) {
                store.clearError()
            }
        } message: {
            Text(store.errorMessage ?? "Something went wrong.")
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        
        // ✅ Working Sheet
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                selectedImage: Binding(
                    get: { store.selectedImage },
                    set: { newImage in
                        store.selectedImage = newImage
                        if let image = newImage {
                            // Run ML prediction after picking the image
                            DispatchQueue.main.async {
                                store.detectFoodItems(from: image)
                            }
                        }
                    }
                ),
                sourceType: imageSource
            )
        }
        .confirmationDialog("Select Image Source", isPresented: $showSourceActionSheet) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    imageSource = .camera
                    showImagePicker = true
                }
            }
            Button("Photo Library") {
                imageSource = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Capture Controls
    private var captureControls: some View {
        HStack(spacing: 16) {
            captureButton(title: "Camera", systemImage: "camera.fill") {
                store.lightImpact()
                imageSource = .camera
                showImagePicker = true
            }
            captureButton(title: "Photos", systemImage: "photo.on.rectangle") {
                store.lightImpact()
                imageSource = .photoLibrary
                showImagePicker = true
            }
        }
    }

    // MARK: - Barcode Section
    private var scanBarcodeSection: some View {
        NavigationLink(destination: ScanProductView()) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                    .font(.title2)
                    .foregroundColor(.white)
                Text("Scan Product Barcode")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
        }
        .padding(.top, 10)
    }

    // MARK: - Capture Button
    private func captureButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.accentPrimary.opacity(0.5), in: RoundedRectangle(cornerRadius: 18))
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.appSurface, .appSurfaceElevated],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22)
            )
            .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Image Preview
    private var imagePreview: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Preview")
                    .font(.headline)
                Group {
                    if let image = store.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.appSurface.opacity(0.6))
                            .frame(height: 220)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    Text("No image yet")
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }
                }
                if store.selectedImage != nil {
                    Text("Detected items update as you adjust grams.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Detected Items Section
    private var detectedItemsSection: some View {
        Group {
            if store.detectedItems.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "rectangle.and.text.magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(Color.accentPrimary)
                        Text("Nothing detected yet")
                            .font(.headline)
                        Text("Snap a meal or choose a photo to see detected items.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Detected items")
                        .font(.title2.weight(.semibold))
                    ForEach(store.detectedItems) { item in
                        detectedRow(for: item)
                    }
                }
            }
        }
    }

    // MARK: - Detected Row
    private func detectedRow(for item: FoodItem) -> some View {
        let gramsBinding = Binding<Double>(
            get: { item.grams },
            set: { newValue in
                store.updateDetectedItem(item, grams: max(newValue, 1))
            }
        )

        return Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                    Spacer()
                    ConfidenceTag(confidence: item.confidence)
                }

                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Grams")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Stepper(value: gramsBinding, in: 1...800, step: 5) {
                            Text("\(Int(item.grams)) g")
                                .font(.body.weight(.medium))
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("\(Int(item.calories)) kcal")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                        Text("\(Int(item.protein))P \(Int(item.carbs))C \(Int(item.fat))F")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddMealView()
            .environmentObject(MealStore())
            .preferredColorScheme(.dark)
    }
}

