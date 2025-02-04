import XCTest
@testable import AIVideoEditorLib

final class ConfigTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Set up test environment variables
        setEnvironmentVariables()
    }
    
    override func tearDown() {
        // Clean up environment variables
        clearEnvironmentVariables()
        super.tearDown()
    }
    
    func testEnvironmentDetection() {
        #if DEBUG
        XCTAssertEqual(Config.Environment.current, Config.Environment.development)
        #else
        XCTAssertEqual(Config.Environment.current, Config.Environment.production)
        #endif
    }
    
    func testFirebaseConfigurationLoading() {
        let config = Config.shared
        
        XCTAssertEqual(config.firebaseApiKey, "test_api_key")
        XCTAssertEqual(config.firebaseProjectId, "test_project_id")
        XCTAssertEqual(config.firebaseStorageBucket, "test_storage_bucket")
        XCTAssertEqual(config.firebaseAppId, "test_app_id")
        XCTAssertEqual(config.firebaseMeasurementId, "test_measurement_id")
        XCTAssertEqual(config.firebaseGcmSenderId, "test_gcm_sender_id")
    }
    
    // MARK: - Helper Methods
    
    private func setEnvironmentVariables() {
        setenv("FIREBASE_API_KEY", "test_api_key", 1)
        setenv("FIREBASE_PROJECT_ID", "test_project_id", 1)
        setenv("FIREBASE_STORAGE_BUCKET", "test_storage_bucket", 1)
        setenv("FIREBASE_APP_ID", "test_app_id", 1)
        setenv("FIREBASE_MEASUREMENT_ID", "test_measurement_id", 1)
        setenv("FIREBASE_GCM_SENDER_ID", "test_gcm_sender_id", 1)
    }
    
    private func clearEnvironmentVariables() {
        unsetenv("FIREBASE_API_KEY")
        unsetenv("FIREBASE_PROJECT_ID")
        unsetenv("FIREBASE_STORAGE_BUCKET")
        unsetenv("FIREBASE_APP_ID")
        unsetenv("FIREBASE_MEASUREMENT_ID")
        unsetenv("FIREBASE_GCM_SENDER_ID")
    }
} 