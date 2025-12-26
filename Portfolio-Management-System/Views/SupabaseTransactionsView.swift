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
    @State private var isSymbolPickerPresented = false
    @State private var symbolSearchText = ""
    @State private var showingAddTransaction = false

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
                                Button {
                                    isSymbolPickerPresented = true
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
        }
        .sheet(isPresented: $isSymbolPickerPresented) {
            SymbolPickerView(
                availableSymbols: availableSymbols,
                selectedSymbol: $selectedSymbol,
                searchText: $symbolSearchText
            )
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddSupabaseTransactionView(
                viewModel: viewModel,
                isPresented: $showingAddTransaction
            )
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

private struct SymbolPickerView: View {
    let availableSymbols: [String]
    @Binding var selectedSymbol: String
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss

    private var matchingSymbols: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return availableSymbols
        }
        return availableSymbols.filter { symbol in
            symbol.range(of: trimmed, options: .caseInsensitive) != nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedSymbol = "All Tickers"
                    dismiss()
                } label: {
                    selectionRow(title: "All Tickers", isSelected: selectedSymbol == "All Tickers")
                }

                if matchingSymbols.isEmpty {
                    Text("No matching tickers")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(matchingSymbols, id: \.self) { symbol in
                        Button {
                            selectedSymbol = symbol
                            dismiss()
                        } label: {
                            selectionRow(title: symbol, isSelected: selectedSymbol == symbol)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search ticker")
            .textInputAutocapitalization(.characters)
            .disableAutocorrection(true)
            .navigationTitle("Select Ticker")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                searchText = ""
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func selectionRow(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
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
                    Text(formatTotal(transaction.quantity * transaction.pricePerShare, currency: transaction.currency))
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
                Text("@ \(formatPrice(transaction.pricePerShare, currency: transaction.currency))")
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
    
    private func formatPrice(_ price: Decimal, currency: String) -> String {
        let number = NSDecimalNumber(decimal: price)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }

    private func formatTotal(_ total: Decimal, currency: String) -> String {
        let number = NSDecimalNumber(decimal: total)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
}

#Preview {
    SupabaseTransactionsView()
}
