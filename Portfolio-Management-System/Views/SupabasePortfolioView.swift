//
//  SupabasePortfolioView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct SupabasePortfolioView: View {
    @ObservedObject private var viewModel = SupabasePortfolioViewModel.shared
    
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
                        // Portfolio Summary Card
                        VStack(spacing: 16) {
                            // Header with USD note
                            HStack {
                                Text("Portfolio Summary")
                                    .font(.headline)
                                Spacer()
                                Text("All values in USD")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Total Portfolio Value - Hero section
                            VStack(spacing: 4) {
                                Text("Total Value")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatUSD(viewModel.totalPortfolioValue))
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            
                            Divider()
                            
                            // Cash & Holdings row
                            HStack(spacing: 0) {
                                VStack(spacing: 4) {
                                    Text("Cash")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatUSD(viewModel.totalCashBalance))
                                        .font(.title3.bold())
                                        .foregroundStyle(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 40)
                                
                                VStack(spacing: 4) {
                                    Text("Stocks")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatUSD(viewModel.totalHoldingsValue))
                                        .font(.title3.bold())
                                        .foregroundStyle(.green)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            
                            Divider()
                            
                            // Today's Change & Gain/Loss row
                            HStack(spacing: 0) {
                                VStack(spacing: 4) {
                                    Text("Today's Change")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatSignedUSD(viewModel.todayChangeValue))
                                        .font(.title3.bold())
                                        .foregroundStyle(viewModel.todayChangeValue >= 0 ? .green : .red)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 40)
                                
                                VStack(spacing: 4) {
                                    Text("Stock Gain/Loss")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatSignedUSD(viewModel.gainLossValue))
                                        .font(.title3.bold())
                                        .foregroundStyle(viewModel.gainLossValue >= 0 ? .green : .red)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // Holdings Section (sorted by market value)
                        if !viewModel.positions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Holdings")
                                        .font(.headline)
                                    Text("(\(viewModel.positions.count))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if viewModel.isRefreshing {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                VStack(spacing: 8) {
                                    ForEach(viewModel.sortedPositions) { position in
                                        PositionRow(
                                            position: position,
                                            latestPrice: viewModel.latestPrices[position.symbol],
                                            exchangeRate: viewModel.getExchangeRate(for: position.symbol)
                                        )
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
                            await viewModel.forceRefresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading || viewModel.isRefreshing)
                }
            }
            .refreshable {
                await viewModel.forceRefresh()
            }
        }
        .task {
            await viewModel.loadPortfolioData()
        }
    }
}

// MARK: - Formatting Helpers

private func formatUSD(_ value: Decimal) -> String {
    let number = NSDecimalNumber(decimal: value)
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "$"
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter.string(from: number) ?? "$0.00"
}

private func formatSignedUSD(_ value: Decimal) -> String {
    let number = NSDecimalNumber(decimal: value)
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "$"
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.positivePrefix = "+$"
    formatter.negativePrefix = "-$"
    return formatter.string(from: number) ?? "$0.00"
}

// MARK: - Supporting Views

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
    let latestPrice: Decimal?
    let exchangeRate: Decimal
    
    var marketValueUSD: Decimal {
        guard let price = latestPrice else { return 0 }
        return price * position.totalShares * exchangeRate
    }
    
    var gainLoss: Decimal {
        marketValueUSD - position.totalCostBase
    }
    
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
                Text(marketValueUSD, format: .currency(code: "USD"))
                    .font(.headline)
                if let price = latestPrice {
                    Text("@ \(price, format: .number.precision(.fractionLength(2)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(gainLoss, format: .currency(code: "USD"))
                    .font(.caption)
                    .foregroundStyle(gainLoss >= 0 ? .green : .red)
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
