//
//  SupabasePortfolioViewModel.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SupabasePortfolioViewModel: ObservableObject {
    // Shared instance for use across all views
    static let shared = SupabasePortfolioViewModel()
    
    @Published var positions: [SupabasePortfolioPosition] = []
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
    @Published var currencyRatesToUSD: [String: Decimal] = [:]
    
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    
    private let dataService = PortfolioDataService.shared
    private let cacheService = PortfolioCacheService.shared
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
            let marketValueLocal = price * position.totalShares
            let exchangeRate = getExchangeRate(for: position.symbol)
            let marketValueUSD = marketValueLocal * exchangeRate
            return partial + marketValueUSD
        }
    }
    
    var totalCostBasis: Decimal {
        // totalCostBase is already in base currency (USD) and includes shares
        // No FX conversion needed
        positions.reduce(0) { $0 + $1.totalCostBase }
    }
    
    var totalPortfolioValue: Decimal {
        totalCashBalance + totalHoldingsValue
    }
    
    // Sorted positions by market value (descending)
    var sortedPositions: [SupabasePortfolioPosition] {
        positions.sorted { pos1, pos2 in
            let value1 = marketValueUSD(for: pos1)
            let value2 = marketValueUSD(for: pos2)
            return value1 > value2
        }
    }
    
    private func marketValueUSD(for position: SupabasePortfolioPosition) -> Decimal {
        let price = latestPrices[position.symbol] ?? 0
        let marketValueLocal = price * position.totalShares
        let exchangeRate = getExchangeRate(for: position.symbol)
        return marketValueLocal * exchangeRate
    }
    
    // MARK: - Cache Loading
    
    private func loadFromCache() {
        guard cacheService.hasCachedData else { return }
        
        if let cached = cacheService.loadCachedPositions() {
            self.positions = cached
        }
        if let cached = cacheService.loadCachedCashAccounts() {
            self.cashAccounts = cached
        }
        if let cached = cacheService.loadCachedAccountUSDValues() {
            self.accountUSDValues = cached.map { $0.toAccountUSDValue() }
            // Rebuild native/base dictionaries
            var native: [UUID: Decimal] = [:]
            var base: [UUID: Decimal] = [:]
            for item in self.accountUSDValues {
                native[item.id] = item.nativeBalance
                base[item.id] = item.usdValue
            }
            self.cashBalancesNative = native
            self.cashBalancesBase = base
        }
        if let cached = cacheService.loadCachedStockTransactions() {
            self.stockTransactions = cached
        }
        if let cached = cacheService.loadCachedStocks() {
            self.stocks = cached
        }
        if let cached = cacheService.loadCachedLatestPrices() {
            self.latestPrices = cached
        }
        if let cached = cacheService.loadCachedCurrencyRates() {
            self.currencyRatesToUSD = cached
        }
        if let cached = cacheService.loadCachedSettings() {
            self.settings = cached
        }
        if let cached = cacheService.loadCachedSnapshot() {
            self.snapshot = cached
        }
        if let cached = cacheService.loadCachedYesterdaySnapshot() {
            self.yesterdaySnapshot = cached
        }
        
        // Recompute summary from cached data
        if !positions.isEmpty {
            computeSummary()
            hasLoadedInitially = true
            print("[Portfolio] Loaded from cache: \(positions.count) positions, \(accountUSDValues.count) accounts")
        }
    }
    
    private func saveToCache() {
        cacheService.cachePositions(positions)
        cacheService.cacheCashAccounts(cashAccounts)
        cacheService.cacheAccountUSDValues(accountUSDValues.map { CachedAccountUSDValue(from: $0) })
        cacheService.cacheStockTransactions(stockTransactions)
        cacheService.cacheStocks(stocks)
        cacheService.cacheLatestPrices(latestPrices)
        cacheService.cacheCurrencyRates(currencyRatesToUSD)
        if let settings = settings {
            cacheService.cacheSettings(settings)
        }
        if let snapshot = snapshot {
            cacheService.cacheSnapshot(snapshot)
        }
        if let yesterdaySnapshot = yesterdaySnapshot {
            cacheService.cacheYesterdaySnapshot(yesterdaySnapshot)
        }
        cacheService.updateCacheTime()
        print("[Portfolio] Saved to cache")
    }
    
    // MARK: - Load Data
    
    /// Main load method - only fetches all data on first login or manual refresh
    /// For tab switches, uses cached data + refreshes prices only
    func loadPortfolioData() async {
        // If already loaded, just refresh prices (fast)
        if hasLoadedInitially {
            await refreshPricesOnly()
            return
        }
        
        // First load - fetch everything
        await loadAllData()
    }
    
    /// Full data load - called on login or manual refresh
    private func loadAllData() async {
        // Show loading only on first load when no cache
        if !cacheService.hasCachedData {
            isLoading = true
        } else {
            isRefreshing = true
        }
        errorMessage = nil
        
        do {
            // Load all data in parallel
            async let settingsTask = dataService.fetchPortfolioSettings()
            async let positionsTask = dataService.fetchPortfolioPositions()
            async let accountsTask = dataService.fetchCashAccounts()
            async let stockTransactionsTask = dataService.fetchStockTransactions(limit: 50)
            async let cashTransactionsTask = dataService.fetchCashTransactions(limit: 50)
            async let stocksTask = dataService.fetchStocks()
            async let snapshotTask = dataService.fetchLatestSnapshot()
            async let yesterdaySnapshotTask = dataService.fetchYesterdaySnapshot()
            
            // Await all results
            let (settingsResult, positionsResult, accountsResult, stockTxResult, cashTxResult, stocksResult, snapshotResult, yesterdaySnapshotResult) = try await (
                settingsTask,
                positionsTask,
                accountsTask,
                stockTransactionsTask,
                cashTransactionsTask,
                stocksTask,
                snapshotTask,
                yesterdaySnapshotTask
            )
            
            // Update state
            self.settings = settingsResult
            self.positions = positionsResult
            self.cashAccounts = accountsResult
            self.stockTransactions = stockTxResult
            self.cashTransactions = cashTxResult
            self.stocks = stocksResult
            self.snapshot = snapshotResult
            self.yesterdaySnapshot = yesterdaySnapshotResult
            
            // Fetch latest prices and currency rates for all positions
            await loadLatestPrices()
            await loadCurrencyRates()
            
            // Calculate cash balances and summary metrics
            await loadCashBalances()
            computeSummary()
            
            print("[Portfolio] Full load: \(positions.count) positions, \(cashAccounts.count) cash accounts, \(stockTransactions.count) transactions")
            
            // Save to cache for next time
            saveToCache()
            
            hasLoadedInitially = true
            lastLoadTime = Date()
            
        } catch let error as APIError {
            self.errorMessage = error.localizedDescription
            print("[Portfolio] Error: \(error.localizedDescription)")
        } catch {
            self.errorMessage = "Failed to load portfolio data"
            print("[Portfolio] Error: \(error.localizedDescription)")
        }
        
        isLoading = false
        isRefreshing = false
    }
    
    /// Lightweight refresh - only updates prices (for tab switches)
    private func refreshPricesOnly() async {
        // Skip if refreshed recently (within 20 minutes)
        let refreshInterval: TimeInterval = 20 * 60 // 20 minutes
        if let lastLoad = lastLoadTime, Date().timeIntervalSince(lastLoad) < refreshInterval {
            return
        }
        
        isRefreshing = true
        await loadLatestPrices()
        computeSummary()
        
        // Update cache with new prices
        cacheService.cacheLatestPrices(latestPrices)
        cacheService.updateCacheTime()
        
        lastLoadTime = Date()
        isRefreshing = false
        print("[Portfolio] Prices refreshed")
    }
    
    /// Manual refresh - reloads everything including cash and transactions
    func forceRefresh() async {
        hasLoadedInitially = false
        lastLoadTime = nil
        await loadAllData()
    }
    
    // MARK: - Load Cash Balances
    
    private func loadCashBalances() async {
        // Compute via SQL-equivalent path to match server screenshot
        do {
            let result = try await dataService.computeCashBalancesUSD(userEmail: "mike.zhang09@gmail.com")
            self.accountUSDValues = result.accounts
            // Map back to per-account native/base for UI that expects those dictionaries
            var native: [UUID: Decimal] = [:]
            var base: [UUID: Decimal] = [:]
            for item in result.accounts {
                native[item.id] = item.nativeBalance
                base[item.id] = item.usdValue
            }
            self.cashBalancesNative = native
            self.cashBalancesBase = base
        } catch {
            // Fallback: local aggregation from transactions
            var nativeBalances: [UUID: Decimal] = [:]
            var baseBalances: [UUID: Decimal] = [:]
            
            for account in cashAccounts {
                let accountTransactions = cashTransactions.filter { $0.cashAccountId == account.id }
                var native: Decimal = 0
                var base: Decimal = 0
                
                for transaction in accountTransactions {
                    let nativeSigned = transaction.direction == .inflow ? transaction.amount : -transaction.amount
                    native += nativeSigned
                    base += transaction.baseAmount
                }
                nativeBalances[account.id] = native
                baseBalances[account.id] = base
            }
            
            self.cashBalancesNative = nativeBalances
            self.cashBalancesBase = baseBalances
        }
    }
    
    private func computeSummary() {
        let holdingsValue = totalHoldingsValue
        let cashValue = totalCashBalance
        let currentTotal = holdingsValue + cashValue
        
        // Calculate today's external cash flow only (exclude internal movements)
        // Only: deposit, withdrawal, dividend, fee, adjustment, interest
        // Exclude: fx_in, fx_out, stock_buy, stock_sell (internal movements)
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
        
        // Today's Change = Current Value - Yesterday's Snapshot - Today's Cash Flow
        // This isolates market performance from cash movements
        if let yesterdayValue = yesterdaySnapshot?.totalValue {
            let changeValue = currentTotal - yesterdayValue - todayCashFlow
            let baseline = yesterdayValue + todayCashFlow
            let changePercent = baseline != 0 ? changeValue / baseline : 0
            self.todayChangeValue = changeValue
            self.todayChangePercent = changePercent
        } else {
            // No snapshot available - show 0
            self.todayChangeValue = 0
            self.todayChangePercent = 0
        }
        
        // Stock Gain/Loss = Holdings Value - Cost Basis (both in USD)
        let costBasis = totalCostBasis
        let gainValue = holdingsValue - costBasis
        let gainPercent = costBasis != 0 ? gainValue / costBasis : 0
        
        self.gainLossValue = gainValue
        self.gainLossPercent = gainPercent
        
        print("[Portfolio] Summary: Total=\(currentTotal), Holdings=\(holdingsValue), Cash=\(cashValue), Change=\(todayChangeValue), Gain=\(gainLossValue)")
    }
    
    // MARK: - Load Latest Prices
    
    private func loadLatestPrices() async {
        let symbols = positions.map { $0.symbol }
        guard !symbols.isEmpty else { return }
        
        do {
            // Batch fetch all prices in one query (much faster)
            let prices = try await dataService.fetchLatestPrices(symbols: symbols)
            self.latestPrices = prices
            print("[Portfolio] Loaded prices for \(prices.count)/\(symbols.count) symbols")
        } catch {
            print("[Portfolio] Failed to batch fetch prices: \(error.localizedDescription)")
            // Fallback: use cached prices if available
            if let cached = cacheService.loadCachedLatestPrices(), !cached.isEmpty {
                self.latestPrices = cached
                print("[Portfolio] Using \(cached.count) cached prices as fallback")
            }
        }
    }
    
    // MARK: - Load Currency Rates
    
    private func loadCurrencyRates() async {
        do {
            let rates = try await dataService.fetchCurrencyRatesToUSD()
            self.currencyRatesToUSD = rates
            print("[Portfolio] Loaded \(rates.count) currency rates")
        } catch {
            print("[Portfolio] Failed to fetch currency rates: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    func getExchangeRate(for symbol: String) -> Decimal {
        guard let stock = stocks.first(where: { $0.symbol == symbol }) else {
            return 1
        }
        
        // Use market field like web app (US, HK, CN)
        let market = stock.market?.uppercased().trimmingCharacters(in: .whitespaces) ?? "US"
        
        switch market {
        case "US":
            return 1
        case "HK":
            // HKD to USD rate
            return currencyRatesToUSD["HKD"] ?? Decimal(1) / Decimal(7.78)
        case "CN":
            // CNY to USD rate
            return currencyRatesToUSD["CNY"] ?? Decimal(1) / Decimal(7.25)
        default:
            // Fallback to currency field if available
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
    
    func refreshData() async {
        await loadPortfolioData()
    }
}
