//
//  Capital.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

struct Capital: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: CapitalType
    let amount: Double
    let description: String
    
    enum CapitalType: String, Codable {
        case initialDeposit = "Initial Deposit"
        case deposit = "Deposit"
        case withdrawal = "Withdrawal"
        case interest = "Interest"
    }
    
    init(type: CapitalType, amount: Double, description: String = "") {
        self.id = UUID()
        self.date = Date()
        self.type = type
        self.amount = amount
        self.description = description
    }
}

struct CapitalSummary {
    var initialCapital: Double = 0
    var totalDeposits: Double = 0
    var totalWithdrawals: Double = 0
    var totalInterest: Double = 0
    
    var currentCashBalance: Double {
        initialCapital + totalDeposits - totalWithdrawals + totalInterest
    }
}
