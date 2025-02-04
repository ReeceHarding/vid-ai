import Foundation

/// Configuration manager for handling environment variables and sensitive data
public final class Config {
    /// Shared instance for singleton access
    public static let shared = Config()
    
    /// Environment type for configuration
    public enum Environment: String {
        case development
        case staging
        case production
        
        /// Current environment based on build configuration
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            if let environmentString = Bundle.main.infoDictionary?["ENV"] as? String,
               let environment = Environment(rawValue: environmentString.lowercased()) {
                return environment
            }
            return .production
            #endif
        }
    }
    
    /// Firebase configuration
    public struct Firebase {
        let apiKey: String
        let projectId: String
        let storageBucket: String
        let appId: String
        let measurementId: String
        let gcmSenderId: String
        
        fileprivate init() {
            // Load from environment or configuration file
            self.apiKey = Config.getEnvironmentVariable("FIREBASE_API_KEY")
            self.projectId = Config.getEnvironmentVariable("FIREBASE_PROJECT_ID")
            self.storageBucket = Config.getEnvironmentVariable("FIREBASE_STORAGE_BUCKET")
            self.appId = Config.getEnvironmentVariable("FIREBASE_APP_ID")
            self.measurementId = Config.getEnvironmentVariable("FIREBASE_MEASUREMENT_ID")
            self.gcmSenderId = Config.getEnvironmentVariable("FIREBASE_GCM_SENDER_ID")
        }
    }
    
    /// Current environment configuration
    public let environment: Environment
    
    /// Firebase configuration
    public let firebase: Firebase
    
    private init() {
        self.environment = Environment.current
        self.firebase = Firebase()
    }
    
    /// Get environment variable value securely
    /// - Parameter key: Environment variable key
    /// - Returns: Value for the environment variable
    private static func getEnvironmentVariable(_ key: String) -> String {
        // First try to get from environment
        if let value = ProcessInfo.processInfo.environment[key] {
            return value
        }
        
        // Then try to get from configuration file
        let filename = "\(Environment.current.rawValue).env"
        guard let path = Bundle.main.path(forResource: filename, ofType: nil),
              let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            fatalError("Missing required environment variable: \(key)")
        }
        
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        fatalError("Missing required environment variable: \(key)")
    }
}

// MARK: - Environment Variable Access
extension Config {
    /// Get Firebase API Key
    public var firebaseApiKey: String {
        firebase.apiKey
    }
    
    /// Get Firebase Project ID
    public var firebaseProjectId: String {
        firebase.projectId
    }
    
    /// Get Firebase Storage Bucket
    public var firebaseStorageBucket: String {
        firebase.storageBucket
    }
    
    /// Get Firebase App ID
    public var firebaseAppId: String {
        firebase.appId
    }
    
    /// Get Firebase Measurement ID
    public var firebaseMeasurementId: String {
        firebase.measurementId
    }
    
    /// Get Firebase GCM Sender ID
    public var firebaseGcmSenderId: String {
        firebase.gcmSenderId
    }
} 