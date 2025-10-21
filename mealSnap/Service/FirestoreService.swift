//
//  FirestoreService.swift
//  mealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    // MARK: - Save Plan
    func saveUserPlan(_ plan: AppPlan, completion: ((Error?) -> Void)? = nil) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
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
    
    // MARK: - Fetch Plan
    func fetchUserPlan(completion: @escaping (AppPlan?, Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(nil, false)
            return
        }
        
        db.collection("users").document(userID).getDocument(completion: { snapshot, error in
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
                sex:Sex(rawValue: data["sex"] as? String ?? "Male") ?? .male,
                heightCM: data["heightCM"] as? Double ?? 0,
                weightKG: data["weightKG"] as? Double ?? 0,
                activity: ActivityLevel(rawValue: data["activity"] as? String ?? "Moderate") ?? .moderate,
                goal: Goal(rawValue: data["goal"] as? String ?? "Maintain") ?? .maintain,
                pace: Pace(rawValue: data["pace"] as? String ?? "Moderate") ?? .moderate,
                bmi: data["bmi"] as? Double ?? 0,
                bmr: data["bmr"] as? Double ?? 0,
                tdee: data["tdee"] as? Double ?? 0,
                targetCalories: data["targetCalories"] as? Int ?? 0,
                proteinG: data["proteinG"] as? Int ?? 0,
                carbsG: data["carbsG"] as? Int ?? 0,
                fatG: data["fatG"] as? Int ?? 0
            )
            
            completion(plan, onboardingComplete)
        })
    }
    
    // Save a meal for the current user
    func saveMeal(for userId: String, meal: MealEntry, completion: @escaping (Error?) -> Void) {
        let mealData: [String: Any] = [
            "date": Timestamp(date: meal.date),
            "totalCalories": meal.totalCalories,
            "totalProtein": meal.totalProtein,
            "totalCarbs": meal.totalCarbs,
            "totalFat": meal.totalFat,
            "items": meal.items.map { [
                "name": $0.name,
                "confidence": $0.confidence,
                "grams": $0.grams,
                "calories": $0.calories,
                "protein": $0.protein,
                "carbs": $0.carbs,
                "fat": $0.fat
            ]}
        ]
        
        db.collection("users")
            .document(userId)
            .collection("meals")
            .document(meal.id.uuidString)
                        .setData(mealData, completion: completion)
    }
    
    // Fetch all meals for the current user
    func fetchMeals(for userId: String, completion: @escaping ([MealEntry]) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("meals")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, error == nil else {
                    print("Error fetching meals: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let meals: [MealEntry] = documents.compactMap { doc in
                    let data = doc.data()
                    guard let date = (data["date"] as? Timestamp)?.dateValue(),
                          let itemsData = data["items"] as? [[String: Any]] else {
                        return nil
                    }
                    
                    let items: [FoodItem] = itemsData.compactMap { item in
                        guard let name = item["name"] as? String,
                              let confidence = item["confidence"] as? Double,
                              let grams = item["grams"] as? Double,
                              let calories = item["calories"] as? Double,
                              let protein = item["protein"] as? Double,
                              let carbs = item["carbs"] as? Double,
                              let fat = item["fat"] as? Double else {
                            return nil
                        }
                        return FoodItem(name: name, confidence: confidence, grams: grams, calories: calories, protein: protein, carbs: carbs, fat: fat)
                    }
                    var entry = MealEntry(date: date, photo: nil, items: items)
                                       entry.id = UUID(uuidString: doc.documentID) ?? UUID()
                                       return entry
                }
                
                completion(meals)
            }
        
//        let sampleItems = [
//            FoodItem(name: "Banana", confidence: 0.9, grams: 120, calories: 105, protein: 1.3, carbs: 27, fat: 0.3),
//            FoodItem(name: "Peanut Butter", confidence: 0.8, grams: 30, calories: 188, protein: 8, carbs: 6, fat: 16)
//        ]
//
//        let meal = MealEntry(date: Date(), photo: nil, items: sampleItems)
//        let firestoreManager = FirestoreManager()
//
//        firestoreManager.saveMeal(for: "demoUserID123", meal: meal) { error in
//            if let error = error {
//                print("Error saving meal: \(error.localizedDescription)")
//            } else {
//                print("Meal saved successfully!")
//            }
//        }
        
        // MARK: - Delete Meal
        func deleteMeal(for userId: String, mealId: UUID, completion: @escaping (Error?) -> Void) {
            db.collection("users")
                .document(userId)
                .collection("meals")
                .document(mealId.uuidString)
                .delete(completion: completion)
        }
    }
}
