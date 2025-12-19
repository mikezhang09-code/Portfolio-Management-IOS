//
//  StockTicker.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import Foundation

struct StockTicker: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var code: String
    var market: String
    var currency: String
    let createdDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, code, market, currency, createdDate
    }
    
    init(name: String, code: String, market: String, currency: String) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.market = market
        self.currency = currency
        self.createdDate = Date()
    }
    
    func displayName() -> String {
        "\(code) - \(name)"
    }
}
