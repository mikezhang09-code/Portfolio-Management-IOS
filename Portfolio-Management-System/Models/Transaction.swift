//
//  Transaction.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

struct Transaction: Identifiable, Codable {
    let id: UUID
    var tickerId: UUID
    let date: Date
    var type: TransactionType
    var quantity: Double
    var pricePerUnit: Double
    var notes: String
    
    enum TransactionType: String, Codable {
        case buy = "Buy"
        case sell = "Sell"
        case dividend = "Dividend"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, tickerId, date, type, quantity, pricePerUnit, notes
    }
    
    init(tickerId: UUID, type: TransactionType, quantity: Double, pricePerUnit: Double, notes: String = "") {
        self.id = UUID()
        self.tickerId = tickerId
        self.date = Date()
        self.type = type
        self.quantity = quantity
        self.pricePerUnit = pricePerUnit
        self.notes = notes
    }
    
    func totalAmount() -> Double {
        quantity * pricePerUnit
    }
    
    func cashImpact() -> Double {
        switch type {
        case .buy:
            return -(quantity * pricePerUnit)
        case .sell:
            return quantity * pricePerUnit
        case .dividend:
            return quantity * pricePerUnit
        }
    }
}
