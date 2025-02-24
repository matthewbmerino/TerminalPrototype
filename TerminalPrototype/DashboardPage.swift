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
    let price: Double // close
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
        // Try to load from a config file (e.g., config.json in the app bundle)
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

// DashboardPage
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
    
    private let config: AlphaVantageConfig? = AlphaVantageConfig.loadFromFile()
    
    var body: some View {
        Group {
            if isExpanded {
                HStack(spacing: 20) {
                    chartView
                    VStack(spacing: 20) {
                        statementButtons
                        tableView
                    }
                }
            } else {
                VStack(spacing: 20) {
                    chartView
                    statementButtons
                    tableView
                }
            }
        }
        .task {
            await fetchStockData()
        }
    }
    
    private var chartView: some View {
        VStack(spacing: 10) {
            HStack {
                Text(tickerSymbol)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.2)))
                }
            }
            
            if isLoading {
                ProgressView("Loading stock data...")
                    .tint(.white)
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Chart {
                    ForEach(stockPrices) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(selectedData?.id == dataPoint.id ? 100 : 20)
                        .annotation(
                            position: .overlay,
                            alignment: selectedData?.id == dataPoint.id ? .top : .center,
                            spacing: 10
                        ) {
                            if selectedData?.id == dataPoint.id {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Date: \(dataPoint.date, format: .dateTime.month().day())")
                                    Text("Close: \(dataPoint.price, format: .currency(code: "USD"))")
                                    Text("Open: \(dataPoint.open, format: .currency(code: "USD"))")
                                    Text("High: \(dataPoint.high, format: .currency(code: "USD"))")
                                    Text("Low: \(dataPoint.low, format: .currency(code: "USD"))")
                                }
                                .font(.caption)
                                .padding(8)
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = value.location
                                        if let date = proxy.value(atX: location.x) as Date?,
                                           let price = proxy.value(atY: location.y) as Double?,
                                           let closest = stockPrices.min(by: {
                                               abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                           }) {
                                            selectedData = closest
                                        }
                                    }
                            )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .currency(code: "USD"))
                    }
                }
                .frame(height: isExpanded ? 400 : 300)
                .padding()
                
                HStack(spacing: 10) {
                    ChartButton(title: "1D", isSelected: chartRange == "1D") {
                        chartRange = "1D"
                        Task { await fetchStockData() }
                    }
                    ChartButton(title: "1W", isSelected: chartRange == "1W") {
                        chartRange = "1W"
                        Task { await fetchStockData() }
                    }
                    ChartButton(title: "1M", isSelected: chartRange == "1M") {
                        chartRange = "1M"
                        Task { await fetchStockData() }
                    }
                    ChartButton(title: "3M", isSelected: chartRange == "3M") {
                        chartRange = "3M"
                        Task { await fetchStockData() }
                    }
                    ChartButton(title: "1Y", isSelected: chartRange == "1Y") {
                        chartRange = "1Y"
                        Task { await fetchStockData() }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var statementButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                StatementButton(title: "Daily", endpoint: "TIME_SERIES_DAILY", isSelected: selectedStatement == "TIME_SERIES_DAILY") {
                    selectedStatement = "TIME_SERIES_DAILY"
                    Task { await fetchStockData() }
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
            .padding(.horizontal)
        }
    }
    
    private var tableView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(selectedStatement.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if selectedStatement == "TIME_SERIES_DAILY" {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), alignment: .leading),
                            GridItem(.flexible(), alignment: .trailing)
                        ],
                        spacing: 10
                    ) {
                        Text("Date").fontWeight(.bold).foregroundColor(.white)
                        Text("Close").fontWeight(.bold).foregroundColor(.white)
                        
                        ForEach(stockPrices.reversed().prefix(10)) { data in
                            Text(data.date, format: .dateTime.month().day().year())
                                .foregroundColor(.white)
                            Text(data.price, format: .currency(code: "USD"))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), alignment: .leading),
                            GridItem(.flexible(), alignment: .trailing)
                        ],
                        spacing: 10
                    ) {
                        Text("Metric").fontWeight(.bold).foregroundColor(.white)
                        Text("Value").fontWeight(.bold).foregroundColor(.white)
                        
                        ForEach(financialData) { item in
                            Text(item.metric)
                                .foregroundColor(.white)
                            Text(item.value)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .frame(maxHeight: isExpanded ? 400 : 200)
    }
    
    struct ChartButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4)
                    )
            }
            .buttonStyle(PlainButtonStyle())
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
        stockPrices = [] // Clear chart data when showing financial statements
        
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
            
        default:
            break
        }
        
        return data.sorted { $0.metric < $1.metric }
    }
}

// StockAppView
struct StockAppView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardPage()
            }
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
        .accentColor(.blue)
        .background(Color.black)
    }
}

#Preview {
    StockAppView()
        .preferredColorScheme(.dark)
}
