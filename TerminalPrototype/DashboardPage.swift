//
//  DashboardPage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

//import SwiftUI
//import Charts
//
//// StockData model
//struct StockData: Identifiable {
//    let id = UUID()
//    let date: Date
//    let price: Double
//    let open: Double
//    let high: Double
//    let low: Double
//    let volume: Int?
//}
//
//// AlphaVantageResponse for Time Series
//struct AlphaVantageResponse: Codable {
//    struct TimeSeries: Codable {
//        let open: String
//        let high: String
//        let low: String
//        let close: String
//        let volume: String
//        
//        enum CodingKeys: String, CodingKey {
//            case open = "1. open"
//            case high = "2. high"
//            case low = "3. low"
//            case close = "4. close"
//            case volume = "5. volume"
//        }
//    }
//    
//    let timeSeries: [String: TimeSeries]
//    let metaData: MetaData?
//    
//    enum CodingKeys: String, CodingKey {
//        case timeSeries = "Time Series (Daily)"
//        case metaData = "Meta Data"
//    }
//    
//    struct MetaData: Codable {
//        let symbol: String
//        
//        enum CodingKeys: String, CodingKey {
//            case symbol = "2. Symbol"
//        }
//    }
//}
//
//// FinancialData for financial statements
//struct FinancialData: Identifiable {
//    let id = UUID()
//    let metric: String
//    let value: String
//}
//
//// Configuration struct for Alpha Vantage
//struct AlphaVantageConfig {
//    let apiKey: String
//    
//    static func loadFromFile() -> AlphaVantageConfig? {
//        guard let path = Bundle.main.path(forResource: "config", ofType: "json") else {
//            print("Config file not found in bundle")
//            return nil
//        }
//        
//        do {
//            let data = try Data(contentsOf: URL(fileURLWithPath: path))
//            let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
//            if let apiKey = json?["alphaVantageAPIKey"] {
//                return AlphaVantageConfig(apiKey: apiKey)
//            }
//            print("API key not found in config file")
//            return nil
//        } catch {
//            print("Error loading config file: \(error.localizedDescription)")
//            return nil
//        }
//    }
//}
//
//// Design System
//struct DesignSystem {
//    static let primaryColor = Color.blue.opacity(0.9)
//    static let backgroundColor = Color.black
//    static let surfaceColor = Color(.systemGray6).opacity(0.15)
//    static let accentColor = Color.blue
//    static let textColor = Color.white
//    static let secondaryTextColor = Color.gray.opacity(0.8)
//    
//    static let cornerRadius: CGFloat = 12
//    static let padding: CGFloat = 16
//    static let smallPadding: CGFloat = 8
//    static let shadowRadius: CGFloat = 4
//}
//
//// Dashboard Page
//struct DashboardPage: View {
//    @State private var stockPrices: [StockData] = []
//    @State private var selectedData: StockData?
//    @State private var financialData: [[FinancialData]] = []
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//    @State private var tickerSymbol: String = "AAPL"
//    @State private var chartRange: String = "1M"
//    @State private var selectedStatement: String = "TIME_SERIES_DAILY"
//    @State private var isLogScale: Bool = false
//    
//    private let config: AlphaVantageConfig? = AlphaVantageConfig.loadFromFile()
//    
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: DesignSystem.padding * 1.5) {
//                    headerView
//                    chartView
//                    statementButtons
//                    dataTableView
//                }
//                .padding(.vertical, DesignSystem.padding)
//                .padding(.horizontal, DesignSystem.padding * 1.2)
//            }
//            .background(DesignSystem.backgroundColor.edgesIgnoringSafeArea(.all))
//            .navigationTitle("Market Analysis")
//        }
//        .task {
//            await fetchStockData()
//            await fetchFinancialData()
//        }
//    }
//    
//    private var headerView: some View {
//        HStack(alignment: .center, spacing: DesignSystem.padding) {
//            TextField("Ticker", text: $tickerSymbol)
//                .textFieldStyle(PlainTextFieldStyle())
//                .padding(DesignSystem.smallPadding)
//                .background(DesignSystem.surfaceColor)
//                .cornerRadius(DesignSystem.cornerRadius)
//                .foregroundColor(DesignSystem.textColor)
//                .submitLabel(.search)
//                .onSubmit {
//                    Task {
//                        await fetchStockData()
//                        await fetchFinancialData()
//                    }
//                }
//                .frame(maxWidth: 120)
//            
//            Text(tickerSymbol.uppercased())
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(DesignSystem.textColor)
//                .minimumScaleFactor(0.8)
//            
//            Spacer()
//        }
//        .padding(DesignSystem.padding)
//        .background(DesignSystem.surfaceColor)
//        .cornerRadius(DesignSystem.cornerRadius)
//        .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
//    }
//    
//    private var chartView: some View {
//        VStack(spacing: DesignSystem.padding) {
//            if isLoading && stockPrices.isEmpty {
//                ProgressView()
//                    .tint(DesignSystem.accentColor)
//                    .scaleEffect(1.2)
//                    .frame(height: 400)
//            } else if let errorMessage = errorMessage, stockPrices.isEmpty {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .font(.subheadline)
//                    .frame(height: 400)
//            } else {
//                Chart {
//                    ForEach(stockPrices) { dataPoint in
//                        AreaMark(
//                            x: .value("Date", dataPoint.date),
//                            y: .value("Price", isLogScale ? log(dataPoint.price + 1) : dataPoint.price)
//                        )
//                        .foregroundStyle(
//                            Gradient(colors: [
//                                DesignSystem.primaryColor.opacity(0.3),
//                                DesignSystem.primaryColor.opacity(0.0)
//                            ])
//                        )
//                        
//                        LineMark(
//                            x: .value("Date", dataPoint.date),
//                            y: .value("Price", isLogScale ? log(dataPoint.price + 1) : dataPoint.price)
//                        )
//                        .foregroundStyle(DesignSystem.primaryColor)
//                        .lineStyle(StrokeStyle(lineWidth: 2))
//                        
//                        PointMark(
//                            x: .value("Date", dataPoint.date),
//                            y: .value("Price", isLogScale ? log(dataPoint.price + 1) : dataPoint.price)
//                        )
//                        .foregroundStyle(DesignSystem.accentColor)
//                        .symbolSize(selectedData?.id == dataPoint.id ? 100 : 0)
//                    }
//                }
//                .chartOverlay { proxy in
//                    GeometryReader { geometry in
//                        Rectangle().fill(.clear).contentShape(Rectangle())
//                            .gesture(
//                                DragGesture()
//                                    .onChanged { value in
//                                        updateSelectedData(proxy: proxy, location: value.location)
//                                    }
//                                    .onEnded { _ in selectedData = nil }
//                            )
//                    }
//                }
//                .chartXAxis {
//                    AxisMarks(values: .stride(by: .day)) { _ in
//                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
//                            .foregroundStyle(DesignSystem.secondaryTextColor.opacity(0.2))
//                        AxisValueLabel(format: .dateTime.month().day())
//                            .foregroundStyle(DesignSystem.secondaryTextColor)
//                            .font(.caption)
//                    }
//                }
//                .chartYAxis {
//                    AxisMarks(position: .leading) { value in
//                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
//                            .foregroundStyle(DesignSystem.secondaryTextColor.opacity(0.2))
//                        if isLogScale {
//                            if let doubleValue = value.as(Double.self) {
//                                AxisValueLabel("\(exp(doubleValue) - 1, format: .currency(code: "USD"))")
//                                    .foregroundStyle(DesignSystem.secondaryTextColor)
//                            }
//                        } else {
//                            AxisValueLabel("\(value.as(Double.self) ?? 0, format: .currency(code: "USD"))")
//                                .foregroundStyle(DesignSystem.secondaryTextColor)
//                        }
//                    }
//                }
//                .frame(height: 400)
//                .padding(DesignSystem.smallPadding)
//                .background(DesignSystem.surfaceColor)
//                .cornerRadius(DesignSystem.cornerRadius)
//                .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
//                .overlay(
//                    selectedData.map { data in
//                        ChartAnnotation(data: data)
//                    }
//                )
//                
//                HStack(spacing: DesignSystem.padding) {
//                    rangeSelector
//                    scaleSelector
//                }
//                .padding(.top, DesignSystem.smallPadding)
//            }
//        }
//    }
//    
//    private var rangeSelector: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: DesignSystem.smallPadding) {
//                ForEach(["1D", "1W", "1M", "3M", "1Y"], id: \.self) { range in
//                    ChartButton(
//                        title: range,
//                        isSelected: chartRange == range,
//                        action: {
//                            chartRange = range
//                            Task { await fetchStockData() }
//                        }
//                    )
//                }
//            }
//            .padding(.vertical, DesignSystem.smallPadding)
//        }
//    }
//    
//    private var scaleSelector: some View {
//        HStack(spacing: DesignSystem.smallPadding) {
//            ChartButton(
//                title: "Linear",
//                isSelected: !isLogScale,
//                action: { isLogScale = false }
//            )
//            ChartButton(
//                title: "Log",
//                isSelected: isLogScale,
//                action: { isLogScale = true }
//            )
//        }
//    }
//    
//    private var statementButtons: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: DesignSystem.smallPadding) {
//                StatementButton(title: "Daily", endpoint: "TIME_SERIES_DAILY", isSelected: selectedStatement == "TIME_SERIES_DAILY") {
//                    selectedStatement = "TIME_SERIES_DAILY"
//                    Task { await fetchFinancialData() }
//                }
//                StatementButton(title: "Income", endpoint: "INCOME_STATEMENT", isSelected: selectedStatement == "INCOME_STATEMENT") {
//                    selectedStatement = "INCOME_STATEMENT"
//                    Task { await fetchFinancialData() }
//                }
//                StatementButton(title: "Balance", endpoint: "BALANCE_SHEET", isSelected: selectedStatement == "BALANCE_SHEET") {
//                    selectedStatement = "BALANCE_SHEET"
//                    Task { await fetchFinancialData() }
//                }
//                StatementButton(title: "Cash Flow", endpoint: "CASH_FLOW", isSelected: selectedStatement == "CASH_FLOW") {
//                    selectedStatement = "CASH_FLOW"
//                    Task { await fetchFinancialData() }
//                }
//                StatementButton(title: "Overview", endpoint: "OVERVIEW", isSelected: selectedStatement == "OVERVIEW") {
//                    selectedStatement = "OVERVIEW"
//                    Task { await fetchFinancialData() }
//                }
//            }
//            .padding(.vertical, DesignSystem.smallPadding)
//        }
//    }
//    
//    private var dataTableView: some View {
//        VStack(alignment: .leading, spacing: DesignSystem.padding) {
//            Text(selectedStatement.replacingOccurrences(of: "_", with: " ").capitalized)
//                .font(.headline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.bottom, DesignSystem.smallPadding)
//            
//            if isLoading && financialData.isEmpty {
//                ProgressView()
//                    .tint(DesignSystem.accentColor)
//                    .scaleEffect(1.2)
//            } else if let errorMessage = errorMessage, financialData.isEmpty {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .font(.subheadline)
//            } else {
//                LazyVGrid(
//                    columns: [
//                        GridItem(.flexible(minimum: 150), alignment: .leading),
//                        GridItem(.flexible(), alignment: .trailing),
//                        GridItem(.flexible(), alignment: .trailing),
//                        GridItem(.flexible(), alignment: .trailing)
//                    ],
//                    spacing: DesignSystem.smallPadding
//                ) {
//                    tableHeader
//                    tableContent
//                }
//                .padding(DesignSystem.padding)
//                .background(DesignSystem.surfaceColor.opacity(0.8))
//                .cornerRadius(DesignSystem.cornerRadius)
//            }
//        }
//        .padding(DesignSystem.padding)
//        .background(DesignSystem.surfaceColor)
//        .cornerRadius(DesignSystem.cornerRadius)
//        .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
//        .frame(maxHeight: 400)
//    }
//    
//    @ViewBuilder
//    private var tableHeader: some View {
//        if selectedStatement == "TIME_SERIES_DAILY" {
//            Text("Date")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//            Text("Close")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//            Text("Open")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//            Text("Volume")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//        } else {
//            Text("Metric")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//            Text("Latest Year")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//            Text("Year -1")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//            Text("Year -2")
//                .font(.subheadline)
//                .fontWeight(.semibold)
//                .foregroundColor(DesignSystem.textColor)
//                .padding(.vertical, DesignSystem.smallPadding / 2)
//        }
//    }
//    
//    @ViewBuilder
//    private var tableContent: some View {
//        if selectedStatement == "TIME_SERIES_DAILY" {
//            ForEach(stockPrices.reversed().prefix(10)) { data in
//                Text(data.date, format: .dateTime.month().day().year())
//                    .foregroundColor(DesignSystem.secondaryTextColor)
//                Text(data.price, format: .currency(code: "USD"))
//                    .foregroundColor(DesignSystem.textColor)
//                Text(data.open, format: .currency(code: "USD"))
//                    .foregroundColor(DesignSystem.textColor)
//                Text("\(data.volume ?? 0)")
//                    .foregroundColor(DesignSystem.textColor)
//            }
//        } else {
//            ForEach(0..<min(financialData.count, 10), id: \.self) { index in
//                let metricData = financialData[index]
//                Text(formatMetricTitle(metricData[0].metric))
//                    .foregroundColor(DesignSystem.secondaryTextColor)
//                ForEach(0..<min(metricData.count, 3)) { yearIndex in
//                    Text(formatValue(metricData[yearIndex].value))
//                        .foregroundColor(DesignSystem.textColor)
//                }
//                if metricData.count < 3 {
//                    ForEach(metricData.count..<3, id: \.self) { _ in
//                        Text("-")
//                            .foregroundColor(DesignSystem.secondaryTextColor)
//                    }
//                }
//            }
//        }
//    }
//    
//    // Custom Components
//    struct ChartButton: View {
//        let title: String
//        let isSelected: Bool
//        let action: () -> Void
//        
//        var body: some View {
//            Button(action: action) {
//                Text(title)
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundColor(isSelected ? DesignSystem.textColor : DesignSystem.secondaryTextColor)
//                    .padding(.horizontal, DesignSystem.padding)
//                    .padding(.vertical, DesignSystem.smallPadding)
//                    .background(
//                        Capsule()
//                            .fill(isSelected ? DesignSystem.primaryColor : DesignSystem.surfaceColor)
//                            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: 2)
//                    )
//            }
//            .buttonStyle(PlainButtonStyle())
//            .scaleEffect(isSelected ? 1.05 : 1.0)
//            .animation(.spring(response: 0.3), value: isSelected)
//        }
//    }
//    
//    struct StatementButton: View {
//        let title: String
//        let endpoint: String
//        let isSelected: Bool
//        let action: () -> Void
//        
//        var body: some View {
//            Button(action: action) {
//                Text(title)
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundColor(isSelected ? DesignSystem.textColor : DesignSystem.secondaryTextColor)
//                    .padding(.horizontal, DesignSystem.padding)
//                    .padding(.vertical, DesignSystem.smallPadding)
//                    .background(
//                        Capsule()
//                            .fill(isSelected ? DesignSystem.primaryColor : DesignSystem.surfaceColor)
//                            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: 2)
//                    )
//            }
//            .buttonStyle(PlainButtonStyle())
//            .scaleEffect(isSelected ? 1.05 : 1.0)
//            .animation(.spring(response: 0.3), value: isSelected)
//        }
//    }
//    
//    struct ChartAnnotation: View {
//        let data: StockData
//        
//        var body: some View {
//            VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
//                Text("Date: \(data.date, format: .dateTime.month().day())")
//                Text("Close: \(data.price, format: .currency(code: "USD"))")
//                Text("Open: \(data.open, format: .currency(code: "USD"))")
//                Text("High: \(data.high, format: .currency(code: "USD"))")
//                Text("Low: \(data.low, format: .currency(code: "USD"))")
//            }
//            .font(.caption)
//            .padding(DesignSystem.padding)
//            .background(DesignSystem.backgroundColor.opacity(0.95))
//            .foregroundColor(DesignSystem.textColor)
//            .cornerRadius(DesignSystem.cornerRadius)
//            .shadow(color: .black.opacity(0.3), radius: DesignSystem.shadowRadius)
//            .position(x: 100, y: 50)
//        }
//    }
//    
//    private func updateSelectedData(proxy: ChartProxy, location: CGPoint) {
//        if let date = proxy.value(atX: location.x) as Date?,
//           let closest = stockPrices.min(by: {
//               abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
//           }) {
//            selectedData = closest
//        }
//    }
//    
//    private func fetchStockData() async {
//        guard let apiKey = config?.apiKey else {
//            errorMessage = "API key not found in configuration"
//            return
//        }
//        
//        isLoading = true
//        errorMessage = nil
//        
//        let urlString = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=\(tickerSymbol)&apikey=\(apiKey)"
//        guard let url = URL(string: urlString) else {
//            errorMessage = "Invalid URL"
//            isLoading = false
//            return
//        }
//        
//        do {
//            let (data, _) = try await URLSession.shared.data(from: url)
//            let decoder = JSONDecoder()
//            let response = try decoder.decode(AlphaVantageResponse.self, from: data)
//            
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy-MM-dd"
//            
//            let allPrices = response.timeSeries.map { (dateString, timeSeries) in
//                let date = dateFormatter.date(from: dateString) ?? Date()
//                return StockData(
//                    date: date,
//                    price: Double(timeSeries.close) ?? 0.0,
//                    open: Double(timeSeries.open) ?? 0.0,
//                    high: Double(timeSeries.high) ?? 0.0,
//                    low: Double(timeSeries.low) ?? 0.0,
//                    volume: Int(timeSeries.volume)
//                )
//            }.sorted { $0.date < $1.date }
//            
//            let now = Date()
//            stockPrices = allPrices.filter { data in
//                let calendar = Calendar.current
//                switch chartRange {
//                case "1D":
//                    let startOfDay = calendar.startOfDay(for: now)
//                    return data.date >= startOfDay
//                case "1W": return data.date > calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
//                case "1M": return data.date > calendar.date(byAdding: .month, value: -1, to: now)!
//                case "3M": return data.date > calendar.date(byAdding: .month, value: -3, to: now)!
//                case "1Y": return data.date > calendar.date(byAdding: .year, value: -1, to: now)!
//                default: return true
//                }
//            }
//            
//            tickerSymbol = response.metaData?.symbol ?? tickerSymbol
//            isLoading = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoading = false
//        }
//    }
//    
//    private func fetchFinancialData() async {
//        guard let apiKey = config?.apiKey else {
//            errorMessage = "API key not found in configuration"
//            return
//        }
//        
//        isLoading = true
//        errorMessage = nil
//        
//        let urlString = "https://www.alphavantage.co/query?function=\(selectedStatement)&symbol=\(tickerSymbol)&apikey=\(apiKey)"
//        guard let url = URL(string: urlString) else {
//            errorMessage = "Invalid URL"
//            isLoading = false
//            return
//        }
//        
//        do {
//            let (data, _) = try await URLSession.shared.data(from: url)
//            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
//            
//            financialData = parseFinancialData(json)
//            isLoading = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isLoading = false
//        }
//    }
//    
//    private func parseFinancialData(_ json: [String: Any]) -> [[FinancialData]] {
//        var yearlyData: [[FinancialData]] = []
//        
//        switch selectedStatement {
//        case "INCOME_STATEMENT", "BALANCE_SHEET", "CASH_FLOW":
//            if let reports = json["annualReports"] as? [[String: String]] {
//                var metricsDict: [String: [String]] = [:]
//                
//                for (index, report) in reports.enumerated() {
//                    guard index < 3 else { break }
//                    for (key, value) in report {
//                        metricsDict[key, default: []].append(value)
//                    }
//                }
//                
//                yearlyData = metricsDict.map { key, values in
//                    values.enumerated().map { FinancialData(metric: key, value: $1) }
//                }.sorted { $0[0].metric < $1[0].metric }
//            }
//            
//        case "OVERVIEW":
//            let data = json.map { FinancialData(metric: $0.key, value: String(describing: $0.value)) }
//            yearlyData = [data]
//            
//        case "TIME_SERIES_DAILY":
//            yearlyData = []
//            
//        default:
//            yearlyData = []
//        }
//        
//        return yearlyData
//    }
//    
//    private func formatMetricTitle(_ metric: String) -> String {
//        let words = metric.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
//            .replacingOccurrences(of: "_", with: " ")
//            .trimmingCharacters(in: .whitespaces)
//            .capitalized
//            .split(separator: " ")
//            .map { String($0) }
//        
//        return words.joined(separator: " ")
//    }
//    
//    private func formatValue(_ value: String) -> String {
//        if let doubleValue = Double(value) {
//            if doubleValue > 1_000_000_000 {
//                return String(format: "%.2fB", doubleValue / 1_000_000_000)
//            } else if doubleValue > 1_000_000 {
//                return String(format: "%.2fM", doubleValue / 1_000_000)
//            } else if doubleValue > 1_000 {
//                return String(format: "%.2fK", doubleValue / 1_000)
//            }
//            return String(format: "%.2f", doubleValue)
//        }
//        return value
//    }
//}
//
//// Main App View
//struct StockAppView: View {
//    var body: some View {
//        TabView {
//            DashboardPage()
//                .tabItem {
//                    Label("Dashboard", systemImage: "chart.xyaxis.line")
//                }
//            
//            NavigationStack {
//                Text("Portfolio Page")
//                    .navigationTitle("Portfolio")
//            }
//            .tabItem {
//                Label("Portfolio", systemImage: "briefcase")
//            }
//            
//            NavigationStack {
//                Text("Settings Page")
//                    .navigationTitle("Settings")
//            }
//            .tabItem {
//                Label("Settings", systemImage: "gear")
//            }
//        }
//        .accentColor(DesignSystem.accentColor)
//        .preferredColorScheme(.dark)
//    }
//}
//
//#Preview {
//    StockAppView()
//}

import SwiftUI
import Charts

// StockData model
struct StockData: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
    let open: Double
    let high: Double
    let low: Double
    let volume: Int?
}

