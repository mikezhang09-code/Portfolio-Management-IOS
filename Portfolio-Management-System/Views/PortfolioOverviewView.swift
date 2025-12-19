//
//  PortfolioOverviewView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct PortfolioOverviewView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    
    var capitalSummary: CapitalSummary {
        viewModel.getCapitalSummary()
    }
    
    var currentCashBalance: Double {
        viewModel.calculateCurrentCashBalance()
    }
    
    var totalHoldingsValue: Double {
        viewModel.getAllHoldings().reduce(0) { sum, holding in
            sum + (holding.quantity * holding.averageCostPerUnit)
        }
    }
    
    var portfolioValue: Double {
        currentCashBalance + totalHoldingsValue
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Portfolio Value Card
                    VStack(spacing: 12) {
                        Text("Total Portfolio Value")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(String(format: "$%.2f", portfolioValue))
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 12) {
                            PortfolioMetricCard(label: "Cash", value: currentCashBalance, color: .blue)
                            PortfolioMetricCard(label: "Holdings", value: totalHoldingsValue, color: .green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(16)
                    
                    // Holdings Breakdown
                    if !viewModel.getAllHoldings().isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Holdings")
                                .font(.headline)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 8) {
                                ForEach(viewModel.getAllHoldings()) { holding in
                                    if let ticker = viewModel.getTickerById(holding.tickerId) {
                                        HoldingRow(
                                            ticker: ticker,
                                            holding: holding
                                        )
                                    }
                                }
                            }
                            .padding(12)
                            .background(.gray.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Capital Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Capital Summary")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 8) {
                            SummaryRow(label: "Initial Capital", value: capitalSummary.initialCapital)
                            SummaryRow(label: "Total Deposits", value: capitalSummary.totalDeposits)
                            SummaryRow(label: "Total Withdrawals", value: -capitalSummary.totalWithdrawals, isNegative: true)
                            SummaryRow(label: "Interest Earned", value: capitalSummary.totalInterest)
                            Divider()
                            SummaryRow(label: "Current Cash", value: currentCashBalance, isBold: true)
                        }
                        .padding(12)
                        .background(.gray.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
            .navigationTitle("Portfolio Overview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PortfolioMetricCard: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "$%.2f", value))
                .font(.headline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct HoldingRow: View {
    let ticker: StockTicker
    let holding: Holding
    
    var holdingValue: Double {
        holding.quantity * holding.averageCostPerUnit
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ticker.code)
                    .font(.headline)
                Text(ticker.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.2f", holding.quantity))
                    .font(.headline)
                Text(String(format: "$%.2f", holdingValue))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
    }
}

struct SummaryRow: View {
    let label: String
    let value: Double
    var isNegative: Bool = false
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isBold ? .headline : .body)
            Spacer()
            Text(String(format: "%+.2f", value))
                .font(isBold ? .headline : .body)
                .foregroundStyle(value >= 0 ? .green : .red)
        }
    }
}

#Preview {
    PortfolioOverviewView(viewModel: PortfolioViewModel())
}
