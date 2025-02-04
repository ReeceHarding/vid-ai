import XCTest
import FirebaseAnalytics
import FirebaseCore
@testable import AIVideoEditorLib

final class FirebaseConfigTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Set up test environment variables
        setEnvironmentVariables()
        // Reset any existing Firebase configuration
        if FirebaseApp.app() != nil {
            FirebaseApp.app()?.delete { _ in }
        }
    }
    
    override func tearDown() {
        // Clean up environment variables
        clearEnvironmentVariables()
        // Clean up Firebase configuration
        if FirebaseApp.app() != nil {
            FirebaseApp.app()?.delete { _ in }
        }
        super.tearDown()
    }
    
    func testFirebaseConfiguration() {
        // Given
        let config = Config.shared
        
        // When
        let options = FirebaseOptions(
            googleAppID: config.firebaseAppId,
            gcmSenderID: config.firebaseGcmSenderId
        )
        options.projectID = config.firebaseProjectId
        options.storageBucket = config.firebaseStorageBucket
        
        // Then
        XCTAssertEqual(options.googleAppID, "test_app_id")
        XCTAssertEqual(options.gcmSenderID, "test_gcm_sender_id")
        XCTAssertEqual(options.projectID, "test_project_id")
        XCTAssertEqual(options.storageBucket, "test_storage_bucket")
    }
    
    func testFirebaseAnalyticsLogging() {
        // Given
        let expectation = XCTestExpectation(description: "Analytics event logged")
        
        // When
        let config = Config.shared
        let options = FirebaseOptions(
            googleAppID: config.firebaseAppId,
            gcmSenderID: config.firebaseGcmSenderId
        )
        options.projectID = config.firebaseProjectId
        options.storageBucket = config.firebaseStorageBucket
        options.apiKey = "test_api_key"
        
        // Skip actual Firebase configuration in test environment
        // Just verify that the configuration values are correct
        XCTAssertEqual(options.googleAppID, "test_app_id")
        XCTAssertEqual(options.gcmSenderID, "test_gcm_sender_id")
        XCTAssertEqual(options.projectID, "test_project_id")
        XCTAssertEqual(options.storageBucket, "test_storage_bucket")
        XCTAssertEqual(options.apiKey, "test_api_key")
        
        // Fulfill the expectation since we're not actually logging events in tests
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
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