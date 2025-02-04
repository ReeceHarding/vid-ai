import SwiftUI; struct ContentView: View { var body: some View { Button("Test Crash") { let numbers = [0]; let _ = numbers[1] } } }
