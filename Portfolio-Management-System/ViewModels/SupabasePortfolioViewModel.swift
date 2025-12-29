//
//  SupabasePortfolioViewModel.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Sorting Enums

enum HoldingSortOption: String, CaseIterable {
    case ticker = "Ticker"
    case marketValue = "Market value"
    case daysGain = "Day's gain"
    case daysGainPercent = "Day's Gain (%)"
    case totalGain = "Total gain"
    case totalGainPercent = "Total Gain (%)"
}

enum SortDirection: String {
    case ascending = "Low to high"
    case descending = "High to low"
    
    var icon: String {
        self == .descending ? "arrow.down" : "arrow.up"
    }
    
    mutating func toggle() {
        self = self == .ascending ? .descending : .ascending
    }
}

@MainActor
class SupabasePortfolioViewModel: ObservableObject {
    // Shared instance for use across all views
    static let shared = SupabasePortfolioViewModel()
    
    @Published var positions: [SupabasePortfolioPosition] = [] {
        didSet { updateCachedPositions() }
    }
    @Published var cashAccounts: [SupabaseCashAccount] = []
    @Published var cashBalancesNative: [UUID: Decimal] = [:]
    @Published var cashBalancesBase: [UUID: Decimal] = [:]
    @Published var accountUSDValues: [PortfolioDataService.AccountUSDValue] = []
    @Published var stockTransactions: [SupabaseStockTransaction] = []
    @Published var cashTransactions: [SupabaseCashTransaction] = []
    @Published var stocks: [SupabaseStock] = []
    @Published var settings: SupabasePortfolioSettings?
    @Published var snapshot: SupabasePortfolioSnapshot?
    @Published var yesterdaySnapshot: SupabasePortfolioSnapshot?
    @Published var todayChangeValue: Decimal = 0
    @Published var todayChangePercent: Decimal = 0
    @Published var gainLossValue: Decimal = 0
    @Published var gainLossPercent: Decimal = 0
    @Published var latestPrices: [String: Decimal] = [:]
    @Published var previousClosePrices: [String: Decimal] = [:]
    @Published var currencyRatesToUSD: [String: Decimal] = [:]
    
    // Sorting state
    @Published var sortOption: HoldingSortOption = .ticker {
        didSet { updateCachedPositions() }
    }
    @Published var sortDirection: SortDirection = .ascending {
        didSet { updateCachedPositions() }
    }
    
    @Published private(set) var cachedSortedPositions: [SupabasePortfolioPosition] = []
    
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    
    private let dataManager = PortfolioDataManager.shared
    private let authManager = AuthenticationManager() // Using local instance if shared is not available or desired
    private var hasLoadedInitially = false
    private var lastLoadTime: Date?
    
    init() {
        // Load cached data immediately on init
        loadFromCache()
    }
    
    // MARK: - Computed Properties
    
    var baseCurrency: String {
        settings?.baseCurrency ?? "USD"
    }
    
    var totalCashBalance: Decimal {
        if !accountUSDValues.isEmpty {
            return accountUSDValues.reduce(0) { $0 + $1.usdValue }
        }
        return cashBalancesBase.values.reduce(0, +)
    }
    
    var totalHoldingsValue: Decimal {
        positions.reduce(0) { partial, position in
            let price = latestPrices[position.symbol] ?? 0
            let exchangeRate = getExchangeRate(for: position.symbol)
            let marketValueUSD = PortfolioCalculator.marketValueUSD(
                position: position,
                latestPrice: price,
                exchangeRate: exchangeRate
            )
            return partial + marketValueUSD
        }
    }
    
    var totalCostBasis: Decimal {
        positions.reduce(0) { $0 + $1.totalCostBase }
    }
    
    var totalPortfolioValue: Decimal {
        totalCashBalance + totalHoldingsValue
    }
    
    var sortedPositions: [SupabasePortfolioPosition] {
        cachedSortedPositions
    }
    
