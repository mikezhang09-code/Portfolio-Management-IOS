//
//  SupabaseCashAccountsView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/19.
//

import SwiftUI

struct SupabaseCashAccountsView: View {
    @ObservedObject private var viewModel = SupabasePortfolioViewModel.shared
    @State private var showingAddTransaction = false
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Loading cash accounts...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text("Error")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Retry") {
                                Task {
                                    await viewModel.forceRefresh()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        // Total Cash Balance Card
                        VStack(spacing: 12) {
                            HStack {
                                Text("Total Cash Balance")
                                    .font(.headline)
                                Spacer()
                                Text("All values in USD")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(formatCashUSD(viewModel.totalCashBalance))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // Cash Accounts List
                        if !viewModel.accountUSDValues.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Cash Accounts")
                                        .font(.headline)
                                    Text("(\(viewModel.accountUSDValues.count))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if viewModel.isRefreshing {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                VStack(spacing: 0) {
                                    ForEach(viewModel.accountUSDValues.sorted { $0.displayName < $1.displayName }) { account in
                                        CashAccountDetailRow(account: account)
                                        if account.id != viewModel.accountUSDValues.sorted(by: { $0.displayName < $1.displayName }).last?.id {
                                            Divider()
                                                .padding(.horizontal, 12)
                                        }
                                    }
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
            .navigationTitle("Cash Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingAddTransaction = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(viewModel.isLoading)

                        Button {
                        Task {
                            await viewModel.forceRefresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading || viewModel.isRefreshing)
                }
            }
            }
            .refreshable {
                await viewModel.forceRefresh()
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddSupabaseTransactionView(
                    viewModel: viewModel,
                    isPresented: $showingAddTransaction,
                    allowedTypes: [.cashDeposit, .cashWithdrawal, .cashInterest, .currencyExchange]
                )
            }
        }
        .task {
            await viewModel.loadPortfolioData()
        }
    }
}

// MARK: - Cash Account Detail Row

struct CashAccountDetailRow: View {
    let account: PortfolioDataService.AccountUSDValue
    
    var body: some View {
        HStack(spacing: 12) {
            // Currency icon
            ZStack {
                Circle()
                    .fill(currencyColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(currencyFlag)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.displayName)
                    .font(.subheadline.weight(.medium))
                Text(account.nativeCurrency)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCashUSD(account.usdValue))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                if account.nativeCurrency != "USD" {
                    Text(formatNativeBalance(account.nativeBalance, currency: account.nativeCurrency))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var currencyColor: Color {
        switch account.nativeCurrency {
        case "USD": return .green
        case "HKD": return .red
        case "CNY": return .orange
        case "EUR": return .blue
        case "GBP": return .purple
        default: return .gray
        }
    }
    
    private var currencyFlag: String {
        switch account.nativeCurrency {
        case "USD": return "🇺🇸"
        case "HKD": return "🇭🇰"
        case "CNY": return "🇨🇳"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "JPY": return "🇯🇵"
        case "CAD": return "🇨🇦"
        case "AUD": return "🇦🇺"
        default: return "💵"
        }
    }
}

// MARK: - Formatting Helpers

private func formatCashUSD(_ value: Decimal) -> String {
    let number = NSDecimalNumber(decimal: value)
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "$"
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter.string(from: number) ?? "$0.00"
}

private func formatNativeBalance(_ value: Decimal, currency: String) -> String {
    let number = NSDecimalNumber(decimal: value)
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    
    let symbol: String
    switch currency {
    case "HKD": symbol = "HK$"
    case "CNY": symbol = "¥"
    case "EUR": symbol = "€"
    case "GBP": symbol = "£"
    case "JPY": symbol = "¥"
    default: symbol = currency + " "
    }
    
    return symbol + (formatter.string(from: number) ?? "0.00")
}

#Preview {
    SupabaseCashAccountsView()
}
