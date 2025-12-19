//
//  PortfolioCacheService.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/19.
//

import Foundation

/// Local cache service for portfolio data to enable instant loading
class PortfolioCacheService {
    static let shared = PortfolioCacheService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Cache keys
    private enum CacheKey: String {
        case positions = "cache_positions"
        case cashAccounts = "cache_cash_accounts"
        case accountUSDValues = "cache_account_usd_values"
        case stockTransactions = "cache_stock_transactions"
        case stocks = "cache_stocks"
        case latestPrices = "cache_latest_prices"
        case currencyRates = "cache_currency_rates"
        case settings = "cache_settings"
        case snapshot = "cache_snapshot"
        case yesterdaySnapshot = "cache_yesterday_snapshot"
        case lastCacheTime = "cache_last_update_time"
    }
    
    private init() {
        // Configure encoder/decoder for dates
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Cache Status
    
    var lastCacheTime: Date? {
        get { defaults.object(forKey: CacheKey.lastCacheTime.rawValue) as? Date }
        set { defaults.set(newValue, forKey: CacheKey.lastCacheTime.rawValue) }
    }
    
    var hasCachedData: Bool {
        lastCacheTime != nil
    }
    
    // MARK: - Positions
    
    func cachePositions(_ positions: [SupabasePortfolioPosition]) {
        save(positions, forKey: .positions)
    }
    
    func loadCachedPositions() -> [SupabasePortfolioPosition]? {
        load(forKey: .positions)
    }
    
    // MARK: - Cash Accounts
    
    func cacheCashAccounts(_ accounts: [SupabaseCashAccount]) {
        save(accounts, forKey: .cashAccounts)
    }
    
    func loadCachedCashAccounts() -> [SupabaseCashAccount]? {
        load(forKey: .cashAccounts)
    }
    
    // MARK: - Account USD Values
    
    func cacheAccountUSDValues(_ values: [CachedAccountUSDValue]) {
        save(values, forKey: .accountUSDValues)
    }
    
    func loadCachedAccountUSDValues() -> [CachedAccountUSDValue]? {
        load(forKey: .accountUSDValues)
    }
    
    // MARK: - Stock Transactions
    
    func cacheStockTransactions(_ transactions: [SupabaseStockTransaction]) {
        save(transactions, forKey: .stockTransactions)
    }
    
    func loadCachedStockTransactions() -> [SupabaseStockTransaction]? {
        load(forKey: .stockTransactions)
    }
    
    // MARK: - Stocks
    
    func cacheStocks(_ stocks: [SupabaseStock]) {
        save(stocks, forKey: .stocks)
    }
    
    func loadCachedStocks() -> [SupabaseStock]? {
        load(forKey: .stocks)
    }
    
    // MARK: - Latest Prices
    
    func cacheLatestPrices(_ prices: [String: Decimal]) {
        let stringPrices = prices.mapValues { "\($0)" }
        defaults.set(stringPrices, forKey: CacheKey.latestPrices.rawValue)
    }
    
    func loadCachedLatestPrices() -> [String: Decimal]? {
        guard let stringPrices = defaults.dictionary(forKey: CacheKey.latestPrices.rawValue) as? [String: String] else {
            return nil
        }
        var result: [String: Decimal] = [:]
        for (key, value) in stringPrices {
            if let decimal = Decimal(string: value) {
                result[key] = decimal
            }
        }
        return result
    }
    
    // MARK: - Currency Rates
    
    func cacheCurrencyRates(_ rates: [String: Decimal]) {
        let stringRates = rates.mapValues { "\($0)" }
        defaults.set(stringRates, forKey: CacheKey.currencyRates.rawValue)
    }
    
    func loadCachedCurrencyRates() -> [String: Decimal]? {
        guard let stringRates = defaults.dictionary(forKey: CacheKey.currencyRates.rawValue) as? [String: String] else {
            return nil
        }
        var result: [String: Decimal] = [:]
        for (key, value) in stringRates {
            if let decimal = Decimal(string: value) {
                result[key] = decimal
            }
        }
        return result
    }
    
    // MARK: - Settings
    
    func cacheSettings(_ settings: SupabasePortfolioSettings) {
        save(settings, forKey: .settings)
    }
    
    func loadCachedSettings() -> SupabasePortfolioSettings? {
        load(forKey: .settings)
    }
    
    // MARK: - Snapshots
    
    func cacheSnapshot(_ snapshot: SupabasePortfolioSnapshot) {
        save(snapshot, forKey: .snapshot)
    }
    
    func loadCachedSnapshot() -> SupabasePortfolioSnapshot? {
        load(forKey: .snapshot)
    }
    
    func cacheYesterdaySnapshot(_ snapshot: SupabasePortfolioSnapshot) {
        save(snapshot, forKey: .yesterdaySnapshot)
    }
    
    func loadCachedYesterdaySnapshot() -> SupabasePortfolioSnapshot? {
        load(forKey: .yesterdaySnapshot)
    }
    
    // MARK: - Update Cache Time
    
    func updateCacheTime() {
        lastCacheTime = Date()
    }
    
    // MARK: - Clear Cache
    
    func clearCache() {
        for key in [CacheKey.positions, .cashAccounts, .accountUSDValues, .stockTransactions, 
                    .stocks, .latestPrices, .currencyRates, .settings, .snapshot, 
                    .yesterdaySnapshot, .lastCacheTime] {
            defaults.removeObject(forKey: key.rawValue)
        }
    }
    
    // MARK: - Private Helpers
    
    private func save<T: Encodable>(_ value: T, forKey key: CacheKey) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key.rawValue)
        } catch {
            print("[Cache] Failed to encode \(key.rawValue): \(error)")
        }
    }
    
    private func load<T: Decodable>(forKey key: CacheKey) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[Cache] Failed to decode \(key.rawValue): \(error)")
            return nil
        }
    }
}

// MARK: - Cacheable Account USD Value

struct CachedAccountUSDValue: Codable, Identifiable {
    let id: UUID
    let displayName: String
    let nativeCurrency: String
    let nativeBalance: Decimal
    let exchangeRate: Decimal
    let usdValue: Decimal
    
    init(from account: PortfolioDataService.AccountUSDValue) {
        self.id = account.id
        self.displayName = account.displayName
        self.nativeCurrency = account.nativeCurrency
        self.nativeBalance = account.nativeBalance
        self.exchangeRate = account.exchangeRate
        self.usdValue = account.usdValue
    }
    
    func toAccountUSDValue() -> PortfolioDataService.AccountUSDValue {
        PortfolioDataService.AccountUSDValue(
            id: id,
            displayName: displayName,
            nativeCurrency: nativeCurrency,
            nativeBalance: nativeBalance,
            exchangeRate: exchangeRate,
            usdValue: usdValue
        )
    }
}
