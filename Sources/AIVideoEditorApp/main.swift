import AppKit
import SwiftUI
import AIVideoEditorLib

// Initialize the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) 