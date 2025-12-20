//
//  AddTransactionView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Binding var isPresented: Bool
    
    @State private var selectedTicker: StockTicker?
    @State private var transactionType: Transaction.TransactionType = .buy
    @State private var quantity: String = ""
    @State private var pricePerUnit: String = ""
    @State private var notes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Stock") {
                    Picker("Select Ticker", selection: $selectedTicker) {
                        Text("Choose a stock").tag(StockTicker?(nil))
                        ForEach(viewModel.tickers) { ticker in
                            Text(ticker.displayName()).tag(StockTicker?(ticker))
                        }
                    }
                }
                
                Section("Transaction Type") {
                    Picker("Type", selection: $transactionType) {
                        Text("Buy").tag(Transaction.TransactionType.buy)
                        Text("Sell").tag(Transaction.TransactionType.sell)
                        Text("Dividend").tag(Transaction.TransactionType.dividend)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Details") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("0", text: $quantity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Price per Unit")
                        Spacer()
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $pricePerUnit)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if let qty = Double(quantity), let price = Double(pricePerUnit) {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(String(format: "$%.2f", qty * price))
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes", text: $notes)
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
                    .disabled(selectedTicker == nil || quantity.isEmpty || pricePerUnit.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveTransaction() {
        guard let ticker = selectedTicker else {
            errorMessage = "Please select a stock"
            showError = true
            return
        }
        
        guard let qty = Double(quantity), qty > 0 else {
            errorMessage = "Please enter a valid quantity"
            showError = true
            return
        }
        
        guard let price = Double(pricePerUnit), price > 0 else {
            errorMessage = "Please enter a valid price"
            showError = true
            return
        }
        
        let transaction = Transaction(
            tickerId: ticker.id,
            type: transactionType,
            quantity: qty,
            pricePerUnit: price,
            notes: notes
        )
        
        viewModel.addTransaction(transaction)
        isPresented = false
    }
}

#Preview {
    @Previewable @State var isPresented = true
    return AddTransactionView(
        viewModel: PortfolioViewModel(),
        isPresented: $isPresented
    )
}
