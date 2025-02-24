import SwiftUI
import Charts
import os

private let logger = Logger(subsystem: "com.terminal.prototype", category: "ChartView")

/// View for displaying interactive stock charts
struct ChartView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var isLogarithmic = false
    @State private var selectedPoint: PlotPoint?
    @State private var chartScale: CGFloat = 1.0
    @State private var chartOffset: CGSize = .zero
    @State private var showingVolumeChart = true
    @State private var zoomStartDate: Date?
    @State private var zoomEndDate: Date?
    @State private var isDraggingForZoom = false
    @State private var isZoomed = false
    @State private var isZoomMode = false
    @State private var isPanning = false
    @State private var lastDragValue: CGFloat = 0
    @State private var customTimeRange: TimeInterval?
    
    // MARK: - Chart Data Models
    private struct PlotPoint: Identifiable, Equatable {
        let id = UUID()
        let date: Date
        let value: Double
        let displayPrice: Double
        let volume: Int
        
        static func == (lhs: PlotPoint, rhs: PlotPoint) -> Bool {
            lhs.date == rhs.date && lhs.value == rhs.value
        }
    }
    
    private struct PlotRange: Identifiable {
        let id = UUID()
        let date: Date
        let low: Double
        let high: Double
        let displayLow: Double
        let displayHigh: Double
        let volume: Int
    }
    
    // MARK: - Formatters & Constants
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    private let volumeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Zoom Presets
    private enum ZoomPreset: String, CaseIterable {
        case all = "All"
        case max = "Max"
        case year5 = "5Y"
        case year3 = "3Y"
        case year1 = "1Y"
        case month6 = "6M"
        case month3 = "3M"
        case month1 = "1M"
        
        var timeInterval: TimeInterval {
            switch self {
            case .all: return .infinity
            case .max: return .infinity
            case .year5: return 86400 * 365 * 5
            case .year3: return 86400 * 365 * 3
            case .year1: return 86400 * 365
            case .month6: return 86400 * 180
            case .month3: return 86400 * 90
            case .month1: return 86400 * 30
            }
        }
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .max: return "Max"
            default: return rawValue
            }
        }
    }
    
    // MARK: - Computed Properties
    private var plotPoints: [PlotPoint] {
        viewModel.timeSeriesData.map { data in
            let value = isLogarithmic ? log(max(data.adjustedClose, 0.01)) : data.adjustedClose
            return PlotPoint(
                date: data.date,
                value: value,
                displayPrice: data.adjustedClose,
                volume: data.volume
            )
        }
    }
    
    private var plotRanges: [PlotRange] {
        viewModel.timeSeriesData.map { data in
            let low = isLogarithmic ? log(max(data.low, 0.01)) : data.low
            let high = isLogarithmic ? log(max(data.high, 0.01)) : data.high
            return PlotRange(
                date: data.date,
                low: low,
                high: high,
                displayLow: data.low,
                displayHigh: data.high,
                volume: data.volume
            )
        }
    }
    
    private var maxVolume: Int {
        plotPoints.map { $0.volume }.max() ?? 0
    }
    
    private var dateFormatStyle: Date.FormatStyle {
        switch viewModel.selectedTimeRange {
        case .month:
            return .dateTime.month(.abbreviated).day()
        case .year:
            return .dateTime.month(.abbreviated).year(.twoDigits)
        case .max:
            return .dateTime.year()
        }
    }
    
    // Add calendar stride helper
    private func calendarStrideInterval(for timeRange: TimeRange, scale: CGFloat = 1.0) -> TimeInterval {
        let calendar = Calendar.current
        
        switch timeRange {
        case .month:
            return 7 * 24 * 3600 // Weekly
        case .year:
            return scale < 1.5 ? 
                90 * 24 * 3600 : // Quarterly when zoomed out
                30 * 24 * 3600   // Monthly when zoomed in
        case .max:
            return 365 * 24 * 3600 // Yearly
        }
    }
    
    private var xAxisStride: StrideThrough<Date> {
        guard let first = filteredPlotPoints.first?.date,
              let last = filteredPlotPoints.last?.date else {
            return stride(
                from: Date(),
                through: Date(),
                by: 30 * 24 * 3600 // Default monthly stride
            )
        }
        
        let interval = calendarStrideInterval(for: viewModel.selectedTimeRange, scale: chartScale)
        
        // Optimize number of stride points based on view width
        let totalDuration = last.timeIntervalSince(first)
        let desiredPoints = min(10, max(4, Int(totalDuration / interval)))
        let adjustedInterval = totalDuration / Double(desiredPoints)
        
        logger.debug("📊 Stride calculation - Interval: \(interval), Points: \(desiredPoints)")
        
        return stride(
            from: first,
            through: last,
            by: adjustedInterval
        )
    }
    
    private var filteredPlotPoints: [PlotPoint] {
        guard let start = zoomStartDate, let end = zoomEndDate, isZoomed else {
            return plotPoints
        }
        return plotPoints.filter { point in
            point.date >= min(start, end) && point.date <= max(start, end)
        }
    }
    
    private var filteredPlotRanges: [PlotRange] {
        guard let start = zoomStartDate, let end = zoomEndDate, isZoomed else {
            return plotRanges
        }
        return plotRanges.filter { range in
            range.date >= min(start, end) && range.date <= max(start, end)
        }
    }
    
    private var visibleDateRange: (start: Date, end: Date)? {
        guard let first = filteredPlotPoints.first?.date,
              let last = filteredPlotPoints.last?.date else {
            return nil
        }
        
        if let customRange = customTimeRange {
            let end = last
            let start = end.addingTimeInterval(-customRange)
            return (start, end)
        }
        
        return (first, last)
    }
    
    private var zoomedPlotPoints: [PlotPoint] {
        guard let range = visibleDateRange else { return filteredPlotPoints }
        return filteredPlotPoints.filter { point in
            point.date >= range.start && point.date <= range.end
        }
    }
    
    private var zoomedPlotRanges: [PlotRange] {
        guard let range = visibleDateRange else { return filteredPlotRanges }
        return filteredPlotRanges.filter { point in
            point.date >= range.start && point.date <= range.end
        }
    }
    
    // MARK: - View Components
    private var zoomControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ZoomPreset.allCases, id: \.self) { preset in
                    Button(action: { applyZoomPreset(preset) }) {
                        Text(preset.displayName)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(customTimeRange == preset.timeInterval ? Color.blue : Color.clear)
                            .foregroundColor(customTimeRange == preset.timeInterval ? .white : .primary)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var chartControls: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue)
                            .tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Log Scale", isOn: $isLogarithmic.animation())
                    .padding(.leading)
            }
            
            zoomControls
            
            HStack {
                Toggle("Volume", isOn: $showingVolumeChart.animation())
                
                Spacer()
                
                Toggle("Zoom Mode", isOn: $isZoomMode.animation())
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                
                if isZoomed || customTimeRange != nil {
                    Button(action: resetZoom) {
                        Label("Reset Zoom", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    .buttonStyle(.borderless)
                }
                
                Button(action: resetChartView) {
                    Label("Reset View", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal)
    }
    
    private func applyZoomPreset(_ preset: ZoomPreset) {
        withAnimation(.easeInOut) {
            if preset == .all || preset == .max {
                customTimeRange = nil
                resetZoom()
                if preset == .max {
                    viewModel.selectedTimeRange = .max
                }
            } else {
                customTimeRange = preset.timeInterval
                // If current time range doesn't have enough data for the zoom level, switch to a more appropriate range
                if preset.timeInterval > TimeInterval(86400 * 365) {
                    viewModel.selectedTimeRange = .max
                } else if preset.timeInterval > TimeInterval(86400 * 90) {
                    viewModel.selectedTimeRange = .year
                } else {
                    viewModel.selectedTimeRange = .month
                }
            }
        }
    }
    
    private func handlePan(_ value: DragGesture.Value) {
        guard let range = visibleDateRange else { return }
        
        let dragAmount = value.translation.width - lastDragValue
        let totalWidth = UIScreen.main.bounds.width * chartScale
        let timePerPoint = range.end.timeIntervalSince(range.start) / Double(totalWidth)
        let timeOffset = Double(dragAmount) * timePerPoint
        
        if let customRange = customTimeRange {
            let newEnd = range.end.addingTimeInterval(-timeOffset)
            let newStart = newEnd.addingTimeInterval(-customRange)
            
            guard let first = filteredPlotPoints.first?.date,
                  let last = filteredPlotPoints.last?.date,
                  newStart >= first && newEnd <= last else {
                return
            }
        }
        
        chartOffset.width += dragAmount
        lastDragValue = value.translation.width
    }
    
    private func resetChartView() {
        withAnimation(.spring()) {
            chartScale = 1.0
            chartOffset = .zero
            customTimeRange = nil
            resetZoom()
        }
    }
    
    private func resetZoom() {
        withAnimation(.spring()) {
            zoomStartDate = nil
            zoomEndDate = nil
            isZoomed = false
            customTimeRange = nil
        }
    }
    
    private func handleZoomSelection(_ proxy: ChartProxy, _ geometry: GeometryProxy, _ value: DragGesture.Value) {
        let xStart = value.startLocation.x
        let xCurrent = value.location.x
        
        guard xStart >= 0, xStart <= geometry.size.width,
              xCurrent >= 0, xCurrent <= geometry.size.width,
              let dateStart = proxy.value(atX: xStart) as Date?,
              let dateCurrent = proxy.value(atX: xCurrent) as Date? else {
            return
        }
        
        zoomStartDate = dateStart
        zoomEndDate = dateCurrent
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
            VStack(alignment: .leading, spacing: 4) {
                if let point = selectedPoint {
                    HStack {
                        Text(point.date, format: dateFormatStyle)
                        Text(priceFormatter.string(from: NSNumber(value: point.displayPrice)) ?? "")
                            .bold()
                        if showingVolumeChart {
                            Text("Vol: \(volumeFormatter.string(from: NSNumber(value: point.volume)) ?? "")")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
                
                Chart {
                    ForEach(zoomedPlotRanges) { range in
                        AreaMark(
                            x: .value("Time", range.date),
                            yStart: .value("Low", range.low),
                            yEnd: .value("High", range.high)
                        )
                        .foregroundStyle(.blue.opacity(0.2))
                    }
                    
                    ForEach(zoomedPlotPoints) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Price", point.value)
                        )
                        .foregroundStyle(.blue.gradient)
                        
                        if showingVolumeChart {
                            BarMark(
                                x: .value("Time", point.date),
                                y: .value("Volume", Double(point.volume) / Double(maxVolume) * point.value * 0.2)
                            )
                            .foregroundStyle(.gray.opacity(0.3))
                        }
                        
                        if selectedPoint?.id == point.id {
                            RuleMark(
                                x: .value("Selected Time", point.date)
                            )
                            .foregroundStyle(.gray.opacity(0.3))
                            
                            RuleMark(
                                y: .value("Selected Price", point.value)
                            )
                            .foregroundStyle(.gray.opacity(0.3))
                        }
                    }
                    
                    if isDraggingForZoom, let start = zoomStartDate, let end = zoomEndDate {
                        RectangleMark(
                            xStart: .value("Zoom Start", start),
                            xEnd: .value("Zoom End", end),
                            yStart: .value("Min", -Double.infinity),
                            yEnd: .value("Max", Double.infinity)
                        )
                        .foregroundStyle(.blue.opacity(0.2))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: Array(xAxisStride)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisValueLabel {
                                Text(date, format: dateFormatStyle)
                                    .font(.caption)
                                    .rotationEffect(.degrees(-45))
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
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if isZoomMode {
                                            isDraggingForZoom = true
                                            handleZoomSelection(proxy, geometry, value)
                                        } else if !isPanning {
                                            let currentX = value.location.x
                                            guard currentX >= 0,
                                                  currentX <= geometry.size.width,
                                                  let date = proxy.value(atX: currentX) as Date? else {
                                                return
                                            }
                                            
                                            if let point = zoomedPlotPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                                selectedPoint = point
                                            }
                                        }
                                    }
                                    .onEnded { value in
                                        if isZoomMode {
                                            isDraggingForZoom = false
                                            if let start = zoomStartDate, let end = zoomEndDate,
                                               abs(value.startLocation.x - value.location.x) > 20 {
                                                isZoomed = true
                                            }
                                            isZoomMode = false
                                        } else {
                                            selectedPoint = nil
                                        }
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        isPanning = true
                                        handlePan(value)
                                    }
                                    .onEnded { _ in
                                        isPanning = false
                                        lastDragValue = 0
                                    }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / chartScale
                                        chartScale = value
                                        let newScale = min(max(chartScale, 0.5), 3.0)
                                        if chartScale != newScale {
                                            chartScale = newScale
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            chartScale = min(max(chartScale, 0.5), 3.0)
                                        }
                                    }
                            )
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        resetChartView()
                                    }
                            )
                    }
                }
                .frame(height: 300)
                .scaleEffect(x: chartScale, y: 1, anchor: .center)
                .offset(x: chartOffset.width, y: 0)
                .animation(.easeInOut, value: isLogarithmic)
                .animation(.easeInOut, value: showingVolumeChart)
                .animation(.easeInOut, value: isZoomed)
                .animation(.easeInOut, value: customTimeRange)
            }
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
            selectedPoint = nil
            resetChartView()
            Task {
                await viewModel.refreshData()
            }
        }
        .onChange(of: viewModel.selectedSymbol) { newSymbol in
            logger.debug("🔄 Symbol changed to: \(newSymbol)")
            selectedPoint = nil
            resetChartView()
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
