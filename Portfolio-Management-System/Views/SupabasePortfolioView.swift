//
//  SupabasePortfolioView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI
import Foundation

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
            PortfolioHeroCard(
                totalValue: viewModel.totalPortfolioValue,
                dayChangeValue: viewModel.todayChangeValue,
                dayChangePercent: viewModel.todayChangePercent,
                gainLossValue: viewModel.gainLossValue,
                gainLossPercent: viewModel.gainLossPercent,
                cashValue: viewModel.totalCashBalance,
                holdingsValue: viewModel.totalHoldingsValue,
                baseCurrency: viewModel.baseCurrency
            )
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
                Text("All Holdings")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                
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
                        totalPortfolioValue: viewModel.totalPortfolioValue,
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
    let totalPortfolioValue: Decimal
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
            allocationPercent: allocationPercent(for: position),
            totalGainPercent: viewModel.totalGainPercent(for: position),
            daysGainValue: viewModel.daysGainUSD(for: position),
            totalGainValue: viewModel.totalGainUSD(for: position),
            currency: stockCurrency(for: position.symbol),
            market: stockMarket(for: position.symbol)
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
    
    private func allocationPercent(for position: SupabasePortfolioPosition) -> Decimal {
        let total = totalPortfolioValue
        guard total > 0 else { return 0 }
        let share = viewModel.marketValueUSD(for: position) / total
        return share * 100
    }
    
    private func stockCurrency(for symbol: String) -> String? {
        viewModel.stocks.first(where: { $0.symbol == symbol })?.currency?.uppercased()
    }
    
    private func stockMarket(for symbol: String) -> String? {
        viewModel.stocks.first(where: { $0.symbol == symbol })?.market?.uppercased()
    }
}

// MARK: - Hero Summary Card

private struct PortfolioHeroCard: View {
    let totalValue: Decimal
    let dayChangeValue: Decimal
    let dayChangePercent: Decimal
    let gainLossValue: Decimal
    let gainLossPercent: Decimal
    let cashValue: Decimal
    let holdingsValue: Decimal
    let baseCurrency: String
    
    private var totalDouble: Double { NSDecimalNumber(decimal: totalValue).doubleValue }
    
    private var allocation: (cash: Double, stocks: Double) {
        let total = max(NSDecimalNumber(decimal: cashValue + holdingsValue).doubleValue, 0.0001)
        let cashPortion = min(NSDecimalNumber(decimal: cashValue).doubleValue / total, 1)
        let stockPortion = min(NSDecimalNumber(decimal: holdingsValue).doubleValue / total, 1)
        return (cash: cashPortion, stocks: stockPortion)
    }
    
