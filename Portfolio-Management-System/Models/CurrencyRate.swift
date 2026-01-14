import Foundation

enum FiatCurrency: String, CaseIterable, Identifiable, Codable {
    case usd = "USD"
    case hkd = "HKD"
    case cny = "CNY"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .hkd: return "HK$"
        case .cny: return "¥"
        }
    }
}

struct CurrencyRate: Identifiable, Codable, Equatable {
    let base: FiatCurrency
    let quote: FiatCurrency
    let rate: Double
    let timestamp: Date

    var id: String { "\(base.rawValue)-\(quote.rawValue)" }
}
