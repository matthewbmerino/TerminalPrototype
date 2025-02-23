//
//  Config.swift
//  TerminalPrototype
//
//  Created by Matthew Merino on 2/23/25.
//

// Config.swift
import Foundation

struct Config: Codable {
    let alphaVantageAPIKey: String
    
    enum CodingKeys: String, CodingKey {
        case alphaVantageAPIKey = "alpha_vantage_api_key"
    }
    
    static func loadFromFile() -> Config? {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json") else {
            print("Config file not found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Config.self, from: data)
        } catch {
            print("Error decoding config: \(error)")
            return nil
        }
    }
}
