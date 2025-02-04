import SwiftUI
import AVKit

struct ContentView: View {
    @State private var selectedVideo: URL?
    @State private var showingFilePicker = false
    @State private var showingSettings = false
    @State private var showingExportOptions = false
    @State private var isPlaying = false
    @State private var selectedQuality = "High"
    
    var body: some View {
        NavigationView {
            VStack {
                Text("AI Video Editor")
                    .font(.largeTitle)
                    .accessibilityIdentifier("AI Video Editor")
                
                if let videoURL = selectedVideo {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(height: 300)
                        .accessibilityIdentifier("VideoPlayer")
                    
                    HStack {
                        Button(isPlaying ? "Pause" : "Play") {
                            isPlaying.toggle()
                        }
                        .accessibilityIdentifier(isPlaying ? "Pause" : "Play")
                        
                        Button("Export") {
                            showingExportOptions = true
                        }
                        .accessibilityIdentifier("Export")
                    }
                    .padding()
                } else {
                    Button("Import Video") {
                        showingFilePicker = true
                    }
                    .accessibilityIdentifier("Import Video")
                }
            }
            .navigationTitle("Home")
            .toolbar {
                Button("Settings") {
                    showingSettings = true
                }
                .accessibilityIdentifier("Settings")
            }
            .sheet(isPresented: $showingFilePicker) {
                Text("File Picker Placeholder")
                    .accessibilityIdentifier("FilePicker")
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    List {
                        Toggle("Dark Mode", isOn: .constant(false))
                            .accessibilityIdentifier("Dark Mode")
                    }
                    .navigationTitle("Settings")
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                NavigationView {
                    Form {
                        Picker("Quality", selection: $selectedQuality) {
                            Text("High").tag("High")
                            Text("Medium").tag("Medium")
                            Text("Low").tag("Low")
                        }
                        .accessibilityIdentifier("Quality")
                        
                        Button("Confirm Export") {
                            showingExportOptions = false
                        }
                        .accessibilityIdentifier("Confirm Export")
                    }
                    .navigationTitle("Export Options")
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 