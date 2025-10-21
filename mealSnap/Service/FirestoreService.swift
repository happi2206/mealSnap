//
//  FirestoreService.swift
//  MealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.

//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

/// Centralized Firestore layer for saving and retrieving user data
final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - Save User Plan
    func saveUserPlan(_ plan: AppPlan, completion: ((Error?) -> Void)? = nil) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "Auth", code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let userData: [String: Any] = [
            "name": plan.name,
            "age": plan.age,
            "sex": plan.sex.rawValue,
            "heightCM": plan.heightCM,
            "weightKG": plan.weightKG,
            "activity": plan.activity.rawValue,
            "goal": plan.goal.rawValue,
            "pace": plan.pace.rawValue,
            "bmi": plan.bmi,
            "bmr": plan.bmr,
            "tdee": plan.tdee,
            "targetCalories": plan.targetCalories,
            "proteinG": plan.proteinG,
            "carbsG": plan.carbsG,
            "fatG": plan.fatG,
            "onboardingComplete": true,
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userID).setData(userData, merge: true) { error in
            if let error = error {
                print("❌ Error saving plan: \(error.localizedDescription)")
            } else {
                print("✅ Plan saved successfully for user: \(userID)")
            }
            completion?(error)
        }
    }
    
    // MARK: - Fetch User Plan
    func fetchUserPlan(completion: @escaping (AppPlan?, Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(nil, false)
            return
        }
        
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error fetching user plan: \(error.localizedDescription)")
                completion(nil, false)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(nil, false)
                return
            }
            
            let onboardingComplete = data["onboardingComplete"] as? Bool ?? false
            
            let plan = AppPlan(
                name: data["name"] as? String ?? "",
                age: data["age"] as? Int ?? 0,
                sex: Sex(rawValue: (data["sex"] as? String ?? "male").lowercased()) ?? .male,
                heightCM: data["heightCM"] as? Double ?? 0,
                weightKG: data["weightKG"] as? Double ?? 0,
                activity: ActivityLevel(rawValue: (data["activity"] as? String ?? "moderate").lowercased()) ?? .moderate,
                goal: Goal(rawValue: (data["goal"] as? String ?? "maintain").lowercased()) ?? .maintain,
                pace: Pace(rawValue: (data["pace"] as? String ?? "moderate").lowercased()) ?? .moderate,
                bmi: data["bmi"] as? Double ?? 0,
                bmr: data["bmr"] as? Double ?? 0,
                tdee: data["tdee"] as? Double ?? 0,
                targetCalories: data["targetCalories"] as? Int ?? 0,
                proteinG: data["proteinG"] as? Int ?? 0,
                carbsG: data["carbsG"] as? Int ?? 0,
                fatG: data["fatG"] as? Int ?? 0
            )
            
            completion(plan, onboardingComplete)
        }
    }
    
    // MARK: - Save Meal Entry
    func saveMealEntry(_ meal: MealEntry, completion: ((Error?) -> Void)? = nil) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "Auth", code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let mealData: [String: Any] = [
            "id": meal.id.uuidString,
            "date": Timestamp(date: meal.date),
            "photoURL": meal.photoURL ?? "",
            "items": meal.items.map { item in
                [
                    "id": item.id.uuidString,
                    "name": item.name,
                    "confidence": item.confidence,
                    "grams": item.grams,
                    "calories": item.calories,
                    "protein": item.protein,
                    "carbs": item.carbs,
                    "fat": item.fat
                ]
            },
            "totalCalories": meal.totalCalories,
            "totalProtein": meal.totalProtein,
            "totalCarbs": meal.totalCarbs,
            "totalFat": meal.totalFat,
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("users")
            .document(userID)
            .collection("meals")
            .document(meal.id.uuidString)
            .setData(mealData, merge: true) { error in
                if let error = error {
                    print("❌ Error saving meal entry: \(error.localizedDescription)")
                } else {
                    print("✅ Meal entry saved successfully for user: \(userID)")
                }
                completion?(error)
            }
    }
    
    // MARK: - 🧠 Save Scanned Image + Detected Food Items
    func uploadScan(image: UIImage, items: [FoodItem], completion: @escaping (Error?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "Auth", code: 401,
                               userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        // Upload image to Firebase Storage
        let imageRef = storage.reference()
            .child("users/\(userID)/scans/\(UUID().uuidString).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(NSError(domain: "Image", code: 500,
                               userInfo: [NSLocalizedDescriptionKey: "Invalid image data"]))
            return
        }
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(error)
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(error)
                    return
                }
                
                guard let photoURL = url?.absoluteString else {
                    completion(NSError(domain: "Storage", code: 404,
                                       userInfo: [NSLocalizedDescriptionKey: "No photo URL found"]))
                    return
                }
                
                // Create a meal entry with detected items
                let meal = MealEntry(
                    date: Date(), photoURL: photoURL, items: items
                )
                
                self.saveMealEntry(meal, completion: completion)
            }
        }
    }
}