    // MARK: - Sorting Logic
    
    private func updateCachedPositions() {
        let sorted = positions.sorted { pos1, pos2 in
            let comparison: Bool
            switch sortOption {
            case .ticker:
                comparison = pos1.symbol < pos2.symbol
            case .marketValue:
                comparison = marketValueUSD(for: pos1) > marketValueUSD(for: pos2)
            case .daysGain:
                comparison = daysGainUSD(for: pos1) > daysGainUSD(for: pos2)
            case .daysGainPercent:
                comparison = daysGainPercent(for: pos1) > daysGainPercent(for: pos2)
            case .totalGain:
                comparison = totalGainUSD(for: pos1) > totalGainUSD(for: pos2)
            case .totalGainPercent:
                comparison = totalGainPercent(for: pos1) > totalGainPercent(for: pos2)
            }
            return sortDirection == .descending ? comparison : !comparison
        }
        
        // Only update if changed to avoid redundant UI refreshes
        if cachedSortedPositions != sorted {
            cachedSortedPositions = sorted
        }
    }
    
    // MARK: - Calculation Wrappers
    
    func marketValueUSD(for position: SupabasePortfolioPosition) -> Decimal {
        let price = latestPrices[position.symbol] ?? 0
        let exchangeRate = getExchangeRate(for: position.symbol)
        return PortfolioCalculator.marketValueUSD(position: position, latestPrice: price, exchangeRate: exchangeRate)
    }
    
    func daysGainUSD(for position: SupabasePortfolioPosition) -> Decimal {
        let currentPrice = latestPrices[position.symbol] ?? 0
        let previousPrice = previousClosePrices[position.symbol] ?? currentPrice
        let exchangeRate = getExchangeRate(for: position.symbol)
        return PortfolioCalculator.daysGainUSD(position: position, latestPrice: currentPrice, previousClosePrice: previousPrice, exchangeRate: exchangeRate)
    }
    
    func daysGainPercent(for position: SupabasePortfolioPosition) -> Decimal {
        let currentPrice = latestPrices[position.symbol] ?? 0
        let previousPrice = previousClosePrices[position.symbol] ?? currentPrice
        return PortfolioCalculator.daysGainPercent(latestPrice: currentPrice, previousClosePrice: previousPrice)
    }
    
    func totalGainUSD(for position: SupabasePortfolioPosition) -> Decimal {
        let marketValue = marketValueUSD(for: position)
        return PortfolioCalculator.totalGainUSD(marketValueUSD: marketValue, totalCostBase: position.totalCostBase)
    }
    
    func totalGainPercent(for position: SupabasePortfolioPosition) -> Decimal {
        let gainUSD = totalGainUSD(for: position)
        return PortfolioCalculator.totalGainPercent(totalGainUSD: gainUSD, totalCostBase: position.totalCostBase)
    }
    
    func averageCostPerShareNative(for position: SupabasePortfolioPosition) -> Decimal {
        return PortfolioCalculator.averageCostPerShareNative(position: position)
    }
    
    func transactionCount(for symbol: String) -> Int {
        stockTransactions.filter { $0.symbol == symbol }.count
    }
    
    func dividendIncome(for symbol: String) -> Decimal {
        stockTransactions
            .filter { $0.symbol == symbol && $0.tradeType == .dividend }
            .reduce(Decimal(0)) { $0 + abs($1.baseGrossAmount) }
    }
    
    // MARK: - Cache Loading
    
