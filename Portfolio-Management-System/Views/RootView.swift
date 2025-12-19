//
//  RootView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var viewModel = PortfolioViewModel()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView(viewModel: viewModel)
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

#Preview {
    RootView()
}
