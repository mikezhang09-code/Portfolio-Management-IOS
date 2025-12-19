//
//  KeychainHelper.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case unexpectedStatus(OSStatus)
    case unableToConvertToString
}

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    // MARK: - Save
    
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unableToConvertToString
        }
        try save(data, for: key)
    }
    
    // MARK: - Retrieve
    
    func retrieve(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.itemNotFound
        }
        
        return data
    }
    
    func retrieveString(for key: String) throws -> String {
        let data = try retrieve(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unableToConvertToString
        }
        return string
    }
    
    // MARK: - Delete
    
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// MARK: - Convenience Keys

extension KeychainHelper {
    private static let accessTokenKey = "supabase.accessToken"
    private static let refreshTokenKey = "supabase.refreshToken"
    private static let userIdKey = "supabase.userId"
    
    func saveAccessToken(_ token: String) throws {
        try save(token, for: Self.accessTokenKey)
    }
    
    func retrieveAccessToken() throws -> String {
        try retrieveString(for: Self.accessTokenKey)
    }
    
    func saveRefreshToken(_ token: String) throws {
        try save(token, for: Self.refreshTokenKey)
    }
    
    func retrieveRefreshToken() throws -> String {
        try retrieveString(for: Self.refreshTokenKey)
    }
    
    func saveUserId(_ userId: String) throws {
        try save(userId, for: Self.userIdKey)
    }
    
    func retrieveUserId() throws -> String {
        try retrieveString(for: Self.userIdKey)
    }
    
    func clearAuthenticationData() {
        try? delete(for: Self.accessTokenKey)
        try? delete(for: Self.refreshTokenKey)
        try? delete(for: Self.userIdKey)
    }
}
