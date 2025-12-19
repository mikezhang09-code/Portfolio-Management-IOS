//
//  AddTickerView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct AddTickerView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Binding var isPresented: Bool
    
    @State private var code: String = ""
    @State private var name: String = ""
    @State private var market: String = ""
    @State private var currency: String = "USD"
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Stock Information") {
                    TextField("Ticker Code (e.g., AAPL)", text: $code)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("Company/Fund Name", text: $name)
                    
                    TextField("Market (e.g., NASDAQ, TSE)", text: $market)
                }
                
                Section("Currency") {
                    Picker("Currency", selection: $currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("JPY").tag("JPY")
                        Text("CAD").tag("CAD")
                        Text("AUD").tag("AUD")
                    }
                }
            }
            .navigationTitle("Add Stock Ticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTicker()
                    }
                    .disabled(code.isEmpty || name.isEmpty || market.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveTicker() {
        let trimmedCode = code.trimmingCharacters(in: .whitespaces).uppercased()
        
        if viewModel.isTickerCodeExists(trimmedCode) {
            errorMessage = "A ticker with code '\(trimmedCode)' already exists"
            showError = true
            return
        }
        
        guard !trimmedCode.isEmpty && !name.isEmpty && !market.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        let ticker = StockTicker(
            name: name,
            code: trimmedCode,
            market: market,
            currency: currency
        )
        
        viewModel.addTicker(ticker)
        isPresented = false
    }
}

#Preview {
    @State var isPresented = true
    return AddTickerView(
        viewModel: PortfolioViewModel(),
        isPresented: $isPresented
    )
}
