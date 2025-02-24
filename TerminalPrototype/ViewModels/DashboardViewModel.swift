import Foundation
import Combine
import os

private let logger = Logger(subsystem: "com.terminal.prototype", category: "DashboardViewModel")

extension DashboardViewModel {
    static func logTypeResolution() {
        logger.debug("""
        🔍 ViewModel Layer Type Resolution:
        - File: \(#file)
        - Models Import Path: \(NSClassFromString("TerminalPrototype.Models") != nil ? "Found" : "Not Found")
        - Portfolio Resolution: \(String(describing: Models.Portfolio.self))
        - TimeSeriesData Resolution: \(String(describing: Models.TimeSeriesData.self))
        - Service Protocol: \(String(describing: StockServiceProtocol.self))
        """)
    }
}

/// View model for managing dashboard state and business logic
@MainActor
final class DashboardViewModel: ObservableObject {
    /// Published properties for view binding
    @Published var selectedSymbol: String
    @Published var selectedTimeRange: TimeRange
    @Published var shares = ""
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    /// Available stock symbols
    let availableSymbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "META"]
    
    private let stockService: StockServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    /// Computed property for accessing portfolio data
    var portfolio: Models.Portfolio {
        stockService.portfolio
    }
    
    /// Computed property for accessing time series data
    var timeSeriesData: [Models.TimeSeriesData] {
        stockService.timeSeriesData
    }
    
    init(stockService: StockServiceProtocol = StockService(),
         initialSymbol: String = "AAPL",
         initialTimeRange: TimeRange = .month) {
        Self.logTypeResolution()
        logger.debug("📱 Initializing DashboardViewModel")
        
        self.stockService = stockService
        self.selectedSymbol = initialSymbol
        self.selectedTimeRange = initialTimeRange
        
        // Observe stock service state
        if let service = stockService as? StockService {
            logger.debug("✅ Successfully cast service to concrete type")
            
            // Use weak self to avoid retain cycles and explicit self to make capture semantics clear
            service.$isLoading
                .receive(on: RunLoop.main)
                .sink { [weak self] newValue in
                    self?.isLoading = newValue
                }
                .store(in: &cancellables)
            
            service.$error
                .receive(on: RunLoop.main)
                .map { $0?.localizedDescription }
                .sink { [weak self] newValue in
                    self?.errorMessage = newValue
                }
                .store(in: &cancellables)
        } else {
            logger.error("❌ Failed to cast service to concrete type")
        }
    }
    
    /// Updates the selected symbol and fetches new data
    /// - Parameter symbol: The new symbol to select
    func selectSymbol(_ symbol: String) {
        logger.debug("Selecting symbol: \(symbol), current portfolio type: \(String(describing: type(of: self.portfolio)))")
        selectedSymbol = symbol
        Task { @MainActor in
            await self.refreshData()
        }
    }
    
    /// Updates the selected time range and fetches new data
    /// - Parameter range: The new time range to select
    func selectTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        Task { @MainActor in
            await self.refreshData()
        }
    }
    
    /// Adds or updates a holding in the portfolio
    /// - Parameters:
    ///   - symbol: The stock symbol
    ///   - shares: Number of shares
    func updateHolding(symbol: String, shares: Int) {
        if let service = stockService as? StockService {
            service.updateHolding(symbol: symbol, shares: shares)
            Task { @MainActor in
                await self.refreshPrice(for: symbol)
            }
        }
    }
    
    /// Refreshes price data for a specific symbol
    /// - Parameter symbol: The symbol to refresh
    func refreshPrice(for symbol: String) async {
        do {
            _ = try await stockService.fetchStockPrice(symbol: symbol)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes all data for the dashboard
    func refreshData() async {
        do {
            async let priceTask = stockService.fetchStockPrice(symbol: selectedSymbol)
            async let timeSeriesTask = stockService.fetchTimeSeries(symbol: selectedSymbol, range: selectedTimeRange)
            
            _ = try await (priceTask, timeSeriesTask)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Refreshes price data for all symbols in the portfolio
    func refreshAllPrices() async {
        for symbol in availableSymbols {
            await refreshPrice(for: symbol)
        }
    }
} 