//
//  SupabaseModels.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

// MARK: - Stocks Master

struct SupabaseStock: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let name: String
    let exchange: String?
    let currency: String?
    let market: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case exchange
        case currency
        case market
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Cash Accounts

struct SupabaseCashAccount: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let currency: String
    let displayName: String
    let createdAt: Date?
    let updatedAt: Date?
    let archivedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currency
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case archivedAt = "archived_at"
    }
}

// MARK: - Transaction Groups

enum TransactionGroupType: String, Codable {
    case cashOnly = "cash_only"
    case stockTrade = "stock_trade"
    case dividend
    case fxTransfer = "fx_transfer"
    case adjustment
}

enum TransactionStatus: String, Codable {
    case pending
    case settled
    case void
}

struct SupabaseTransactionGroup: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let groupType: TransactionGroupType
    let status: TransactionStatus
    let occurredAt: Date
    let settledAt: Date?
    let notes: String?
    let externalRef: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case groupType = "group_type"
        case status
        case occurredAt = "occurred_at"
        case settledAt = "settled_at"
        case notes
        case externalRef = "external_ref"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Cash Transactions

enum CashTransactionLegType: String, Codable {
    case deposit
    case withdrawal
    case fxIn = "fx_in"
    case fxOut = "fx_out"
    case stockBuy = "stock_buy"
    case stockSell = "stock_sell"
    case dividend
    case fee
    case adjustment
    case interest
}

enum CashTransactionDirection: String, Codable {
    case inflow
    case outflow
}

struct SupabaseCashTransaction: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let cashAccountId: UUID
    let legType: CashTransactionLegType
    let direction: CashTransactionDirection
    let amount: Decimal
    let currency: String
    let fxRate: Decimal
    let baseAmount: Decimal
    let occurredAt: Date
    let settledAt: Date
    let relatedStockTransactionId: UUID?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case groupId = "group_id"
        case cashAccountId = "cash_account_id"
        case legType = "leg_type"
        case direction
        case amount
        case currency
        case fxRate = "fx_rate"
        case baseAmount = "base_amount"
        case occurredAt = "occurred_at"
        case settledAt = "settled_at"
        case relatedStockTransactionId = "related_stock_transaction_id"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Stock Transactions

enum StockTradeType: String, Codable {
    case buy
    case sell
    case dividend
}

struct SupabaseStockTransaction: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let groupId: UUID
    let stockId: UUID
    let symbol: String
    let tradeType: StockTradeType
    let tradeDate: Date
    let settlementDate: Date?
    let quantity: Decimal
    let pricePerShare: Decimal
    let grossAmount: Decimal
    let fees: Decimal
    let currency: String
    let fxRate: Decimal
    let baseGrossAmount: Decimal
    let baseFees: Decimal
    let averageCostSnapshot: Decimal?
    let totalSharesSnapshot: Decimal?
    let totalCostBaseSnapshot: Decimal?
    let realizedPlBase: Decimal?
    let linkedCashTransactionId: UUID?
    let status: TransactionStatus
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case groupId = "group_id"
        case stockId = "stock_id"
        case symbol
        case tradeType = "trade_type"
        case tradeDate = "trade_date"
        case settlementDate = "settlement_date"
        case quantity
        case pricePerShare = "price_per_share"
        case grossAmount = "gross_amount"
        case fees
        case currency
        case fxRate = "fx_rate"
        case baseGrossAmount = "base_gross_amount"
        case baseFees = "base_fees"
        case averageCostSnapshot = "average_cost_snapshot"
        case totalSharesSnapshot = "total_shares_snapshot"
        case totalCostBaseSnapshot = "total_cost_base_snapshot"
        case realizedPlBase = "realized_pl_base"
        case linkedCashTransactionId = "linked_cash_transaction_id"
        case status
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Portfolio Positions

struct SupabasePortfolioPosition: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let stockId: UUID
    let symbol: String
    let totalShares: Decimal
    let totalCostBase: Decimal
    let averageCostBase: Decimal?
    let totalCostNative: Decimal?
    let lastTransactionAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case stockId = "stock_id"
        case symbol
        case totalShares = "total_shares"
        case totalCostBase = "total_cost_base"
        case averageCostBase = "average_cost_base"
        case totalCostNative = "total_cost_native"
        case lastTransactionAt = "last_transaction_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Portfolio Settings

struct SupabasePortfolioSettings: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let baseCurrency: String
    let baseCurrencySetAt: Date
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case baseCurrency = "base_currency"
        case baseCurrencySetAt = "base_currency_set_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Historical Prices

