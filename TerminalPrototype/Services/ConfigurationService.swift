import Foundation

/// Errors that can occur during configuration loading
enum ConfigurationError: Error {
    case fileNotFound
    case decodingError(Error)
    case invalidConfiguration
    
    var localizedDescription: String {
        switch self {
        case .fileNotFound:
            return "Configuration file not found"
        case .decodingError(let error):
            return "Error decoding configuration: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Invalid configuration data"
        }
    }
}

/// Service responsible for managing application configuration
final class ConfigurationService {
    /// Shared instance for singleton access
    static let shared = ConfigurationService()
    
    /// The loaded configuration
    private(set) var config: Config?
    
    private init() {
        loadConfiguration()
    }
    
    /// Configuration model
    struct Config: Codable {
        let alphaVantageAPIKey: String
        
        enum CodingKeys: String, CodingKey {
            case alphaVantageAPIKey = "alpha_vantage_api_key"
        }
    }
    
    /// Loads the configuration from the config.json file
    /// - Throws: ConfigurationError if loading fails
    private func loadConfiguration() {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json") else {
            print(ConfigurationError.fileNotFound.localizedDescription)
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            config = try decoder.decode(Config.self, from: data)
        } catch {
            print(ConfigurationError.decodingError(error).localizedDescription)
        }
    }
    
    /// Gets the Alpha Vantage API key from configuration
    /// - Throws: ConfigurationError if the key is not available
    /// - Returns: The API key string
    func getAlphaVantageAPIKey() throws -> String {
        guard let apiKey = config?.alphaVantageAPIKey else {
            throw ConfigurationError.invalidConfiguration
        }
        return apiKey
    }
} 