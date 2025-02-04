@preconcurrency import AVFoundation
import XCTest
import AppKit
@testable import AIVideoEditorLib

// Helper extension to convert AVAudioPCMBuffer to CMSampleBuffer
extension AVAudioPCMBuffer {
    func toCMSampleBuffer() throws -> CMSampleBuffer? {
        var asbd = format.streamDescription.pointee
        var formatDescription: CMFormatDescription?
        
        let status = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let description = formatDescription else {
            return nil
        }
        
        let sampleCount = Int(frameLength)
        let timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: Int32(format.sampleRate)),
            presentationTimeStamp: .zero,
            decodeTimeStamp: .zero
        )
        
        var sampleBuffer: CMSampleBuffer?
        let sampleSize = Int(frameLength * format.streamDescription.pointee.mBytesPerFrame)
        
        let sampleStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: description,
            sampleCount: sampleCount,
            sampleTimingEntryCount: 1,
            sampleTimingArray: [timing],
            sampleSizeEntryCount: 1,
            sampleSizeArray: [sampleSize],
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleStatus == noErr, let buffer = sampleBuffer else {
            return nil
        }
        
        return buffer
    }
}

final class VideoProcessingTests: XCTestCase {
    var videoProcessor: VideoProcessingService!
    var testVideoURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        videoProcessor = VideoProcessingService()
        
        // Create a test video URL in the temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        testVideoURL = tempDir.appendingPathComponent("test_video.mp4")
        
