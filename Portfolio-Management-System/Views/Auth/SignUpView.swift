//
//  SignUpView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && passwordsMatch && password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Join to sync your portfolio across devices")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            TextField("your.email@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            SecureField("At least 6 characters", text: $password)
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            if !password.isEmpty && password.count < 6 {
                                Text("Password must be at least 6 characters")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.top, 4)
                        }
                        
                        // Sign Up Button
                        Button(action: {
                            Task {
                                await signUp()
                            }
                        }) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!isFormValid || authManager.isLoading)
                        .padding(.top, 8)
                        
                        // Terms
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func signUp() async {
        do {
            try await authManager.signUp(email: email, password: password)
            alertMessage = "Account created successfully! You can now sign in."
            showAlert = true
        } catch {
            // Error is already shown in authManager.errorMessage
        }
    }
}

#Preview {
    SignUpView()
}
