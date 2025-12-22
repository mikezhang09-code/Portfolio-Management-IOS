//
//  SupabaseStocksView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/22.
//

import SwiftUI

struct SupabaseStocksView: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    @State private var selectedTab = 0
    @State private var showingAddStock = false
    @State private var selectedStock: SupabaseStock?
    @State private var isUpdatingPrices = false
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    Text("Market Overview").tag(0)
                    Text("Manage Stocks").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if selectedTab == 0 {
                    MarketOverviewTab(
                        viewModel: viewModel,
                        selectedStock: $selectedStock,
                        isUpdatingPrices: $isUpdatingPrices
                    )
                } else {
                    ManageStocksTab(
                        viewModel: viewModel,
                        showingAddStock: $showingAddStock,
                        selectedStock: $selectedStock,
                        showingEditSheet: $showingEditSheet,
                        isUpdatingPrices: $isUpdatingPrices
                    )
                }
            }
            .navigationTitle("Stocks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Refresh Prices Button
                        Button(action: updatePrices) {
                            if isUpdatingPrices {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isUpdatingPrices)
                        
                        if selectedTab == 1 {
                            Button(action: { showingAddStock = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddStock) {
                AddSupabaseStockView(viewModel: viewModel, isPresented: $showingAddStock)
            }
            .sheet(item: $selectedStock) { stock in
                if showingEditSheet {
                    EditSupabaseStockView(
                        viewModel: viewModel,
                        stock: stock,
                        isPresented: $showingEditSheet
                    )
                } else {
                    StockDetailSheet(viewModel: viewModel, stock: stock)
                }
            }
        }
    }
    
    private func updatePrices() {
        isUpdatingPrices = true
        Task {
            await viewModel.forceRefresh()
            isUpdatingPrices = false
        }
    }
}

// MARK: - Market Overview Tab

struct MarketOverviewTab: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    @Binding var selectedStock: SupabaseStock?
    @Binding var isUpdatingPrices: Bool
    
    var body: some View {
        if viewModel.stocks.isEmpty {
            EmptyStocksView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.stocks) { stock in
                        StockCardView(
                            stock: stock,
                            price: viewModel.latestPrices[stock.symbol],
                            isSelected: selectedStock?.id == stock.id
                        )
                        .onTapGesture {
                            selectedStock = stock
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Manage Stocks Tab

struct ManageStocksTab: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    @Binding var showingAddStock: Bool
    @Binding var selectedStock: SupabaseStock?
    @Binding var showingEditSheet: Bool
    @Binding var isUpdatingPrices: Bool
    
    var body: some View {
        if viewModel.stocks.isEmpty {
            EmptyStocksView()
        } else {
            List {
                ForEach(viewModel.stocks) { stock in
                    StockListRow(
                        stock: stock,
                        price: viewModel.latestPrices[stock.symbol]
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingEditSheet = true
                        selectedStock = stock
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteStock(stock)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Empty State

struct EmptyStocksView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Stocks")
                .font(.headline)
            Text("Add your first stock or ETF to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - Stock Card View (for Market Overview)

struct StockCardView: View {
    let stock: SupabaseStock
    let price: Decimal?
    var isSelected: Bool = false
    
    private var currency: String {
        switch stock.market?.uppercased() {
        case "US": return "USD"
        case "HK": return "HKD"
        case "CN": return "CNY"
        default: return stock.currency ?? "USD"
        }
    }
    
    private var currencySymbol: String {
        switch currency {
        case "HKD": return "HK$"
        case "CNY": return "¥"
        default: return "$"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.symbol)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(stock.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let priceValue = price {
                        Text("\(currencySymbol)\(formatPrice(priceValue))")
                            .font(.title3)
                            .fontWeight(.semibold)
                    } else {
                        Text("--")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text(stock.market ?? "US")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(marketColor.opacity(0.15))
                            .foregroundColor(marketColor)
                            .cornerRadius(4)
                        
                        Text(currency)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
    
    private var marketColor: Color {
        switch stock.market?.uppercased() {
        case "US": return .blue
        case "HK": return .orange
        case "CN": return .red
        default: return .gray
        }
    }
    
    private func formatPrice(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "\(value)"
    }
}

// MARK: - Stock List Row (for Manage Stocks)

struct StockListRow: View {
    let stock: SupabaseStock
    let price: Decimal?
    
    private var currency: String {
        switch stock.market?.uppercased() {
        case "US": return "USD"
        case "HK": return "HKD"
        case "CN": return "CNY"
        default: return stock.currency ?? "USD"
        }
    }
    
    private var currencySymbol: String {
        switch currency {
        case "HKD": return "HK$"
        case "CNY": return "¥"
        default: return "$"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.headline)
                Text(stock.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let priceValue = price {
                    Text("\(currencySymbol)\(formatPrice(priceValue))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("--")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text(stock.market ?? "US")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(currency)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatPrice(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "\(value)"
    }
}

// MARK: - Stock Detail Sheet

struct StockDetailSheet: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    let stock: SupabaseStock
    @Environment(\.dismiss) private var dismiss
    
    private var currency: String {
        switch stock.market?.uppercased() {
        case "US": return "USD"
        case "HK": return "HKD"
        case "CN": return "CNY"
        default: return stock.currency ?? "USD"
        }
    }
    
    private var currencySymbol: String {
        switch currency {
        case "HKD": return "HK$"
        case "CNY": return "¥"
        default: return "$"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(stock.symbol)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(stock.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Price Card
                    VStack(spacing: 12) {
                        if let priceValue = viewModel.latestPrices[stock.symbol] {
                            Text("\(currencySymbol)\(formatPrice(priceValue))")
                                .font(.system(size: 40, weight: .bold))
                        } else {
                            Text("Price Unavailable")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 16) {
                            DetailBadge(title: "Market", value: stock.market ?? "US")
                            DetailBadge(title: "Currency", value: currency)
                            if let exchange = stock.exchange {
                                DetailBadge(title: "Exchange", value: exchange)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Market Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Market Information")
                            .font(.headline)
                        
                        InfoRow(label: "Symbol", value: stock.symbol)
                        InfoRow(label: "Name", value: stock.name)
                        InfoRow(label: "Market", value: stock.market ?? "US")
                        InfoRow(label: "Exchange", value: stock.exchange ?? "N/A")
                        InfoRow(label: "Currency", value: currency)
                        
                        if let updatedAt = stock.updatedAt {
                            InfoRow(label: "Last Updated", value: formatDate(updatedAt))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Stock Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatPrice(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "\(value)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Add Stock View

struct AddSupabaseStockView: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    @Binding var isPresented: Bool
    
    @State private var symbol: String = ""
    @State private var previewData: StockLookupResponse?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private var trimmedSymbol: String {
        symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
    
    private var tickerPlaceholder: String {
        "e.g., AAPL, 0700, 000001"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(tickerPlaceholder, text: $symbol)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .onChange(of: symbol) { _ in
                            previewData = nil
                        }
                    
                    Text("Enter the base ticker. We'll add market suffixes and fetch the live data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Stock Ticker")
                } footer: {
                    Text(tickerFormatHint)
                }
                
                if let preview = previewData {
                    Section("Preview Data") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(preview.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(previewSubtitle(for: preview))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(previewData == nil ? "Fetch" : "Add") {
                        handleSubmit()
                    }
                    .disabled(trimmedSymbol.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView(previewData == nil ? "Fetching Data..." : "Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private var tickerFormatHint: String {
        "Formats: US (AAPL), Hong Kong (0700), China (000001)"
    }
    
    private func validateTicker(_ symbol: String) -> Bool {
        matches("^[A-Z]{1,5}$", in: symbol)
            || matches("^[0-9]{4,5}(\\.HK)?$", in: symbol)
            || matches("^[0-9]{6}(\\.(SS|SZ))?$", in: symbol)
    }
    
    private func inferMarket(for symbol: String) -> String? {
        let upperSymbol = symbol.uppercased()
        if upperSymbol.hasSuffix(".HK") {
            return "HK"
        }
        if upperSymbol.hasSuffix(".SS") || upperSymbol.hasSuffix(".SZ") {
            return "CN"
        }
        if matches("^[A-Z]{1,5}$", in: upperSymbol) {
            return "US"
        }
        if matches("^[0-9]{4,5}$", in: upperSymbol) {
            return "HK"
        }
        if matches("^[0-9]{6}$", in: upperSymbol) {
            return "CN"
        }
        return nil
    }
    
    private func normalizedMarket(_ market: String?) -> String? {
        let trimmed = market?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else { return nil }
        return trimmed.uppercased()
    }
    
    private func normalizedExchange(_ exchange: String?) -> String? {
        let trimmed = exchange?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }
    
    private func previewSubtitle(for preview: StockLookupResponse) -> String {
        let resolvedMarket = normalizedMarket(preview.market)
            ?? inferMarket(for: preview.symbol)
            ?? "US"
        let symbolText = preview.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let exchange = normalizedExchange(preview.exchange) {
            return "\(symbolText) • \(resolvedMarket) • \(exchange)"
        }
        return "\(symbolText) • \(resolvedMarket)"
    }

    private func resolveSymbolAndMarket(from input: String) -> (symbol: String, market: String)? {
        let upperSymbol = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !upperSymbol.isEmpty else { return nil }

        if upperSymbol.hasSuffix(".HK") {
            return (upperSymbol, "HK")
        }
        if upperSymbol.hasSuffix(".SS") || upperSymbol.hasSuffix(".SZ") {
            return (upperSymbol, "CN")
        }
        if matches("^[A-Z]{1,5}$", in: upperSymbol) {
            return (upperSymbol, "US")
        }
        if matches("^[0-9]{4,5}$", in: upperSymbol) {
            return (upperSymbol + ".HK", "HK")
        }
        if matches("^[0-9]{6}$", in: upperSymbol) {
            return (upperSymbol + cnSuffix(for: upperSymbol), "CN")
        }
        return nil
    }

    private func cnSuffix(for code: String) -> String {
        code.hasPrefix("6") ? ".SS" : ".SZ"
    }

    private func matches(_ pattern: String, in symbol: String) -> Bool {
        symbol.range(of: pattern, options: .regularExpression) != nil
    }
    
    private func handleSubmit() {
        let inputSymbol = trimmedSymbol
        
        // Validate ticker format
        if !validateTicker(inputSymbol) {
            errorMessage = "Invalid ticker format. Use AAPL, 0700, or 000001"
            showError = true
            return
        }

        guard let resolved = resolveSymbolAndMarket(from: inputSymbol) else {
            errorMessage = "Unable to infer market from ticker"
            showError = true
            return
        }

        let symbol = resolved.symbol
        let market = resolved.market
        
        // Check if stock already exists
        if viewModel.stocks.contains(where: { $0.symbol.uppercased() == symbol }) {
            errorMessage = "Stock '\(symbol)' already exists"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                if previewData == nil {
                    let fetched = try await viewModel.fetchStockPreview(symbol: symbol, market: market)
                    let preview = StockLookupResponse(
                        symbol: symbol,
                        name: fetched.name,
                        exchange: normalizedExchange(fetched.exchange),
                        market: normalizedMarket(fetched.market) ?? market
                    )
                    await MainActor.run {
                        previewData = preview
                        isLoading = false
                    }
                } else if let preview = previewData {
                    let previewSymbol = preview.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    let resolvedMarket = normalizedMarket(preview.market)
                        ?? inferMarket(for: previewSymbol)
                        ?? "US"
                    try await viewModel.addStock(
                        symbol: previewSymbol,
                        name: preview.name,
                        market: resolvedMarket,
                        exchange: normalizedExchange(preview.exchange)
                    )
                    await MainActor.run {
                        isLoading = false
                        isPresented = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = previewData == nil
                        ? "Failed to fetch stock data: \(error.localizedDescription)"
                        : "Failed to add stock: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Edit Stock View

struct EditSupabaseStockView: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    let stock: SupabaseStock
    @Binding var isPresented: Bool
    
    @State private var name: String
    @State private var exchange: String
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    init(viewModel: SupabasePortfolioViewModel, stock: SupabaseStock, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.stock = stock
        self._isPresented = isPresented
        self._name = State(initialValue: stock.name)
        self._exchange = State(initialValue: stock.exchange ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Stock Information") {
                    HStack {
                        Text("Symbol")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(stock.symbol)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Market")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(stock.market ?? "US")
                            .fontWeight(.medium)
                    }
                    
                    TextField("Company/Fund Name", text: $name)
                    
                    TextField("Exchange", text: $exchange)
                }
            }
            .navigationTitle("Edit Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        updateStock()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
    
    private func updateStock() {
        isLoading = true
        
        Task {
            do {
                try await viewModel.updateStock(
                    id: stock.id,
                    name: name,
                    exchange: exchange.isEmpty ? nil : exchange
                )
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to update stock: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

#Preview {
    SupabaseStocksView(viewModel: SupabasePortfolioViewModel.shared)
}
