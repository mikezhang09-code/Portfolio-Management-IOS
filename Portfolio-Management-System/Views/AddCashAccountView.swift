//
//  AddCashAccountView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/27.
//

import SwiftUI

struct AddCashAccountView: View {
    @ObservedObject var viewModel: SupabasePortfolioViewModel
    @Binding var isPresented: Bool
    @State private var displayName = ""
    @State private var currency = "USD"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let currencies = ["USD", "HKD", "CNY", "EUR", "GBP", "JPY", "CAD", "AUD"]

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Cash Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        submit()
                    }
                    .disabled(isSaving || trimmedName.isEmpty)
                }
            }
        }
    }

    private func submit() {
        errorMessage = nil
        guard !trimmedName.isEmpty else {
            errorMessage = "Enter an account name."
            return
        }

        isSaving = true
        Task {
            do {
                try await viewModel.addCashAccount(currency: currency, displayName: trimmedName)
                isPresented = false
            } catch {
                errorMessage = "Unable to add cash account. \(error.localizedDescription)"
            }
            isSaving = false
        }
    }
}

#Preview {
    AddCashAccountView(viewModel: SupabasePortfolioViewModel.shared, isPresented: .constant(true))
}