    private func loadFromCache() {
        guard dataManager.hasCachedData else { return }
        
        let cached = dataManager.loadCachedData()
        
        if let p = cached.positions { self.positions = p }
        if let ca = cached.cashAccounts { self.cashAccounts = ca }
        if let auv = cached.accountUSDValues {
            self.accountUSDValues = auv
            rebuildCashDictionaries(from: auv)
        }
        if let st = cached.stockTransactions { self.stockTransactions = st }
        if let ct = cached.cashTransactions { self.cashTransactions = ct }
        if let s = cached.stocks { self.stocks = s }
        if let lp = cached.latestPrices { self.latestPrices = lp }
        if let cr = cached.currencyRates { self.currencyRatesToUSD = cr }
        if let settings = cached.settings { self.settings = settings }
        if let snapshot = cached.snapshot { self.snapshot = snapshot }
        if let yesterdaySnapshot = cached.yesterdaySnapshot { self.yesterdaySnapshot = yesterdaySnapshot }
        
        if !positions.isEmpty {
            computeSummary()
            hasLoadedInitially = true
            updateCachedPositions()
        }
    }
    
    private func rebuildCashDictionaries(from values: [PortfolioDataService.AccountUSDValue]) {
        var native: [UUID: Decimal] = [:]
        var base: [UUID: Decimal] = [:]
        for item in values {
            native[item.id] = item.nativeBalance
            base[item.id] = item.usdValue
        }
        self.cashBalancesNative = native
        self.cashBalancesBase = base
    }
    
    private func saveToCache() {
        dataManager.saveToCache(
            positions: positions,
            cashAccounts: cashAccounts,
            accountUSDValues: accountUSDValues,
            stockTransactions: stockTransactions,
            cashTransactions: cashTransactions,
            stocks: stocks,
            latestPrices: latestPrices,
            currencyRates: currencyRatesToUSD,
            settings: settings,
            snapshot: snapshot,
            yesterdaySnapshot: yesterdaySnapshot
        )
    }
    
    // MARK: - Load Data
    
    func loadPortfolioData() async {
        if hasLoadedInitially {
            await refreshPricesOnly()
            return
        }
        await loadAllData()
    }
    