// AlphaVantageResponse for Time Series
struct AlphaVantageResponse: Codable {
    struct TimeSeries: Codable {
        let open: String
        let high: String
        let low: String
        let close: String
        let volume: String
        
        enum CodingKeys: String, CodingKey {
            case open = "1. open"
            case high = "2. high"
            case low = "3. low"
            case close = "4. close"
            case volume = "5. volume"
        }
    }
    
    let timeSeries: [String: TimeSeries]
    let metaData: MetaData?
    
    enum CodingKeys: String, CodingKey {
        case timeSeries = "Time Series (Daily)"
        case metaData = "Meta Data"
    }
    
    struct MetaData: Codable {
        let symbol: String
        
        enum CodingKeys: String, CodingKey {
            case symbol = "2. Symbol"
        }
    }
}

// FinancialData for financial statements
struct FinancialData: Identifiable {
    let id = UUID()
    let metric: String
    let value: String
    let year: Int?
}

// Configuration struct for Alpha Vantage
struct AlphaVantageConfig {
    let apiKey: String
    
    static func loadFromFile() -> AlphaVantageConfig? {
        guard let path = Bundle.main.path(forResource: "config", ofType: "json") else {
            print("Config file not found in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
            if let apiKey = json?["alphaVantageAPIKey"] {
                return AlphaVantageConfig(apiKey: apiKey)
            }
            print("API key not found in config file")
            return nil
        } catch {
            print("Error loading config file: \(error.localizedDescription)")
            return nil
        }
    }
}

// Design System
struct DesignSystem {
    static let primaryColor = Color.blue.opacity(0.9)
    static let backgroundColor = Color.black
    static let surfaceColor = Color(.systemGray6).opacity(0.15)
    static let accentColor = Color.blue
    static let textColor = Color.white
    static let secondaryTextColor = Color.gray.opacity(0.8)
    static let tableHeaderColor = Color.blue.opacity(0.1)
    static let tableHoverColor = Color.blue.opacity(0.05)
    static let tableBorderColor = Color.gray.opacity(0.2)
    
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let shadowRadius: CGFloat = 4
}

// Dashboard Page
struct DashboardPage: View {
    @State private var stockPrices: [StockData] = []
    @State private var selectedData: StockData?
    @State private var financialData: [[FinancialData]] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var tickerSymbol: String = "AAPL"
    @State private var chartRange: String = "1M"
    @State private var selectedStatement: String = "TIME_SERIES_DAILY"
    @State private var isLogScale: Bool = false
    
