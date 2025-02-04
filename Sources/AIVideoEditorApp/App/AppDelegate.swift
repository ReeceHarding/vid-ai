import AppKit
import SwiftUI
import FirebaseCore
import FirebaseAnalytics
import AIVideoEditorLib
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var isUITesting: Bool
    private let logger = Logger(subsystem: "com.aivideo.editor", category: "AppDelegate")
    
    override init() {
        self.isUITesting = ProcessInfo.processInfo.arguments.contains("UI-Testing")
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            if !isUITesting {
                try configureFirebase()
            }
            setupMainWindow()
            
            // Set up test environment if needed
            if isUITesting {
                // Set up test data
                UserDefaults.standard.set(false, forKey: "darkMode")
                
                // Load test video
                if let testVideoURL = Bundle.main.url(forResource: "test_video", withExtension: "mp4", subdirectory: "Resources") {
                    UserDefaults.standard.set(testVideoURL.path, forKey: "lastVideoPath")
                    logger.info("Successfully loaded test video for UI testing")
                } else {
                    logger.error("Failed to find test video file")
                }
            }
        } catch {
            logger.error("Failed to configure Firebase: \(error.localizedDescription)")
            let alert = NSAlert()
            alert.messageText = "Configuration Error"
            alert.informativeText = "Failed to initialize the application. Please check your configuration."
            alert.alertStyle = .critical
            alert.runModal()
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func configureFirebase() throws {
        let config = Config.shared
        let options = FirebaseOptions(
            googleAppID: config.firebaseAppId,
            gcmSenderID: config.firebaseGcmSenderId
        )
        options.projectID = config.firebaseProjectId
        options.storageBucket = config.firebaseStorageBucket
        
        FirebaseApp.configure(options: options)
        logger.info("Firebase configured successfully")
    }
    
    private func setupMainWindow() {
        let contentView = ContentView()
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "AI Video Editor"
        window?.center()
        window?.setFrameAutosaveName("Main Window")
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup code here
    }
} 