//
//  PortfolioDataService.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

@MainActor
class PortfolioDataService {
    static let shared = PortfolioDataService()
    private let apiClient = SupabaseAPIClient.shared
    
    private init() {}
    
    // MARK: - Fetch Portfolio Positions
    
    func fetchPortfolioPositions() async throws -> [SupabasePortfolioPosition] {
        let positions: [SupabasePortfolioPosition] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_positions",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "total_shares", value: "gt.0"),
                URLQueryItem(name: "order", value: "symbol.asc")
            ]
        )
        return positions
    }
    
    // MARK: - Fetch Cash Accounts
    
    func fetchCashAccounts() async throws -> [SupabaseCashAccount] {
        let accounts: [SupabaseCashAccount] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_cash_accounts",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "archived_at", value: "is.null"),
                URLQueryItem(name: "order", value: "currency.asc")
            ]
        )
        return accounts
    }
    
    // MARK: - Fetch Cash Balance for Account
    
    func fetchCashBalance(accountId: UUID) async throws -> Decimal {
        let transactions: [SupabaseCashTransaction] = try await apiClient.get(
            endpoint: "rest/v1/cash_transactions",
            queryItems: [
                URLQueryItem(name: "select", value: "amount,direction"),
                URLQueryItem(name: "cash_account_id", value: "eq.\(accountId.uuidString)"),
                URLQueryItem(name: "order", value: "occurred_at.desc")
            ]
        )
        
        var balance: Decimal = 0
        for transaction in transactions {
            if transaction.direction == .inflow {
                balance += transaction.amount
            } else {
                balance -= transaction.amount
            }
        }
        return balance
    }
    
    // MARK: - Fetch Stocks
    
    func fetchStocks() async throws -> [SupabaseStock] {
        let stocks: [SupabaseStock] = try await apiClient.get(
            endpoint: "rest/v1/stocks_master",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "symbol.asc")
            ]
        )
        return stocks
    }
    
    // MARK: - Fetch Transaction Groups
    
    func fetchTransactionGroups(limit: Int = 50) async throws -> [SupabaseTransactionGroup] {
        let groups: [SupabaseTransactionGroup] = try await apiClient.get(
            endpoint: "rest/v1/transaction_groups",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "occurred_at.desc"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return groups
    }
    
    // MARK: - Fetch Stock Transactions
    
    func fetchStockTransactions(limit: Int = 100) async throws -> [SupabaseStockTransaction] {
        let transactions: [SupabaseStockTransaction] = try await apiClient.get(
            endpoint: "rest/v1/stock_transactions",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "trade_date.desc"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return transactions
    }
    
    // MARK: - Fetch Cash Transactions
    
    func fetchCashTransactions(limit: Int = 100) async throws -> [SupabaseCashTransaction] {
        let transactions: [SupabaseCashTransaction] = try await apiClient.get(
            endpoint: "rest/v1/cash_transactions",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "occurred_at.desc"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return transactions
    }
    
    // MARK: - Fetch Portfolio Settings
    
    func fetchPortfolioSettings() async throws -> SupabasePortfolioSettings? {
        let settings: [SupabasePortfolioSettings] = try await apiClient.get(
            endpoint: "rest/v1/user_portfolio_settings",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return settings.first
    }
    
    // MARK: - Fetch Historical Prices
    
    private struct PriceWithSymbolResponse: Codable {
        let symbol: String
        let price: Decimal
        let date: String
    }
    
    func fetchLatestPrice(symbol: String) async throws -> Decimal? {
        let prices: [PriceWithSymbolResponse] = try await apiClient.get(
            endpoint: "rest/v1/historical_prices",
            queryItems: [
                URLQueryItem(name: "select", value: "symbol,price,date"),
                URLQueryItem(name: "symbol", value: "eq.\(symbol)"),
                URLQueryItem(name: "order", value: "date.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return prices.first?.price
    }
    
    /// Batch fetch latest prices for multiple symbols in one query
    func fetchLatestPrices(symbols: [String]) async throws -> [String: Decimal] {
        guard !symbols.isEmpty else { return [:] }
        
        // Build IN query for all symbols
        let symbolList = symbols.map { "\"\($0)\"" }.joined(separator: ",")
        
        let prices: [PriceWithSymbolResponse] = try await apiClient.get(
            endpoint: "rest/v1/historical_prices",
            queryItems: [
                URLQueryItem(name: "select", value: "symbol,price,date"),
                URLQueryItem(name: "symbol", value: "in.(\(symbolList))"),
                URLQueryItem(name: "order", value: "date.desc")
            ]
        )
        
        // Group by symbol and take the latest price for each
        var result: [String: Decimal] = [:]
        var seenSymbols: Set<String> = []
        
        for price in prices {
            if !seenSymbols.contains(price.symbol) {
                result[price.symbol] = price.price
                seenSymbols.insert(price.symbol)
            }
        }
        
        print("[DataService] Fetched prices for \(result.count)/\(symbols.count) symbols")
        return result
    }
    
    // MARK: - Create Cash Account
    
    func createCashAccount(currency: String, displayName: String) async throws -> SupabaseCashAccount {
        struct CreateAccountBody: Encodable {
            let currency: String
            let display_name: String
        }
        
        let body = CreateAccountBody(currency: currency, display_name: displayName)
        let result: [SupabaseCashAccount] = try await apiClient.post(endpoint: "rest/v1/portfolio_cash_accounts", body: body)
        
        guard let account = result.first else {
            throw APIError.invalidResponse
        }
        return account
    }
    
    // MARK: - Fetch Snapshots
    
    func fetchLatestSnapshot() async throws -> SupabasePortfolioSnapshot? {
        let snapshots: [SupabasePortfolioSnapshot] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_snapshots",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "snapshot_date.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return snapshots.first
    }
    
    func fetchYesterdaySnapshot() async throws -> SupabasePortfolioSnapshot? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let todayISO = dateFormatter.string(from: today)
        
        let snapshots: [SupabasePortfolioSnapshot] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_snapshots",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "snapshot_date", value: "lt.\(todayISO)"),
                URLQueryItem(name: "order", value: "snapshot_date.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return snapshots.first
    }
    
    // MARK: - FX Rates
    
    func fetchCurrencyRatesToUSD() async throws -> [String: Decimal] {
        return try await fetchLatestRatesToUSD()
    }
    
    private struct CurrencyRateResponse: Codable {
        let fromCurrency: String
        let toCurrency: String
        let rate: Decimal
        let date: String
        
        enum CodingKeys: String, CodingKey {
            case fromCurrency = "from_currency"
            case toCurrency = "to_currency"
            case rate
            case date
        }
    }
    
    private func fetchLatestRatesToUSD() async throws -> [String: Decimal] {
        // Fetch both direct and inverted USD pairs, then prefer the latest by currency
        let directRates: [CurrencyRateResponse] = try await apiClient.get(
            endpoint: "rest/v1/currency_rates",
            queryItems: [
                URLQueryItem(name: "select", value: "from_currency,to_currency,rate,date"),
                URLQueryItem(name: "to_currency", value: "eq.USD"),
                URLQueryItem(name: "order", value: "date.desc")
            ]
        )
        let invertedRatesSrc: [CurrencyRateResponse] = try await apiClient.get(
            endpoint: "rest/v1/currency_rates",
            queryItems: [
                URLQueryItem(name: "select", value: "from_currency,to_currency,rate,date"),
                URLQueryItem(name: "from_currency", value: "eq.USD"),
                URLQueryItem(name: "order", value: "date.desc")
            ]
        )
        
        var latest: [String: (date: String, rate: Decimal)] = [:]
        
        for r in directRates {
            let code = r.fromCurrency.uppercased().trimmingCharacters(in: .whitespaces)
            if let existing = latest[code] {
                if r.date > existing.date { latest[code] = (r.date, r.rate) }
            } else {
                latest[code] = (r.date, r.rate)
            }
        }
        for r in invertedRatesSrc {
            let code = r.toCurrency.uppercased().trimmingCharacters(in: .whitespaces)
            guard r.rate != 0 else { continue }
            let inverted = (1 / r.rate)
            if let existing = latest[code] {
                if r.date > existing.date { latest[code] = (r.date, inverted) }
            } else {
                latest[code] = (r.date, inverted)
            }
        }
        
        var result: [String: Decimal] = [:]
        for (code, tuple) in latest {
            result[code] = tuple.rate
        }
        result["USD"] = 1
        return result
    }
    
    // MARK: - Cash Balances (SQL-equivalent)
    
    struct AccountUSDValue: Identifiable { let id: UUID; let displayName: String; let nativeCurrency: String; let nativeBalance: Decimal; let exchangeRate: Decimal; let usdValue: Decimal }
    
    private struct CashAccountResponse: Codable {
        let id: UUID
        let currency: String
        let displayName: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case currency
            case displayName = "display_name"
        }
    }
    
    private struct CashTransactionResponse: Codable {
        let cashAccountId: UUID
        let amount: Decimal
        let direction: String
        
        enum CodingKeys: String, CodingKey {
            case cashAccountId = "cash_account_id"
            case amount
            case direction
        }
    }
    
    func computeCashBalancesUSD(userEmail: String) async throws -> (accounts: [AccountUSDValue], totalUSD: Decimal) {
        // Step 1: Fetch accounts
        let accounts: [CashAccountResponse] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_cash_accounts",
            queryItems: [
                URLQueryItem(name: "select", value: "id,currency,display_name"),
                URLQueryItem(name: "order", value: "display_name.asc")
            ]
        )
        
        // Step 1b: Fetch all cash transactions for these accounts
        let transactions: [CashTransactionResponse] = try await apiClient.get(
            endpoint: "rest/v1/cash_transactions",
            queryItems: [
                URLQueryItem(name: "select", value: "cash_account_id,amount,direction"),
                URLQueryItem(name: "order", value: "occurred_at.asc")
            ]
        )
        
        // Native balances per account
        struct Key: Hashable { let accountId: UUID; let currency: String; let displayName: String }
        var nativeBalances: [Key: Decimal] = [:]
        
        for tx in transactions {
            guard let account = accounts.first(where: { $0.id == tx.cashAccountId }) else { continue }
            let key = Key(accountId: account.id, currency: account.currency.uppercased().trimmingCharacters(in: .whitespaces), displayName: account.displayName)
            
            // Apply direction: inflow = +amount, outflow = -amount
            let isInflow = tx.direction.lowercased() == "inflow"
            let signed = isInflow ? tx.amount : -tx.amount
            nativeBalances[key, default: 0] += signed
        }
        
        // Step 2: latest rates to USD
        let latestRates = try await fetchLatestRatesToUSD()
        
        // Step 3: account USD values
        var accountValues: [AccountUSDValue] = []
        var totalUSD: Decimal = 0
        
        for (key, native) in nativeBalances {
            let code = key.currency
            let rate = (code == "USD") ? 1 : (latestRates[code] ?? 1)
            let usd = (native * rate)
            let item = AccountUSDValue(id: key.accountId, displayName: key.displayName, nativeCurrency: code, nativeBalance: native, exchangeRate: rate, usdValue: (usd as NSDecimalNumber).rounding(2))
            accountValues.append(item)
            totalUSD += usd
        }
        
        // Sort like SQL output
        accountValues.sort { $0.displayName < $1.displayName }
        return (accountValues, (totalUSD as NSDecimalNumber).rounding(2))
    }
}

// Decimal rounding helper
extension NSDecimalNumber {
    func rounding(_ scale: Int16) -> Decimal {
        let behavior = NSDecimalNumberHandler(roundingMode: .plain, scale: scale, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        return self.rounding(accordingToBehavior: behavior).decimalValue
    }
}
