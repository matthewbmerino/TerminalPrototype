//
//  DashboardPage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

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
    
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let shadowRadius: CGFloat = 4
}

// Dashboard Page
struct DashboardPage: View {
    @State private var stockPrices: [StockData] = []
    @State private var selectedData: StockData?
    @State private var financialData: [FinancialData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var tickerSymbol: String = "AAPL"
    @State private var chartRange: String = "1M"
    @State private var isExpanded: Bool = false
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .foregroundColor(DesignSystem.accentColor)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(DesignSystem.smallPadding)
                }
            }
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
                    .frame(height: isExpanded ? 400 : 300)
            } else if let errorMessage = errorMessage, stockPrices.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .frame(height: isExpanded ? 400 : 300)
            } else {
                Chart {
                    ForEach(stockPrices) { dataPoint in
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
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(DesignSystem.secondaryTextColor.opacity(0.2))
                        AxisValueLabel(format: .dateTime.month().day())
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
                .frame(height: isExpanded ? 400 : 300)
                .padding(DesignSystem.smallPadding)
                .background(DesignSystem.surfaceColor)
                .cornerRadius(DesignSystem.cornerRadius)
                .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
                .overlay(
                    selectedData.map { data in
                        ChartAnnotation(data: data)
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
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .trailing)
                    ],
                    spacing: DesignSystem.smallPadding
                ) {
                    tableHeader
                    tableContent
                }
                .padding(DesignSystem.padding)
                .background(DesignSystem.surfaceColor.opacity(0.8))
                .cornerRadius(DesignSystem.cornerRadius)
            }
        }
        .padding(DesignSystem.padding)
        .background(DesignSystem.surfaceColor)
        .cornerRadius(DesignSystem.cornerRadius)
        .shadow(color: .black.opacity(0.2), radius: DesignSystem.shadowRadius)
        .frame(maxHeight: isExpanded ? 400 : 200)
    }
    
    private var tableHeader: some View {
        Group {
            Text(selectedStatement == "TIME_SERIES_DAILY" ? "Date" : "Metric")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.textColor)
                .padding(.vertical, DesignSystem.smallPadding / 2)
            Text(selectedStatement == "TIME_SERIES_DAILY" ? "Close" : "Value")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.textColor)
                .padding(.vertical, DesignSystem.smallPadding / 2)
        }
    }
    
    private var tableContent: some View {
        Group {
            if selectedStatement == "TIME_SERIES_DAILY" {
                ForEach(stockPrices.reversed().prefix(10)) { data in
                    Text(data.date, format: .dateTime.month().day().year())
                        .foregroundColor(DesignSystem.secondaryTextColor)
                    Text(data.price, format: .currency(code: "USD"))
                        .foregroundColor(DesignSystem.textColor)
                }
            } else {
                ForEach(financialData.prefix(10)) { item in
                    Text(item.metric)
                        .foregroundColor(DesignSystem.secondaryTextColor)
                    Text(item.value)
                        .foregroundColor(DesignSystem.textColor)
                }
            }
        }
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
        
        var body: some View {
            VStack(alignment: .leading, spacing: DesignSystem.smallPadding) {
                Text("Date: \(data.date, format: .dateTime.month().day())")
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
            
            var allPrices = response.timeSeries.map { (dateString, timeSeries) in
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
                switch chartRange {
                case "1D": return data.date > Calendar.current.date(byAdding: .day, value: -1, to: now)!
                case "1W": return data.date > Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now)!
                case "1M": return data.date > Calendar.current.date(byAdding: .month, value: -1, to: now)!
                case "3M": return data.date > Calendar.current.date(byAdding: .month, value: -3, to: now)!
                case "1Y": return data.date > Calendar.current.date(byAdding: .year, value: -1, to: now)!
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
    
    private func parseFinancialData(_ json: [String: Any]) -> [FinancialData] {
        var data: [FinancialData] = []
        
        switch selectedStatement {
        case "INCOME_STATEMENT":
            if let reports = json["annualReports"] as? [[String: String]],
               let latestReport = reports.first {
                data = latestReport.map { FinancialData(metric: $0.key, value: $0.value) }
            }
            
        case "BALANCE_SHEET":
            if let reports = json["annualReports"] as? [[String: String]],
               let latestReport = reports.first {
                data = latestReport.map { FinancialData(metric: $0.key, value: $0.value) }
            }
            
        case "CASH_FLOW":
            if let reports = json["annualReports"] as? [[String: String]],
               let latestReport = reports.first {
                data = latestReport.map { FinancialData(metric: $0.key, value: $0.value) }
            }
            
        case "OVERVIEW":
            data = json.map { FinancialData(metric: $0.key, value: String(describing: $0.value)) }
            
        case "TIME_SERIES_DAILY":
            break
            
        default:
            break
        }
        
        return data.sorted { $0.metric < $1.metric }
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
