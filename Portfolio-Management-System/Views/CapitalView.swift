//
//  CapitalView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct CapitalView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @State private var showingAddCapital = false
    
    var capitalSummary: CapitalSummary {
        viewModel.getCapitalSummary()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Balance Card
                VStack(spacing: 12) {
                    Text("Current Cash Balance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "$%.2f", capitalSummary.currentCashBalance))
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 16) {
                        BalanceDetailView(label: "Initial", amount: capitalSummary.initialCapital)
                        BalanceDetailView(label: "Deposits", amount: capitalSummary.totalDeposits)
                        BalanceDetailView(label: "Interest", amount: capitalSummary.totalInterest)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(16)
                
                // Capital Operations List
                if viewModel.capitals.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "banknote")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Capital Operations")
                            .font(.headline)
                        Text("Add your initial capital to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                } else {
                    List {
                        ForEach(viewModel.capitals.sorted { $0.date > $1.date }) { capital in
                            CapitalOperationRow(capital: capital)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteCapitalOperation(capital)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
            .navigationTitle("Capital Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddCapital = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showingAddCapital) {
                AddCapitalOperationView(viewModel: viewModel, isPresented: $showingAddCapital)
            }
        }
    }
}

struct BalanceDetailView: View {
    let label: String
    let amount: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(String(format: "$%.2f", amount))
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(.white.opacity(0.5))
        .cornerRadius(8)
    }
}

struct CapitalOperationRow: View {
    let capital: Capital
    
    var typeColor: Color {
        switch capital.type {
        case .initialDeposit, .deposit, .interest:
            return .green
        case .withdrawal:
            return .red
        }
    }
    
    var typeIcon: String {
        switch capital.type {
        case .initialDeposit:
            return "dollarsign.circle.fill"
        case .deposit:
            return "arrow.down.circle.fill"
        case .withdrawal:
            return "arrow.up.circle.fill"
        case .interest:
            return "percent"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .font(.system(size: 20))
                .foregroundStyle(typeColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(capital.type.rawValue)
                    .font(.headline)
                Text(capital.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !capital.description.isEmpty {
                    Text(capital.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%+.2f", capital.amount))
                    .font(.headline)
                    .foregroundStyle(capital.amount >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CapitalView(viewModel: PortfolioViewModel())
}
