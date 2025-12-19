//
//  PortfolioViewModel.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation
import SwiftUI
import Combine

class PortfolioViewModel: ObservableObject {
    @Published var capitals: [Capital] = []
    @Published var tickers: [StockTicker] = []
    @Published var transactions: [Transaction] = []
    @Published var holdings: [UUID: Holding] = [:]
    
    private let capitalStorageKey = "portfolioCapitals"
    private let tickerStorageKey = "portfolioTickers"
    private let transactionStorageKey = "portfolioTransactions"
    private let holdingStorageKey = "portfolioHoldings"
    
    init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    
    private func saveCapitals() {
        if let encoded = try? JSONEncoder().encode(capitals) {
            UserDefaults.standard.set(encoded, forKey: capitalStorageKey)
        }
    }
    
    private func saveTickers() {
        if let encoded = try? JSONEncoder().encode(tickers) {
            UserDefaults.standard.set(encoded, forKey: tickerStorageKey)
        }
    }
    
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: transactionStorageKey)
        }
    }
    
    private func saveHoldings() {
        let holdingsArray = Array(holdings.values)
        if let encoded = try? JSONEncoder().encode(holdingsArray) {
            UserDefaults.standard.set(encoded, forKey: holdingStorageKey)
        }
    }
    
    private func loadData() {
        loadCapitals()
        loadTickers()
        loadTransactions()
        loadHoldings()
    }
    
    private func loadCapitals() {
        if let data = UserDefaults.standard.data(forKey: capitalStorageKey),
           let decoded = try? JSONDecoder().decode([Capital].self, from: data) {
            self.capitals = decoded
        }
    }
    
    private func loadTickers() {
        if let data = UserDefaults.standard.data(forKey: tickerStorageKey),
           let decoded = try? JSONDecoder().decode([StockTicker].self, from: data) {
            self.tickers = decoded
        }
    }
    
    private func loadTransactions() {
        if let data = UserDefaults.standard.data(forKey: transactionStorageKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            self.transactions = decoded
        }
    }
    
    private func loadHoldings() {
        if let data = UserDefaults.standard.data(forKey: holdingStorageKey),
           let decoded = try? JSONDecoder().decode([Holding].self, from: data) {
            self.holdings = Dictionary(uniqueKeysWithValues: decoded.map { ($0.tickerId, $0) })
        }
    }
    
    // MARK: - Capital Management
    
    func addCapitalOperation(type: Capital.CapitalType, amount: Double, description: String) {
        let capital = Capital(type: type, amount: amount, description: description)
        capitals.append(capital)
        capitals.sort { $0.date < $1.date }
        saveCapitals()
    }
    
    func deleteCapitalOperation(_ capital: Capital) {
        capitals.removeAll { $0.id == capital.id }
        saveCapitals()
    }
    
    func getCapitalSummary() -> CapitalSummary {
        var summary = CapitalSummary()
        
        for capital in capitals {
            switch capital.type {
            case .initialDeposit:
                summary.initialCapital += capital.amount
            case .deposit:
                summary.totalDeposits += capital.amount
            case .withdrawal:
                summary.totalWithdrawals += capital.amount
            case .interest:
                summary.totalInterest += capital.amount
            }
        }
        
        return summary
    }
    
    // MARK: - Ticker Management
    
    func addTicker(_ ticker: StockTicker) {
        tickers.append(ticker)
        tickers.sort { $0.code < $1.code }
        saveTickers()
    }
    
    func updateTicker(_ ticker: StockTicker) {
        if let index = tickers.firstIndex(where: { $0.id == ticker.id }) {
            tickers[index] = ticker
            saveTickers()
        }
    }
    
    func deleteTicker(_ ticker: StockTicker) {
        tickers.removeAll { $0.id == ticker.id }
        // Also remove any holdings for this ticker
        holdings.removeValue(forKey: ticker.id)
        saveTickers()
        saveHoldings()
    }
    
    func getTickerById(_ id: UUID) -> StockTicker? {
        tickers.first { $0.id == id }
    }
    
    func isTickerCodeExists(_ code: String, excludeId: UUID? = nil) -> Bool {
        tickers.contains { ticker in
            ticker.code.uppercased() == code.uppercased() && ticker.id != excludeId
        }
    }
    
    // MARK: - Transaction Management
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        updateHoldingsWithTransaction(transaction)
        updateCashBalance(with: transaction)
        transactions.sort { $0.date < $1.date }
        saveTransactions()
        saveHoldings()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        // Recalculate all holdings since transaction order matters for average cost
        recalculateAllHoldings()
        saveTransactions()
        saveHoldings()
    }
    
    func getTransactionsByTicker(_ tickerId: UUID) -> [Transaction] {
        transactions.filter { $0.tickerId == tickerId }
    }
    
    // MARK: - Holdings Management
    
    private func updateHoldingsWithTransaction(_ transaction: Transaction) {
        if var holding = holdings[transaction.tickerId] {
            holding.updateWithTransaction(transaction)
            holdings[transaction.tickerId] = holding
        } else {
            // Create new holding
            let holding = Holding(
                tickerId: transaction.tickerId,
                quantity: transaction.type == .buy ? transaction.quantity : 0,
                averageCostPerUnit: transaction.pricePerUnit
            )
            holdings[transaction.tickerId] = holding
        }
    }
    
    private func recalculateAllHoldings() {
        // Reset all holdings
        holdings.removeAll()
        
        // Sort transactions by date
        let sortedTransactions = transactions.sorted { $0.date < $1.date }
        
        // Rebuild holdings from transactions
        for transaction in sortedTransactions {
            updateHoldingsWithTransaction(transaction)
        }
    }
    
    func getHoldingByTicker(_ tickerId: UUID) -> Holding? {
        holdings[tickerId]
    }
    
    func getAllHoldings() -> [Holding] {
        Array(holdings.values).sorted { 
            getTickerById($0.tickerId)?.code ?? "" < getTickerById($1.tickerId)?.code ?? ""
        }
    }
    
    // MARK: - Cash Balance Management
    
    private func updateCashBalance(with transaction: Transaction) {
        // The cash balance is calculated from capital operations and transactions
        // This is called to ensure consistency
    }
    
    func calculateCurrentCashBalance() -> Double {
        let capitalSummary = getCapitalSummary()
        let transactionImpact = transactions.reduce(0) { $0 + $1.cashImpact() }
        return capitalSummary.currentCashBalance + transactionImpact
    }
}
