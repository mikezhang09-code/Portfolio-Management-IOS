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
                        
                        // Holdings Section
                        if !viewModel.positions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Holdings Header with Sort Button
                                HStack {
                                    Text("All")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(16)
                                    
                                    Spacer()
                                    
                                    Text("Sort by")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
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
                                    
                                    if viewModel.isRefreshing {
                                        ProgressView()
                                            .scaleEffect(0.7)
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
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
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

// MARK: - Holdings Sort Sheet

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
                
                Button {
                    isPresented = false
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(Color(.systemBackground))
    }
}

// MARK: - Expandable Position Row

struct ExpandablePositionRow: View {
    let position: SupabasePortfolioPosition
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    let isExpanded: Bool
    let onToggle: () -> Void

    @State private var activeSheet: ActiveSheet?
    
    private var daysGainPercent: Decimal {
        viewModel.daysGainPercent(for: position)
    }
    
    private var totalGainPercent: Decimal {
        viewModel.totalGainPercent(for: position)
    }

    private var daysGainValue: Decimal {
        viewModel.daysGainUSD(for: position)
    }

    private var totalGainValue: Decimal {
        viewModel.totalGainUSD(for: position)
    }
    
    private var marketValue: Decimal {
        viewModel.marketValueUSD(for: position)
    }
    
    private var currentPrice: Decimal {
        viewModel.latestPrices[position.symbol] ?? 0
    }
    
    private var stockName: String? {
        viewModel.getStockName(for: position.symbol)
    }
    
    private var isMarketValueSort: Bool {
        viewModel.sortOption == .marketValue
    }

    private var isDaysGainSort: Bool {
        viewModel.sortOption == .daysGain || viewModel.sortOption == .daysGainPercent
    }

    private var isTotalGainSort: Bool {
        viewModel.sortOption == .totalGain || viewModel.sortOption == .totalGainPercent
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row (always visible)
            Button(action: onToggle) {
                if isMarketValueSort {
                    // Market value sort view: price on left, market value on right with total gain % below
                    HStack {
                        // Left: Current price and percentage change
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(position.symbol)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Open")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            
                            if currentPrice > 0 {
                                Text(formatPrice(currentPrice))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(formatPercent(daysGainPercent))
                                    .font(.caption)
                                    .foregroundStyle(daysGainPercent >= 0 ? .green : .red)
                            }
                        }
                        
                        Spacer()
                        
                        // Right: Market value with total gain % below
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatNumber(marketValue))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(formatPercent(totalGainPercent) + " Total")
                                .font(.caption2)
                                .foregroundStyle(totalGainPercent >= 0 ? .green : .red)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                } else {
                    // Default view: ticker, name, price, percentage change (no chart)
                    HStack {
                        defaultLeftContent
                        
                        Spacer()

                        if isDaysGainSort {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatSignedValue(daysGainValue, percent: nil))
                                    .font(.headline)
                                    .foregroundStyle(daysGainValue >= 0 ? .green : .red)
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        } else if isTotalGainSort {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatSignedValue(totalGainValue, percent: totalGainPercent))
                                    .font(.headline)
                                    .foregroundStyle(totalGainValue >= 0 ? .green : .red)
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        } else {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 0) {
                    // Detail rows
                    VStack(spacing: 12) {
                        detailRow("Avg. cost / share", value: formatDecimal(viewModel.averageCostPerShareNative(for: position)))
                        detailRow("Total cost", value: formatNumber(position.totalCostBase))
                        
                        Divider()

                        detailRow("Day's gain", value: formatSignedValue(viewModel.daysGainUSD(for: position), percent: daysGainPercent), valueColor: viewModel.daysGainUSD(for: position) >= 0 ? .green : .red)
                        detailRow("Total gain", value: formatSignedValue(viewModel.totalGainUSD(for: position), percent: totalGainPercent), valueColor: viewModel.totalGainUSD(for: position) >= 0 ? .green : .red)
                        detailRow("Market value", value: formatNumber(marketValue))

                        Divider()

                        // Shares row with navigation
                        HStack {
                            Text("Shares")
                                .foregroundStyle(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(formatDecimal(position.totalShares))
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.primary)
                        }
                        .font(.subheadline)

                        // Transactions row with navigation
                        Button {
                            activeSheet = .transactions
                        } label: {
                            HStack {
                                Text("Transactions")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("\(viewModel.transactionCount(for: position.symbol)) total")
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundStyle(.primary)
                            }
                            .font(.subheadline)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        // Total dividend income
                        detailRow("Total dividend income", value: formatNumber(viewModel.dividendIncome(for: position.symbol)))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    
                    // Add transaction button
                    HStack {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add transaction")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        activeSheet = .addTransaction
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .transactions:
                StockTransactionsSheet(
                    viewModel: viewModel,
                    symbol: position.symbol,
                    stockName: stockName
                )
            case .addTransaction:
                AddSupabaseTransactionView(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { activeSheet == .addTransaction },
                        set: { newValue in
                            if !newValue {
                                activeSheet = nil
                            }
                        }
                    ),
                    preselectedSymbol: position.symbol
                )
            }
        }
    }
    
    private func detailRow(_ label: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
        }
        .font(.subheadline)
    }
    
    private func formatPrice(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter.string(from: number) ?? "0.00"
    }
    
    private func formatPercent(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+"
        formatter.negativePrefix = ""
        let formatted = formatter.string(from: number) ?? "0.00"
        return formatted + "%"
    }
    
    private func formatNumber(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: number) ?? "0"
    }
    
    private func formatDecimal(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: number) ?? "0.00"
    }
    
    private func formatSignedValue(_ value: Decimal, percent: Decimal?) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        let valueStr = formatter.string(from: number) ?? "0.00"
        
        if let pct = percent {
            let pctNumber = NSDecimalNumber(decimal: pct)
            let pctFormatter = NumberFormatter()
            pctFormatter.numberStyle = .decimal
            pctFormatter.maximumFractionDigits = 2
            pctFormatter.minimumFractionDigits = 2
            pctFormatter.positivePrefix = "+"
            pctFormatter.negativePrefix = ""
            let pctStr = pctFormatter.string(from: pctNumber) ?? "0.00"
            return "\(valueStr) (\(pctStr)%)"
        }
        return valueStr
    }

    private var defaultLeftContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(position.symbol)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            if let name = stockName {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            if currentPrice > 0 {
                HStack(spacing: 8) {
                    Text(formatPrice(currentPrice))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(formatPercent(daysGainPercent))
                        .font(.caption)
                        .foregroundStyle(daysGainPercent >= 0 ? .green : .red)
                }
            }
        }
    }
}

private enum ActiveSheet: Identifiable {
    case transactions
    case addTransaction

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
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading transactions...")
                        .frame(maxWidth: .infinity)
                } else if filteredTransactions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No transactions yet")
                            .font(.headline)
                        Text("Add a transaction to see activity for this stock.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(filteredTransactions.count) Transactions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

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
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .navigationTitle(stockName ?? symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
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
