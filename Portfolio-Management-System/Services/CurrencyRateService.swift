import Foundation

struct CurrencyRateService {
    private let apiClient = SupabaseAPIClient.shared

    private struct ExchangeRateHostResponse: Decodable {
        let base: String
        let rates: [String: Double]
        let date: String?
    }

    private struct SupabaseRateRow: Decodable {
        let fromCurrency: String
        let toCurrency: String
        let rate: Double
        let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case fromCurrency = "from_currency"
            case toCurrency = "to_currency"
            case rate
            case updatedAt = "updated_at"
        }
    }

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func fetchFXRates() async throws -> [CurrencyRate] {
        if let supabaseRates = try? await fetchFromSupabase() {
            return supabaseRates
        }

        guard let url = URL(string: "https://api.exchangerate.host/latest?base=USD&symbols=HKD,CNY") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try decoder.decode(ExchangeRateHostResponse.self, from: data)
        return buildRates(from: decoded)
    }

    func fallbackRates() -> [CurrencyRate] {
        let now = Date()
        let usdHkd = CurrencyRate(base: .usd, quote: .hkd, rate: 7.80, timestamp: now)
        let usdCny = CurrencyRate(base: .usd, quote: .cny, rate: 7.10, timestamp: now)
        let cnyHkd = CurrencyRate(base: .cny, quote: .hkd, rate: usdHkd.rate / usdCny.rate, timestamp: now)
        return [usdHkd, usdCny, cnyHkd]
    }

    // MARK: - Supabase

    private func fetchFromSupabase() async throws -> [CurrencyRate]? {
        // Mirror backend: pull latest stored rates (populated by edge function fetch-currency-data)
        let rows: [SupabaseRateRow] = try await apiClient.get(
            endpoint: "rest/v1/currency_rates",
            queryItems: [
                URLQueryItem(name: "select", value: "from_currency,to_currency,rate,updated_at"),
                URLQueryItem(name: "or", value: "(and(from_currency.eq.USD,to_currency.eq.HKD),and(from_currency.eq.USD,to_currency.eq.CNY),and(from_currency.eq.CNY,to_currency.eq.HKD))"),
                URLQueryItem(name: "order", value: "updated_at.desc")
            ]
        )

        let latest = collapseToLatest(rows)
        return latest.isEmpty ? nil : latest
    }

    private func collapseToLatest(_ rows: [SupabaseRateRow]) -> [CurrencyRate] {
        var map: [String: SupabaseRateRow] = [:]
        for row in rows {
            let key = "\(row.fromCurrency.uppercased())-\(row.toCurrency.uppercased())"
            if let existing = map[key] {
                if let newDate = row.updatedAt, let oldDate = existing.updatedAt {
                    if newDate > oldDate { map[key] = row }
                } else {
                    map[key] = row
                }
            } else {
                map[key] = row
            }
        }

        let now = Date()
        return map.values.compactMap { row in
            guard
                let base = FiatCurrency(rawValue: row.fromCurrency.uppercased()),
                let quote = FiatCurrency(rawValue: row.toCurrency.uppercased()),
                row.rate > 0
            else { return nil }

            return CurrencyRate(
                base: base,
                quote: quote,
                rate: row.rate,
                timestamp: row.updatedAt ?? now
            )
        }
    }

    // MARK: - Helpers

    private func buildRates(from response: ExchangeRateHostResponse) -> [CurrencyRate] {
        let now = Date()
        let usdHkdRate = response.rates[FiatCurrency.hkd.rawValue]
        let usdCnyRate = response.rates[FiatCurrency.cny.rawValue]
        let usdHkd = CurrencyRate(base: .usd, quote: .hkd, rate: usdHkdRate ?? 0, timestamp: now)
        let usdCny = CurrencyRate(base: .usd, quote: .cny, rate: usdCnyRate ?? 0, timestamp: now)
        var rates: [CurrencyRate] = []

        if usdHkd.rate > 0 { rates.append(usdHkd) }
        if usdCny.rate > 0 { rates.append(usdCny) }

        if let hkd = usdHkdRate, let cny = usdCnyRate, hkd > 0, cny > 0 {
            let derived = CurrencyRate(base: .cny, quote: .hkd, rate: hkd / cny, timestamp: now)
            rates.append(derived)
        }
        return rates
    }
}
