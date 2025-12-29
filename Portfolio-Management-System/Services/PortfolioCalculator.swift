//
//  PortfolioCalculator.swift
//  Portfolio-Management-System
//
//  Created by Antigravity on 2025/12/29.
//

import Foundation

struct PortfolioCalculator {
    
    static func marketValueUSD(position: SupabasePortfolioPosition, latestPrice: Decimal, exchangeRate: Decimal) -> Decimal {
        let marketValueLocal = latestPrice * position.totalShares
        return marketValueLocal * exchangeRate
    }
    
    static func marketValueLocal(position: SupabasePortfolioPosition, latestPrice: Decimal) -> Decimal {
        return latestPrice * position.totalShares
    }
    
    static func daysGainUSD(position: SupabasePortfolioPosition, latestPrice: Decimal, previousClosePrice: Decimal, exchangeRate: Decimal) -> Decimal {
        let priceChange = latestPrice - previousClosePrice
        return priceChange * position.totalShares * exchangeRate
    }
    
    static func daysGainPercent(latestPrice: Decimal, previousClosePrice: Decimal) -> Decimal {
        guard previousClosePrice != 0 else { return 0 }
        return (latestPrice - previousClosePrice) / previousClosePrice * 100
    }
    
    static func totalGainUSD(marketValueUSD: Decimal, totalCostBase: Decimal) -> Decimal {
        return marketValueUSD - totalCostBase
    }
    
    static func totalGainPercent(totalGainUSD: Decimal, totalCostBase: Decimal) -> Decimal {
        guard totalCostBase != 0 else { return 0 }
        return totalGainUSD / totalCostBase * 100
    }
    
    static func averageCostPerShareNative(position: SupabasePortfolioPosition) -> Decimal {
        guard position.totalShares != 0 else { return 0 }
        if let nativeCost = position.totalCostNative {
            return nativeCost / position.totalShares
        }
        return position.totalCostBase / position.totalShares
    }
    
    static func calculateSummary(
        totalHoldingsValue: Decimal,
        totalCashBalance: Decimal,
        yesterdayTotalValue: Decimal?,
        todayCashFlow: Decimal,
        totalCostBasis: Decimal
    ) -> (todayChangeValue: Decimal, todayChangePercent: Decimal, gainLossValue: Decimal, gainLossPercent: Decimal) {
        
        let currentTotal = totalHoldingsValue + totalCashBalance
        
        let todayChangeValue: Decimal
        let todayChangePercent: Decimal
        
        if let yesterdayValue = yesterdayTotalValue {
            todayChangeValue = currentTotal - yesterdayValue - todayCashFlow
            let baseline = yesterdayValue + todayCashFlow
            todayChangePercent = baseline != 0 ? todayChangeValue / baseline : 0
        } else {
            todayChangeValue = 0
            todayChangePercent = 0
        }
        
        let gainLossValue = totalHoldingsValue - totalCostBasis
        let gainLossPercent = totalCostBasis != 0 ? gainLossValue / totalCostBasis : 0
        
        return (todayChangeValue, todayChangePercent, gainLossValue, gainLossPercent)
    }
}
