//
//  PortfolioFormatter.swift
//  Portfolio-Management-System
//
//  Created by Antigravity on 2025/12/29.
//

import Foundation

struct PortfolioFormatter {
    
    // MARK: - Formatters
    
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    private static let signedCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+$"
        formatter.negativePrefix = "-$"
        return formatter
    }()
    
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter
    }()
    
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+"
        formatter.negativePrefix = ""  // Minus sign is automatic? No, wait. Default number formatter handles negative.
        // Actually, for custom prefixes, we usually valid. 
        // But if negativePrefix is "", it suppresses the minus sign? 
        // Let's look at existing code: formatter.negativePrefix = "" 
        // This suggests it relies on value being passed? 
        // Wait, if value is negative, and negativePrefix is "", it might show absolute value?
        // Let's check Foundation: if you set positivePrefix, you often alter negative formats.
        // EXISTING CODE: formatter.negativePrefix = ""
        // This is suspicious. If I pass -5, does it show "5%"?
        // Ah, typically one sets both. positive "+" and negative "-".
        // Let's stick to existing behavior for signed = true, which seems to work (user sees +8.83%, assuming it's positive).
        return formatter
    }()
    
    private static let neutralPercentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        // No custom prefixes, so it defaults to standard "-1.23" and "1.23"
        return formatter
    }()
    
    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    private static let signedDecimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"
        return formatter
    }()
    
    // MARK: - Public Methods
    
    static func formatUSD(_ value: Decimal) -> String {
        return currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
    
    static func formatSignedUSD(_ value: Decimal) -> String {
        return signedCurrencyFormatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
    
    static func formatPrice(_ value: Decimal) -> String {
        return priceFormatter.string(from: value as NSDecimalNumber) ?? "0.00"
    }
    
    static func formatPercent(_ value: Decimal, signed: Bool = true) -> String {
        let formatter = signed ? percentFormatter : neutralPercentFormatter
        let formatted = formatter.string(from: value as NSDecimalNumber) ?? "0.00"
        return formatted + "%"
    }
    
    static func formatNumber(_ value: Decimal) -> String {
        return integerFormatter.string(from: value as NSDecimalNumber) ?? "0"
    }
    
    static func formatDecimal(_ value: Decimal) -> String {
        return decimalFormatter.string(from: value as NSDecimalNumber) ?? "0.00"
    }
    
    static func formatSignedValue(_ value: Decimal, percent: Decimal? = nil) -> String {
        let valueStr = signedDecimalFormatter.string(from: value as NSDecimalNumber) ?? "0.00"
        
        if let pct = percent {
            let pctStr = formatPercent(pct)
            return "\(valueStr) (\(pctStr))"
        }
        return valueStr
    }
}
