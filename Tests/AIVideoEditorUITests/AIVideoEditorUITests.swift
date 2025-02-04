import XCTest
@testable import AIVideoEditorApp

final class AIVideoEditorUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Set up test environment
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // Test 1: Verify Home Screen Navigation Title
    func testHomeScreenTitle() throws {
        // Verify the navigation title is "Home"
        let navigationBar = app.navigationBars["Home"]
        XCTAssertTrue(navigationBar.exists, "Home navigation bar should exist")
        
        // Verify the main text label exists
        let mainLabel = app.staticTexts["AI Video Editor"]
        XCTAssertTrue(mainLabel.exists, "Main title label should exist")
    }
    
    // Test 2: Test Video Import Button and Auto-loaded Test Video
    func testVideoImportButton() throws {
        // First verify that our test video is loaded automatically
        let videoPlayer = app.otherElements["VideoPlayer"]
        XCTAssertTrue(videoPlayer.waitForExistence(timeout: 5), "Video player should appear with test video")
        
        // Test import functionality for new video
        let importButton = app.buttons["Import Video"]
        XCTAssertTrue(importButton.exists, "Import video button should exist")
        importButton.tap()
        
        // Verify file picker appears
        let filePicker = app.otherElements["FilePicker"]
        XCTAssertTrue(filePicker.waitForExistence(timeout: 2), "File picker should appear")
    }
    
    // Test 3: Test Settings Menu
    func testSettingsMenu() throws {
        // First verify video is loaded
        let videoPlayer = app.otherElements["VideoPlayer"]
        XCTAssertTrue(videoPlayer.waitForExistence(timeout: 5), "Video player should appear with test video")
        
        // Tap settings button
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists, "Settings button should exist")
        settingsButton.tap()
        
        // Wait for settings view to appear
        let darkModeToggle = app.switches["Dark Mode"]
        XCTAssertTrue(darkModeToggle.waitForExistence(timeout: 2), "Dark mode toggle should exist")
        
        // Test dark mode toggle
        darkModeToggle.tap()
        XCTAssertEqual(darkModeToggle.value as? String, "1", "Dark mode should be enabled")
    }
    
    // Test 4: Test Video Processing Controls with Auto-loaded Video
    func testVideoProcessingControls() throws {
        // Verify test video is loaded
        let videoPlayer = app.otherElements["VideoPlayer"]
        XCTAssertTrue(videoPlayer.waitForExistence(timeout: 5), "Video player should appear with test video")
        
        // Test play button
        let playButton = app.buttons["Play"]
        XCTAssertTrue(playButton.exists, "Play button should exist")
        playButton.tap()
        
        // Wait for pause button to appear
        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 2), "Pause button should appear after playing")
        pauseButton.tap()
        
        // Verify play button reappears
        XCTAssertTrue(playButton.waitForExistence(timeout: 2), "Play button should reappear after pausing")
    }
    
    // Test 5: Test Export Functionality with Auto-loaded Video
    func testExportFunctionality() throws {
        // Verify test video is loaded
        let videoPlayer = app.otherElements["VideoPlayer"]
        XCTAssertTrue(videoPlayer.waitForExistence(timeout: 5), "Video player should appear with test video")
        
        // Tap export button
        let exportButton = app.buttons["Export"]
        XCTAssertTrue(exportButton.exists, "Export button should exist")
        exportButton.tap()
        
        // Test quality picker
        let qualityPicker = app.pickers["Quality"]
        XCTAssertTrue(qualityPicker.waitForExistence(timeout: 2), "Quality picker should exist")
        
        // Test confirm export button
        let exportConfirmButton = app.buttons["Confirm Export"]
        XCTAssertTrue(exportConfirmButton.exists, "Export confirm button should exist")
        exportConfirmButton.tap()
        
        // Verify we return to main view and video is still loaded
        XCTAssertTrue(videoPlayer.exists, "Should return to video player view")
    }
} 