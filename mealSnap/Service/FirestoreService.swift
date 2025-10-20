//
//  FirestoreService.swift
//  mealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    private let db = Firestore.firestore()
    
    func createUserDocument(user: User, completion: @escaping (Error?) -> Void) {
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "onboardingCompleted": false
        ]
        
        db.collection("users").document(user.uid).setData(userData) { error in
            completion(error)
        }
    }
    
    func markOnboardingComplete(for userId: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).updateData(["onboardingCompleted": true]) { error in
            completion(error)
        }
    }
    
    func fetchOnboardingStatus(for userId: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let completed = data["onboardingCompleted"] as? Bool {
                completion(completed)
            } else {
                completion(false)
            }
        }
    }
}
