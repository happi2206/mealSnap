//
//  AuthViewModel.swift
//  mealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.
//

import Foundation
import FirebaseAuth

// MARK: - Authentication ViewModel

/// `AuthViewModel` manages all Firebase Authentication-related actions
class AuthViewModel: ObservableObject {
   
    // MARK: - Published Properties
    @Published var user: User? = nil
    @Published var email: String = ""
    @Published var name: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Initializer
        
    /// Initializes the authentication view model.
    init() {
        self.user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }
    
    // MARK: - Sign Up
        
    /// Registers a new user in Firebase Authentication using the provided email, name, and password.
    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        guard !name.isEmpty else {
            errorMessage = "Name is required."
            return
        }
        
        isLoading = true
        do {
            // Create the user
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
            
            // Update the display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            errorMessage = ""
            print(" User created with display name: \(name)")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Sign In
        
    /// Signs in an existing user using email and password credentials.
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        isLoading = true
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            errorMessage = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Sign Out
        
    /// Signs out the current user from Firebase Authentication.
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
