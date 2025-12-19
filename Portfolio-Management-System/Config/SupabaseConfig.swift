//
//  SupabaseConfig.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

struct SupabaseConfig {
    static let projectURL = "https://obcdtnxdnzrrzmwtnjgj.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9iY2R0bnhkbnpycnptd3RuamdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQwMTkxNzYsImV4cCI6MjA2OTU5NTE3Nn0.05wTyQdVbNEktYwW6Fl_guPJ2iJLzej6uEjNcEo495Q"
    
    static var url: URL {
        guard let url = URL(string: projectURL) else {
            fatalError("Invalid Supabase URL")
        }
        return url
    }
}
