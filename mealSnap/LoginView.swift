//
//  LoginView.swift
//  mealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.
//

import SwiftUI

/// View for user login and signup.
struct LoginView: View {
    
    // MARK: - State
    @State var isSignUp: Bool = false // Toggle between login and signup
    @State private var showPassword = false // Toggle password visibility
    
    // MARK: - Environment Object
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - App Logo
//            Image("logo")
//                .resizable()
//                .scaledToFit()
            
            // MARK: - Heading
            if(isSignUp){
                Text("Create Account")
                    .font(.largeTitle)
                    .bold()
            }
            
            // MARK: - Name Field (Signup only)
            if(isSignUp){
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                    TextField("User Name", text: $authVM.name)
                        .keyboardType(.alphabet)
                        .autocapitalization(.none)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // MARK: - Email Field
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.gray)
                TextField("Email", text: $authVM.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // MARK: - Password Field
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.gray)
                ZStack(alignment: .trailing) {
                    if showPassword {
                        TextField("Password", text: $authVM.password)
                            .autocapitalization(.none)
                    } else {
                        SecureField("Password", text: $authVM.password)
                            .autocapitalization(.none)
                    }
                    
                    // Toggle password visibility button'
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // MARK: - Error Message
            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            // MARK: - Login / Signup Button
            Button(action: {
                Task {
                    if isSignUp {
                        await authVM.signUp()
                    } else {
                        await authVM.signIn()
                    }
                }
            }) {
                if authVM.isLoading {
                    // Loading spinner while performing network call
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    
                } else {
                    Text(isSignUp ? "Sign Up" : "Log In")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .font(.headline)
                }
            }
            
            // MARK: - Toggle between Login and Signup
            Button(isSignUp ? "Already have an account? Log In" :
                    "Don't have an account? Sign Up") {
                isSignUp.toggle()
                authVM.errorMessage = ""
            }
                    .font(.footnote)
                    .padding(.top, 10)
            
        }
        .padding()
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}
