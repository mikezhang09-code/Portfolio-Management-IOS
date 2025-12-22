//
//  SupabaseAPIClient.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized. Please sign in again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

@MainActor
class SupabaseAPIClient {
    static let shared = SupabaseAPIClient()
    
    private let baseURL = SupabaseConfig.url
    private let apiKey = SupabaseConfig.anonKey
    private let authManager: AuthenticationManager
    
    private init() {
        // We'll inject the auth manager later
        self.authManager = AuthenticationManager()
    }
    
    // MARK: - Generic GET Request
    
    func get<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        // Add authorization if user is authenticated
        if let accessToken = try? authManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("[API] GET \(endpoint) - Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try ISO8601 with fractional seconds
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                // Try ISO8601 without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                print("[API] Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[API] Response JSON: \(jsonString)")
                }
                throw APIError.decodingError(error)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Generic POST Request
    
    func post<T: Decodable, U: Encodable>(
        endpoint: String,
        body: U
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        // Add authorization if user is authenticated
        if let accessToken = try? authManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("[API] POST \(endpoint) - Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(errorMessage)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Supabase Edge Function Request

    func postFunction<T: Decodable, U: Encodable>(
        name: String,
        body: U
    ) async throws -> T {
        let url = baseURL.appendingPathComponent("functions/v1/\(name)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        // Add authorization if user is authenticated
        if let accessToken = try? authManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            print("[API] POST functions/\(name) - Status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(errorMessage)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Generic PATCH Request
    
    func patch<U: Encodable>(
        endpoint: String,
        id: UUID,
        body: U
    ) async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        // Add authorization if user is authenticated
        if let accessToken = try? authManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("[API] PATCH \(endpoint) - Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(errorMessage)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Generic DELETE Request
    
    func delete(
        endpoint: String,
        id: UUID
    ) async throws {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(id.uuidString)")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        
        // Add authorization if user is authenticated
        if let accessToken = try? authManager.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("[API] DELETE \(endpoint) - Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(errorMessage)
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Historical Data Endpoints
    
    func fetchHistoricalPortfolioSnapshots(
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 365
    ) async throws -> [HistoricalPortfolioSnapshot] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "order", value: "snapshot_date.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        if let start = startDate {
            let dateStr = dateFormatter.string(from: start)
            queryItems.append(URLQueryItem(name: "snapshot_date", value: "gte.\(dateStr)"))
        }
        
        if let end = endDate {
            let dateStr = dateFormatter.string(from: end)
            queryItems.append(URLQueryItem(name: "snapshot_date", value: "lte.\(dateStr)"))
        }
        
        return try await get(
            endpoint: "rest/v1/historical_portfolio_snapshots",
            queryItems: queryItems
        )
    }
    
    func fetchHistoricalBenchmarkSnapshots(
        benchmarkSymbol: String = "^GSPC",
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int = 365
    ) async throws -> [HistoricalBenchmarkSnapshot] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "index_symbol", value: "eq.\(benchmarkSymbol)"),
            URLQueryItem(name: "order", value: "snapshot_date.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        
        if let start = startDate {
            let dateStr = dateFormatter.string(from: start)
            queryItems.append(URLQueryItem(name: "snapshot_date", value: "gte.\(dateStr)"))
        }
        
        if let end = endDate {
            let dateStr = dateFormatter.string(from: end)
            queryItems.append(URLQueryItem(name: "snapshot_date", value: "lte.\(dateStr)"))
        }
        
        return try await get(
            endpoint: "rest/v1/historical_benchmark_snapshots",
            queryItems: queryItems
        )
    }
}
