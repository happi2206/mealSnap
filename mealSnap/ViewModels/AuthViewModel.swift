//
//  AuthViewModel.swift
//  MealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Handles Firebase Authentication and user session state for MealSnap.
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var user: User?
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        self.user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }
    
    // MARK: - Sign Up
    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        guard !name.isEmpty else {
            errorMessage = "Name is required."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            
            // Update Firebase Auth profile
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Create basic user doc in Firestore for later plan use
            let userData: [String: Any] = [
                "uid": user.uid,
                "email": email,
                "name": name,
                "createdAt": Timestamp(date: Date()),
                "onboardingComplete": false
            ]
            try await db.collection("users").document(user.uid).setData(userData)
            
            self.user = user
            errorMessage = ""
            print("✅ User created successfully with name: \(name)")
        } catch {
            print("❌ Sign-up error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign In
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            errorMessage = ""
            print("✅ Signed in as: \(result.user.email ?? "")")
        } catch {
            print("❌ Sign-in error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            resetFields()
            WidgetBridge.clear()
            print("✅ User signed out successfully.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Reset Fields
    func resetFields() {
        email = ""
        password = ""
        name = ""
        errorMessage = ""
    }
}
