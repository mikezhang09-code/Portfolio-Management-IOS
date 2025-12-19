//
//  AuthenticationManager.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation
import Combine

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case invalidResponse
    case tokenExpired
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .tokenExpired:
            return "Session expired. Please sign in again"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }
}

struct SignInResponse: Codable {
    let session: AuthSession?
    let user: AuthUser?
}

struct SupabaseAuthError: Codable {
    let message: String?
    let hint: String?
    let error: String?
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = SupabaseConfig.url
    private let apiKey = SupabaseConfig.anonKey
    private let keychain = KeychainHelper.shared
    
    init() {
        // Try to restore session from keychain
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Build URL with grant_type as query parameter per Supabase spec
        var components = URLComponents(url: baseURL.appendingPathComponent("auth/v1/token"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "grant_type", value: "password")]
        guard let url = components.url else { throw AuthError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        // No Authorization header for password grant
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
            print("[Auth] Sign-in HTTP status: \(http.statusCode)")
            if let bodyText = String(data: data, encoding: .utf8) { print("[Auth] Response body: \(bodyText)") }
            
            guard http.statusCode == 200 else {
                let serverMsg = parseErrorMessage(data)
                self.errorMessage = serverMsg ?? "Invalid email or password"
                throw AuthError.invalidCredentials
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let authResponse = try decoder.decode(AuthSession.self, from: data)
            try keychain.saveAccessToken(authResponse.accessToken)
            try keychain.saveRefreshToken(authResponse.refreshToken)
            try keychain.saveUserId(authResponse.user.id)
            self.currentUser = authResponse.user
            self.isAuthenticated = true
        } catch let error as AuthError {
            self.errorMessage = error.localizedDescription
            throw error
        } catch {
            let authError = AuthError.networkError(error)
            self.errorMessage = authError.localizedDescription
            throw authError
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let endpoint = baseURL.appendingPathComponent("auth/v1/signup")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        // Intentionally no Authorization header
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            print("[Auth] Sign-up HTTP status: \(httpResponse.statusCode)")
            if let bodyText = String(data: data, encoding: .utf8) { print("[Auth] Sign-up body: \(bodyText)") }
            
            guard httpResponse.statusCode == 200 else {
                let serverMsg = parseErrorMessage(data)
                self.errorMessage = serverMsg ?? "Sign up failed"
                throw AuthError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let signInResponse = try decoder.decode(SignInResponse.self, from: data)
            
            if let session = signInResponse.session {
                try keychain.saveAccessToken(session.accessToken)
                try keychain.saveRefreshToken(session.refreshToken)
                try keychain.saveUserId(session.user.id)
                self.currentUser = session.user
                self.isAuthenticated = true
            }
            
        } catch let error as AuthError {
            self.errorMessage = error.localizedDescription
            throw error
        } catch {
            let authError = AuthError.networkError(error)
            self.errorMessage = authError.localizedDescription
            throw authError
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        isLoading = true
        
        defer { isLoading = false }
        
        // Clear keychain
        keychain.clearAuthenticationData()
        
        // Clear state
        self.currentUser = nil
        self.isAuthenticated = false
        self.errorMessage = nil
    }
    
    // MARK: - Restore Session
    
    private func restoreSession() async {
        do {
            let accessToken = try keychain.retrieveAccessToken()
            let userId = try keychain.retrieveUserId()
            
            // Verify token is still valid by making a simple API call
            guard await verifyToken(accessToken) else {
                // Token expired, clear everything
                keychain.clearAuthenticationData()
                return
            }
            
            // Token is valid, restore session
            self.currentUser = AuthUser(id: userId, email: "", createdAt: nil)
            self.isAuthenticated = true
            
        } catch {
            // No stored session, do nothing
        }
    }
    
    // MARK: - Verify Token
    
    private func verifyToken(_ token: String) async -> Bool {
        let endpoint = baseURL.appendingPathComponent("auth/v1/user")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - Get Current Access Token
    
    func getAccessToken() throws -> String {
        try keychain.retrieveAccessToken()
    }
    
    // MARK: - Parse Error Message
    
    private func parseErrorMessage(_ data: Data) -> String? {
        if let serverError = try? JSONDecoder().decode(SupabaseAuthError.self, from: data) {
            if let message = serverError.message, !message.isEmpty { return message }
            if let hint = serverError.hint, !hint.isEmpty { return hint }
            if let err = serverError.error, !err.isEmpty { return err }
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty { return text }
        return nil
    }
}
