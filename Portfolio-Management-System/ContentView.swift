//
//  ContentView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            // Cloud Portfolio (Supabase)
            SupabasePortfolioView()
                .tabItem {
                    Label("My Portfolio", systemImage: "chart.pie.fill")
                }
            
            // Local Overview (for offline/demo)
            PortfolioOverviewView(viewModel: viewModel)
                .tabItem {
                    Label("Local", systemImage: "chart.bar.fill")
                }
            
            CapitalView(viewModel: viewModel)
                .tabItem {
                    Label("Capital", systemImage: "banknote.fill")
                }
            
            TickerManagementView(viewModel: viewModel)
                .tabItem {
                    Label("Tickers", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            TransactionManagementView(viewModel: viewModel)
                .tabItem {
                    Label("Transactions", systemImage: "arrow.left.arrow.right")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView(viewModel: PortfolioViewModel())
        .environmentObject(AuthenticationManager())
}