struct SupabaseHistoricalPrice: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let price: Decimal
    let date: Date
    let priceType: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case price
        case date
        case priceType = "price_type"
        case createdAt = "created_at"
    }
}

// MARK: - Portfolio Snapshot

struct SupabasePortfolioSnapshot: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let snapshotDate: Date
    let totalValue: Decimal
    let totalCostBasis: Decimal
    let totalGainLoss: Decimal
    let totalReturnPercent: Decimal
    let currency: String
    let createdAt: Date?
    let totalShares: Decimal?
    let navPerShare: Decimal?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case snapshotDate = "snapshot_date"
        case totalValue = "total_value"
        case totalCostBasis = "total_cost_basis"
        case totalGainLoss = "total_gain_loss"
        case totalReturnPercent = "total_return_percent"
        case currency
        case createdAt = "created_at"
        case totalShares = "total_shares"
        case navPerShare = "nav_per_share"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        let dateString = try container.decode(String.self, forKey: .snapshotDate)
        if let parsedDate = SupabasePortfolioSnapshot.dateFormatter.date(from: dateString) {
            snapshotDate = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .snapshotDate,
                                                   in: container,
                                                   debugDescription: "Cannot decode date string \(dateString)")
        }
        totalValue = try container.decode(Decimal.self, forKey: .totalValue)
        totalCostBasis = try container.decode(Decimal.self, forKey: .totalCostBasis)
        totalGainLoss = try container.decode(Decimal.self, forKey: .totalGainLoss)
        totalReturnPercent = try container.decode(Decimal.self, forKey: .totalReturnPercent)
        currency = try container.decode(String.self, forKey: .currency)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        totalShares = try container.decodeIfPresent(Decimal.self, forKey: .totalShares)
        navPerShare = try container.decodeIfPresent(Decimal.self, forKey: .navPerShare)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Currency Rates

struct SupabaseCurrencyRate: Codable, Identifiable {
    let id: UUID
    let fromCurrency: String
    let toCurrency: String
    let rate: Decimal
    let date: Date
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromCurrency = "from_currency"
        case toCurrency = "to_currency"
        case rate
        case date
        case createdAt = "created_at"
    }
}

// MARK: - Historical Portfolio Snapshots

struct HistoricalPortfolioSnapshot: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let snapshotDate: Date
    let totalValue: Decimal
    let principle: Decimal
    let totalShares: Decimal
    let navPerShare: Decimal
    let currency: String
    let createdAt: Date?
    
    // Computed properties for compatibility
    var totalCostBasis: Decimal { principle }
    var totalGainLoss: Decimal { totalValue - principle }
    var totalReturnPercent: Decimal {
        guard principle > 0 else { return 0 }
        return ((totalValue - principle) / principle) * 100
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case snapshotDate = "snapshot_date"
        case totalValue = "total_value"
        case principle
        case totalShares = "total_shares"
        case navPerShare = "nav_per_share"
        case currency
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        
        let dateString = try container.decode(String.self, forKey: .snapshotDate)
        if let parsedDate = HistoricalPortfolioSnapshot.dateFormatter.date(from: dateString) {
            snapshotDate = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .snapshotDate,
                                                   in: container,
                                                   debugDescription: "Cannot decode date string \(dateString)")
        }
        
        totalValue = try container.decode(Decimal.self, forKey: .totalValue)
        principle = try container.decode(Decimal.self, forKey: .principle)
        totalShares = try container.decode(Decimal.self, forKey: .totalShares)
        navPerShare = try container.decode(Decimal.self, forKey: .navPerShare)
        currency = try container.decode(String.self, forKey: .currency)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Historical Benchmark Snapshots

struct HistoricalBenchmarkSnapshot: Codable, Identifiable {
    let id: UUID
    let indexSymbol: String
    let snapshotDate: Date
    let price: Decimal
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case indexSymbol = "index_symbol"
        case snapshotDate = "snapshot_date"
        case price
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        indexSymbol = try container.decode(String.self, forKey: .indexSymbol)
        
        let dateString = try container.decode(String.self, forKey: .snapshotDate)
        if let parsedDate = HistoricalBenchmarkSnapshot.dateFormatter.date(from: dateString) {
            snapshotDate = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .snapshotDate,
                                                   in: container,
                                                   debugDescription: "Cannot decode date string \(dateString)")
        }
        
        price = try container.decode(Decimal.self, forKey: .price)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
