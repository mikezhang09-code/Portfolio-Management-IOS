//
//  TickerManagementView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/18.
//

import SwiftUI

struct TickerManagementView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    @State private var showingAddTicker = false
    @State private var selectedTicker: StockTicker?
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.tickers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Tickers")
                            .font(.headline)
                        Text("Add your first stock or ETF to get started")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(32)
                } else {
                    List {
                        ForEach(viewModel.tickers) { ticker in
                            TickerRow(ticker: ticker)
                                .onTapGesture {
                                    selectedTicker = ticker
                                    showingEditSheet = true
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteTicker(ticker)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Stock Tickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTicker = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showingAddTicker) {
                AddTickerView(viewModel: viewModel, isPresented: $showingAddTicker)
            }
            .sheet(item: $selectedTicker) { ticker in
                EditTickerView(
                    viewModel: viewModel,
                    ticker: ticker,
                    isPresented: $showingEditSheet
                )
            }
        }
    }
}

struct TickerRow: View {
    let ticker: StockTicker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticker.code)
                        .font(.headline)
                    Text(ticker.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(ticker.market)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(ticker.currency)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TickerManagementView(viewModel: PortfolioViewModel())
}
