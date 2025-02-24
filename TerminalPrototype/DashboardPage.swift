//
//  DashboardPage.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

import SwiftUI
import Charts

// Data model for stock prices (unchanged)
struct StockData: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

// Alpha Vantage API response structure (unchanged)
struct AlphaVantageResponse: Codable {
    struct TimeSeries: Codable {
        let open: String
        let high: String
        let low: String
        let close: String
        
        enum CodingKeys: String, CodingKey {
            case open = "1. open"
            case high = "2. high"
            case low = "3. low"
            case close = "4. close"
        }
    }
    
    let timeSeries: [String: TimeSeries]
    
    enum CodingKeys: String, CodingKey {
        case timeSeries = "Time Series (Daily)"
    }
}

// Dashboard Page View (unchanged)
struct DashboardPage: View {
    @State private var stockPrices: [StockData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let config = Config.loadFromFile()
    private let symbol = "AAPL"
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading stock data...")
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            } else {
                Chart {
                    ForEach(stockPrices) { dataPoint in
                        LineMark(
                            x: .value("Time", dataPoint.date),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("Time", dataPoint.date),
                            y: .value("Price", dataPoint.price)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day(.defaultDigits))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .currency(code: "USD"))
                    }
                }
                .frame(height: 300)
                .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Stock Dashboard")
        .task {
            await fetchStockData()
        }
    }
    
    private func fetchStockData() async {
        guard let apiKey = config?.alphaVantageAPIKey else {
            errorMessage = "API key not found in configuration"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let urlString = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=\(symbol)&apikey=\(apiKey)"
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
            
            stockPrices = response.timeSeries.map { (dateString, timeSeries) in
                let date = dateFormatter.date(from: dateString) ?? Date()
                let price = Double(timeSeries.close) ?? 0.0
                return StockData(date: date, price: price)
            }.sorted { $0.date < $1.date }
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// Main App View (renamed from ContentView to StockAppView)
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
