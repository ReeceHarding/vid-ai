import Foundation
import AVFoundation
import CoreImage
import AppKit

enum VideoProcessingError: Error {
    case loadFailed
    case exportFailed(String)
    case invalidAsset
    case invalidSegment
    case invalidComposition
    case invalidOverlay
    case processingFailed(String)
}

public class VideoProcessingService {
    private let exportQueue = DispatchQueue(label: "com.aivideoeditor.export")
    
    public init() {}
    
    public func loadVideo(from url: URL) async throws -> AVAsset {
        let asset = AVAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard !tracks.isEmpty else {
            throw VideoProcessingError.invalidAsset
        }
        return asset
    }
    
    public func extractSegment(from asset: AVAsset, startTime: CMTime, endTime: CMTime) async throws -> AVAsset {
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
    
    public func findNearestKeyframe(in asset: AVAsset, around time: CMTime) async throws -> CMTime {
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw VideoProcessingError.invalidAsset
        }
        
        // Get sample timing information
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                AVVideoAllowWideColorKey: true
            ]
        )
        output.alwaysCopiesSampleData = false
        reader.add(output)
        
        guard reader.startReading() else {
            throw VideoProcessingError.invalidAsset
        }
        
        var keyframeTimes: [CMTime] = []
        
        // Read all samples to find keyframes
        while let sampleBuffer = output.copyNextSampleBuffer() {
            let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]]
            
            if let first = attachments?.first {
                let notDependsOnOthers = (first[kCMSampleAttachmentKey_DependsOnOthers] as? Bool) == false
                let isKeyframe = (first[kCMSampleAttachmentKey_NotSync] as? Bool) == false
                
                if notDependsOnOthers || isKeyframe {
                    keyframeTimes.append(presentationTime)
                }
            }
        }
        
        reader.cancelReading()
        
        // If no keyframes found, try to infer them based on the video settings
        if keyframeTimes.isEmpty {
            // Assuming keyframes every 0.5 seconds
            let duration = try await asset.load(.duration)
            let keyframeInterval = 0.5 // 0.5 seconds
            var currentTime = CMTime.zero
            
            while currentTime < duration {
                keyframeTimes.append(currentTime)
                currentTime = CMTimeAdd(currentTime, CMTime(seconds: keyframeInterval, preferredTimescale: 600))
            }
        }
        
        // If still no keyframes, return the original time
        guard !keyframeTimes.isEmpty else {
            return time
        }
        
        // Find the nearest keyframe
        var nearestTime = keyframeTimes[0]
        var minDiff = abs(CMTimeGetSeconds(time) - CMTimeGetSeconds(nearestTime))
        
        for keyframeTime in keyframeTimes {
            let diff = abs(CMTimeGetSeconds(time) - CMTimeGetSeconds(keyframeTime))
            if diff < minDiff {
                minDiff = diff
                nearestTime = keyframeTime
            }
        }
        
        // If the nearest keyframe is the same as the input time (within a small threshold),
        // return the next keyframe if available
        if abs(CMTimeGetSeconds(nearestTime) - CMTimeGetSeconds(time)) < 0.001 {
            if let nextKeyframe = keyframeTimes.first(where: { CMTimeGetSeconds($0) > CMTimeGetSeconds(time) }) {
                return nextKeyframe
            }
        }
        
        return nearestTime
    }
    
    public func combineSegments(_ segments: [AVAsset], withTransitionDuration duration: CMTime = CMTime(seconds: 0.5, preferredTimescale: 600)) async throws -> AVAsset {
        guard !segments.isEmpty else {
            throw VideoProcessingError.invalidComposition
        }
        
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
    
    public func generateOverlay(text: String, size: CGSize) throws -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let rect = CGRect(x: (size.width - textSize.width) / 2,
                        y: (size.height - textSize.height) / 2,
                        width: textSize.width,
                        height: textSize.height)
        
        text.draw(in: rect, withAttributes: attributes)
        image.unlockFocus()
        
        return image
    }
    
    public func generateContextualOverlay(text: String, size: CGSize) throws -> NSImage {
        // For now, this is just an alias for generateOverlay
        // In a real implementation, we would add context-specific styling
        return try generateOverlay(text: text, size: size)
    }
    
    public func insertOverlay(_ image: NSImage, into composition: AVMutableComposition, at time: CMTime, duration: CMTime) throws {
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            throw VideoProcessingError.invalidComposition
        }
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: time, duration: duration)
        
        // Create CALayer for overlay
        let overlayLayer = CALayer()
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            overlayLayer.contents = cgImage
        }
        overlayLayer.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        overlayLayer.opacity = 0.8
        
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)
        
        instruction.layerInstructions = [layerInstruction]
    }
    
    public func normalizeAudio(in composition: AVMutableComposition) throws {
        guard let audioTrack = composition.tracks(withMediaType: .audio).first else {
            return
        }
        
        let audioMix = AVMutableAudioMix()
        let parameters = AVMutableAudioMixInputParameters(track: audioTrack)
        parameters.setVolume(1.0, at: .zero)
        audioMix.inputParameters = [parameters]
    }
    
    public func export(composition: AVAsset, to outputURL: URL, preset: String = AVAssetExportPresetHighestQuality) async throws {
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
} 