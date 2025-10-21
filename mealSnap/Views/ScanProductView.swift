//
//  ScanProductView.swift
//  MealSnap
//
//  Created by Farhan Khan on 21/10/2025.
//

import SwiftUI

struct ScanProductView: View {
    @StateObject private var scanner = BarcodeScanner()
    @State private var product: ProductInfo?
    @State private var errorMessage: String?
    @State private var isUploading = false
    @State private var selectedImage: UIImage?        // ✅ Added this line
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Camera preview background
            CameraPreviewLayer(scanner: scanner)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 30)
                    Spacer()
                }
                Spacer()
                
                // Display results
                if let product = product {
                    VStack(spacing: 8) {
                        Text(product.name)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        Text("Calories: \(Int(product.calories)) kcal")
                            .foregroundColor(.white.opacity(0.9))
                        Text("Protein: \(Int(product.protein))g  •  Carbs: \(Int(product.carbs))g  •  Fat: \(Int(product.fat))g")
                            .foregroundColor(.white.opacity(0.8))
                        
                        if isUploading {
                            ProgressView("Uploading to Firestore...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.top, 10)
                        } else {
                            Button(action: uploadToFirestore) {
                                Text("Add to My Meals")
                                    .fontWeight(.bold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green.opacity(0.85))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 12)
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.bottom, 40)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.bottom, 40)
                } else {
                    VStack {
                        ProgressView("Scanning for barcodes...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                        Text("Point the camera at a product barcode")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.subheadline)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            scanner.onProductScanned = { item in
                product = item
                // Use a placeholder until real photo capture is added
                selectedImage = UIImage(systemName: "photo")
            }

            scanner.onError = { err in
                errorMessage = err.localizedDescription
            }
        }
    }
    
    // MARK: - Upload scanned item to Firestore
    private func uploadToFirestore() {
        guard let product = product else { return }
        isUploading = true
        
        let foodItem = FoodItem(
            name: product.name,
            confidence: 1.0,
            grams: product.grams,
            calories: product.calories,
            protein: product.protein,
            carbs: product.carbs,
            fat: product.fat
        )
        
        Task {
            // ✅ Use selected image or a placeholder
            let uploadImage = selectedImage ?? UIImage(systemName: "photo")!
            
            FirestoreService.shared.uploadScan(image: uploadImage, items: [foodItem]) { error in
                isUploading = false
                if let error = error {
                    errorMessage = "Failed to upload: \(error.localizedDescription)"
                } else {
                    dismiss()
                }
            }
        }

    }
}

// MARK: - Camera Preview Layer Wrapper
struct CameraPreviewLayer: UIViewRepresentable {
    let scanner: BarcodeScanner
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        DispatchQueue.main.async {
            scanner.startScanning(in: view)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

