//
//  AnalysisViewModel.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/20.
//

import Foundation
import SwiftUI
import Combine

enum AnalysisTimeRange: String, CaseIterable {
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case tenYears = "10Y"
    case all = "All"
    
    var days: Int? {
        switch self {
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .threeYears: return 365 * 3
        case .fiveYears: return 365 * 5
        case .tenYears: return 365 * 10
        case .all: return nil
        }
    }
    
    func startDate(from endDate: Date = Date()) -> Date? {
        switch self {
        case .all:
            return nil
        default:
            guard let days = days else { return nil }
            return Calendar.current.date(byAdding: .day, value: -days, to: endDate)
        }
    }
}

@MainActor
class AnalysisViewModel: ObservableObject {
    static let shared = AnalysisViewModel()
    
    @Published var portfolioSnapshots: [HistoricalPortfolioSnapshot] = []
    @Published var benchmarkSnapshots: [HistoricalBenchmarkSnapshot] = []
    @Published var selectedTimeRange: AnalysisTimeRange = .threeMonths
    @Published var selectedBenchmark: String = "^GSPC" // S&P 500
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = SupabaseAPIClient.shared
    
    private init() {}
    
    // MARK: - Computed Properties
    
    var filteredPortfolioSnapshots: [HistoricalPortfolioSnapshot] {
        let startDate = selectedTimeRange.startDate()
        if let start = startDate {
            return portfolioSnapshots.filter { $0.snapshotDate >= start }
        }
        return portfolioSnapshots
    }
    
    var filteredBenchmarkSnapshots: [HistoricalBenchmarkSnapshot] {
        let startDate = selectedTimeRange.startDate()
        if let start = startDate {
            return benchmarkSnapshots.filter { $0.snapshotDate >= start }
        }
        return benchmarkSnapshots
    }
    
    var portfolioPerformance: Decimal {
        guard let first = filteredPortfolioSnapshots.last,
              let last = filteredPortfolioSnapshots.first else {
            return 0
        }
        
        guard first.navPerShare > 0 else { return 0 }
        return ((last.navPerShare - first.navPerShare) / first.navPerShare) * 100
    }
    
    var benchmarkPerformance: Decimal {
        guard let first = filteredBenchmarkSnapshots.last,
              let last = filteredBenchmarkSnapshots.first else {
            return 0
        }
        
        guard first.price > 0 else { return 0 }
        return ((last.price - first.price) / first.price) * 100
    }
    
    var relativePerformance: Decimal {
        return portfolioPerformance - benchmarkPerformance
    }
    
    var currentTotalValue: Decimal {
        filteredPortfolioSnapshots.first?.totalValue ?? 0
    }
    
    var currentGainLoss: Decimal {
        filteredPortfolioSnapshots.first?.totalGainLoss ?? 0
    }
    
    var currentReturnPercent: Decimal {
        filteredPortfolioSnapshots.first?.totalReturnPercent ?? 0
    }

    var selectedBenchmarkName: String {
        availableBenchmarks.first(where: { $0.id == selectedBenchmark })?.name ?? "Benchmark"
    }
    
    // MARK: - Risk Metrics
    
    var volatility: Decimal {
        let returns = calculateDailyReturns(snapshots: filteredPortfolioSnapshots)
        guard !returns.isEmpty else { return 0 }
        
        let mean = returns.reduce(0 as Decimal, +) / Decimal(returns.count)
        let sumSquaredDiffs = returns.reduce(0 as Decimal) { sum, value in
            let diff = value - mean
            return sum + (diff * diff)
        }
        
        // Annualized Volatility (assuming 252 trading days)
        let variance = sumSquaredDiffs / Decimal(returns.count)
        let stdDev = pow(Double(truncating: variance as NSNumber), 0.5)
        return Decimal(stdDev * sqrt(252)) * 100
    }
    
