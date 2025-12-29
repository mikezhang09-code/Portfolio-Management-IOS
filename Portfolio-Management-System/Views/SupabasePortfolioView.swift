//
//  SupabasePortfolioView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct SupabasePortfolioView: View {
    @ObservedObject private var viewModel = SupabasePortfolioViewModel.shared
    @State private var showSortSheet = false
    @State private var expandedPositionId: UUID? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView("Loading portfolio...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if viewModel.positions.isEmpty && viewModel.totalCashBalance == 0 {
                        PortfolioEmptyStateView()
                    } else {
                        portfolioContent
                    }
                }
            }
            .navigationTitle("My Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    refreshButton
                }
            }
            .refreshable {
                await viewModel.forceRefresh()
            }
            .sheet(isPresented: $showSortSheet) {
                HoldingSortSheet(
                    selectedOption: $viewModel.sortOption,
                    sortDirection: $viewModel.sortDirection,
                    isPresented: $showSortSheet
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await viewModel.loadPortfolioData()
        }
    }
    
    // MARK: - Subviews
    
    private var portfolioContent: some View {
        VStack(spacing: 16) {
            // Portfolio Summary Card
            VStack(spacing: 16) {
                summaryHeader
                totalValueSection
                Divider()
                cashStocksRow
                Divider()
                performanceRow
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            
            // Holdings Section
            if !viewModel.positions.isEmpty {
                holdingsSection
            } else if !viewModel.cashAccounts.isEmpty {
                // If no stock positions but has cash, show cash accounts
                cashAccountsSection
            }
            
            Spacer().frame(height: 20)
        }
    }
    
    private var summaryHeader: some View {
        HStack {
            Text("Portfolio Summary")
                .font(.headline)
            Spacer()
            Text("All values in USD")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    private var totalValueSection: some View {
        VStack(spacing: 4) {
            Text("Total Value")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(PortfolioFormatter.formatUSD(viewModel.totalPortfolioValue))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private var cashStocksRow: some View {
        HStack(spacing: 0) {
            summaryDetailBlock(label: "Cash", value: viewModel.totalCashBalance, color: .blue)
            Divider().frame(height: 40)
            summaryDetailBlock(label: "Stocks", value: viewModel.totalHoldingsValue, color: .green)
        }
    }
    
    private var performanceRow: some View {
        HStack(spacing: 0) {
            summaryDetailBlock(label: "Today's Change", value: viewModel.todayChangeValue, color: viewModel.todayChangeValue >= 0 ? .green : .red, isSigned: true)
            Divider().frame(height: 40)
            summaryDetailBlock(label: "Stock Gain/Loss", value: viewModel.gainLossValue, color: viewModel.gainLossValue >= 0 ? .green : .red, isSigned: true)
        }
    }
    
    private func summaryDetailBlock(label: String, value: Decimal, color: Color, isSigned: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(isSigned ? PortfolioFormatter.formatSignedUSD(value) : PortfolioFormatter.formatUSD(value))
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                
                Spacer()
                
                sortButton
                
                if viewModel.isRefreshing {
                    ProgressView().scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 16)
            
            // Holdings List
            VStack(spacing: 0) {
                ForEach(viewModel.sortedPositions) { position in
                    ExpandablePositionRow(
                        position: position,
                        viewModel: viewModel,
                        isExpanded: expandedPositionId == position.id,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedPositionId == position.id {
                                    expandedPositionId = nil
                                } else {
                                    expandedPositionId = position.id
                                }
                            }
                        }
                    )
                    
                    if position.id != viewModel.sortedPositions.last?.id {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    private var cashAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cash Accounts")
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                ForEach(viewModel.cashAccounts) { account in
                    CashAccountRow(
                        account: account,
                        balance: viewModel.cashBalancesNative[account.id] ?? 0
                    )
                    .padding(.horizontal, 16)
                    
                    if account.id != viewModel.cashAccounts.last?.id {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    private var sortButton: some View {
        Button {
            showSortSheet = true
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.sortOption.rawValue)
                    .font(.subheadline.weight(.medium))
                Image(systemName: viewModel.sortDirection.icon)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(16)
        }
    }
    
    private var refreshButton: some View {
        Button {
            Task { await viewModel.forceRefresh() }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(viewModel.isLoading || viewModel.isRefreshing)
    }
    
    private func errorView(_ error: String) -> some View {
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
                Task { await viewModel.loadPortfolioData() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Empty State

struct PortfolioEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue.opacity(0.8))
            
            VStack(spacing: 8) {
                Text("Your Portfolio is Empty")
                    .font(.title3.bold())
                Text("Start by adding your first stock transaction or deposit some cash.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            NavigationLink(destination: Text("Add Transaction View")) { // Placeholder
                Text("Add Your First Asset")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(24)
            }
        }
        .padding(.vertical, 60)
    }
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

// MARK: - Holdings Sort Sheet (Existing, minimal changes)

struct HoldingSortSheet: View {
    @Binding var selectedOption: HoldingSortOption
    @Binding var sortDirection: SortDirection
    @Binding var isPresented: Bool
    
    @State private var tempOption: HoldingSortOption
    @State private var tempDirection: SortDirection
    
    init(selectedOption: Binding<HoldingSortOption>, sortDirection: Binding<SortDirection>, isPresented: Binding<Bool>) {
        self._selectedOption = selectedOption
        self._sortDirection = sortDirection
        self._isPresented = isPresented
        self._tempOption = State(initialValue: selectedOption.wrappedValue)
        self._tempDirection = State(initialValue: sortDirection.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sort by")
                .font(.title2.bold())
                .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(HoldingSortOption.allCases, id: \.self) { option in
                        Button {
                            if tempOption == option {
                                tempDirection.toggle()
                            } else {
                                tempOption = option
                                tempDirection = option == .ticker ? .ascending : .descending
                            }
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .foregroundStyle(tempOption == option ? .white : .primary)
                                Spacer()
                                if tempOption == option {
                                    HStack(spacing: 4) {
                                        Text(tempDirection.rawValue)
                                        Image(systemName: tempDirection.icon)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(tempOption == option ? Color.blue : Color(.systemGray5))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            applyCancelButtons
        }
        .padding(.horizontal, 24)
        .background(Color(.systemBackground))
    }
    
    private var applyCancelButtons: some View {
        VStack(spacing: 12) {
            Button {
                selectedOption = tempOption
                sortDirection = tempDirection
                isPresented = false
            } label: {
                Text("Apply")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .foregroundStyle(.primary)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            Button { isPresented = false } label: {
                Text("Cancel")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Expandable Position Row

struct ExpandablePositionRow: View {
    let position: SupabasePortfolioPosition
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    let isExpanded: Bool
    let onToggle: () -> Void

    @State private var activeSheet: ActiveSheet?
    
    // Performance optimization: compute these once and pass into sub-views
    private var summaryData: PositionSummaryData {
        PositionSummaryData(
            symbol: position.symbol,
            name: viewModel.getStockName(for: position.symbol),
            currentPrice: viewModel.latestPrices[position.symbol] ?? 0,
            daysGainPercent: viewModel.daysGainPercent(for: position),
            marketValue: viewModel.marketValueUSD(for: position),
            totalGainPercent: viewModel.totalGainPercent(for: position),
            daysGainValue: viewModel.daysGainUSD(for: position),
            totalGainValue: viewModel.totalGainUSD(for: position)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                PositionSummaryRow(
                    data: summaryData,
                    isExpanded: isExpanded,
                    sortOption: viewModel.sortOption
                )
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                PositionDetailView(
                    position: position,
                    viewModel: viewModel,
                    summaryData: summaryData,
                    onAddTransaction: { activeSheet = .addTransaction },
                    onShowTransactions: { activeSheet = .transactions }
                )
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .transactions:
                StockTransactionsSheet(
                    viewModel: viewModel,
                    symbol: position.symbol,
                    stockName: summaryData.name
                )
            case .addTransaction:
                AddSupabaseTransactionView(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { activeSheet == .addTransaction },
                        set: { if !$0 { activeSheet = nil } }
                    ),
                    preselectedSymbol: position.symbol,
                    allowedTypes: [.stockBuy, .stockSell, .stockDividend]
                )
            }
        }
    }
}

// MARK: - Position Sub-components

struct PositionSummaryData {
    let symbol: String
    let name: String?
    let currentPrice: Decimal
    let daysGainPercent: Decimal
    let marketValue: Decimal
    let totalGainPercent: Decimal
    let daysGainValue: Decimal
    let totalGainValue: Decimal
}

struct PositionSummaryRow: View {
    let data: PositionSummaryData
    let isExpanded: Bool
    let sortOption: HoldingSortOption
    
    var body: some View {
        HStack {
            // Left: Symbol, Price, Day's Gain
            VStack(alignment: .leading, spacing: 4) {
                Text(data.symbol)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if data.currentPrice > 0 {
                    HStack(spacing: 8) {
                        Text(PortfolioFormatter.formatPrice(data.currentPrice))
                            .font(.subheadline)
                        Text(PortfolioFormatter.formatPercent(data.daysGainPercent))
                            .font(.caption)
                            .foregroundStyle(data.daysGainPercent >= 0 ? .green : .red)
                    }
                } else if let name = data.name {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Right: Sorted Value or Market Value
            VStack(alignment: .trailing, spacing: 2) {
                if sortOption == .marketValue {
                    Text(PortfolioFormatter.formatNumber(data.marketValue))
                        .font(.headline)
                    Text(PortfolioFormatter.formatPercent(data.totalGainPercent) + " Total")
                        .font(.caption2)
                        .foregroundStyle(data.totalGainPercent >= 0 ? .green : .red)
                } else if sortOption == .daysGain || sortOption == .daysGainPercent {
                    Text(PortfolioFormatter.formatSignedValue(data.daysGainValue))
                        .font(.headline)
                        .foregroundStyle(data.daysGainValue >= 0 ? .green : .red)
                } else if sortOption == .totalGain || sortOption == .totalGainPercent {
                    Text(PortfolioFormatter.formatSignedValue(data.totalGainValue, percent: data.totalGainPercent))
                        .font(.headline)
                        .foregroundStyle(data.totalGainValue >= 0 ? .green : .red)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct PositionDetailView: View {
    let position: SupabasePortfolioPosition
    let viewModel: SupabasePortfolioViewModel
    let summaryData: PositionSummaryData
    let onAddTransaction: () -> Void
    let onShowTransactions: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                detailRow("Avg. cost / share", value: PortfolioFormatter.formatDecimal(viewModel.averageCostPerShareNative(for: position)))
                detailRow("Total cost", value: PortfolioFormatter.formatNumber(position.totalCostBase))
                
                Divider()

                detailRow("Day's gain", value: PortfolioFormatter.formatSignedValue(summaryData.daysGainValue, percent: summaryData.daysGainPercent), valueColor: summaryData.daysGainValue >= 0 ? .green : .red)
                detailRow("Total gain", value: PortfolioFormatter.formatSignedValue(summaryData.totalGainValue, percent: summaryData.totalGainPercent), valueColor: summaryData.totalGainValue >= 0 ? .green : .red)
                detailRow("Market value", value: PortfolioFormatter.formatNumber(summaryData.marketValue))

                Divider()

                sharesRow
                transactionsButton
                
                Divider()

                detailRow("Total dividend income", value: PortfolioFormatter.formatNumber(viewModel.dividendIncome(for: position.symbol)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            
            addTransactionButton
        }
    }
    
    private func detailRow(_ label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(valueColor)
        }
        .font(.subheadline)
    }
    
    private var sharesRow: some View {
        HStack {
            Text("Shares").foregroundStyle(.secondary)
            Spacer()
            Text(PortfolioFormatter.formatDecimal(position.totalShares))
        }
        .font(.subheadline)
    }
    
    private var transactionsButton: some View {
        Button(action: onShowTransactions) {
            HStack {
                Text("Transactions").foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(viewModel.transactionCount(for: position.symbol)) total")
                    Image(systemName: "chevron.right").font(.caption)
                }
                .foregroundStyle(.primary)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
    }
    
    private var addTransactionButton: some View {
        Button(action: onAddTransaction) {
            HStack {
                Image(systemName: "plus").font(.caption)
                Text("Add transaction").font(.subheadline)
            }
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Transaction Sheets

private enum ActiveSheet: Identifiable {
    case transactions, addTransaction
    var id: Int { hashValue }
}

private struct StockTransactionsSheet: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    let symbol: String
    let stockName: String?
    @Environment(\.dismiss) private var dismiss

    private var filteredTransactions: [SupabaseStockTransaction] {
        viewModel.stockTransactions
            .filter { $0.symbol == symbol }
            .sorted { $0.tradeDate > $1.tradeDate }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading transactions...")
                } else if filteredTransactions.isEmpty {
                    emptyTransactionsView
                } else {
                    transactionsList
                }
            }
            .navigationTitle(stockName ?? symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private var emptyTransactionsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No transactions yet").font(.headline)
            Text("Add a transaction to see activity for this stock.").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 32)
    }
    
    private var transactionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(filteredTransactions.count) Transactions")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredTransactions) { transaction in
                        SupabaseTransactionDetailRow(
                            transaction: transaction,
                            stockName: viewModel.getStockName(for: transaction.symbol)
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    SupabasePortfolioView()
}
