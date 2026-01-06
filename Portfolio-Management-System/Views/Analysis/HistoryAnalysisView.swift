//
//  HistoryAnalysisView.swift
//  Portfolio-Management-System
//
//  Created by admin on 2025/12/20.
//

import SwiftUI
import Charts

struct HistoryAnalysisView: View {
    @ObservedObject private var viewModel = AnalysisViewModel.shared
    @State private var selectedTab: String = "analysis"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Tab Selector
                    Picker("Tab", selection: $selectedTab) {
                        Text("Analysis").tag("analysis")
                        Text("Data Management").tag("data")
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 8)
                    
                    if selectedTab == "analysis" {
                        analysisContent
                    } else {
                        dataManagementContent
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Historical Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.loadAnalysisData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            if viewModel.portfolioSnapshots.isEmpty {
                await viewModel.loadAnalysisData()
            }
        }
    }
    
    // MARK: - Analysis Content
    
    private var analysisContent: some View {
        VStack(spacing: 24) {
            
            // Analysis Controls Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Analysis Controls")
                    .font(.headline)
                
                Text("Configure date range and benchmarks for comparison")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                // Date Range Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Date Range")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AnalysisTimeRange.allCases, id: \.self) { range in
                                Button {
                                    Task {
                                        await viewModel.changeTimeRange(range)
                                    }
                                } label: {
                                    Text(range.rawValue)
                                        .font(.caption.bold())
                                        .foregroundStyle(viewModel.selectedTimeRange == range ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(viewModel.selectedTimeRange == range ? Color.primary : Color(.systemGray6))
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Benchmark Indices Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Benchmark Indices")
                        .font(.headline)
                    
                    Menu {
                        ForEach(viewModel.availableBenchmarks) { benchmark in
                            Button {
                                Task {
                                    await viewModel.changeBenchmark(benchmark.id)
                                }
                            } label: {
                                HStack {
                                    Text(benchmark.name)
                                    if viewModel.selectedBenchmark == benchmark.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.availableBenchmarks.first(where: { $0.id == viewModel.selectedBenchmark })?.name ?? "Select Benchmark")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            
            if viewModel.isLoading {
                ProgressView("Loading data...")
                    .frame(height: 200)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Filtered Analysis")
                        .font(.title3)
                        .bold()
                    Text("Results based on selected date range")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Performance Chart (Moved to Top)
                chartCard
                
                // Risk Metrics
                RiskMetricsCard(
                    volatility: viewModel.volatility,
                    maxDrawdown: viewModel.maxDrawdown,
                    sharpeRatio: viewModel.sharpeRatio,
                    startValue: viewModel.filteredPortfolioSnapshots.last?.navPerShare ?? 0,
                    endValue: viewModel.filteredPortfolioSnapshots.first?.navPerShare ?? 0
                )
            }
        }
    }
    
    // MARK: - Chart Card
    
    private var chartCard: some View {
        let portfolioData = viewModel.normalizeData(viewModel.filteredPortfolioSnapshots)
        let benchmarkData = viewModel.normalizeBenchmarkData(viewModel.filteredBenchmarkSnapshots)
        let benchmarkName = viewModel.selectedBenchmarkName
        
        // Calculate Y-Axis Scale
        let allValues = portfolioData.map(\.1) + benchmarkData.map(\.1)
        let minVal = (allValues.min() ?? 90.0)
        let maxVal = (allValues.max() ?? 110.0)
        // Add 2% padding
        let yDomain = (minVal * 0.98)...(maxVal * 1.02)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Performance Comparison")
                .font(.headline)
            
            if !viewModel.filteredPortfolioSnapshots.isEmpty {
                Chart {
                    // Portfolio line
                    ForEach(portfolioData, id: \.0) { item in
                        LineMark(
                            x: .value("Date", item.0),
                            y: .value("Value", item.1)
                        )
                        .foregroundStyle(by: .value("Series", "Portfolio"))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    
                    // Benchmark line
                    ForEach(benchmarkData, id: \.0) { item in
                        LineMark(
                            x: .value("Date", item.0),
                            y: .value("Value", item.1)
                        )
                        .foregroundStyle(by: .value("Series", benchmarkName))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    
                    // Baseline
                    RuleMark(y: .value("Base", 100))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                }
                .chartForegroundStyleScale([
                    "Portfolio": .blue,
                    benchmarkName: .orange
                ])
                .chartYScale(domain: yDomain)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(Int(val))%")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(xAxisDateString(for: date))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .frame(height: 300) // Increased height slightly
                
                // Legend
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                        Text("Portfolio")
                            .font(.caption)
                            .bold()
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                        Text(benchmarkName)
                            .font(.caption)
                            .bold()
                    }
                }
            } else {
                Text("No data available for selected period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Data Management Content
    
    private var dataManagementContent: some View {
        VStack(spacing: 20) {
            Text("Data Management")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                Image(systemName: "doc.text.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                
                Text("Upload Historical Data")
                    .font(.headline)
                
                Text("Data upload is currently only supported via the Web Application.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Link("Open Web App", destination: URL(string: "https://your-web-app-url.com")!)
                    .buttonStyle(.borderedProminent)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
    
    // MARK: - Helper Methods
    
    private func xAxisDateString(for date: Date) -> String {
        let range = viewModel.selectedTimeRange
        let formatter = DateFormatter()
        
        switch range {
        case .threeYears, .fiveYears, .tenYears, .all:
            formatter.dateFormat = "yyyy"
        case .oneYear:
            formatter.dateFormat = "MMM"
        case .sixMonths:
            formatter.dateFormat = "MMM"
        case .threeMonths:
            formatter.dateFormat = "d MMM"
        }
        
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryAnalysisView()
}
