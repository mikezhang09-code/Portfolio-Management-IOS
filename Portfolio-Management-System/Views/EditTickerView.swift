//
//  EditTickerView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct EditTickerView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @State var ticker: StockTicker
    @Binding var isPresented: Bool
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Stock Information") {
                    TextField("Ticker Code", text: $ticker.code)
                        .textInputAutocapitalization(.characters)
                    
                    TextField("Company/Fund Name", text: $ticker.name)
                    
                    TextField("Market", text: $ticker.market)
                }
                
                Section("Currency") {
                    Picker("Currency", selection: $ticker.currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                        Text("JPY").tag("JPY")
                        Text("CAD").tag("CAD")
                        Text("AUD").tag("AUD")
                    }
                }
            }
            .navigationTitle("Edit Ticker")
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
        let trimmedCode = ticker.code.trimmingCharacters(in: .whitespaces).uppercased()
        
        if viewModel.isTickerCodeExists(trimmedCode, excludeId: ticker.id) {
            errorMessage = "A ticker with code '\(trimmedCode)' already exists"
            showError = true
            return
        }
        
        ticker.code = trimmedCode
        viewModel.updateTicker(ticker)
        isPresented = false
    }
}

#Preview {
    @State var isPresented = true
    @State var ticker = StockTicker(name: "Apple", code: "AAPL", market: "NASDAQ", currency: "USD")
    return EditTickerView(
        viewModel: PortfolioViewModel(),
        ticker: ticker,
        isPresented: $isPresented
    )
}
