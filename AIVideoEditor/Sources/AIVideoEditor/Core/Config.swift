import Foundation

enum ConfigError: Error {
    case missingKey(String)
    case invalidValue(String)
}

enum Environment {
    case development
    case staging
    case production
    
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        if let env = ProcessInfo.processInfo.environment["APP_ENV"] {
            switch env.lowercased() {
            case "staging": return .staging
            case "production": return .production
            default: return .development
            }
        }
        return .development
        #endif
    }
}

final class Config {
    static let shared = Config()
    
    private var environmentVariables: [String: String] = [:]
    private let secureStore = KeychainStore()
    
    private init() {
        loadEnvironmentVariables()
    }
    
    private func loadEnvironmentVariables() {
        if let path = Bundle.main.path(forResource: "\(Environment.current)", ofType: "env") {
            do {
                let contents = try String(contentsOfFile: path, encoding: .utf8)
                let lines = contents.components(separatedBy: .newlines)
                
                for line in lines {
                    let parts = line.components(separatedBy: "=")
                    if parts.count == 2 {
                        let key = parts[0].trimmingCharacters(in: .whitespaces)
                        let value = parts[1].trimmingCharacters(in: .whitespaces)
                        environmentVariables[key] = value
                    }
                }
            } catch {
                print("Error loading environment variables: \(error)")
            }
        }
        
        // Load from process environment
        for (key, value) in ProcessInfo.processInfo.environment {
            environmentVariables[key] = value
        }
    }
    
    func string(for key: String) throws -> String {
        if let value = environmentVariables[key] {
            return value
        }
        
        if let value = try? secureStore.get(key: key) {
            return value
        }
        
        throw ConfigError.missingKey(key)
    }
    
    func int(for key: String) throws -> Int {
        let stringValue = try string(for: key)
        guard let intValue = Int(stringValue) else {
            throw ConfigError.invalidValue("Value for \(key) is not an integer")
        }
        return intValue
    }
    
    func bool(for key: String) throws -> Bool {
        let stringValue = try string(for: key)
        switch stringValue.lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: throw ConfigError.invalidValue("Value for \(key) is not a boolean")
        }
    }
    
    func url(for key: String) throws -> URL {
        let stringValue = try string(for: key)
        guard let url = URL(string: stringValue) else {
            throw ConfigError.invalidValue("Value for \(key) is not a valid URL")
        }
        return url
    }
    
    func set(_ value: String, for key: String, secure: Bool = false) throws {
        if secure {
            try secureStore.set(value, for: key)
        } else {
            environmentVariables[key] = value
        }
    }
}

// MARK: - Keychain Storage

private class KeychainStore {
    func set(_ value: String, for key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            
            SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
        }
    }
    
    func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 