//
//  SupabaseTransactionsView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/19.
//

import SwiftUI

struct SupabaseTransactionsView: View {
    @ObservedObject private var viewModel = SupabasePortfolioViewModel.shared
    @State private var selectedSymbol: String = "All Tickers"
    @State private var selectedTradeType: StockTradeType? = nil

    private var availableSymbols: [String] {
        let symbols = Set(viewModel.stockTransactions.map { $0.symbol })
        return symbols.sorted()
    }

    private var filteredTransactions: [SupabaseStockTransaction] {
        viewModel.stockTransactions
            .filter { transaction in
                let matchesSymbol = selectedSymbol == "All Tickers" || transaction.symbol == selectedSymbol
                let matchesType = selectedTradeType == nil || transaction.tradeType == selectedTradeType
                return matchesSymbol && matchesType
            }
            .sorted { $0.tradeDate > $1.tradeDate }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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
                        // Filters
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Stock Transactions")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                Menu {
                                    Button("All Tickers") {
                                        selectedSymbol = "All Tickers"
                                    }
                                    ForEach(availableSymbols, id: \.self) { symbol in
                                        Button(symbol) {
                                            selectedSymbol = symbol
                                        }
                                    }
                                } label: {
                                    filterPill(
                                        title: selectedSymbol,
                                        systemImage: "chevron.down"
                                    )
                                }
                                
                                Menu {
                                    Button("All Types") {
                                        selectedTradeType = nil
                                    }
                                    Button("Buy") {
                                        selectedTradeType = .buy
                                    }
                                    Button("Sell") {
                                        selectedTradeType = .sell
                                    }
                                    Button("Dividend") {
                                        selectedTradeType = .dividend
                                    }
                                } label: {
                                    filterPill(
                                        title: selectedTradeType?.rawValue.capitalized ?? "All Types",
                                        systemImage: "line.3.horizontal.decrease.circle"
                                    )
                                }
                                
                                Spacer()
                                
                                if viewModel.isRefreshing {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Summary row
                        HStack {
                            Text("\(filteredTransactions.count) Transactions")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(selectedSymbol == "All Tickers" ? "All Tickers" : selectedSymbol)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)

                        // Transactions List
                        VStack(spacing: 12) {
                            if filteredTransactions.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.secondary)
                                    Text("No matching transactions")
                                        .font(.headline)
                                    Text("Try adjusting the filters to see more activity.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                ForEach(filteredTransactions) { transaction in
                                    SupabaseTransactionDetailRow(
                                        transaction: transaction,
                                        stockName: viewModel.getStockName(for: transaction.symbol)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
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

    private func filterPill(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Image(systemName: systemImage)
                .font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
        .foregroundStyle(.primary)
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
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: typeIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(typeColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(transaction.symbol)
                            .font(.headline)
                        Text(transaction.tradeType.rawValue.uppercased())
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(typeColor.opacity(0.15))
                            .foregroundStyle(typeColor)
                            .clipShape(Capsule())
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

                VStack(alignment: .trailing, spacing: 6) {
                    Text(formatTotal(transaction.quantity * transaction.pricePerShare))
                        .font(.subheadline.weight(.semibold))
                    Text(formatShares(transaction.quantity))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Text("Price")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("@ \(formatPrice(transaction.pricePerShare))")
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
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
