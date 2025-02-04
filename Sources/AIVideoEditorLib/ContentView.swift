import SwiftUI

@available(macOS 10.15, *)
public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        Text("AI Video Editor")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@available(macOS 10.15, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 