//
//  SettingsView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let user = authManager.currentUser {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("User ID")
                            Spacer()
                            Text(user.id.prefix(8) + "...")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out")
                        }
                        .foregroundStyle(.red)
                    }
                }
                
                Section("Data") {
                    NavigationLink(destination: Text("Sync Status")) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Settings")
                        }
                    }
                    
                    NavigationLink(destination: Text("Export Data")) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("Privacy Policy")
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("Terms of Service")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? Your data will remain synced in the cloud.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationManager())
}
