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
            
            SupabaseStocksView(viewModel: SupabasePortfolioViewModel.shared)
                .tabItem {
                    Label("Stocks", systemImage: "chart.bar.fill")
                }
            
            SupabaseTransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "arrow.left.arrow.right")
                }

            // Analysis - Portfolio Performance
            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
                }

            SupabaseCashAccountsView()
                .tabItem {
                    Label("Cash", systemImage: "banknote.fill")
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
