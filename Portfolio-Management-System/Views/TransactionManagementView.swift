//
//  TransactionManagementView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct TransactionManagementView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @State private var showingAddTransaction = false
    @State private var selectedTicker: UUID?
    
    var filteredTransactions: [Transaction] {
        if let tickerId = selectedTicker {
            return viewModel.transactions.filter { $0.tickerId == tickerId }
        }
        return viewModel.transactions
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.tickers.isEmpty {
                    Picker("Filter by Ticker", selection: $selectedTicker) {
                        Text("All Transactions").tag(UUID?(nil))
                        ForEach(viewModel.tickers) { ticker in
                            Text(ticker.code).tag(UUID?(ticker.id))
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(12)
                }
                
                if filteredTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Transactions")
                            .font(.headline)
                        Text("Start trading to record transactions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                } else {
                    List {
                        ForEach(filteredTransactions.sorted { $0.date > $1.date }) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                ticker: viewModel.getTickerById(transaction.tickerId)
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteTransaction(transaction)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTransaction = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                    .disabled(viewModel.tickers.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(viewModel: viewModel, isPresented: $showingAddTransaction)
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let ticker: StockTicker?
    
    var typeColor: Color {
        switch transaction.type {
        case .buy:
            return .red
        case .sell:
            return .green
        case .dividend:
            return .blue
        }
    }
    
    var typeIcon: String {
        switch transaction.type {
        case .buy:
            return "arrow.down.circle.fill"
        case .sell:
            return "arrow.up.circle.fill"
        case .dividend:
            return "percent"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: typeIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(typeColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ticker?.code ?? "Unknown")
                            .font(.headline)
                        Text(transaction.type.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(typeColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.2f", transaction.quantity))
                        .font(.headline)
                    Text(String(format: "@ $%.2f", transaction.pricePerUnit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !transaction.notes.isEmpty {
                Text(transaction.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 40)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TransactionManagementView(viewModel: PortfolioViewModel())
}
