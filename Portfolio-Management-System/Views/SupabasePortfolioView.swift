//
//  SupabasePortfolioView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct SupabasePortfolioView: View {
    @StateObject private var viewModel = SupabasePortfolioViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Loading portfolio...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text("Error Loading Portfolio")
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await viewModel.loadPortfolioData()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        // Portfolio Value Card
                        VStack(spacing: 12) {
                            Text("Portfolio Summary")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                MetricCard(
                                    label: "Total Value",
                                    value: viewModel.totalPortfolioValue,
                                    currency: viewModel.baseCurrency,
                                    color: .primary
                                )
                                MetricCard(
                                    label: "Today's Change",
                                    value: viewModel.todayChangeValue,
                                    currency: viewModel.baseCurrency,
                                    color: viewModel.todayChangeValue >= 0 ? .green : .red
                                )
                                MetricCard(
                                    label: "Stock Gain/Loss",
                                    value: viewModel.gainLossValue,
                                    currency: viewModel.baseCurrency,
                                    color: viewModel.gainLossValue >= 0 ? .green : .red
                                )
                            }
                            
                            HStack(spacing: 12) {
                                MetricCard(
                                    label: "Cash",
                                    value: viewModel.totalCashBalance,
                                    currency: viewModel.baseCurrency,
                                    color: .blue
                                )
                                MetricCard(
                                    label: "Holdings",
                                    value: viewModel.totalHoldingsValue,
                                    currency: viewModel.baseCurrency,
                                    color: .green
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(16)
                        
                        // Cash Accounts Section
                        if !viewModel.cashAccounts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Cash Accounts")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 8) {
                                    ForEach(viewModel.cashAccounts) { account in
                                        CashAccountRow(
                                            account: account,
                                            balance: viewModel.cashBalancesNative[account.id] ?? 0
                                        )
                                    }
                                }
                                .padding(12)
                                .background(.gray.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Holdings Section
                        if !viewModel.positions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Holdings")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 8) {
                                    ForEach(viewModel.positions) { position in
                                        PositionRow(position: position)
                                    }
                                }
                                .padding(12)
                                .background(.gray.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // Recent Transactions Section
                        if !viewModel.stockTransactions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Transactions")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 8) {
                                    ForEach(viewModel.stockTransactions.prefix(10)) { transaction in
                                        SupabaseTransactionRow(transaction: transaction)
                                    }
                                }
                                .padding(12)
                                .background(.gray.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
            .navigationTitle("My Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.loadPortfolioData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.loadPortfolioData()
            }
        }
        .task {
            await viewModel.loadPortfolioData()
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let label: String
    let value: Decimal
    let currency: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: currency))
                .font(.headline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CashAccountRow: View {
    let account: SupabaseCashAccount
    let balance: Decimal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.displayName)
                    .font(.headline)
                Text(account.currency)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(balance, format: .currency(code: account.currency))
                .font(.headline)
                .foregroundStyle(balance >= 0 ? Color.primary : Color.red)
        }
        .padding(.vertical, 8)
    }
}

struct PositionRow: View {
    let position: SupabasePortfolioPosition
    
    var marketValue: Decimal { position.totalCostBase }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.headline)
                Text("\(position.totalShares, format: .number.precision(.fractionLength(2))) shares")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(marketValue, format: .currency(code: "USD"))
                    .font(.headline)
                if let avgCost = position.averageCostBase {
                    Text("Avg: \(avgCost, format: .currency(code: "USD"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct SupabaseTransactionRow: View {
    let transaction: SupabaseStockTransaction
    
    var tradeTypeColor: Color {
        switch transaction.tradeType {
        case .buy: return .green
        case .sell: return .red
        case .dividend: return .blue
        }
    }
    
    var tradeTypeIcon: String {
        switch transaction.tradeType {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .dividend: return "dollarsign.circle.fill"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: tradeTypeIcon)
                .foregroundStyle(tradeTypeColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.symbol)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(transaction.tradeType.rawValue.capitalized)
                    Text("•")
                    Text(transaction.tradeDate, style: .date)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.grossAmount, format: .currency(code: transaction.currency))
                    .font(.headline)
                Text("\(transaction.quantity, format: .number) @ \(transaction.pricePerShare, format: .currency(code: transaction.currency))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SupabasePortfolioView()
}
