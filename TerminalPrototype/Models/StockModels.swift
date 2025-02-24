import Foundation
import os

private let logger = Logger(subsystem: "com.terminal.prototype", category: "StockModels")

// MARK: - Module Information
extension Bundle {
    static func logModuleInfo() {
        logger.debug("""
        🔍 Module Configuration:
        - Main Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")
        - Module Name: \(String(describing: Bundle.main.infoDictionary?["CFBundleName"]))
        - Module Path: \(Bundle.main.bundlePath)
        """)
    }
}

// MARK: - Data Models
public enum Models {
    static func logTypeAvailability() {
        logger.debug("""
        📚 Type Availability Check:
        - Module: \(String(describing: Bundle.main.bundleIdentifier))
        - StockData: \(String(describing: StockData.self))
        - TimeSeriesData: \(String(describing: TimeSeriesData.self))
        - Portfolio: \(String(describing: Portfolio.self))
        - Defined in file: \(#file)
        """)
    }
    
    /// Represents stock data with current price information
    public struct StockData: Codable, Identifiable {
        public let id = UUID()
        public let symbol: String
        public let price: Double
        public let timestamp: Date
        
        public init(symbol: String, price: Double, timestamp: Date) {
            self.symbol = symbol
            self.price = price
            self.timestamp = timestamp
        }
        
        enum CodingKeys: String, CodingKey {
            case symbol = "1. symbol"
            case price = "2. price"
            case timestamp = "3. last refreshed"
        }
    }

    /// Represents time series data point for stock charts
    public struct TimeSeriesData: Identifiable {
        public let id = UUID()
        public let date: Date
        public let open: Double
        public let high: Double
        public let low: Double
        public let close: Double
        public let volume: Int
        
        public init(date: Date, open: Double, high: Double, low: Double, close: Double, volume: Int) {
            self.date = date
            self.open = open
            self.high = high
            self.low = low
            self.close = close
            self.volume = volume
        }
    }

    /// Represents the response structure for Alpha Vantage Global Quote endpoint
    public struct GlobalQuote: Codable {
        public let globalQuote: [String: String]
        
        public init(globalQuote: [String: String]) {
            self.globalQuote = globalQuote
        }
        
        enum CodingKeys: String, CodingKey {
            case globalQuote = "Global Quote"
        }
    }

    /// Represents a user's portfolio with holdings and current stock data
    public struct Portfolio {
        /// Dictionary mapping stock symbols to number of shares held
        public var holdings: [String: Int]
        /// Dictionary mapping stock symbols to their latest stock data
        public var stockData: [String: StockData]
        
        public init(holdings: [String: Int], stockData: [String: StockData]) {
            self.holdings = holdings
            self.stockData = stockData
        }
        
        /// Updates the number of shares held for a given symbol
        public mutating func updateHolding(symbol: String, shares: Int) {
            holdings[symbol] = shares
        }
        
        /// Calculates the total value of the portfolio
        public func totalValue() -> Double {
            holdings.reduce(0.0) { total, holding in
                let (symbol, shares) = holding
                guard let data = stockData[symbol] else { return total }
                return total + (data.price * Double(shares))
            }
        }
    }
}

// Call logging functions when module loads
@_cdecl("ModelsModuleInitialize")
public func moduleInitialize() {
    Bundle.logModuleInfo()
    Models.logTypeAvailability()
} 