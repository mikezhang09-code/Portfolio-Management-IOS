//
//  Holding.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

struct Holding: Identifiable, Codable {
    let tickerId: UUID
    var quantity: Double
    var averageCostPerUnit: Double
    var totalCostBasis: Double
    
    var id: UUID { tickerId }
    
    enum CodingKeys: String, CodingKey {
        case tickerId, quantity, averageCostPerUnit, totalCostBasis
    }
    
    init(tickerId: UUID, quantity: Double, averageCostPerUnit: Double) {
        self.tickerId = tickerId
        self.quantity = quantity
        self.averageCostPerUnit = averageCostPerUnit
        self.totalCostBasis = quantity * averageCostPerUnit
    }
    
    mutating func updateWithTransaction(_ transaction: Transaction) {
        switch transaction.type {
        case .buy:
            let previousCost = quantity * averageCostPerUnit
            let newCost = transaction.quantity * transaction.pricePerUnit
            let totalCost = previousCost + newCost
            let totalQuantity = quantity + transaction.quantity
            
            self.averageCostPerUnit = totalQuantity > 0 ? totalCost / totalQuantity : 0
            self.quantity = totalQuantity
            self.totalCostBasis = totalCost
            
        case .sell:
            let totalQuantity = quantity - transaction.quantity
            self.quantity = max(0, totalQuantity)
            self.totalCostBasis = self.quantity * averageCostPerUnit
            
        case .dividend:
            // Dividends don't affect holdings quantity or cost basis
            break
        }
    }
}
