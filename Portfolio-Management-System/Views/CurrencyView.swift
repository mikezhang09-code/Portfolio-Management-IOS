import SwiftUI

struct CurrencyView: View {
    @StateObject private var viewModel = CurrencyViewModel()

    private struct CurrencyPairItem: Identifiable {
        let id: String
        let base: FiatCurrency
        let quote: FiatCurrency
    }

    private let trackedPairs: [CurrencyPairItem] = [
        .init(id: "USD-HKD", base: .usd, quote: .hkd),
        .init(id: "USD-CNY", base: .usd, quote: .cny),
        .init(id: "CNY-HKD", base: .cny, quote: .hkd)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    ratesSection
                    converterSection
                }
                .padding()
            }
            .navigationTitle("Currencies")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadRates() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.loadRates()
            }
        }
        .task {
            await viewModel.loadRates()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Major FX Rates")
                .font(.title3.bold())
            if let lastUpdated = viewModel.lastUpdated {
                Text("Last updated: \(formatted(date: lastUpdated))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ratesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(trackedPairs) { pair in
                rateRow(base: pair.base, quote: pair.quote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private var converterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Currency Transfer")
                    .font(.headline)
                Spacer()
                Button {
                    swapCurrencies()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                }
                .buttonStyle(.borderless)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("From", selection: $viewModel.fromCurrency) {
                        ForEach(FiatCurrency.allCases) { currency in
                            Text(currency.displayName).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("To", selection: $viewModel.toCurrency) {
                        ForEach(FiatCurrency.allCases) { currency in
                            Text(currency.displayName).tag(currency)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Amount", value: $viewModel.amountToConvert, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            }

            Button {
                viewModel.convert()
            } label: {
                Text("Convert")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)

            if let result = viewModel.convertedAmount {
                Text("Converted: \(viewModel.toCurrency.symbol)\(formattedAmount(result))")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private func rateRow(base: FiatCurrency, quote: FiatCurrency) -> some View {
        let rateValue = viewModel.rateBetween(from: base, to: quote)
        return HStack {
            VStack(alignment: .leading) {
                Text("\(base.rawValue)/\(quote.rawValue)")
                    .font(.headline)
                Text("1 \(base.symbol) = \(quote.symbol)\(formattedRate(rateValue))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedRate(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.4f", value)
    }

    private func formattedAmount(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func swapCurrencies() {
        let currentFrom = viewModel.fromCurrency
        viewModel.fromCurrency = viewModel.toCurrency
        viewModel.toCurrency = currentFrom
    }
}

#Preview {
    CurrencyView()
}
