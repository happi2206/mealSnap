//
//  LoginView.swift
//  MealSnap
//
//  Created by Rujeet Prajapati on 20/10/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSignUp = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    header
                    formCard
                    togglePrompt
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isSignUp ? "Create your MealSnap account" : "Welcome back to MealSnap")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text(isSignUp ? "Join the community and capture smarter meals." : "Continue tracking your meals effortlessly.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
    
    private var formCard: some View {
        Card(edges: EdgeInsets(top: 26, leading: 24, bottom: 26, trailing: 24)) {
            VStack(spacing: 20) {
                if isSignUp {
                    AuthField(
                        icon: "person.circle",
                        placeholder: "Full name",
                        text: $authVM.name,
                        keyboard: .namePhonePad
                    )
                    .focused($focusedField, equals: .name)
                }
                
                AuthField(
                    icon: "envelope",
                    placeholder: "Email address",
                    text: $authVM.email,
                    keyboard: .emailAddress,
                    textInput: .never
                )
                .focused($focusedField, equals: .email)
                
                PasswordField(
                    icon: "lock",
                    placeholder: "Password",
                    text: $authVM.password,
                    isShowing: $showPassword
                )
                .focused($focusedField, equals: .password)
                
                if isSignUp {
                    PasswordField(
                        icon: "lock.rotation",
                        placeholder: "Confirm password",
                        text: $confirmPassword,
                        isShowing: $showConfirmPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                }
                
                if !authVM.errorMessage.isEmpty {
                    ErrorText(message: authVM.errorMessage)
                        .transition(.opacity)
                }
                
                PrimaryButton(
                    title: isSignUp ? "Sign Up" : "Log In",
                    systemImage: isSignUp ? "person.badge.plus" : "arrow.right.circle.fill"
                ) {
                    Task { await submitAction() }
                }
                .disabled(authVM.isLoading)
                .overlay(alignment: .center) {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                }
            }
        }
    }
    
    private var togglePrompt: some View {
        HStack(spacing: 6) {
            Text(isSignUp ? "Already have an account?" : "New to MealSnap?")
                .foregroundStyle(.secondary)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isSignUp.toggle()
                    authVM.errorMessage = ""
                    authVM.password.removeAll()
                    confirmPassword.removeAll()
                }
            } label: {
                Text(isSignUp ? "Log In" : "Create one")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentPrimary)
            }
        }
        .font(.footnote)
    }
    
    private func submitAction() async {
        if isSignUp {
            guard authVM.password == confirmPassword else {
                authVM.errorMessage = "Passwords do not match."
                return
            }
            await authVM.signUp()
        } else {
            await authVM.signIn()
        }
    }
}

// MARK: - Fields

private struct AuthField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var textInput: TextInputAutocapitalization = .words
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentSecondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(textInput)
                .disableAutocorrection(true)
                .keyboardType(keyboard)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct PasswordField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentSecondary)
            Group {
                if isShowing {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                } else {
                    SecureField(placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
            }
            .foregroundStyle(.primary)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowing.toggle()
                }
            } label: {
                Image(systemName: isShowing ? "eye.slash.fill" : "eye.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(isShowing ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
