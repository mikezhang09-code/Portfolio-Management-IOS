//
//  LoginView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var networkStatus: NetworkStatus = .checking
    
    enum NetworkStatus { case checking, online, offline }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with App Icon and status
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.blue)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(networkStatus == .online ? Color.green : (networkStatus == .offline ? Color.red : Color.orange))
                                .frame(width: 10, height: 10)
                            Text(statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Retry") { Task { await checkSupabaseHealth() } }
                                .font(.caption)
                        }
                    }
                    
                    Text("Portfolio Manager")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Track your investments")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 48)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Login Form
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
                        
                        SecureField("Enter password", text: $password)
                            .textContentType(.password)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                    
                    // Sign In Button
                    Button(action: {
                        Task {
                            await signIn()
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                    }
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    .padding(.top, 8)
                    
                    // Sign Up Link
                    Button(action: {
                        showSignUp = true
                    }) {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Demo Mode Button
                Button(action: {
                    print("[Auth] Demo Mode activated - bypassing Supabase")
                    authManager.currentUser = AuthUser(id: "demo-user", email: "demo@local", createdAt: nil)
                    authManager.isAuthenticated = true
                }) {
                    Text("Continue in Demo Mode (Offline)")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSignUp) {
                SignUpView().environmentObject(authManager)
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .task { await checkSupabaseHealth() }
        }
    }
    
    private var statusText: String {
        switch networkStatus {
        case .checking: return "Checking…"
        case .online: return "Online"
        case .offline: return "Offline"
        }
    }
    
    private func signIn() async {
        do {
            print("[Auth] Attempting sign-in for: \(email)")
            try await authManager.signIn(email: email, password: password)
            print("[Auth] Sign-in success for: \(email)")
        } catch {
            print("[Auth] Sign-in failed: \(error.localizedDescription)")
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func checkSupabaseHealth() async {
        networkStatus = .checking
        let healthURL = SupabaseConfig.url.appendingPathComponent("auth/v1/health")
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 6
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                print("[Network] Health status: \(http.statusCode)")
                if (200...299).contains(http.statusCode) || http.statusCode == 401 {
                    // 401 still means endpoint is reachable but requires auth
                    networkStatus = .online
                } else {
                    networkStatus = .offline
                }
            } else {
                networkStatus = .offline
            }
        } catch {
            print("[Network] Health check failed: \(error.localizedDescription)")
            networkStatus = .offline
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthenticationManager())
}
