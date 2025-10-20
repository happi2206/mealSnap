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
}
