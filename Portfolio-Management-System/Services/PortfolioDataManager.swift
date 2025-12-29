//
//  PortfolioDataManager.swift
//  Portfolio-Management-System
//
//  Created by Antigravity on 2025/12/29.
//

import Foundation

class PortfolioDataManager {
    static let shared = PortfolioDataManager()
    
    private let dataService = PortfolioDataService.shared
    private let cacheService = PortfolioCacheService.shared
    
    private init() {}
    
    // MARK: - Data Fetching
    
    func fetchAllData() async throws -> (
        settings: SupabasePortfolioSettings?,
        positions: [SupabasePortfolioPosition],
        accounts: [SupabaseCashAccount],
        stockTransactions: [SupabaseStockTransaction],
        cashTransactions: [SupabaseCashTransaction],
        stocks: [SupabaseStock],
        snapshot: SupabasePortfolioSnapshot?,
        yesterdaySnapshot: SupabasePortfolioSnapshot?
    ) {
        async let settingsTask = dataService.fetchPortfolioSettings()
        async let positionsTask = dataService.fetchPortfolioPositions()
        async let accountsTask = dataService.fetchCashAccounts()
        async let stockTransactionsTask = dataService.fetchStockTransactions(limit: 500)
        async let cashTransactionsTask = dataService.fetchCashTransactions(limit: 50)
        async let stocksTask = dataService.fetchStocks()
        async let snapshotTask = dataService.fetchLatestSnapshot()
        async let yesterdaySnapshotTask = dataService.fetchYesterdaySnapshot()
        
        return try await (
            settingsTask,
            positionsTask,
            accountsTask,
            stockTransactionsTask,
            cashTransactionsTask,
            stocksTask,
            snapshotTask,
            yesterdaySnapshotTask
        )
    }
    
    func fetchLatestPrices(symbols: [String]) async throws -> [String: Decimal] {
        return try await dataService.fetchLatestPrices(symbols: symbols)
    }
    
    func fetchPreviousClosePrices(symbols: [String]) async throws -> [String: Decimal] {
        return try await dataService.fetchPreviousClosePrices(symbols: symbols)
    }
    
    func fetchCurrencyRates() async throws -> [String: Decimal] {
        return try await dataService.fetchCurrencyRatesToUSD()
    }
    
    func computeCashBalancesUSD(userEmail: String) async throws -> (accounts: [PortfolioDataService.AccountUSDValue], totalUSD: Decimal) {
        return try await dataService.computeCashBalancesUSD(userEmail: userEmail)
    }
    
    // MARK: - Caching
    
    var hasCachedData: Bool {
        return cacheService.hasCachedData
    }
    
    func loadCachedData() -> (
        positions: [SupabasePortfolioPosition]?,
        cashAccounts: [SupabaseCashAccount]?,
        accountUSDValues: [PortfolioDataService.AccountUSDValue]?,
        stockTransactions: [SupabaseStockTransaction]?,
        cashTransactions: [SupabaseCashTransaction]?,
        stocks: [SupabaseStock]?,
        latestPrices: [String: Decimal]?,
        currencyRates: [String: Decimal]?,
        settings: SupabasePortfolioSettings?,
        snapshot: SupabasePortfolioSnapshot?,
        yesterdaySnapshot: SupabasePortfolioSnapshot?
    ) {
        let positions = cacheService.loadCachedPositions()
        let cashAccounts = cacheService.loadCachedCashAccounts()
        let accountUSDValues = cacheService.loadCachedAccountUSDValues()?.map { $0.toAccountUSDValue() }
        let stockTransactions = cacheService.loadCachedStockTransactions()
        let cashTransactions = cacheService.loadCachedCashTransactions()
        let stocks = cacheService.loadCachedStocks()
        let latestPrices = cacheService.loadCachedLatestPrices()
        let currencyRates = cacheService.loadCachedCurrencyRates()
        let settings = cacheService.loadCachedSettings()
        let snapshot = cacheService.loadCachedSnapshot()
        let yesterdaySnapshot = cacheService.loadCachedYesterdaySnapshot()
        
        return (
            positions,
            cashAccounts,
            accountUSDValues,
            stockTransactions,
            cashTransactions,
            stocks,
            latestPrices,
            currencyRates,
            settings,
            snapshot,
            yesterdaySnapshot
        )
    }
    
    func saveToCache(
        positions: [SupabasePortfolioPosition]?,
        cashAccounts: [SupabaseCashAccount]?,
        accountUSDValues: [PortfolioDataService.AccountUSDValue]?,
        stockTransactions: [SupabaseStockTransaction]?,
        cashTransactions: [SupabaseCashTransaction]?,
        stocks: [SupabaseStock]?,
        latestPrices: [String: Decimal]?,
        currencyRates: [String: Decimal]?,
        settings: SupabasePortfolioSettings?,
        snapshot: SupabasePortfolioSnapshot?,
        yesterdaySnapshot: SupabasePortfolioSnapshot?
    ) {
        if let p = positions { cacheService.cachePositions(p) }
        if let ca = cashAccounts { cacheService.cacheCashAccounts(ca) }
        if let auv = accountUSDValues { cacheService.cacheAccountUSDValues(auv.map { CachedAccountUSDValue(from: $0) }) }
        if let st = stockTransactions { cacheService.cacheStockTransactions(st) }
        if let ct = cashTransactions { cacheService.cacheCashTransactions(ct) }
        if let s = stocks { cacheService.cacheStocks(s) }
        if let lp = latestPrices { cacheService.cacheLatestPrices(lp) }
        if let cr = currencyRates { cacheService.cacheCurrencyRates(cr) }
        if let set = settings { cacheService.cacheSettings(set) }
        if let snap = snapshot { cacheService.cacheSnapshot(snap) }
        if let ysnap = yesterdaySnapshot { cacheService.cacheYesterdaySnapshot(ysnap) }
        
        cacheService.updateCacheTime()
    }
}
