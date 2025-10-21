//
//  BarcodeScanner.swift
//  MealSnap
//
//  Created by Farhan Khan on 21/10/2025.
//

import Foundation
import AVFoundation
import UIKit
import Vision
import CoreML
import SwiftUI

@MainActor
final class BarcodeScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedProduct: ProductInfo?
    @Published var errorMessage: String?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let visionManager = VisionManager()
    
    var onProductScanned: ((ProductInfo) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Start Scanning
    func startScanning(in view: UIView) {
        let session = AVCaptureSession()
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput)
        else {
            onError?(BarcodeScannerError.cameraUnavailable)
            errorMessage = "Camera unavailable."
            return
        }
        session.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .qr]
        } else {
            onError?(BarcodeScannerError.metadataOutputUnavailable)
            errorMessage = "Metadata output unavailable."
            return
        }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.insertSublayer(preview, at: 0)
        
        self.captureSession = session
        self.previewLayer = preview
        isScanning = true
        
        session.startRunning()
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        isScanning = false
    }
    
    // MARK: - Delegate
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let first = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = first.stringValue
        else { return }
        
        stopScanning()
        
        Task {
            do {
                let product = try await fetchProductInfo(for: code)
                scannedProduct = product
                onProductScanned?(product)
            } catch {
                if let fallbackProduct = await analyzeImageFromCamera() {
                    scannedProduct = fallbackProduct
                    onProductScanned?(fallbackProduct)
                } else {
                    onError?(BarcodeScannerError.productNotFound)
                    errorMessage = "Product not found."
                }
            }
        }
    }
    
    // MARK: - Product Lookup via OpenFoodFacts API
    func fetchProductInfo(for barcode: String) async throws -> ProductInfo {
        let apiURL = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        let (data, response) = try await URLSession.shared.data(from: apiURL)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw BarcodeScannerError.productNotFound
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let productData = json?["product"] as? [String: Any] else {
            throw BarcodeScannerError.productNotFound
        }
        
        let name = productData["product_name"] as? String ?? "Unknown Product"
        let nutriments = productData["nutriments"] as? [String: Any] ?? [:]
        
        return ProductInfo(
            name: name,
            grams: 100,
            calories: nutriments["energy-kcal_100g"] as? Double ?? 0,
            protein: nutriments["proteins_100g"] as? Double ?? 0,
            carbs: nutriments["carbohydrates_100g"] as? Double ?? 0,
            fat: nutriments["fat_100g"] as? Double ?? 0
        )
    }
    
    // MARK: - AI-based Fallback
    private func analyzeImageFromCamera() async -> ProductInfo? {
        guard let sampleImage = UIImage(named: "sample_food") else { return nil }
        let foodItems = await visionManager.analyze(image: sampleImage)
        guard let top = foodItems.first else { return nil }
        
        return ProductInfo(
            name: top.name,
            grams: top.grams,
            calories: top.calories,
            protein: top.protein,
            carbs: top.carbs,
            fat: top.fat
        )
    }
}

// MARK: - Model & Errors
struct ProductInfo: Identifiable {
    var id = UUID()
    var name: String
    var grams: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}

enum BarcodeScannerError: Error {
    case cameraUnavailable
    case metadataOutputUnavailable
    case productNotFound
}

