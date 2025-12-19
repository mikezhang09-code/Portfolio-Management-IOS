//
//  SupabaseTransactionsView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/19.
//

import SwiftUI

struct SupabaseTransactionsView: View {
    @ObservedObject private var viewModel = SupabasePortfolioViewModel.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Loading transactions...")
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
                    } else if viewModel.stockTransactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No Transactions")
                                .font(.headline)
                            Text("Your recent stock transactions will appear here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    } else {
                        // Transactions Header
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                            Text("(\(viewModel.stockTransactions.count))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if viewModel.isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Transactions List
                        VStack(spacing: 0) {
                            ForEach(viewModel.stockTransactions) { transaction in
                                SupabaseTransactionDetailRow(
                                    transaction: transaction,
                                    stockName: viewModel.getStockName(for: transaction.symbol)
                                )
                                if transaction.id != viewModel.stockTransactions.last?.id {
                                    Divider()
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
                        .padding(.horizontal, 16)
                        
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
            .navigationTitle("Transactions")
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

// MARK: - Transaction Detail Row

struct SupabaseTransactionDetailRow: View {
    let transaction: SupabaseStockTransaction
    let stockName: String?
    
    var typeColor: Color {
        switch transaction.tradeType {
        case .buy:
            return .red
        case .sell:
            return .green
        case .dividend:
            return .blue
        }
    }
    
    var typeIcon: String {
        switch transaction.tradeType {
        case .buy:
            return "arrow.down.circle.fill"
        case .sell:
            return "arrow.up.circle.fill"
        case .dividend:
            return "dollarsign.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: typeIcon)
                .font(.system(size: 24))
                .foregroundStyle(typeColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(transaction.symbol)
                        .font(.headline)
                    Text(transaction.tradeType.rawValue.uppercased())
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.15))
                        .foregroundStyle(typeColor)
                        .cornerRadius(4)
                }
                
                if let name = stockName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Text(transaction.tradeDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatShares(transaction.quantity))
                    .font(.subheadline.weight(.semibold))
                Text("@ \(formatPrice(transaction.pricePerShare))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatTotal(transaction.quantity * transaction.pricePerShare))
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatShares(_ quantity: Decimal) -> String {
        let number = NSDecimalNumber(decimal: quantity)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 0
        return (formatter.string(from: number) ?? "0") + " shares"
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let number = NSDecimalNumber(decimal: price)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
    
    private func formatTotal(_ total: Decimal) -> String {
        let number = NSDecimalNumber(decimal: total)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
}

#Preview {
    SupabaseTransactionsView()
}