    var maxDrawdown: Decimal {
        var maxDrawdown: Decimal = 0
        var peak: Decimal = -999999
        
        // Snapshots are typically desc order, we need asc for drawdown calc
        // Using NAV for drawdown to reflect performance drawdown, not withdrawal drawdown
        let sortedSnapshots = filteredPortfolioSnapshots.sorted { $0.snapshotDate < $1.snapshotDate }
        
        for snapshot in sortedSnapshots {
            if snapshot.navPerShare > peak {
                peak = snapshot.navPerShare
            }
            
            // Avoid division by zero if nav is 0
            if peak > 0 {
                let drawdown = (peak - snapshot.navPerShare) / peak
                if drawdown > maxDrawdown {
                    maxDrawdown = drawdown
                }
            }
        }
        
        return maxDrawdown * 100
    }
    
    var sharpeRatio: Decimal {
        let rfRate: Decimal = 0.04 // Risk-free rate assumption (4%)
        let returns = calculateDailyReturns(snapshots: filteredPortfolioSnapshots)
        guard !returns.isEmpty else { return 0 }
        
        let meanDailyReturn = returns.reduce(0, +) / Decimal(returns.count)
        let annualizedReturn = meanDailyReturn * 252
        
        let vol = volatility / 100 // Convert back from percentage
        guard vol > 0 else { return 0 }
        
        return (annualizedReturn - rfRate) / vol
    }
    
    private func calculateDailyReturns(snapshots: [HistoricalPortfolioSnapshot]) -> [Decimal] {
        // Sort asc by date
        let sorted = snapshots.sorted { $0.snapshotDate < $1.snapshotDate }
        guard sorted.count > 1 else { return [] }
        var returns: [Decimal] = []
        
        for i in 1..<sorted.count {
            let prev = sorted[i-1].navPerShare
            let curr = sorted[i].navPerShare
            
            if prev > 0 {
                let dailyReturn = (curr - prev) / prev
                returns.append(dailyReturn)
            }
        }
        
        return returns
    }
    
    // MARK: - Supported Benchmarks
    
    struct BenchmarkOption: Hashable, Identifiable {
        let id: String
        let name: String
    }
    
    let availableBenchmarks: [BenchmarkOption] = [
        BenchmarkOption(id: "^GSPC", name: "S&P 500"),
        BenchmarkOption(id: "^IXIC", name: "NASDAQ"),
        BenchmarkOption(id: "^DJI", name: "Dow Jones"),
        BenchmarkOption(id: "000001.SS", name: "SSE Composite"),
        BenchmarkOption(id: "399001.SZ", name: "SZSE Component"),
        BenchmarkOption(id: "000300.SS", name: "CSI 300"),
        BenchmarkOption(id: "^FTSE", name: "FTSE 100"),
        BenchmarkOption(id: "^HSI", name: "Hang Seng")
    ]
    
    // MARK: - Data Loading
    
