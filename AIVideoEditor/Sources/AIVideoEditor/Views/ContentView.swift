import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("AI Video Editor")
                    .font(.title)
                
                Button("Test Crash") {
                    fatalError("Test crash")
                }
            }
        }
    }
}