    private var sparklinePoints: [Double] {
        [0.18, 0.35, 0.3, 0.52, 0.45, 0.62, 0.58, 0.74, 0.68, 0.9]
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.85), Color.blue.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.25)
                )
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
            
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text("Total value")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(baseCurrency.uppercased())
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2))
                                .foregroundStyle(.white.opacity(0.9))
                                .clipShape(Capsule())
                        }
                        Text(PortfolioFormatter.formatUSD(totalValue))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    HeroSparkline(points: sparklinePoints)
                        .frame(width: 96, height: 48)
                        .opacity(0.9)
                }
                
                HStack(spacing: 12) {
                    gainPill(
                        title: "Today",
                        value: dayChangeValue,
                        percent: dayChangePercent
                    )
                    
                    gainPill(
                        title: "Total",
                        value: gainLossValue,
                        percent: gainLossPercent
                    )
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Allocation")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        Text("Cash \(PortfolioFormatter.formatUSD(cashValue)) | Stocks \(PortfolioFormatter.formatUSD(holdingsValue))")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    GeometryReader { geo in
                        let totalWidth = geo.size.width
                        let cashWidth = totalWidth * allocation.cash
                        let stocksWidth = totalWidth * allocation.stocks
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.12))
                                .frame(height: 10)
                            
                            HStack(spacing: 0) {
                                Capsule()
                                    .fill(Color.white.opacity(0.85))
                                    .frame(width: cashWidth, height: 10)
                                Capsule()
                                    .fill(Color.green.opacity(0.9))
                                    .frame(width: stocksWidth, height: 10)
                            }
                        }
                    }
                    .frame(height: 10)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func gainPill(title: String, value: Decimal, percent: Decimal) -> some View {
        let isPositive = value >= 0
        let displayPercent = percent * 100  // Convert decimal to percentage (0.01 -> 1%)
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text(PortfolioFormatter.formatSignedUSD(value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(PortfolioFormatter.formatPercent(displayPercent))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isPositive ? Color.white.opacity(0.16) : Color.red.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct HeroSparkline: View {
    let points: [Double]
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let normalized = normalize(points: points)
            let step = width / CGFloat(max(normalized.count - 1, 1))
            
            Path { path in
                guard let first = normalized.first else { return }
                path.move(to: CGPoint(x: 0, y: height - height * CGFloat(first)))
                for (index, value) in normalized.enumerated() where index > 0 {
                    let x = CGFloat(index) * step
                    let y = height - height * CGFloat(value)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.8), .white.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
    
    private func normalize(points: [Double]) -> [Double] {
        guard let min = points.min(), let max = points.max(), max - min > 0 else { return points }
        return points.map { ($0 - min) / (max - min) * 0.85 + 0.05 }
    }
}

// MARK: - Position Sub-components

struct PositionSummaryData {
    let symbol: String
    let name: String?
    let currentPrice: Decimal
    let daysGainPercent: Decimal
    let marketValue: Decimal
    let allocationPercent: Decimal
    let totalGainPercent: Decimal
    let daysGainValue: Decimal
    let totalGainValue: Decimal
    let currency: String?
    let market: String?
}

struct PositionSummaryRow: View {
    let data: PositionSummaryData
    let isExpanded: Bool
    let sortOption: HoldingSortOption
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(data.symbol)
                        .font(.headline.weight(.semibold))
                    if let currency = data.currency {
                        Text(currency)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                    if let market = data.market {
                        Text(market)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if data.currentPrice > 0 {
                    HStack(spacing: 10) {
                        Text(PortfolioFormatter.formatPrice(data.currentPrice))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(PortfolioFormatter.formatPercent(data.daysGainPercent))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((data.daysGainPercent >= 0 ? Color.green : Color.red).opacity(0.12))
                            .foregroundStyle(data.daysGainPercent >= 0 ? .green : .red)
                            .clipShape(Capsule())
                    }
                } else if let name = data.name {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(PortfolioFormatter.formatNumber(data.marketValue))
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(PortfolioFormatter.formatPercent(data.allocationPercent))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
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
            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Performance")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        detailRow("Day's gain", value: PortfolioFormatter.formatSignedValue(summaryData.daysGainValue, percent: summaryData.daysGainPercent), valueColor: summaryData.daysGainValue >= 0 ? .green : .red)
                        detailRow("Total gain", value: PortfolioFormatter.formatSignedValue(summaryData.totalGainValue, percent: summaryData.totalGainPercent), valueColor: summaryData.totalGainValue >= 0 ? .green : .red)
                        detailRow("Dividend income", value: PortfolioFormatter.formatNumber(viewModel.dividendIncome(for: position.symbol)))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cost & Qty")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        detailRow("Avg cost / share", value: PortfolioFormatter.formatDecimal(viewModel.averageCostPerShareNative(for: position)))
                        detailRow("Shares", value: PortfolioFormatter.formatDecimal(position.totalShares))
                        detailRow("Market value", value: PortfolioFormatter.formatNumber(summaryData.marketValue))
                        detailRow("Total cost", value: PortfolioFormatter.formatNumber(position.totalCostBase))
                    }
                }
                
                Button(action: onShowTransactions) {
                    HStack {
                        Text("View transactions")
                        Spacer()
                        HStack(spacing: 6) {
                            Text("\(viewModel.transactionCount(for: position.symbol))")
                            Image(systemName: "chevron.right").font(.caption)
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemGray6))
            
            Button(action: onAddTransaction) {
                HStack {
                    Image(systemName: "plus").font(.caption)
                    Text("Add transaction").font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
            }
            .buttonStyle(.plain)
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


