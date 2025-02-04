import Foundation
import AVFoundation
import Speech

enum TranscriptionError: Error {
    case audioExtractionFailed
    case transcriptionFailed(String)
    case authorizationDenied
    case invalidAudio
}

class TranscriptionService {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    
    func requestAuthorization() async throws {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        guard status == .authorized else {
            throw TranscriptionError.authorizationDenied
        }
    }
    
    func transcribeVideo(url: URL, onProgress: @escaping (Double) -> Void) async throws -> [Transcript.TranscriptSegment] {
        try await requestAuthorization()
        
        let asset = AVAsset(url: url)
        guard let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first else {
            throw TranscriptionError.invalidAudio
        }
        
        // Extract audio to temporary file
        let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        export?.outputURL = audioURL
        export?.outputFileType = .m4a
        
        await export?.export()
        
        if let error = export?.error {
            throw TranscriptionError.audioExtractionFailed
        }
        
        // Perform transcription
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = true
        
        guard let recognizer = speechRecognizer else {
            throw TranscriptionError.transcriptionFailed("Speech recognizer not available")
        }
        
        var segments: [Transcript.TranscriptSegment] = []
        
        for try await result in recognizer.recognitionResults(for: request) {
            let transcriptionSegments = result.bestTranscription.segments.map { segment in
                Transcript.TranscriptSegment(
                    startTime: segment.timestamp,
                    endTime: segment.timestamp + segment.duration,
                    text: segment.substring,
                    confidence: segment.confidence
                )
            }
            
            segments = transcriptionSegments
            
            let progress = Double(result.bestTranscription.segments.count) / Double(segments.count)
            onProgress(progress)
        }
        
        // Clean up temporary audio file
        try? FileManager.default.removeItem(at: audioURL)
        
        return segments
    }
    
    func transcribeLiveAudio() -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                
                let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                recognitionRequest.shouldReportPartialResults = true
                
                guard let recognizer = speechRecognizer else {
                    continuation.finish(throwing: TranscriptionError.transcriptionFailed("Speech recognizer not available"))
                    return
                }
                
                let recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
                    if let error = error {
                        continuation.finish(throwing: TranscriptionError.transcriptionFailed(error.localizedDescription))
                    } else if let result = result {
                        continuation.yield(result.bestTranscription.formattedString)
                        
                        if result.isFinal {
                            continuation.finish()
                        }
                    }
                }
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    recognitionRequest.append(buffer)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
                
                continuation.onTermination = { @Sendable _ in
                    audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    recognitionRequest.endAudio()
                    recognitionTask.cancel()
                }
                
            } catch {
                continuation.finish(throwing: TranscriptionError.transcriptionFailed(error.localizedDescription))
            }
        }
    }
    
    func stopLiveTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
} 