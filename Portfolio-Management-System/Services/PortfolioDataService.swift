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
    
    // MARK: - Fetch Historical Price
    
    func fetchLatestPrice(symbol: String) async throws -> Decimal? {
        let prices: [SupabaseHistoricalPrice] = try await apiClient.get(
            endpoint: "rest/v1/historical_prices",
            queryItems: [
                URLQueryItem(name: "select", value: "price"),
                URLQueryItem(name: "symbol", value: "eq.\(symbol)"),
                URLQueryItem(name: "order", value: "date.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return prices.first?.price
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
    
    // MARK: - Fetch Latest Snapshot
    
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
    
    // MARK: - FX Rates
    private func fetchLatestRatesToUSD() async throws -> [String: Decimal] {
        // Fetch both direct and inverted USD pairs, then prefer the latest by currency
        let directRates: [SupabaseCurrencyRate] = try await apiClient.get(
            endpoint: "rest/v1/currency_rates",
            queryItems: [
                URLQueryItem(name: "select", value: "from_currency, to_currency, rate, date"),
                URLQueryItem(name: "to_currency", value: "eq.USD"),
                URLQueryItem(name: "order", value: "date.desc")
            ]
        )
        let invertedRatesSrc: [SupabaseCurrencyRate] = try await apiClient.get(
            endpoint: "rest/v1/currency_rates",
            queryItems: [
                URLQueryItem(name: "select", value: "from_currency, to_currency, rate, date"),
                URLQueryItem(name: "from_currency", value: "eq.USD"),
                URLQueryItem(name: "order", value: "date.desc")
            ]
        )
        
        var latest: [String: (date: Date, rate: Decimal)] = [:]
        
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
    
    func computeCashBalancesUSD(userEmail: String) async throws -> (accounts: [AccountUSDValue], totalUSD: Decimal) {
        // Step 1: Fetch accounts joined with user by email
        let accounts: [SupabaseCashAccount] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_cash_accounts",
            queryItems: [
                URLQueryItem(name: "select", value: "id,user_id,currency,display_name"),
                // In PostgREST, we cannot filter by email here without a view; assume RLS scopes to the user
                URLQueryItem(name: "order", value: "display_name.asc")
            ]
        )
        
        // Step 1b: Fetch all cash transactions for these accounts
        let transactions: [SupabaseCashTransaction] = try await apiClient.get(
            endpoint: "rest/v1/cash_transactions",
            queryItems: [
                URLQueryItem(name: "select", value: "cash_account_id, amount, direction, currency"),
                URLQueryItem(name: "order", value: "occurred_at.asc")
            ]
        )
        
        // Native balances per account per currency (there may be multi-currency under same display name in screenshot)
        struct Key: Hashable { let accountId: UUID; let currency: String; let displayName: String }
        var nativeBalances: [Key: Decimal] = [:]
        
        for tx in transactions {
            guard let account = accounts.first(where: { $0.id == tx.cashAccountId }) else { continue }
            let key = Key(accountId: account.id, currency: account.currency.uppercased().trimmingCharacters(in: .whitespaces), displayName: account.displayName)
            let signed = (tx.direction == .inflow) ? tx.amount : -tx.amount
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