    func loadAnalysisData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { try await self.loadPortfolioSnapshots() }
                group.addTask { try await self.loadBenchmarkSnapshots() }
                try await group.waitForAll()
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadPortfolioSnapshots() async throws {
        var allSnapshots: [HistoricalPortfolioSnapshot] = []
        var hasMore = true
        let batchSize = 1000
        var currentEndDate = Date()
        let targetStartDate = selectedTimeRange.startDate()
        
        // Safety break to prevent infinite loops (e.g. max 20 batches = ~20k records = ~80 years)
        var batchCount = 0
        let maxBatches = 20
        
        while hasMore && batchCount < maxBatches {
            batchCount += 1
            
            let batch = try await apiClient.fetchHistoricalPortfolioSnapshots(
                startDate: targetStartDate, // If nil, keeps going back
                endDate: currentEndDate,
                limit: batchSize
            )
            
            if batch.isEmpty {
                hasMore = false
            } else {
                allSnapshots.append(contentsOf: batch)
                
                // If we got less than requested, we've reached the end
                if batch.count < batchSize {
                    hasMore = false
                } else {
                    // Prepare for next batch: continue from the oldest date received
                    if let oldestInBatch = batch.last?.snapshotDate {
                        // Subtract 1 second/day to avoid overlap depending on precision,
                        // but usually simply using the date as 'lte' (less than or equal) might duplicate.
                        // Ideally we use 'lt' (less than).
                        // Since API uses inclusive date filtering usually, we need to be careful.
                        // Let's assume we filter by < oldestInBatch.
                        // However, SupabaseAPIClient uses `lte` for endDate.
                        // So we set new endDate to the day before the oldest date.
                        currentEndDate = Calendar.current.date(byAdding: .day, value: -1, to: oldestInBatch) ?? oldestInBatch
                        
                        // If we have a target start date, and we've passed it, stop.
                        if let target = targetStartDate, oldestInBatch <= target {
                            hasMore = false
                        }
                    } else {
                        hasMore = false
                    }
                }
            }
        }
        
        // Deduplicate just in case
        let unique = Array(Set(allSnapshots.map { $0.id })).compactMap { id in
            allSnapshots.first(where: { $0.id == id })
        }
        
        self.portfolioSnapshots = unique.sorted { $0.snapshotDate > $1.snapshotDate }
    }
    
    func loadBenchmarkSnapshots() async throws {
        var allSnapshots: [HistoricalBenchmarkSnapshot] = []
        var hasMore = true
        let batchSize = 1000
        var currentEndDate = Date()
        let targetStartDate = selectedTimeRange.startDate()
        
        var batchCount = 0
        let maxBatches = 20
        
        while hasMore && batchCount < maxBatches {
            batchCount += 1
            
            let batch = try await apiClient.fetchHistoricalBenchmarkSnapshots(
                benchmarkSymbol: selectedBenchmark,
                startDate: targetStartDate,
                endDate: currentEndDate,
                limit: batchSize
            )
            
            if batch.isEmpty {
                hasMore = false
            } else {
                allSnapshots.append(contentsOf: batch)
                
                if batch.count < batchSize {
                    hasMore = false
                } else {
                    if let oldestInBatch = batch.last?.snapshotDate {
                        currentEndDate = Calendar.current.date(byAdding: .day, value: -1, to: oldestInBatch) ?? oldestInBatch
                        
                        if let target = targetStartDate, oldestInBatch <= target {
                            hasMore = false
                        }
                    } else {
                        hasMore = false
                    }
                }
            }
        }
        
        // Deduplicate
        let unique = Array(Set(allSnapshots.map { $0.id })).compactMap { id in
            allSnapshots.first(where: { $0.id == id })
        }
        
        self.benchmarkSnapshots = unique.sorted { $0.snapshotDate > $1.snapshotDate }
    }
    
    func changeTimeRange(_ range: AnalysisTimeRange) async {
        selectedTimeRange = range
        await loadAnalysisData()
    }
    
    func changeBenchmark(_ symbol: String) async {
        selectedBenchmark = symbol
        do {
            try await loadBenchmarkSnapshots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Methods
    
    func normalizeData(_ snapshots: [HistoricalPortfolioSnapshot]) -> [(Date, Double)] {
        guard let firstValue = snapshots.last?.navPerShare, firstValue > 0 else {
            return []
        }
        
        return snapshots.reversed().map { snapshot in
            let normalized = (Double(truncating: snapshot.navPerShare as NSNumber) / Double(truncating: firstValue as NSNumber)) * 100
            return (snapshot.snapshotDate, normalized)
        }
    }
    
    func normalizeBenchmarkData(_ snapshots: [HistoricalBenchmarkSnapshot]) -> [(Date, Double)] {
        guard let firstValue = snapshots.last?.price, firstValue > 0 else {
            return []
        }
        
        return snapshots.reversed().map { snapshot in
            let normalized = (Double(truncating: snapshot.price as NSNumber) / Double(truncating: firstValue as NSNumber)) * 100
            return (snapshot.snapshotDate, normalized)
        }
    }
}
