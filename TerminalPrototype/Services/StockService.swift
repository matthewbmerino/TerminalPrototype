import Foundation
import Combine
import os

private let logger = Logger(subsystem: "com.terminal.prototype", category: "StockService")

extension StockService {
    static func logTypeResolution() {
        logger.debug("""
        🔍 Service Layer Type Resolution:
        - File: \(#file)
        - Models Namespace: \(String(describing: Models.self))
        - Portfolio Type: \(String(describing: Models.Portfolio.self))
        - TimeSeriesData Type: \(String(describing: Models.TimeSeriesData.self))
        - Protocol Requirements: \(String(describing: StockServiceProtocol.self))
        """)
    }
}

/// Errors that can occur during stock data operations
enum StockServiceError: Error {
    case invalidURL
    case apiError(String)
    case decodingError(Error)
    case networkError(Error)
    case configurationError(ConfigurationError)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .apiError(let message):
            return "API Error: \(message)"
        case .decodingError(let error):
            return "Error decoding response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .configurationError(let error):
            return error.localizedDescription
        }
    }
}

/// Protocol defining the interface for stock data operations
protocol StockServiceProtocol: AnyObject {
    var portfolio: Models.Portfolio { get }
    var timeSeriesData: [Models.TimeSeriesData] { get }
    var isLoading: Bool { get }
    var error: StockServiceError? { get }
    
    func fetchStockPrice(symbol: String) async throws -> Models.StockData
    func fetchTimeSeries(symbol: String, range: TimeRange) async throws -> [Models.TimeSeriesData]
    func updateHolding(symbol: String, shares: Int)
}

/// Represents different time ranges for stock data
public enum TimeRange: String, CaseIterable, Identifiable {
    case month = "Monthly"
    case year = "Yearly"
    case max = "Max"
    
    public var id: String { rawValue }
    
    var apiFunction: String {
        switch self {
        case .month:
            return "TIME_SERIES_WEEKLY"
        case .year, .max:
            return "TIME_SERIES_MONTHLY"
        }
    }
    
    var timeSeriesKey: String {
        switch self {
        case .month:
            return "Weekly Time Series"
        case .year, .max:
            return "Monthly Time Series"
        }
    }
    
    var dateFormat: String {
        return "yyyy-MM-dd"
    }
    
    var outputSize: String {
        switch self {
        case .max:
            return "full"
        default:
            return "compact"
        }
    }
    
    var dataPoints: Int {
        switch self {
        case .month:
            return 12  // Show 3 months of weekly data
        case .year:
            return 24  // Show 2 years of monthly data
        case .max:
            return Int.max
        }
    }
}

/// Service responsible for fetching and managing stock data
final class StockService: StockServiceProtocol, ObservableObject {
    /// Published properties for MVVM binding
    @Published private(set) var portfolio = Models.Portfolio(holdings: [:], stockData: [:])
    @Published private(set) var timeSeriesData: [Models.TimeSeriesData] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: StockServiceError?
    
    private let baseURL = "https://www.alphavantage.co/query"
    private let configService: ConfigurationService
    
    init(configService: ConfigurationService = .shared) {
        Self.logTypeResolution()
        logger.debug("📦 Initializing StockService")
        self.configService = configService
    }
    
    /// Fetches current stock price for a symbol
    /// - Parameter symbol: The stock symbol to fetch
    /// - Returns: StockData containing current price information
    func fetchStockPrice(symbol: String) async throws -> Models.StockData {
        logger.debug("Fetching stock price with resolved types: StockData=\(String(describing: Models.StockData.self))")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let apiKey = try configService.getAlphaVantageAPIKey()
            var components = URLComponents(string: baseURL)
            components?.queryItems = [
                URLQueryItem(name: "function", value: "GLOBAL_QUOTE"),
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "apikey", value: apiKey)
            ]
            
            guard let url = components?.url else {
                throw StockServiceError.invalidURL
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(Models.GlobalQuote.self, from: data)
            
            guard let price = Double(response.globalQuote["05. price"] ?? "0"),
                  let symbol = response.globalQuote["01. symbol"],
                  let timestampStr = response.globalQuote["07. latest trading day"],
                  let timestamp = ISO8601DateFormatter().date(from: timestampStr) else {
                throw StockServiceError.apiError("Invalid response format")
            }
            
            let stockData = Models.StockData(symbol: symbol, price: price, timestamp: timestamp)
            
            DispatchQueue.main.async {
                self.portfolio.stockData[symbol] = stockData
                self.error = nil
            }
            
            return stockData
        } catch let error as ConfigurationError {
            self.error = .configurationError(error)
            throw StockServiceError.configurationError(error)
        } catch {
            self.error = .networkError(error)
            throw StockServiceError.networkError(error)
        }
    }
    
    /// Fetches time series data for a symbol
    /// - Parameters:
    ///   - symbol: The stock symbol to fetch
    ///   - range: The time range to fetch
    /// - Returns: Array of time series data points
    func fetchTimeSeries(symbol: String, range: TimeRange) async throws -> [Models.TimeSeriesData] {
        logger.debug("Fetching \(range.rawValue) data for \(symbol)")
        isLoading = true
        defer { isLoading = false }
        
        do {
            let apiKey = try configService.getAlphaVantageAPIKey()
            var components = URLComponents(string: baseURL)
            
            var queryItems = [
                URLQueryItem(name: "function", value: range.apiFunction),
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "outputsize", value: range.outputSize)
            ]
            
            components?.queryItems = queryItems
            
            guard let url = components?.url else {
                throw StockServiceError.invalidURL
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let timeSeries = json?[range.timeSeriesKey] as? [String: [String: String]] else {
                throw StockServiceError.apiError("Invalid time series format")
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = range.dateFormat
            
            let processedData = timeSeries
                .compactMap { (dateStr, values) -> Models.TimeSeriesData? in
                    guard let date = dateFormatter.date(from: dateStr),
                          let open = Double(values["1. open"] ?? ""),
                          let high = Double(values["2. high"] ?? ""),
                          let low = Double(values["3. low"] ?? ""),
                          let close = Double(values["4. close"] ?? ""),
                          let adjustedClose = Double(values["5. adjusted close"] ?? ""),
                          let volume = Int(values["6. volume"] ?? "") else {
                        return nil
                    }
                    
                    return Models.TimeSeriesData(
                        date: date,
                        open: open,
                        high: high,
                        low: low,
                        close: close,
                        adjustedClose: adjustedClose,
                        volume: volume
                    )
                }
                .sorted { $0.date < $1.date }
            
            let limitedData = range == .max ? 
                processedData : 
                Array(processedData.suffix(range.dataPoints))
            
            DispatchQueue.main.async {
                self.timeSeriesData = limitedData
                self.error = nil
            }
            
            return limitedData
        } catch let error as ConfigurationError {
            self.error = .configurationError(error)
            throw StockServiceError.configurationError(error)
        } catch {
            self.error = .networkError(error)
            throw StockServiceError.networkError(error)
        }
    }
    
    /// Updates the portfolio with new holding information
    /// - Parameters:
    ///   - symbol: The stock symbol to update
    ///   - shares: The number of shares held
    func updateHolding(symbol: String, shares: Int) {
        portfolio.updateHolding(symbol: symbol, shares: shares)
    }
} 