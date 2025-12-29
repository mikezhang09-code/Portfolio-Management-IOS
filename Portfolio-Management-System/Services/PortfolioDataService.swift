//
//  PortfolioDataService.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

struct StockLookupResponse: Decodable {
    let symbol: String
    let name: String
    let exchange: String?
    let market: String?
}

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
    
    /// Fetch previous close prices (second most recent price) for multiple symbols
    func fetchPreviousClosePrices(symbols: [String]) async throws -> [String: Decimal] {
        guard !symbols.isEmpty else { return [:] }
        
        let symbolList = symbols.map { "\"\($0)\"" }.joined(separator: ",")
        
        let prices: [PriceWithSymbolResponse] = try await apiClient.get(
            endpoint: "rest/v1/historical_prices",
            queryItems: [
                URLQueryItem(name: "select", value: "symbol,price,date"),
                URLQueryItem(name: "symbol", value: "in.(\(symbolList))"),
                URLQueryItem(name: "order", value: "date.desc")
            ]
        )
        
        // Group by symbol and take the second price (previous close) for each
        var result: [String: Decimal] = [:]
        var symbolPriceCount: [String: Int] = [:]
        
        for price in prices {
            let count = symbolPriceCount[price.symbol] ?? 0
            if count == 1 {
                // This is the second price (previous close)
                result[price.symbol] = price.price
            }
            symbolPriceCount[price.symbol] = count + 1
        }
        
        print("[DataService] Fetched previous close for \(result.count)/\(symbols.count) symbols")
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
    
    // MARK: - Stock Management (CRUD)
    
    func createStock(symbol: String, name: String, market: String, exchange: String?) async throws {
        struct CreateStockBody: Encodable {
            let symbol: String
            let name: String
            let market: String
            let exchange: String?
        }
        
        let body = CreateStockBody(symbol: symbol, name: name, market: market, exchange: exchange)
        let _: [SupabaseStock] = try await apiClient.post(endpoint: "rest/v1/stocks_master", body: body)
    }
    
    func updateStock(id: UUID, name: String, exchange: String?) async throws {
        struct UpdateStockBody: Encodable {
            let name: String
            let exchange: String?
        }
        
        let body = UpdateStockBody(name: name, exchange: exchange)
        try await apiClient.patch(endpoint: "rest/v1/stocks_master", id: id, body: body)
    }
    
    func deleteStock(id: UUID) async throws {
        try await apiClient.delete(endpoint: "rest/v1/stocks_master", id: id)
    }

    // MARK: - Transaction Management

    func createTransactionGroup(
        groupType: TransactionGroupType,
        status: TransactionStatus,
        occurredAt: Date,
        settledAt: Date?,
        notes: String?,
        externalRef: String?
    ) async throws -> SupabaseTransactionGroup {
        struct CreateTransactionGroupBody: Encodable {
            let group_type: TransactionGroupType
            let status: TransactionStatus
            let occurred_at: Date
            let settled_at: Date?
            let notes: String?
            let external_ref: String?
        }

        let body = CreateTransactionGroupBody(
            group_type: groupType,
            status: status,
            occurred_at: occurredAt,
            settled_at: settledAt,
            notes: notes,
            external_ref: externalRef
        )
        let result: [SupabaseTransactionGroup] = try await apiClient.post(endpoint: "rest/v1/transaction_groups", body: body)
        guard let group = result.first else {
            throw APIError.invalidResponse
        }
        return group
    }

    func createCashTransaction(
        groupId: UUID,
        cashAccountId: UUID,
        legType: CashTransactionLegType,
        direction: CashTransactionDirection,
        amount: Decimal,
        currency: String,
        fxRate: Decimal,
        baseAmount: Decimal,
        occurredAt: Date,
        settledAt: Date,
        relatedStockTransactionId: UUID?,
        notes: String?
    ) async throws -> SupabaseCashTransaction {
        struct CreateCashTransactionBody: Encodable {
            let group_id: UUID
            let cash_account_id: UUID
            let leg_type: CashTransactionLegType
            let direction: CashTransactionDirection
            let amount: Decimal
            let currency: String
            let fx_rate: Decimal
            let base_amount: Decimal
            let occurred_at: Date
            let settled_at: Date
            let related_stock_transaction_id: UUID?
            let notes: String?
        }

        let body = CreateCashTransactionBody(
            group_id: groupId,
            cash_account_id: cashAccountId,
            leg_type: legType,
            direction: direction,
            amount: amount,
            currency: currency,
            fx_rate: fxRate,
            base_amount: baseAmount,
            occurred_at: occurredAt,
            settled_at: settledAt,
            related_stock_transaction_id: relatedStockTransactionId,
            notes: notes
        )
        let result: [SupabaseCashTransaction] = try await apiClient.post(endpoint: "rest/v1/cash_transactions", body: body)
        guard let transaction = result.first else {
            throw APIError.invalidResponse
        }
        return transaction
    }

    func createStockTransaction(
        groupId: UUID,
        stockId: UUID,
        symbol: String,
        tradeType: StockTradeType,
        tradeDate: Date,
        settlementDate: Date?,
        quantity: Decimal,
        pricePerShare: Decimal,
        grossAmount: Decimal,
        fees: Decimal,
        currency: String,
        fxRate: Decimal,
        baseGrossAmount: Decimal,
        baseFees: Decimal,
        status: TransactionStatus,
        notes: String?
    ) async throws -> SupabaseStockTransaction {
        struct CreateStockTransactionBody: Encodable {
            let group_id: UUID
            let stock_id: UUID
            let symbol: String
            let trade_type: StockTradeType
            let trade_date: Date
            let settlement_date: Date?
            let quantity: Decimal
            let price_per_share: Decimal
            let gross_amount: Decimal
            let fees: Decimal
            let currency: String
            let fx_rate: Decimal
            let base_gross_amount: Decimal
            let base_fees: Decimal
            let status: TransactionStatus
            let notes: String?
            let average_cost_snapshot: Decimal?
            let total_shares_snapshot: Decimal?
            let total_cost_base_snapshot: Decimal?
            let realized_pl_base: Decimal?
            let linked_cash_transaction_id: UUID?
        }

        let body = CreateStockTransactionBody(
            group_id: groupId,
            stock_id: stockId,
            symbol: symbol,
            trade_type: tradeType,
            trade_date: tradeDate,
            settlement_date: settlementDate,
            quantity: quantity,
            price_per_share: pricePerShare,
            gross_amount: grossAmount,
            fees: fees,
            currency: currency,
            fx_rate: fxRate,
            base_gross_amount: baseGrossAmount,
            base_fees: baseFees,
            status: status,
            notes: notes,
            average_cost_snapshot: nil,
            total_shares_snapshot: nil,
            total_cost_base_snapshot: nil,
            realized_pl_base: nil,
            linked_cash_transaction_id: nil
        )
        let result: [SupabaseStockTransaction] = try await apiClient.post(endpoint: "rest/v1/stock_transactions", body: body)
        guard let transaction = result.first else {
            throw APIError.invalidResponse
        }
        return transaction
    }

    // MARK: - Stock Lookup (Finance API via Edge Function)

    func fetchStockData(symbol: String, market: String?) async throws -> StockLookupResponse {
        struct StockLookupBody: Encodable {
            let symbol: String
            let market: String?
        }

        let body = StockLookupBody(symbol: symbol, market: market)
        return try await apiClient.postFunction(name: "fetch-stock-data", body: body)
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
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Format dates as YYYY-MM-DD (matching web app format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yesterdayISO = dateFormatter.string(from: yesterday)
        let todayISO = dateFormatter.string(from: today)
        
        print("[DataService] Fetching yesterday snapshot, yesterday=\(yesterdayISO), today=\(todayISO)")
        
        // First try: get exact yesterday's snapshot (like web app)
        let exactSnapshots: [SupabasePortfolioSnapshot] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_snapshots",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "snapshot_date", value: "eq.\(yesterdayISO)"),
                URLQueryItem(name: "order", value: "snapshot_date.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        
        if let snapshot = exactSnapshots.first {
            print("[DataService] Found exact yesterday snapshot: \(snapshot.snapshotDate), value=\(snapshot.totalValue)")
            return snapshot
        }
        
        // Fallback: get most recent snapshot before today (for weekends/holidays)
        let fallbackSnapshots: [SupabasePortfolioSnapshot] = try await apiClient.get(
            endpoint: "rest/v1/portfolio_snapshots",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "snapshot_date", value: "lt.\(todayISO)"),
                URLQueryItem(name: "order", value: "snapshot_date.desc"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        
        if let snapshot = fallbackSnapshots.first {
            print("[DataService] Found fallback snapshot: \(snapshot.snapshotDate), value=\(snapshot.totalValue)")
            return snapshot
        }
        
        print("[DataService] No yesterday snapshot found")
        return nil
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

        for account in accounts {
            let key = Key(
                accountId: account.id,
                currency: account.currency.uppercased().trimmingCharacters(in: .whitespaces),
                displayName: account.displayName
            )
            nativeBalances[key] = 0
        }
        
        for tx in transactions {
            guard let account = accounts.first(where: { $0.id == tx.cashAccountId }) else { continue }
            let key = Key(
                accountId: account.id,
                currency: account.currency.uppercased().trimmingCharacters(in: .whitespaces),
                displayName: account.displayName
            )
            
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
