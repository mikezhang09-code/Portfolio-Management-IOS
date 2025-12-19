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
    @Published var todayChangeValue: Decimal = 0
    @Published var todayChangePercent: Decimal = 0
    @Published var gainLossValue: Decimal = 0
    @Published var gainLossPercent: Decimal = 0
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataService = PortfolioDataService.shared
    
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
            partial + position.totalCostBase
        }
    }
    
    var totalCostBasis: Decimal {
        positions.reduce(0) { partial, position in
            partial + position.totalCostBase
        }
    }
    
    var totalPortfolioValue: Decimal {
        totalCashBalance + totalHoldingsValue
    }
    
    // MARK: - Load Data
    
    func loadPortfolioData() async {
        isLoading = true
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
            
            // Await all results
            let (settingsResult, positionsResult, accountsResult, stockTxResult, cashTxResult, stocksResult, snapshotResult) = try await (
                settingsTask,
                positionsTask,
                accountsTask,
                stockTransactionsTask,
                cashTransactionsTask,
                stocksTask,
                snapshotTask
            )
            
            // Update state
            self.settings = settingsResult
            self.positions = positionsResult
            self.cashAccounts = accountsResult
            self.stockTransactions = stockTxResult
            self.cashTransactions = cashTxResult
            self.stocks = stocksResult
            self.snapshot = snapshotResult
            
            // Calculate cash balances and summary metrics
            await loadCashBalances()
            computeSummary()
            
            print("[Portfolio] Loaded: \(positions.count) positions, \(cashAccounts.count) cash accounts, \(stockTransactions.count) stock transactions")
            
        } catch let error as APIError {
            self.errorMessage = error.localizedDescription
            print("[Portfolio] Error: \(error.localizedDescription)")
        } catch {
            self.errorMessage = "Failed to load portfolio data"
            print("[Portfolio] Error: \(error.localizedDescription)")
        }
        
        isLoading = false
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
        
        let calendar = Calendar.current
        let cashFlowLegs: Set<CashTransactionLegType> = [.deposit, .withdrawal, .dividend, .fee, .adjustment, .interest, .fxIn, .fxOut, .stockBuy, .stockSell]
        let todayCashFlow = cashTransactions
            .filter { tx in
                calendar.isDateInToday(tx.occurredAt) && cashFlowLegs.contains(tx.legType)
            }
            .reduce(Decimal(0)) { partial, tx in
                partial + tx.baseAmount
            }
        
        let previousClose = snapshot?.totalValue ?? (currentTotal - todayCashFlow)
        let baseline = previousClose + todayCashFlow
        
        let changeValue = currentTotal - baseline
        let changePercent = baseline != 0 ? changeValue / baseline : 0
        
        let costBasis = totalCostBasis
        let gainValue = holdingsValue - costBasis
        let gainPercent = costBasis != 0 ? gainValue / costBasis : 0
        
        self.todayChangeValue = changeValue
        self.todayChangePercent = changePercent
        self.gainLossValue = gainValue
        self.gainLossPercent = gainPercent
    }
    
    // MARK: - Helper Methods
    
    func getStockName(for symbol: String) -> String? {
        stocks.first { $0.symbol == symbol }?.name
    }
    
    func refreshData() async {
        await loadPortfolioData()
    }
}
