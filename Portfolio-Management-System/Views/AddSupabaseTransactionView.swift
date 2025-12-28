//
//  AddSupabaseTransactionView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/29.
//

import SwiftUI

struct AddSupabaseTransactionView: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    @Binding var isPresented: Bool
    var preselectedSymbol: String? = nil
    var allowedTypes: [TransactionEntryType]? = nil

    enum TransactionEntryType: String, CaseIterable, Identifiable {
        case stockBuy = "Stock Buy"
        case stockSell = "Stock Sell"
        case stockDividend = "Stock Dividend"
        case cashDeposit = "Cash Deposit"
        case cashWithdrawal = "Cash Withdrawal"
        case cashInterest = "Cash Interest"
        case currencyExchange = "Currency Exchange"

        var id: String { rawValue }
    }

    @State private var transactionType: TransactionEntryType = .stockBuy
    @State private var selectedDate = Date()
    @State private var status: TransactionStatus = .settled
    @State private var externalRef = ""
    @State private var notes = ""

    @State private var selectedCashAccountId: UUID?
    @State private var targetCashAccountId: UUID?
    @State private var selectedStockId: UUID?

    @State private var amount = ""
    @State private var shares = ""
    @State private var pricePerShare = ""
    @State private var fees = "0"

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var sortedAccounts: [SupabaseCashAccount] {
        viewModel.cashAccounts.sorted { $0.displayName < $1.displayName }
    }

    private var sortedStocks: [SupabaseStock] {
        viewModel.stocks.sorted { $0.symbol < $1.symbol }
    }

    private var selectedCashAccount: SupabaseCashAccount? {
        guard let id = selectedCashAccountId else { return nil }
        return viewModel.cashAccounts.first { $0.id == id }
    }

    private var selectedTargetAccount: SupabaseCashAccount? {
        guard let id = targetCashAccountId else { return nil }
        return viewModel.cashAccounts.first { $0.id == id }
    }

    private var selectedStock: SupabaseStock? {
        guard let id = selectedStockId else { return nil }
        return viewModel.stocks.first { $0.id == id }
    }

    private var isStockTrade: Bool {
        transactionType == .stockBuy || transactionType == .stockSell
    }

    private var isDividend: Bool {
        transactionType == .stockDividend
    }

    private var isCashOnly: Bool {
        transactionType == .cashDeposit || transactionType == .cashWithdrawal || transactionType == .cashInterest
    }

    private var isFxTransfer: Bool {
        transactionType == .currencyExchange
    }

    private var requiresStockSelection: Bool {
        isStockTrade || isDividend
    }

    private var requiresSourceAccount: Bool {
        isCashOnly || isStockTrade || isDividend || isFxTransfer
    }

    private var availableTargetAccounts: [SupabaseCashAccount] {
        sortedAccounts.filter { $0.id != selectedCashAccountId }
    }

    private var isFormValid: Bool {
        if requiresSourceAccount && selectedCashAccountId == nil {
            return false
        }
        if requiresStockSelection && selectedStockId == nil {
            return false
        }

        switch transactionType {
        case .cashDeposit, .cashWithdrawal, .cashInterest:
            return parsedDecimal(amount) ?? 0 > 0
        case .stockBuy, .stockSell:
            return (parsedDecimal(shares) ?? 0) > 0
                && (parsedDecimal(pricePerShare) ?? 0) > 0
                && (parsedDecimal(fees) ?? 0) >= 0
        case .stockDividend:
            return (parsedDecimal(amount) ?? 0) > 0
                && (parsedDecimal(shares) ?? 0) > 0
                && (parsedDecimal(fees) ?? 0) >= 0
        case .currencyExchange:
            guard let source = selectedCashAccountId, let target = targetCashAccountId, source != target else {
                return false
            }
            return (parsedDecimal(amount) ?? 0) > 0
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Type") {
                    Picker("Type", selection: $transactionType) {
                        ForEach(availableTypes) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Date & Status") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    Picker("Status", selection: $status) {
                        Text("Settled").tag(TransactionStatus.settled)
                        Text("Pending").tag(TransactionStatus.pending)
                        Text("Void").tag(TransactionStatus.void)
                    }
                    .pickerStyle(.segmented)
                }

                if requiresStockSelection {
                    Section("Stock") {
                        if sortedStocks.isEmpty {
                            Text("No stocks available. Add one in the Stocks tab first.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Stock", selection: $selectedStockId) {
                                Text("Select stock").tag(UUID?.none)
                                ForEach(sortedStocks, id: \.id) { stock in
                                    Text("\(stock.symbol) - \(stock.name)").tag(Optional(stock.id))
                                }
                            }
                        }
                    }
                }

                if requiresSourceAccount {
                    Section(isFxTransfer ? "From Account" : "Cash Account") {
                        if sortedAccounts.isEmpty {
                            Text("No cash accounts available. Add one in the Cash tab first.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Account", selection: $selectedCashAccountId) {
                                Text("Select account").tag(UUID?.none)
                                ForEach(sortedAccounts, id: \.id) { account in
                                    Text("\(account.displayName) (\(account.currency))").tag(Optional(account.id))
                                }
                            }
                        }
                    }
                }

                if isFxTransfer {
                    Section("To Account") {
                        if availableTargetAccounts.isEmpty {
                            Text("Select a different source account to choose a destination.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Destination", selection: $targetCashAccountId) {
                                Text("Select destination").tag(UUID?.none)
                                ForEach(availableTargetAccounts, id: \.id) { account in
                                    Text("\(account.displayName) (\(account.currency))").tag(Optional(account.id))
                                }
                            }
                        }
                    }
                }

                Section("Amounts") {
                    if isCashOnly {
                        amountField(label: "Amount", text: $amount, currency: selectedCashAccount?.currency)
                    } else if isStockTrade {
                        amountField(label: "Shares", text: $shares, currency: nil)
                        amountField(label: "Price per Share", text: $pricePerShare, currency: selectedCashAccount?.currency)
                        amountField(label: "Fees", text: $fees, currency: selectedCashAccount?.currency)
                    } else if isDividend {
                        amountField(label: "Dividend Amount", text: $amount, currency: selectedCashAccount?.currency)
                        amountField(label: "Shares", text: $shares, currency: nil)
                        amountField(label: "Dividend per Share", text: $pricePerShare, currency: selectedCashAccount?.currency)
                        amountField(label: "Withholding / Fees", text: $fees, currency: selectedCashAccount?.currency)
                    } else if isFxTransfer {
                        amountField(label: "From Amount", text: $amount, currency: selectedCashAccount?.currency)
                        if let targetAmount = fxTargetAmount, let targetCurrency = selectedTargetAccount?.currency {
                            summaryRow(label: "To Amount", value: formatAmount(targetAmount, currency: targetCurrency))
                        }
                    }
                }

                if let summary = summaryRows {
                    Section("Summary") {
                        ForEach(summary, id: \.label) { row in
                            summaryRow(label: row.label, value: row.value)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes)
                    TextField("External reference (optional)", text: $externalRef)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
            .onAppear {
                if let allowed = allowedTypes, !allowed.contains(transactionType), let first = allowed.first {
                    transactionType = first
                }
                ensureDefaultSelections()
            }
            .onChange(of: transactionType) { _, _ in
                ensureDefaultSelections()
            }
            .onChange(of: selectedCashAccountId) { _, _ in
                ensureTargetAccount()
            }
            .onChange(of: viewModel.cashAccounts.count) { _, _ in
                ensureDefaultSelections()
            }
            .onChange(of: viewModel.stocks.count) { _, _ in
                ensureDefaultSelections()
            }
        }
    }

    private var availableTypes: [TransactionEntryType] {
        if let allowed = allowedTypes {
            return allowed
        }
        return TransactionEntryType.allCases
    }

    private var summaryRows: [(label: String, value: String)]? {
        switch transactionType {
        case .stockBuy, .stockSell:
            guard let account = selectedCashAccount,
                  let sharesValue = parsedDecimal(shares),
                  let priceValue = parsedDecimal(pricePerShare) else { return nil }
            let feesValue = parsedDecimal(fees) ?? 0
            let gross = rounded(sharesValue * priceValue, scale: 2)
            let netCash = transactionType == .stockBuy ? gross + feesValue : gross - feesValue
            return [
                (label: "Gross Amount", value: formatAmount(gross, currency: account.currency)),
                (label: "Net Cash", value: formatAmount(netCash, currency: account.currency))
            ]
        case .stockDividend:
            guard let account = selectedCashAccount,
                  let dividend = parsedDecimal(amount) else { return nil }
            let feesValue = parsedDecimal(fees) ?? 0
            let netCash = dividend - feesValue
            return [
                (label: "Net Cash", value: formatAmount(netCash, currency: account.currency))
            ]
        case .currencyExchange:
            return nil
        default:
            return nil
        }
    }

    private var fxTargetAmount: Decimal? {
        guard isFxTransfer,
              let source = selectedCashAccount,
              let target = selectedTargetAccount,
              let sourceAmount = parsedDecimal(amount),
              sourceAmount > 0 else { return nil }
        guard let sourceRate = rateToUSD(for: source.currency),
              let targetRate = rateToUSD(for: target.currency),
              targetRate != 0 else { return nil }
        let usdValue = sourceAmount * sourceRate
        return usdValue / targetRate
    }

    private func amountField(label: String, text: Binding<String>, currency: String?) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let currency {
                Text(currency)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func ensureDefaultSelections() {
        if requiresSourceAccount && selectedCashAccountId == nil {
            selectedCashAccountId = sortedAccounts.first?.id
        }
        if requiresStockSelection && selectedStockId == nil {
            if let symbol = preselectedSymbol,
               let match = sortedStocks.first(where: { $0.symbol == symbol }) {
                selectedStockId = match.id
            } else {
                selectedStockId = sortedStocks.first?.id
            }
        }
        if isFxTransfer {
            ensureTargetAccount()
        }
    }

    private func ensureTargetAccount() {
        guard isFxTransfer else { return }
        if let targetId = targetCashAccountId,
           availableTargetAccounts.contains(where: { $0.id == targetId }) {
            return
        }
        targetCashAccountId = availableTargetAccounts.first?.id
    }

    private func parsedDecimal(_ value: String) -> Decimal? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed.replacingOccurrences(of: ",", with: ""))
    }

    private func rounded(_ value: Decimal, scale: Int) -> Decimal {
        var source = value
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .plain)
        return result
    }

    private func rateToUSD(for currency: String) -> Decimal? {
        let code = currency.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if code == "USD" {
            return 1
        }
        return viewModel.currencyRatesToUSD[code]
    }

    private func formatAmount(_ value: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        let formatted = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
        return "\(formatted) \(currency)"
    }

    private func saveTransaction() {
        isSaving = true
        Task {
            do {
                try await createTransaction()
                await viewModel.forceRefresh()
                await MainActor.run {
                    isSaving = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func createTransaction() async throws {
        let occurredAt = selectedDate
        let settledAt = selectedDate
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExternalRef = externalRef.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesValue = trimmedNotes.isEmpty ? nil : trimmedNotes
        let externalRefValue = trimmedExternalRef.isEmpty ? nil : trimmedExternalRef

        if isCashOnly {
            guard let account = selectedCashAccount else {
                throw TransactionEntryError("Select a cash account.")
            }
            guard let amountValue = parsedDecimal(amount), amountValue > 0 else {
                throw TransactionEntryError("Enter a valid transaction amount.")
            }
            guard let fxRate = rateToUSD(for: account.currency) else {
                throw TransactionEntryError("Missing FX rate for \(account.currency).")
            }

            let roundedAmount = rounded(amountValue, scale: 2)
            let baseAmount = rounded(roundedAmount * fxRate, scale: 4)
            let (direction, legType): (CashTransactionDirection, CashTransactionLegType) = {
                switch transactionType {
                case .cashDeposit:
                    return (.inflow, .deposit)
                case .cashInterest:
                    return (.inflow, .interest)
                default:
                    return (.outflow, .withdrawal)
                }
            }()

            let signedBaseAmount = direction == .inflow ? baseAmount : -baseAmount
            let group = try await viewModel.createTransactionGroup(
                groupType: .cashOnly,
                status: status,
                occurredAt: occurredAt,
                settledAt: settledAt,
                notes: notesValue,
                externalRef: externalRefValue
            )

            _ = try await viewModel.createCashTransaction(
                groupId: group.id,
                cashAccountId: account.id,
                legType: legType,
                direction: direction,
                amount: roundedAmount,
                currency: account.currency,
                fxRate: fxRate,
                baseAmount: signedBaseAmount,
                occurredAt: occurredAt,
                settledAt: settledAt,
                relatedStockTransactionId: nil,
                notes: notesValue
            )
            return
        }

        if isStockTrade {
            guard let account = selectedCashAccount else {
                throw TransactionEntryError("Select a settlement cash account.")
            }
            guard let stock = selectedStock else {
                throw TransactionEntryError("Select a stock symbol.")
            }
            guard let sharesValue = parsedDecimal(shares), sharesValue > 0 else {
                throw TransactionEntryError("Enter a valid share amount.")
            }
            guard let priceValue = parsedDecimal(pricePerShare), priceValue > 0 else {
                throw TransactionEntryError("Enter a valid price per share.")
            }
            let feesValue = parsedDecimal(fees) ?? 0
            if feesValue < 0 {
                throw TransactionEntryError("Fees must be zero or positive.")
            }
            guard let fxRate = rateToUSD(for: account.currency) else {
                throw TransactionEntryError("Missing FX rate for \(account.currency).")
            }

            let grossAmount = rounded(sharesValue * priceValue, scale: 2)
            let roundedFees = rounded(feesValue, scale: 2)
            let netCash = transactionType == .stockBuy ? grossAmount + roundedFees : grossAmount - roundedFees
            if transactionType == .stockSell && netCash <= 0 {
                throw TransactionEntryError("Sell proceeds must exceed fees.")
            }

            let baseGrossAmount = rounded(grossAmount * fxRate, scale: 4)
            let baseFees = rounded(roundedFees * fxRate, scale: 4)
            let baseCashAmount = rounded(netCash * fxRate, scale: 4)
            let cashAmount = netCash < 0 ? -netCash : netCash

            let group = try await viewModel.createTransactionGroup(
                groupType: .stockTrade,
                status: status,
                occurredAt: occurredAt,
                settledAt: settledAt,
                notes: notesValue,
                externalRef: externalRefValue
            )

            let stockTransaction = try await viewModel.createStockTransaction(
                groupId: group.id,
                stockId: stock.id,
                symbol: stock.symbol,
                tradeType: transactionType == .stockBuy ? .buy : .sell,
                tradeDate: occurredAt,
                settlementDate: settledAt,
                quantity: rounded(sharesValue, scale: 6),
                pricePerShare: rounded(priceValue, scale: 4),
                grossAmount: grossAmount,
                fees: roundedFees,
                currency: account.currency,
                fxRate: fxRate,
                baseGrossAmount: baseGrossAmount,
                baseFees: baseFees,
                status: status,
                notes: notesValue
            )

            _ = try await viewModel.createCashTransaction(
                groupId: group.id,
                cashAccountId: account.id,
                legType: transactionType == .stockBuy ? .stockBuy : .stockSell,
                direction: transactionType == .stockBuy ? .outflow : .inflow,
                amount: cashAmount,
                currency: account.currency,
                fxRate: fxRate,
                baseAmount: transactionType == .stockBuy ? -baseCashAmount : baseCashAmount,
                occurredAt: occurredAt,
                settledAt: settledAt,
                relatedStockTransactionId: stockTransaction.id,
                notes: notesValue
            )
            return
        }

        if isDividend {
            guard let account = selectedCashAccount else {
                throw TransactionEntryError("Select the cash account receiving the dividend.")
            }
            guard let stock = selectedStock else {
                throw TransactionEntryError("Select the stock paying the dividend.")
            }
            guard let dividendAmount = parsedDecimal(amount), dividendAmount > 0 else {
                throw TransactionEntryError("Enter a valid dividend amount.")
            }
            guard let sharesValue = parsedDecimal(shares), sharesValue > 0 else {
                throw TransactionEntryError("Enter a valid share count.")
            }
            let feesValue = parsedDecimal(fees) ?? 0
            if feesValue < 0 {
                throw TransactionEntryError("Fees must be zero or positive.")
            }
            if feesValue > dividendAmount {
                throw TransactionEntryError("Fees cannot exceed the dividend amount.")
            }
            guard let fxRate = rateToUSD(for: account.currency) else {
                throw TransactionEntryError("Missing FX rate for \(account.currency).")
            }

            let perShareValue = parsedDecimal(pricePerShare) ?? 0
            let derivedPerShare = perShareValue > 0 ? perShareValue : dividendAmount / sharesValue

            let roundedDividend = rounded(dividendAmount, scale: 2)
            let roundedFees = rounded(feesValue, scale: 2)
            let netCash = roundedDividend - roundedFees
            let baseGrossAmount = rounded(roundedDividend * fxRate, scale: 4)
            let baseFees = rounded(roundedFees * fxRate, scale: 4)
            let baseNetCash = rounded(netCash * fxRate, scale: 4)

            let group = try await viewModel.createTransactionGroup(
                groupType: .dividend,
                status: status,
                occurredAt: occurredAt,
                settledAt: settledAt,
                notes: notesValue,
                externalRef: externalRefValue
            )

            let stockTransaction = try await viewModel.createStockTransaction(
                groupId: group.id,
                stockId: stock.id,
                symbol: stock.symbol,
                tradeType: .dividend,
                tradeDate: occurredAt,
                settlementDate: settledAt,
                quantity: rounded(sharesValue, scale: 6),
                pricePerShare: rounded(derivedPerShare, scale: 4),
                grossAmount: roundedDividend,
                fees: roundedFees,
                currency: account.currency,
                fxRate: fxRate,
                baseGrossAmount: baseGrossAmount,
                baseFees: baseFees,
                status: status,
                notes: notesValue
            )

            _ = try await viewModel.createCashTransaction(
                groupId: group.id,
                cashAccountId: account.id,
                legType: .dividend,
                direction: .inflow,
                amount: netCash,
                currency: account.currency,
                fxRate: fxRate,
                baseAmount: baseNetCash,
                occurredAt: occurredAt,
                settledAt: settledAt,
                relatedStockTransactionId: stockTransaction.id,
                notes: notesValue
            )
            return
        }

        if isFxTransfer {
            guard let sourceAccount = selectedCashAccount else {
                throw TransactionEntryError("Select a source cash account.")
            }
            guard let targetAccount = selectedTargetAccount else {
                throw TransactionEntryError("Select a destination cash account.")
            }
            if sourceAccount.id == targetAccount.id {
                throw TransactionEntryError("Choose two different accounts for an exchange.")
            }
            guard let sourceAmount = parsedDecimal(amount), sourceAmount > 0 else {
                throw TransactionEntryError("Enter a valid amount to exchange.")
            }
            guard let sourceRate = rateToUSD(for: sourceAccount.currency),
                  let targetRate = rateToUSD(for: targetAccount.currency),
                  sourceRate > 0,
                  targetRate > 0 else {
                throw TransactionEntryError("Missing FX rates for selected currencies.")
            }

            let usdValue = sourceAmount * sourceRate
            let targetAmount = usdValue / targetRate
            if targetAmount <= 0 {
                throw TransactionEntryError("Unable to calculate the converted amount.")
            }

            let roundedSourceAmount = rounded(sourceAmount, scale: 2)
            let roundedTargetAmount = rounded(targetAmount, scale: 2)
            let roundedUsdValue = rounded(usdValue, scale: 4)

            let group = try await viewModel.createTransactionGroup(
                groupType: .fxTransfer,
                status: status,
                occurredAt: occurredAt,
                settledAt: settledAt,
                notes: notesValue,
                externalRef: externalRefValue
            )

            _ = try await viewModel.createCashTransaction(
                groupId: group.id,
                cashAccountId: sourceAccount.id,
                legType: .fxOut,
                direction: .outflow,
                amount: roundedSourceAmount,
                currency: sourceAccount.currency,
                fxRate: sourceRate,
                baseAmount: -roundedUsdValue,
                occurredAt: occurredAt,
                settledAt: settledAt,
                relatedStockTransactionId: nil,
                notes: notesValue
            )

            _ = try await viewModel.createCashTransaction(
                groupId: group.id,
                cashAccountId: targetAccount.id,
                legType: .fxIn,
                direction: .inflow,
                amount: roundedTargetAmount,
                currency: targetAccount.currency,
                fxRate: targetRate,
                baseAmount: roundedUsdValue,
                occurredAt: occurredAt,
                settledAt: settledAt,
                relatedStockTransactionId: nil,
                notes: notesValue
            )
        }
    }
}

private struct TransactionEntryError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
