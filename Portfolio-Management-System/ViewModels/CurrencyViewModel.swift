import Foundation
import SwiftUI
import Combine

@MainActor
final class CurrencyViewModel: ObservableObject {
    @Published var rates: [CurrencyRate] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var convertedAmount: Double?
    @Published var amountToConvert: Double = 100
    @Published var fromCurrency: FiatCurrency = .usd
    @Published var toCurrency: FiatCurrency = .hkd

    private let service: CurrencyRateService

    init(service: CurrencyRateService = CurrencyRateService()) {
        self.service = service
    }

    func loadRates() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await service.fetchFXRates()
            await applyRates(fetched)
        } catch {
            let fallback = service.fallbackRates()
            await applyRates(fallback)
            errorMessage = "Live FX rates unavailable. Showing fallback values."
        }
        isLoading = false
    }

    func convert() {
        guard let rate = rateBetween(from: fromCurrency, to: toCurrency) else {
            errorMessage = "No rate available for selected currencies."
            convertedAmount = nil
            return
        }
        convertedAmount = amountToConvert * rate
    }

    func rateDescription(for rate: CurrencyRate) -> String {
        String(format: "%.4f", rate.rate)
    }

    func rateBetween(from: FiatCurrency, to: FiatCurrency) -> Double? {
        if from == to { return 1 }
        if let direct = rates.first(where: { $0.base == from && $0.quote == to }) {
            return direct.rate
        }
        if let inverse = rates.first(where: { $0.base == to && $0.quote == from }), inverse.rate != 0 {
            return 1 / inverse.rate
        }
        // Derive via USD when direct pair missing (e.g., CNY/HKD)
        if let usdToFrom = usdRate(to: from), let usdToTo = usdRate(to: to), usdToFrom != 0 {
            return usdToTo / usdToFrom
        }
        return nil
    }

    private func usdRate(to currency: FiatCurrency) -> Double? {
        if currency == .usd { return 1 }
        if let direct = rates.first(where: { $0.base == .usd && $0.quote == currency }) {
            return direct.rate
        }
        if let inverse = rates.first(where: { $0.base == currency && $0.quote == .usd }), inverse.rate != 0 {
            return 1 / inverse.rate
        }
        return nil
    }

    // MARK: - Private

    private func applyRates(_ newRates: [CurrencyRate]) async {
        rates = newRates.sorted { $0.id < $1.id }
        lastUpdated = newRates.map { $0.timestamp }.max()
    }
}
