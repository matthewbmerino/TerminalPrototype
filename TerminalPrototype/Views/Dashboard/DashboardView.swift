import SwiftUI
import Charts
import os

private let logger = Logger(subsystem: "com.terminal.prototype", category: "DashboardView")

/// Main dashboard view for displaying portfolio and charts
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingError = false
    
    // Break down complex expressions for debugging
    private var portfolioSummary: (totalValue: Double, holdingsCount: Int) {
        logger.debug("📊 Computing portfolio summary")
        let total = viewModel.portfolio.totalValue()
        let count = viewModel.portfolio.holdings.count
        logger.debug("💰 Portfolio stats - Total: \(total), Holdings: \(count)")
        return (total, count)
    }
    
    private var activeHoldings: [(symbol: String, data: Models.StockData, shares: Int)] {
        logger.debug("📋 Processing active holdings")
        return viewModel.portfolio.stockData.compactMap { (symbol, data) in
            guard let shares = viewModel.portfolio.holdings[symbol], shares > 0 else { return nil }
            return (symbol: symbol, data: data, shares: shares)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Interactive Chart
                    ChartView(viewModel: viewModel)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    
                    // Portfolio Summary
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Portfolio Summary")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Value")
                                    .foregroundColor(.secondary)
                                Text("$\(portfolioSummary.totalValue, specifier: "%.2f")")
                                    .font(.title2)
                                    .bold()
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Holdings")
                                    .foregroundColor(.secondary)
                                Text("\(portfolioSummary.holdingsCount)")
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Holdings List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Holdings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(activeHoldings, id: \.symbol) { holding in
                            HoldingRowView(data: holding.data, shares: holding.shares)
                                .onTapGesture {
                                    logger.debug("👆 Selected holding: \(holding.symbol)")
                                    viewModel.selectSymbol(holding.symbol)
                                }
                        }
                    }
                    
                    // Add Holdings Form
                    VStack(spacing: 10) {
                        Text("Add Holding")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Picker("Symbol", selection: $viewModel.selectedSymbol) {
                            ForEach(viewModel.availableSymbols, id: \.self) { symbol in
                                Text(symbol).tag(symbol)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        TextField("Number of shares", text: $viewModel.shares)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            if let shareCount = Int(viewModel.shares) {
                                logger.debug("➕ Adding holding: \(viewModel.selectedSymbol) - \(shareCount) shares")
                                viewModel.updateHolding(symbol: viewModel.selectedSymbol, shares: shareCount)
                                viewModel.shares = ""
                            }
                        }) {
                            Text("Add Holding")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Portfolio Dashboard")
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            )
            .onChange(of: viewModel.errorMessage) { error in
                logger.debug("⚠️ Error state changed: \(String(describing: error))")
                showingError = error != nil
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                logger.debug("🚀 Initial dashboard load")
                await viewModel.refreshAllPrices()
            }
        }
    }
}

/// Row view for displaying individual holdings
struct HoldingRowView: View {
    let data: Models.StockData  // Using fully qualified type
    let shares: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(data.symbol)
                    .font(.headline)
                Text("\(shares) shares")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(data.price, specifier: "%.2f")")
                    .font(.headline)
                Text("$\(data.price * Double(shares), specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

#Preview {
    DashboardView()
} 