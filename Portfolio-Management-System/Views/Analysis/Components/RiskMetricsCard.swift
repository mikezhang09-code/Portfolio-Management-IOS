//
//  RiskMetricsCard.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/20.
//

import SwiftUI

struct RiskMetricsCard: View {
    let volatility: Decimal
    let maxDrawdown: Decimal
    let sharpeRatio: Decimal
    let startValue: Decimal
    let endValue: Decimal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Metrics")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricItem(title: "Volatility (Ann.)", value: formatPercent(volatility), color: .purple)
                MetricItem(title: "Max Drawdown", value: formatPercent(maxDrawdown), color: .red)
                MetricItem(title: "Sharpe Ratio", value: formatDecimal(sharpeRatio), color: .blue)
                MetricItem(title: "Return/Risk", value: volatility != 0 ? formatDecimal(((endValue - startValue)/startValue * 100) / volatility) : "0.00", color: .green)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
    
    private func formatPercent(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return (formatter.string(from: value as NSNumber) ?? "0.00") + "%"
    }
    
    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: value as NSNumber) ?? "0.00"
    }
}

private struct MetricItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
