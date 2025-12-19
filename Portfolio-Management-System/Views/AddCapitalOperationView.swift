//
//  AddCapitalOperationView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct AddCapitalOperationView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @Binding var isPresented: Bool
    
    @State private var selectedType: Capital.CapitalType = .deposit
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Operation Type") {
                    Picker("Type", selection: $selectedType) {
                        Text("Initial Deposit").tag(Capital.CapitalType.initialDeposit)
                        Text("Deposit").tag(Capital.CapitalType.deposit)
                        Text("Withdrawal").tag(Capital.CapitalType.withdrawal)
                        Text("Interest").tag(Capital.CapitalType.interest)
                    }
                }
                
                Section("Amount") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Notes") {
                    TextField("Optional description", text: $description)
                }
            }
            .navigationTitle("Add Capital Operation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveOperation()
                    }
                    .disabled(amount.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveOperation() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }
        
        viewModel.addCapitalOperation(
            type: selectedType,
            amount: amountValue,
            description: description
        )
        
        isPresented = false
    }
}

#Preview {
    @State var isPresented = true
    return AddCapitalOperationView(
        viewModel: PortfolioViewModel(),
        isPresented: $isPresented
    )
}
