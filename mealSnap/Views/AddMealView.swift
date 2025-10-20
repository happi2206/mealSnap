//
//  AddMealView.swift
//  MealSnap
//
//  Created by Happiness Adeboye on 12/10/2025.
//

import SwiftUI
import UIKit

struct AddMealView: View {
    @EnvironmentObject private var store: MealStore
    @State private var showErrorToast = false
    
    // 🆕 New states for image picking
        @State private var showImagePicker = false
        @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
        @State private var showSourceActionSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                captureControls
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
        .alert("Heads up", isPresented: $showErrorToast, actions: {
            Button("OK", role: .cancel) {
                store.clearError()
            }
        }, message: {
            Text(store.errorMessage ?? "Something went wrong.")
        })
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        // 🆕 Present image picker
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImage: $store.selectedImage, sourceType: imageSource)
                }
                // 🆕 Show source selection action sheet
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
    
    private var captureControls: some View {
        HStack(spacing: 16) {
            captureButton(title: "Camera", systemImage: "camera.fill") {
                store.lightImpact()
//                store.selectedImage = UIImage(systemName: "camera.macro")
                imageSource = .camera
                showImagePicker = true
            }
            captureButton(title: "Photos", systemImage: "photo.on.rectangle") {
                store.lightImpact()
//                store.selectedImage = UIImage(systemName: "photo.stack")
                imageSource = .photoLibrary
                showImagePicker = true
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func captureButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.accentPrimary.opacity(0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(LinearGradient(colors: [.appSurface, .appSurfaceElevated], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Select \(title.lowercased()) source")
    }
    
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
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
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
    
    private func detectedRow(for item: FoodItem) -> some View {
        let gramsBinding = Binding<Double>(
            get: { item.grams },
            set: { newValue in
                let stepped = max(newValue, 1)
                store.updateDetectedItem(item, grams: stepped)
            }
        )
        
        return Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
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
                        .accessibilityHint("Adjust grams for \(item.name)")
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