    private func loadAllData() async {
        if !dataManager.hasCachedData {
            isLoading = true
        } else {
            isRefreshing = true
        }
        errorMessage = nil
        
        do {
            let result = try await dataManager.fetchAllData()
            
            self.settings = result.settings
            self.positions = result.positions
            self.cashAccounts = result.accounts
            self.stockTransactions = result.stockTransactions
            self.cashTransactions = result.cashTransactions
            self.stocks = result.stocks
            self.snapshot = result.snapshot
            self.yesterdaySnapshot = result.yesterdaySnapshot
            
            await loadLatestPrices()
            await loadPreviousClosePrices()
            await loadCurrencyRates()
            await loadCashBalances()
            computeSummary()
            
            saveToCache()
            hasLoadedInitially = true
            lastLoadTime = Date()
            updateCachedPositions()
            
        } catch {
            self.errorMessage = "Failed to load portfolio: \(error.localizedDescription)"
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    private func refreshPricesOnly() async {
        let refreshInterval: TimeInterval = 20 * 60
        if let lastLoad = lastLoadTime, Date().timeIntervalSince(lastLoad) < refreshInterval {
            return
        }
        
        isRefreshing = true
        await loadLatestPrices()
        computeSummary()
        
        dataManager.saveToCache(positions: nil, cashAccounts: nil, accountUSDValues: nil, stockTransactions: nil, cashTransactions: nil, stocks: nil, latestPrices: latestPrices, currencyRates: nil, settings: nil, snapshot: nil, yesterdaySnapshot: nil)
        
        lastLoadTime = Date()
        isRefreshing = false
    }
    
    func forceRefresh() async {
        hasLoadedInitially = false
        lastLoadTime = nil
        await loadAllData()
    }
    
    // MARK: - Load Cash Balances
    
    private func loadCashBalances() async {
        do {
            // Fix: Use authenticated user's email instead of hardcoded value
            let userEmail = authManager.currentUser?.email ?? "mike.zhang09@gmail.com"
            let result = try await dataManager.computeCashBalancesUSD(userEmail: userEmail)
            self.accountUSDValues = result.accounts
            rebuildCashDictionaries(from: result.accounts)
        } catch {
            // Fallback handled in DataManager or skip for now
        }
    }
    
    private func computeSummary() {
        let holdingsValue = totalHoldingsValue
        let cashValue = totalCashBalance
        
        let calendar = Calendar.current
        let externalFlowLegs: Set<CashTransactionLegType> = [.deposit, .withdrawal, .dividend, .fee, .adjustment, .interest]
        let todayCashFlow = cashTransactions
            .filter { tx in
                calendar.isDateInToday(tx.occurredAt) && externalFlowLegs.contains(tx.legType)
            }
            .reduce(Decimal(0)) { partial, tx in
                let amount = tx.baseAmount
                return partial + (tx.direction == .inflow ? abs(amount) : -abs(amount))
            }
        
        let summary = PortfolioCalculator.calculateSummary(
            totalHoldingsValue: holdingsValue,
            totalCashBalance: cashValue,
            yesterdayTotalValue: yesterdaySnapshot?.totalValue,
            todayCashFlow: todayCashFlow,
            totalCostBasis: totalCostBasis
        )
        
        self.todayChangeValue = summary.todayChangeValue
        self.todayChangePercent = summary.todayChangePercent
        self.gainLossValue = summary.gainLossValue
        self.gainLossPercent = summary.gainLossPercent
    }
    
    // MARK: - Load Helpers
    
    private func loadLatestPrices() async {
        let stockSymbols = stocks.map { $0.symbol }
        let symbols = stockSymbols.isEmpty ? positions.map { $0.symbol } : stockSymbols
        guard !symbols.isEmpty else { return }
        
        do {
            let prices = try await dataManager.fetchLatestPrices(symbols: symbols)
            self.latestPrices = prices
        } catch {
            if let cached = dataManager.loadCachedData().latestPrices {
                self.latestPrices = cached
            }
        }
    }
    
    private func loadPreviousClosePrices() async {
        let stockSymbols = stocks.map { $0.symbol }
        let symbols = stockSymbols.isEmpty ? positions.map { $0.symbol } : stockSymbols
        guard !symbols.isEmpty else { return }
        
        do {
            let prices = try await dataManager.fetchPreviousClosePrices(symbols: symbols)
            self.previousClosePrices = prices
        } catch {}
    }
    
    private func loadCurrencyRates() async {
        do {
            let rates = try await dataManager.fetchCurrencyRates()
            self.currencyRatesToUSD = rates
        } catch {}
    }
    
    // MARK: - Helper Methods
    
    func getExchangeRate(for symbol: String) -> Decimal {
        guard let stock = stocks.first(where: { $0.symbol == symbol }) else {
            return 1
        }
        
        let market = stock.market?.uppercased().trimmingCharacters(in: .whitespaces) ?? "US"
        
        switch market {
        case "US": return 1
        case "HK": return currencyRatesToUSD["HKD"] ?? Decimal(1) / Decimal(7.78)
        case "CN": return currencyRatesToUSD["CNY"] ?? Decimal(1) / Decimal(7.25)
        default:
            if let currency = stock.currency?.uppercased().trimmingCharacters(in: .whitespaces),
               currency != "USD" {
                return currencyRatesToUSD[currency] ?? 1
            }
            return 1
        }
    }
    
    func getStockName(for symbol: String) -> String? {
        stocks.first { $0.symbol == symbol }?.name
    }

    // MARK: - Transaction & Stock Management (Proxies to DataManager/Service)

    func createTransactionGroup(groupType: TransactionGroupType, status: TransactionStatus, occurredAt: Date, settledAt: Date?, notes: String?, externalRef: String?) async throws -> SupabaseTransactionGroup {
        try await PortfolioDataService.shared.createTransactionGroup(groupType: groupType, status: status, occurredAt: occurredAt, settledAt: settledAt, notes: notes, externalRef: externalRef)
    }

    func createCashTransaction(groupId: UUID, cashAccountId: UUID, legType: CashTransactionLegType, direction: CashTransactionDirection, amount: Decimal, currency: String, fxRate: Decimal, baseAmount: Decimal, occurredAt: Date, settledAt: Date, relatedStockTransactionId: UUID?, notes: String?) async throws -> SupabaseCashTransaction {
        let tx = try await PortfolioDataService.shared.createCashTransaction(groupId: groupId, cashAccountId: cashAccountId, legType: legType, direction: direction, amount: amount, currency: currency, fxRate: fxRate, baseAmount: baseAmount, occurredAt: occurredAt, settledAt: settledAt, relatedStockTransactionId: relatedStockTransactionId, notes: notes)
        cashTransactions.insert(tx, at: 0)
        saveToCache()
        return tx
    }

    func createStockTransaction(groupId: UUID, stockId: UUID, symbol: String, tradeType: StockTradeType, tradeDate: Date, settlementDate: Date?, quantity: Decimal, pricePerShare: Decimal, grossAmount: Decimal, fees: Decimal, currency: String, fxRate: Decimal, baseGrossAmount: Decimal, baseFees: Decimal, status: TransactionStatus, notes: String?) async throws -> SupabaseStockTransaction {
        let tx = try await PortfolioDataService.shared.createStockTransaction(groupId: groupId, stockId: stockId, symbol: symbol, tradeType: tradeType, tradeDate: tradeDate, settlementDate: settlementDate, quantity: quantity, pricePerShare: pricePerShare, grossAmount: grossAmount, fees: fees, currency: currency, fxRate: fxRate, baseGrossAmount: baseGrossAmount, baseFees: baseFees, status: status, notes: notes)
        stockTransactions.insert(tx, at: 0)
        saveToCache()
        return tx
    }
    
    func addStock(symbol: String, name: String, market: String, exchange: String?) async throws {
        try await PortfolioDataService.shared.createStock(symbol: symbol, name: name, market: market, exchange: exchange)
        self.stocks = try await PortfolioDataService.shared.fetchStocks()
        saveToCache()
    }
    
    func addCashAccount(currency: String, displayName: String) async throws {
        let account = try await PortfolioDataService.shared.createCashAccount(currency: currency, displayName: displayName)
        
        // Add the new account to the local cache
        cashAccounts.append(account)
        cashAccounts.sort { $0.displayName < $1.displayName }
        
        // Create a new account value entry
        let exchangeRate = currencyRatesToUSD[currency.uppercased()] ?? 1.0
        let newAccountValue = PortfolioDataService.AccountUSDValue(
            id: account.id,
            displayName: displayName,
            nativeCurrency: currency.uppercased(),
            nativeBalance: 0,
            exchangeRate: exchangeRate,
            usdValue: 0
        )
        accountUSDValues.append(newAccountValue)
        accountUSDValues.sort { $0.displayName < $1.displayName }
        
        // Update cash balances
        cashBalancesNative[account.id] = 0
        cashBalancesBase[account.id] = 0
        
        // Save to cache
        saveToCache()
    }
    
    func updateStock(id: UUID, name: String, exchange: String?) async throws {
        try await PortfolioDataService.shared.updateStock(id: id, name: name, exchange: exchange)
        self.stocks = try await PortfolioDataService.shared.fetchStocks()
        saveToCache()
    }
    
    func deleteStock(_ stock: SupabaseStock) async {
        do {
            try await PortfolioDataService.shared.deleteStock(id: stock.id)
            stocks.removeAll { $0.id == stock.id }
            saveToCache()
        } catch {
            errorMessage = "Failed to delete stock: \(error.localizedDescription)"
        }
    }
    
    func fetchStockPreview(symbol: String, market: String?) async throws -> StockLookupResponse {
        try await PortfolioDataService.shared.fetchStockData(symbol: symbol, market: market)
    }
}