        // Create a sample test video file
        try await createSampleTestVideo()
    }
    
    override func tearDown() {
        // Clean up test files
        try? FileManager.default.removeItem(at: testVideoURL)
        super.tearDown()
    }
    
    private func createSampleTestVideo() async throws {
        // Create a CIImage with a gradient
        let width = 1920
        let height = 1080
        let gradientImage = CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5)).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Create a CGImage from CIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(gradientImage, from: gradientImage.extent) else {
            throw VideoProcessingError.invalidAsset
        }
        
        // Create a pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                           width,
                           height,
                           kCVPixelFormatType_32ARGB,
                           attrs,
                           &pixelBuffer)
        
        guard let pixelBuffer = pixelBuffer else {
            throw VideoProcessingError.invalidAsset
        }
        
        // Copy CGImage into pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
            throw VideoProcessingError.invalidAsset
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: testVideoURL.path) {
            try FileManager.default.removeItem(at: testVideoURL)
        }
        
        // Create asset writer
        guard let writer = try? AVAssetWriter(url: testVideoURL, fileType: .mp4) else {
            throw VideoProcessingError.invalidAsset
        }
        
        // Configure video input with strict keyframe interval
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: 15, // Force keyframe every 15 frames (0.5s at 30fps)
                AVVideoMaxKeyFrameIntervalDurationKey: 0.5, // Force keyframe every 0.5 seconds
                AVVideoExpectedSourceFrameRateKey: 30, // Explicitly set frame rate
                AVVideoAllowFrameReorderingKey: false // Disable frame reordering for more predictable keyframes
            ]
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.transform = CGAffineTransform(rotationAngle: 0) // Force no rotation
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        
        // Configure audio input
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        
        videoInput.expectsMediaDataInRealTime = false
        audioInput.expectsMediaDataInRealTime = false
        
        writer.add(videoInput)
        writer.add(audioInput)
        
        guard writer.startWriting() else {
            throw VideoProcessingError.invalidAsset
        }
        
        writer.startSession(atSourceTime: .zero)
        
        // Create audio buffer
        let sampleRate = 44100.0
        let duration = 2.0 // 2 seconds to ensure we have multiple keyframes
        let numberOfSamples = Int(sampleRate * duration)
        let frequency = 440.0 // A4 note
        
        var audioData = [Float](repeating: 0, count: numberOfSamples * 2) // Stereo
        for i in 0..<numberOfSamples {
            let sampleTime = Double(i) / sampleRate
            let sample = Float(sin(2.0 * .pi * frequency * sampleTime)) * 0.5
            audioData[i * 2] = sample     // Left channel
            audioData[i * 2 + 1] = sample // Right channel
        }
        
        // Create audio buffer format description
        var asbd = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 8,
            mFramesPerPacket: 1,
            mBytesPerFrame: 8,
            mChannelsPerFrame: 2,
            mBitsPerChannel: 32,
            mReserved: 0
        )
        
        var formatDescription: CMFormatDescription?
        CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        // Write frames
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Write video frames
            group.addTask {
                let frameCount = 60 // 2 seconds at 30fps
                for i in 0..<frameCount {
                    while !videoInput.isReadyForMoreMediaData {
                        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 second
                    }
                    
                    let frameTime = CMTime(value: CMTimeValue(i), timescale: 30)
                    
                    // Force keyframe at specific intervals
                    if i % 15 == 0 { // Every 15 frames (0.5s at 30fps)
                        var sampleBuffer: CMSampleBuffer?
                        var formatDescription: CMFormatDescription?
                        
                        CVPixelBufferLockBaseAddress(pixelBuffer, [])
                        CMVideoFormatDescriptionCreateForImageBuffer(
                            allocator: kCFAllocatorDefault,
                            imageBuffer: pixelBuffer,
                            formatDescriptionOut: &formatDescription
                        )
                        
                        if let formatDescription = formatDescription {
                            var timing = CMSampleTimingInfo(
                                duration: CMTime(value: 1, timescale: 30),
                                presentationTimeStamp: frameTime,
                                decodeTimeStamp: .invalid
                            )
                            CMSampleBufferCreateForImageBuffer(
                                allocator: kCFAllocatorDefault,
                                imageBuffer: pixelBuffer,
                                dataReady: true,
                                makeDataReadyCallback: nil,
                                refcon: nil,
                                formatDescription: formatDescription,
                                sampleTiming: &timing,
                                sampleBufferOut: &sampleBuffer
                            )
                        }
                        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                        
                        if let sampleBuffer = sampleBuffer {
                            CMSetAttachment(sampleBuffer, key: kCMSampleAttachmentKey_DependsOnOthers, value: kCFBooleanFalse, attachmentMode: kCMAttachmentMode_ShouldPropagate)
                            CMSetAttachment(sampleBuffer, key: kCMSampleAttachmentKey_NotSync, value: kCFBooleanFalse, attachmentMode: kCMAttachmentMode_ShouldPropagate)
                            videoInput.append(sampleBuffer)
                        } else {
                            pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
                        }
                    } else {
                        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
                    }
                }
                
                videoInput.markAsFinished()
            }
            
            // Write audio samples
            group.addTask {
                let audioData = audioData // Capture for async context
                let blockSize = 4096
                let blockCount = (numberOfSamples * 2 + blockSize - 1) / blockSize
                
                for block in 0..<blockCount {
                    while !audioInput.isReadyForMoreMediaData {
                        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 second
                    }
                    
                    let startSample = block * blockSize
                    let endSample = min(startSample + blockSize, numberOfSamples * 2)
                    let blockLength = endSample - startSample
                    
                    var blockBuffer: CMBlockBuffer?
                    let status = CMBlockBufferCreateWithMemoryBlock(
                        allocator: kCFAllocatorDefault,
                        memoryBlock: nil,
                        blockLength: blockLength * 4, // 4 bytes per float
                        blockAllocator: nil,
                        customBlockSource: nil,
                        offsetToData: 0,
                        dataLength: blockLength * 4,
                        flags: 0,
                        blockBufferOut: &blockBuffer
                    )
                    
                    guard status == noErr, let blockBuffer = blockBuffer else {
                        continue
                    }
                    
                    // Copy audio data to block buffer
                    _ = audioData[startSample..<endSample].withUnsafeBytes { ptr in
                        CMBlockBufferReplaceDataBytes(
                            with: ptr.baseAddress!,
                            blockBuffer: blockBuffer,
                            offsetIntoDestination: 0,
                            dataLength: blockLength * 4
                        )
                    }
                    
                    var sampleBuffer: CMSampleBuffer?
                    let numSamples = blockLength / 2 // Convert from samples to frames (stereo)
                    let timing = CMSampleTimingInfo(
                        duration: CMTime(value: 1, timescale: Int32(sampleRate)),
                        presentationTimeStamp: CMTime(value: CMTimeValue(startSample / 2), timescale: Int32(sampleRate)),
                        decodeTimeStamp: .invalid
                    )
                    
                    guard let formatDescription = formatDescription else {
                        continue
                    }
                    
                    CMSampleBufferCreate(
                        allocator: kCFAllocatorDefault,
                        dataBuffer: blockBuffer,
                        dataReady: true,
                        makeDataReadyCallback: nil,
                        refcon: nil,
                        formatDescription: formatDescription,
                        sampleCount: numSamples,
                        sampleTimingEntryCount: 1,
                        sampleTimingArray: [timing],
                        sampleSizeEntryCount: 0,
                        sampleSizeArray: nil,
                        sampleBufferOut: &sampleBuffer
                    )
                    
                    if let buffer = sampleBuffer {
                        audioInput.append(buffer)
                    }
                }
                
                audioInput.markAsFinished()
            }
            
            try await group.waitForAll()
        }
        
        // Finish writing
        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }
        
        // Verify the file exists and has valid tracks
        guard FileManager.default.fileExists(atPath: testVideoURL.path) else {
            throw VideoProcessingError.invalidAsset
        }
        
        let finalAsset = AVAsset(url: testVideoURL)
        let finalVideoTracks = try await finalAsset.loadTracks(withMediaType: .video)
        let finalAudioTracks = try await finalAsset.loadTracks(withMediaType: .audio)
        
        guard !finalVideoTracks.isEmpty, !finalAudioTracks.isEmpty else {
            throw VideoProcessingError.invalidAsset
        }
    }
    
    // Task 51: Test Video Processing Service
    func testVideoProcessorInitialization() {
        XCTAssertNotNil(videoProcessor, "VideoProcessor should be initialized")
    }
    
    // Task 52: Test Segment Extraction
    func testSegmentExtraction() async throws {
        // Given
        let asset = AVAsset(url: testVideoURL)
        let startTime = CMTime(seconds: 0, preferredTimescale: 600)
        let endTime = CMTime(seconds: 5, preferredTimescale: 600)
        
        // When
        let extractedSegment = try await videoProcessor.extractSegment(from: asset, startTime: startTime, endTime: endTime)
        
        // Then
        XCTAssertNotNil(extractedSegment)
        let duration = try await extractedSegment.load(.duration)
        XCTAssertEqual(duration.seconds, 5.0, accuracy: 0.1)
    }
    
    // Task 53: Test Keyframe Alignment
    func testKeyframeAlignment() async throws {
        // Given
        let asset = AVAsset(url: testVideoURL)
        let startTime = CMTime(seconds: 0.75, preferredTimescale: 600) // Between keyframes
        
        // When
        let alignedTime = try await videoProcessor.findNearestKeyframe(in: asset, around: startTime)
        
        // Then
        XCTAssertNotNil(alignedTime)
        XCTAssertNotEqual(alignedTime.seconds, startTime.seconds, "Time should be adjusted to nearest keyframe")
    }
    
    // Task 54: Test Video Stitching
    func testVideoStitching() async throws {
        // Given
        let segment1 = AVAsset(url: testVideoURL)
        let segment2 = AVAsset(url: testVideoURL)
        let segments = [segment1, segment2]
        
        // When
        let composition = try await videoProcessor.combineSegments(segments)
        
        // Then
        XCTAssertNotNil(composition)
        let videoTracks = try await composition.loadTracks(withMediaType: AVMediaType.video)
        let audioTracks = try await composition.loadTracks(withMediaType: AVMediaType.audio)
        XCTAssertEqual(videoTracks.count, 1)
        XCTAssertEqual(audioTracks.count, 1)
    }
    
    // Task 55: Test Overlay Generation and Insertion
    func testOverlayGeneration() throws {
        // Given
        let text = "Test Overlay"
        let size = CGSize(width: 1920, height: 1080)
        
        // When
        let overlay = try videoProcessor.generateOverlay(text: text, size: size)
        
        // Then
        XCTAssertNotNil(overlay)
        XCTAssertEqual(overlay.size.width, size.width)
        XCTAssertEqual(overlay.size.height, size.height)
    }
    
    func testOverlayInsertion() async throws {
        // Given
        let composition = AVMutableComposition()
        let overlay = try videoProcessor.generateOverlay(text: "Test", size: CGSize(width: 1920, height: 1080))
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        let duration = CMTime(seconds: 5, preferredTimescale: 600)
        
        // Create a video track in the composition for testing
        let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        XCTAssertNotNil(videoTrack)
        
        // When
        try videoProcessor.insertOverlay(overlay, into: composition, at: time, duration: duration)
        
        // Then
        let tracks = try await composition.loadTracks(withMediaType: AVMediaType.video)
        XCTAssertEqual(tracks.count, 1)
    }
    
    // Task 56: Test Contextual Overlay Generation
    func testContextualOverlayGeneration() throws {
        // Given
        let context = "Chapter 1: Introduction"
        let size = CGSize(width: 1920, height: 1080)
        
        // When
        let overlay = try videoProcessor.generateContextualOverlay(text: context, size: size)
        
        // Then
        XCTAssertNotNil(overlay)
        XCTAssertEqual(overlay.size.width, size.width)
        XCTAssertEqual(overlay.size.height, size.height)
    }
    
    // Task 57: Test Audio Normalization
    func testAudioNormalization() async throws {
        // Given
        let composition = AVMutableComposition()
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        XCTAssertNotNil(audioTrack)
        
        // When
        try videoProcessor.normalizeAudio(in: composition)
        
        // Then
        let tracks = try await composition.loadTracks(withMediaType: AVMediaType.audio)
        XCTAssertEqual(tracks.count, 1)
    }
    
    // Test error conditions
    func testInvalidSegmentExtraction() async throws {
        // Given
        let asset = AVAsset(url: testVideoURL)
        let startTime = CMTime(seconds: 10, preferredTimescale: 600)
        let endTime = CMTime(seconds: 5, preferredTimescale: 600)
        
        // When/Then
        do {
            _ = try await videoProcessor.extractSegment(from: asset, startTime: startTime, endTime: endTime)
            XCTFail("Should throw an error for invalid time range")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testEmptyComposition() async throws {
        // Given
        let segments: [AVAsset] = []
        
        // When/Then
        do {
            _ = try await videoProcessor.combineSegments(segments)
            XCTFail("Should throw an error for empty segments array")
        } catch {
            XCTAssertNotNil(error)
        }
    }
} 