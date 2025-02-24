import SwiftUI
import Charts
import os

private let logger = Logger(subsystem: "com.terminal.prototype", category: "ChartView")

/// View for displaying interactive stock charts
struct ChartView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var isLogarithmic = false
    
    // MARK: - Chart Data Models
    private struct PlotPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
    
    private struct PlotRange: Identifiable {
        let id = UUID()
        let date: Date
        let low: Double
        let high: Double
    }
    
    // MARK: - Formatters & Constants
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    // MARK: - Computed Properties
    private var plotPoints: [PlotPoint] {
        viewModel.timeSeriesData.map { data in
            let value = isLogarithmic ? log(max(data.close, 0.01)) : data.close
            return PlotPoint(date: data.date, value: value)
        }
    }
    
    private var plotRanges: [PlotRange] {
        viewModel.timeSeriesData.map { data in
            let low = isLogarithmic ? log(max(data.low, 0.01)) : data.low
            let high = isLogarithmic ? log(max(data.high, 0.01)) : data.high
            return PlotRange(date: data.date, low: low, high: high)
        }
    }
    
    private var dateFormatStyle: Date.FormatStyle {
        switch viewModel.selectedTimeRange {
        case .day:
            return .dateTime.hour()
        case .week, .month:
            return .dateTime.month().day()
        case .year:
            return .dateTime.month().year()
        }
    }
    
    private var xAxisValues: [Date] {
        guard let start = plotPoints.first?.date,
              let end = plotPoints.last?.date else { return [] }
        
        let interval: TimeInterval = viewModel.selectedTimeRange == .day ? 3600 : 86400
        let numberOfPoints = Int((end.timeIntervalSince(start) / interval).rounded()) + 1
        
        return (0..<numberOfPoints).map { index in
            start.addingTimeInterval(Double(index) * interval)
        }
    }
    
    // MARK: - View Components
    private var chartControls: some View {
        HStack {
            Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.rawValue.replacingOccurrences(of: "TIME_SERIES_", with: ""))
                        .tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Toggle("Log Scale", isOn: $isLogarithmic.animation())
                .padding(.leading)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var chartContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(height: 300)
        } else if plotPoints.isEmpty {
            Text("No data available")
                .frame(height: 300)
        } else {
            Chart {
                ForEach(plotRanges) { range in
                    AreaMark(
                        x: .value("Time", range.date),
                        yStart: .value("Low", range.low),
                        yEnd: .value("High", range.high)
                    )
                    .foregroundStyle(.blue.opacity(0.2))
                }
                
                ForEach(plotPoints) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Price", point.value)
                    )
                    .foregroundStyle(.blue.gradient)
                }
            }
            .chartXAxis {
                AxisMarks(values: xAxisValues) { value in
                    if let date = value.as(Date.self) {
                        AxisGridLine()
                        AxisValueLabel {
                            Text(date, format: dateFormatStyle)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let doubleValue = value.as(Double.self) {
                        AxisGridLine()
                        AxisValueLabel {
                            if isLogarithmic {
                                Text(priceFormatter.string(from: NSNumber(value: exp(doubleValue))) ?? "")
                            } else {
                                Text(priceFormatter.string(from: NSNumber(value: doubleValue)) ?? "")
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
            .animation(.easeInOut, value: isLogarithmic)
        }
    }
    
    private var symbolPicker: some View {
        Picker("Symbol", selection: $viewModel.selectedSymbol) {
            ForEach(viewModel.availableSymbols, id: \.self) { symbol in
                Text(symbol).tag(symbol)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            chartControls
            
            chartContent
                .onChange(of: isLogarithmic) { newValue in
                    logger.debug("📊 Scale changed to: \(newValue ? "logarithmic" : "linear")")
                }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            symbolPicker
        }
        .onChange(of: viewModel.selectedTimeRange) { newRange in
            logger.debug("🔄 Time range changed to: \(newRange.rawValue)")
            Task {
                await viewModel.refreshData()
            }
        }
        .onChange(of: viewModel.selectedSymbol) { newSymbol in
            logger.debug("🔄 Symbol changed to: \(newSymbol)")
            Task {
                await viewModel.refreshData()
            }
        }
        .task {
            logger.debug("🚀 Initial chart data load")
            await viewModel.refreshData()
        }
    }
}

// MARK: - Preview Provider
struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(viewModel: DashboardViewModel())
    }
} 