    private let config: AlphaVantageConfig? = AlphaVantageConfig.loadFromFile()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.padding * 1.5) {
                    headerView
                    chartView
                    statementButtons
                    dataTableView
                }
                .padding(.vertical, DesignSystem.padding)
                .padding(.horizontal, DesignSystem.padding * 1.2)
            }
            .background(DesignSystem.backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationTitle("Market Analysis")
        }
        .task {
            await fetchStockData()
            await fetchFinancialData()
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .center, spacing: DesignSystem.padding) {
            TextField("Ticker", text: $tickerSymbol)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(DesignSystem.smallPadding)
                .background(DesignSystem.surfaceColor)
                .cornerRadius(DesignSystem.cornerRadius)
                .foregroundColor(DesignSystem.textColor)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await fetchStockData()
                        await fetchFinancialData()
                    }
                }
                .frame(maxWidth: 120)
            
            Text(tickerSymbol.uppercased())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.textColor)
                .minimumScaleFactor(0.8)
            
            Spacer()
        }
        .padding(DesignSystem.padding)
        .background(DesignSystem.surfaceColor)
        .cornerRadius(DesignSystem.cornerRadius)
        .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
    }
    
    private var chartView: some View {
        VStack(spacing: DesignSystem.padding) {
            if isLoading && stockPrices.isEmpty {
                ProgressView()
                    .tint(DesignSystem.accentColor)
                    .scaleEffect(1.2)
                    .frame(height: 400)
            } else if let errorMessage = errorMessage, stockPrices.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .frame(height: 400)
            } else {
                Chart {
                    ForEach(stockPrices, id: \.id) { dataPoint in
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Price", isLogScale ? log(dataPoint.price + 1) : dataPoint.price)
                        )
                        .foregroundStyle(
                            Gradient(colors: [
                                DesignSystem.primaryColor.opacity(0.3),
                                DesignSystem.primaryColor.opacity(0.0)
                            ])
                        )
                        
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Price", isLogScale ? log(dataPoint.price + 1) : dataPoint.price)
                        )
                        .foregroundStyle(DesignSystem.primaryColor)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Price", isLogScale ? log(dataPoint.price + 1) : dataPoint.price)
                        )
                        .foregroundStyle(DesignSystem.accentColor)
                        .symbolSize(selectedData?.id == dataPoint.id ? 100 : 0)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        updateSelectedData(proxy: proxy, location: value.location)
                                    }
                                    .onEnded { _ in selectedData = nil }
                            )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(DesignSystem.secondaryTextColor.opacity(0.2))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: dateFormatter)
                            }
                        }
                        .foregroundStyle(DesignSystem.secondaryTextColor)
                        .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(DesignSystem.secondaryTextColor.opacity(0.2))
                        if isLogScale {
                            if let doubleValue = value.as(Double.self) {
                                AxisValueLabel("\(exp(doubleValue) - 1, format: .currency(code: "USD"))")
                                    .foregroundStyle(DesignSystem.secondaryTextColor)
                            }
                        } else {
                            AxisValueLabel("\(value.as(Double.self) ?? 0, format: .currency(code: "USD"))")
                                .foregroundStyle(DesignSystem.secondaryTextColor)
                        }
                    }
                }
                .frame(height: 400)
                .padding(DesignSystem.smallPadding)
                .background(DesignSystem.surfaceColor)
                .cornerRadius(DesignSystem.cornerRadius)
                .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
                .overlay(
                    selectedData.map { data in
                        ChartAnnotation(data: data, dateFormatter: dateFormatter)
                    }
                )
                
                HStack(spacing: DesignSystem.padding) {
                    rangeSelector
                    scaleSelector
                }
                .padding(.top, DesignSystem.smallPadding)
            }
        }
    }
    
    private var rangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.smallPadding) {
                ForEach(["1D", "1W", "1M", "3M", "1Y"], id: \.self) { range in
                    ChartButton(
                        title: range,
                        isSelected: chartRange == range,
                        action: {
                            chartRange = range
                            Task { await fetchStockData() }
                        }
                    )
                }
            }
            .padding(.vertical, DesignSystem.smallPadding)
        }
    }
    
    private var scaleSelector: some View {
        HStack(spacing: DesignSystem.smallPadding) {
            ChartButton(
                title: "Linear",
                isSelected: !isLogScale,
                action: { isLogScale = false }
            )
            ChartButton(
                title: "Log",
                isSelected: isLogScale,
                action: { isLogScale = true }
            )
        }
    }
    
    private var statementButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.smallPadding) {
                StatementButton(title: "Daily", endpoint: "TIME_SERIES_DAILY", isSelected: selectedStatement == "TIME_SERIES_DAILY") {
                    selectedStatement = "TIME_SERIES_DAILY"
                    Task { await fetchFinancialData() }
                }
                StatementButton(title: "Income", endpoint: "INCOME_STATEMENT", isSelected: selectedStatement == "INCOME_STATEMENT") {
                    selectedStatement = "INCOME_STATEMENT"
                    Task { await fetchFinancialData() }
                }
                StatementButton(title: "Balance", endpoint: "BALANCE_SHEET", isSelected: selectedStatement == "BALANCE_SHEET") {
                    selectedStatement = "BALANCE_SHEET"
                    Task { await fetchFinancialData() }
                }
                StatementButton(title: "Cash Flow", endpoint: "CASH_FLOW", isSelected: selectedStatement == "CASH_FLOW") {
                    selectedStatement = "CASH_FLOW"
                    Task { await fetchFinancialData() }
                }
                StatementButton(title: "Overview", endpoint: "OVERVIEW", isSelected: selectedStatement == "OVERVIEW") {
                    selectedStatement = "OVERVIEW"
                    Task { await fetchFinancialData() }
                }
            }
            .padding(.vertical, DesignSystem.smallPadding)
        }
    }
    
    private var dataTableView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.padding) {
            Text(selectedStatement.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.textColor)
                .padding(.bottom, DesignSystem.smallPadding)
            
            if isLoading && financialData.isEmpty {
                ProgressView()
                    .tint(DesignSystem.accentColor)
                    .scaleEffect(1.2)
            } else if let errorMessage = errorMessage, financialData.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else {
                ScrollView(.vertical) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(minimum: 200), alignment: .leading),
                            GridItem(.flexible(), alignment: .trailing),
                            GridItem(.flexible(), alignment: .trailing),
                            GridItem(.flexible(), alignment: .trailing)
                        ],
                        spacing: 0
                    ) {
                        tableHeader
                        tableContent
                    }
                }
                .frame(maxHeight: 400)
                .background(DesignSystem.surfaceColor.opacity(0.8))
                .cornerRadius(DesignSystem.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                        .stroke(DesignSystem.tableBorderColor, lineWidth: 1)
                )
            }
        }
        .padding(DesignSystem.padding)
        .background(DesignSystem.surfaceColor)
        .cornerRadius(DesignSystem.cornerRadius)
        .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
    }
    
    private var tableHeader: some View {
        Group {
            if selectedStatement == "TIME_SERIES_DAILY" {
                tableHeaderCell("Date")
                tableHeaderCell("Close")
                tableHeaderCell("Open")
                tableHeaderCell("Volume")
            } else {
                tableHeaderCell("Metric")
                tableHeaderCell("2024")
                tableHeaderCell("2023")
                tableHeaderCell("2022")
            }
        }
        .background(DesignSystem.tableHeaderColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(DesignSystem.tableBorderColor),
            alignment: .bottom
        )
    }
    
    private func tableHeaderCell(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(DesignSystem.textColor)
            .padding(.vertical, DesignSystem.smallPadding)
            .padding(.horizontal, DesignSystem.padding)
            .frame(maxWidth: .infinity, alignment: text == "Metric" ? .leading : .trailing)
    }
    
    private var tableContent: some View {
        Group {
            if selectedStatement == "TIME_SERIES_DAILY" {
                ForEach(stockPrices.reversed().prefix(10), id: \.id) { data in
                    tableCell(data.date)
                    tableCell(data.price, format: .currency(code: "USD"))
                    tableCell(data.open, format: .currency(code: "USD"))
                    tableCell("\(data.volume ?? 0)")
                }
            } else {
                ForEach(0..<min(financialData.count, 10), id: \.self) { index in
                    let metricData = financialData[index]
                    tableCell(formatMetricTitle(metricData[0].metric), isMetric: true)
                    ForEach(0..<min(metricData.count, 3), id: \.self) { yearIndex in
                        tableCell(formatValue(metricData[yearIndex].value))
                    }
                    if metricData.count < 3 {
                        ForEach(0..<(3 - metricData.count), id: \.self) { _ in
                            tableCell("-")
                        }
                    }
                }
            }
        }
        .overlay(
            Divider()
                .foregroundColor(DesignSystem.tableBorderColor)
                .padding(.horizontal, DesignSystem.padding),
            alignment: .top
        )
    }
    
    private let dateFormatter: Date.FormatStyle = .dateTime.month().day().year()
    
    private func tableCell(_ value: String, isMetric: Bool = false) -> some View {
        HStack {
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(isMetric ? DesignSystem.secondaryTextColor : DesignSystem.textColor)
                .padding(.vertical, DesignSystem.smallPadding)
                .padding(.horizontal, DesignSystem.padding)
                .frame(maxWidth: .infinity, alignment: isMetric ? .leading : .trailing)
        }
        .background(Color.clear)
        .contentShape(Rectangle())
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(DesignSystem.tableBorderColor),
            alignment: .trailing
        )
    }
    
    private func tableCell(_ value: Date) -> some View {
        tableCell(value.formatted(dateFormatter))
    }
    
    private func tableCell(_ value: Double, format: FloatingPointFormatStyle<Double>.Currency) -> some View {
        tableCell(value.formatted(format))
    }
    
    // Custom Components
    struct ChartButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? DesignSystem.textColor : DesignSystem.secondaryTextColor)
                    .padding(.horizontal, DesignSystem.padding)
                    .padding(.vertical, DesignSystem.smallPadding)
                    .background(
                        Capsule()
                            .fill(isSelected ? DesignSystem.primaryColor : DesignSystem.surfaceColor)
                            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
    
    struct StatementButton: View {
        let title: String
        let endpoint: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? DesignSystem.textColor : DesignSystem.secondaryTextColor)
                    .padding(.horizontal, DesignSystem.padding)
                    .padding(.vertical, DesignSystem.smallPadding)
                    .background(
                        Capsule()
                            .fill(isSelected ? DesignSystem.primaryColor : DesignSystem.surfaceColor)
                            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.1), radius: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
    
    struct ChartAnnotation: View {
        let data: StockData
        let dateFormatter: Date.FormatStyle
        
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                Text("Date: \(data.date.formatted(dateFormatter))")
                Text("Close: \(data.price, format: .currency(code: "USD"))")
                Text("Open: \(data.open, format: .currency(code: "USD"))")
                Text("High: \(data.high, format: .currency(code: "USD"))")
                Text("Low: \(data.low, format: .currency(code: "USD"))")
            }
            .font(.caption)
            .padding(DesignSystem.padding)
            .background(DesignSystem.backgroundColor.opacity(0.95))
            .foregroundColor(DesignSystem.textColor)
            .cornerRadius(DesignSystem.cornerRadius)
            .shadow(color: .black.opacity(0.3), radius: DesignSystem.shadowRadius)
            .position(x: 100, y: 50)
        }
    }
    
    private func updateSelectedData(proxy: ChartProxy, location: CGPoint) {
        if let date = proxy.value(atX: location.x) as Date?,
           let closest = stockPrices.min(by: {
               abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
           }) {
            selectedData = closest
        }
    }
    
    private func fetchStockData() async {
        guard let apiKey = config?.apiKey else {
            errorMessage = "API key not found in configuration"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=\(tickerSymbol)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(AlphaVantageResponse.self, from: data)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let allPrices = response.timeSeries.map { (dateString, timeSeries) in
                let date = dateFormatter.date(from: dateString) ?? Date()
                return StockData(
                    date: date,
                    price: Double(timeSeries.close) ?? 0.0,
                    open: Double(timeSeries.open) ?? 0.0,
                    high: Double(timeSeries.high) ?? 0.0,
                    low: Double(timeSeries.low) ?? 0.0,
                    volume: Int(timeSeries.volume)
                )
            }.sorted { $0.date < $1.date }
            
            let now = Date()
            stockPrices = allPrices.filter { data in
                let calendar = Calendar.current
                switch chartRange {
                case "1D":
                    let startOfDay = calendar.startOfDay(for: now)
                    return data.date >= startOfDay
                case "1W": return data.date > calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
                case "1M": return data.date > calendar.date(byAdding: .month, value: -1, to: now)!
                case "3M": return data.date > calendar.date(byAdding: .month, value: -3, to: now)!
                case "1Y": return data.date > calendar.date(byAdding: .year, value: -1, to: now)!
                default: return true
                }
            }
            
            tickerSymbol = response.metaData?.symbol ?? tickerSymbol
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func fetchFinancialData() async {
        guard let apiKey = config?.apiKey else {
            errorMessage = "API key not found in configuration"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://www.alphavantage.co/query?function=\(selectedStatement)&symbol=\(tickerSymbol)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            financialData = parseFinancialData(json)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func parseFinancialData(_ json: [String: Any]) -> [[FinancialData]] {
        var yearlyData: [[FinancialData]] = []
        let currentYear = Calendar.current.component(.year, from: Date())
        
        switch selectedStatement {
        case "INCOME_STATEMENT", "BALANCE_SHEET", "CASH_FLOW":
            if let reports = json["annualReports"] as? [[String: String]] {
                var metricsDict: [String: [(value: String, year: Int)]] = [:]
                
                for report in reports.prefix(3) {
                    let year = Int(report["fiscalDateEnding"]?.prefix(4) ?? "") ?? currentYear
                    for (key, value) in report {
                        if key != "fiscalDateEnding" {
                            metricsDict[key, default: []].append((value, year))
                        }
                    }
                }
                
                yearlyData = metricsDict.map { key, values in
                    values.map { FinancialData(metric: key, value: $0.value, year: $0.year) }
                }.sorted { $0[0].metric < $1[0].metric }
            }
            
        case "OVERVIEW":
            let data = json.map { FinancialData(metric: $0.key, value: String(describing: $0.value), year: nil) }
            yearlyData = [data]
            
        case "TIME_SERIES_DAILY":
            yearlyData = []
            
        default:
            yearlyData = []
        }
        
        return yearlyData
    }
    
    private func formatMetricTitle(_ metric: String) -> String {
        let abbreviations: [String: String] = [
            "totalRevenue": "Rev",
            "netIncome": "NI",
            "grossProfit": "GP",
            "operatingIncome": "OI",
            "totalAssets": "TA",
            "totalLiabilities": "TL",
            "totalEquity": "TE",
            "cashFlowFromOperating": "CFO",
            "cashFlowFromInvesting": "CFI",
            "cashFlowFromFinancing": "CFF"
        ]
        
        return abbreviations[metric] ?? metric
            .replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .map { String($0.prefix(1)).uppercased() }
            .joined()
    }
    
    private func formatValue(_ value: String) -> String {
        if let doubleValue = Double(value) {
            if doubleValue > 1_000_000_000 {
                return String(format: "%.2fB", doubleValue / 1_000_000_000)
            } else if doubleValue > 1_000_000 {
                return String(format: "%.2fM", doubleValue / 1_000_000)
            } else if doubleValue > 1_000 {
                return String(format: "%.2fK", doubleValue / 1_000)
            }
            return String(format: "%.2f", doubleValue)
        }
        return value
    }
}

// Main App View
struct StockAppView: View {
    var body: some View {
        TabView {
            DashboardPage()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.xyaxis.line")
                }
            
            NavigationStack {
                Text("Portfolio Page")
                    .navigationTitle("Portfolio")
            }
            .tabItem {
                Label("Portfolio", systemImage: "briefcase")
            }
            
            NavigationStack {
                Text("Settings Page")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .accentColor(DesignSystem.accentColor)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    StockAppView()
}
