import Foundation
import AVFoundation
import CoreImage
import UIKit

enum VideoProcessingError: Error {
    case loadFailed
    case exportFailed(String)
    case invalidAsset
    case invalidSegment
    case invalidComposition
    case invalidOverlay
    case processingFailed(String)
}

class VideoProcessingService {
    private let exportQueue = DispatchQueue(label: "com.aivideoeditor.export")
    
    func loadVideo(from url: URL) async throws -> AVAsset {
        let asset = AVAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard !tracks.isEmpty else {
            throw VideoProcessingError.invalidAsset
        }
        return asset
    }
    
    func extractSegment(from asset: AVAsset, startTime: CMTime, endTime: CMTime) async throws -> AVAsset {
        let composition = AVMutableComposition()
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoProcessingError.invalidSegment
        }
        
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
        
        return composition
    }
    
    func combineSegments(_ segments: [AVAsset], withTransitionDuration duration: CMTime = CMTime(seconds: 0.5, preferredTimescale: 600)) async throws -> AVAsset {
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw VideoProcessingError.invalidComposition
        }
        
        var currentTime = CMTime.zero
        var instructions: [AVMutableVideoCompositionInstruction] = []
        
        for (index, segment) in segments.enumerated() {
            guard let videoTrack = try? await segment.loadTracks(withMediaType: .video).first,
                  let audioTrack = try? await segment.loadTracks(withMediaType: .audio).first else {
                continue
            }
            
            let segmentDuration = try await segment.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: segmentDuration)
            
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
            try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: currentTime)
            
            if index > 0 {
                // Add cross-dissolve transition
                let transitionTimeRange = CMTimeRange(start: currentTime, duration: duration)
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = transitionTimeRange
                
                let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                fromLayer.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: transitionTimeRange)
                
                let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                toLayer.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: transitionTimeRange)
                
                instruction.layerInstructions = [fromLayer, toLayer]
                instructions.append(instruction)
            }
            
            currentTime = CMTimeAdd(currentTime, segmentDuration)
        }
        
        videoComposition.instructions = instructions
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        return composition
    }
    
    func generateOverlay(text: String, size: CGSize) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let rect = CGRect(x: (size.width - textSize.width) / 2,
                            y: (size.height - textSize.height) / 2,
                            width: textSize.width,
                            height: textSize.height)
            
            text.draw(in: rect, withAttributes: attributes)
        }
        return image
    }
    
    func insertOverlay(_ image: UIImage, into composition: AVMutableComposition, at time: CMTime, duration: CMTime) throws {
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            throw VideoProcessingError.invalidComposition
        }
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: time, duration: duration)
        
        // Create CALayer for overlay
        let overlayLayer = CALayer()
        overlayLayer.contents = image.cgImage
        overlayLayer.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        overlayLayer.opacity = 0.8
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        instruction.layerInstructions = [layerInstruction]
    }
    
    func export(composition: AVAsset, to outputURL: URL, preset: String = AVAssetExportPresetHighestQuality) async throws {
        guard let export = AVAssetExportSession(asset: composition, presetName: preset) else {
            throw VideoProcessingError.exportFailed("Could not create export session")
        }
        
        export.outputURL = outputURL
        export.outputFileType = .mp4
        
        await export.export()
        
        if let error = export.error {
            throw VideoProcessingError.exportFailed(error.localizedDescription)
        }
    }
    
    func normalizeAudio(in composition: AVMutableComposition) throws {
        guard let audioTrack = composition.tracks(withMediaType: .audio).first else {
            return
        }
        
        let audioMix = AVMutableAudioMix()
        let parameters = AVMutableAudioMixInputParameters(track: audioTrack)
        parameters.setVolume(1.0, at: .zero)
        audioMix.inputParameters = [parameters]
    }
    
    func applyFilter(_ filter: CIFilter, to composition: AVMutableComposition) throws {
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            throw VideoProcessingError.invalidComposition
        }
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = CGSize(width: 1920, height: 1080)
        
        // Apply CIFilter
        videoComposition.customVideoCompositorClass = CIFilterCompositor.self
    }
} 