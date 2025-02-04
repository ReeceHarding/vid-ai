import Foundation
import FirebaseStorage
import Combine

enum StorageError: Error {
    case uploadFailed(String)
    case downloadFailed(String)
    case deleteFailed(String)
    case invalidURL
    case invalidFile
}

class StorageService {
    private let storage = Storage.storage()
    
    func uploadVideo(url: URL, courseId: String, lectureId: String, onProgress: @escaping (Double) -> Void) async throws -> String {
        let filename = "\(lectureId).mp4"
        let path = "courses/\(courseId)/lectures/\(lectureId)/\(filename)"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putFile(from: url, metadata: metadata)
            
            uploadTask.observe(.progress) { snapshot in
                let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
                onProgress(percentComplete)
            }
            
            uploadTask.observe(.success) { _ in
                continuation.resume(returning: path)
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: StorageError.uploadFailed(error.localizedDescription))
                }
            }
        }
    }
    
    func downloadVideo(path: String, onProgress: @escaping (Double) -> Void) async throws -> URL {
        let storageRef = storage.reference().child(path)
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        return try await withCheckedThrowingContinuation { continuation in
            let downloadTask = storageRef.write(toFile: localURL)
            
            downloadTask.observe(.progress) { snapshot in
                let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
                onProgress(percentComplete)
            }
            
            downloadTask.observe(.success) { _ in
                continuation.resume(returning: localURL)
            }
            
            downloadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: StorageError.downloadFailed(error.localizedDescription))
                }
            }
        }
    }
    
    func deleteVideo(path: String) async throws {
        let storageRef = storage.reference().child(path)
        
        do {
            try await storageRef.delete()
        } catch {
            throw StorageError.deleteFailed(error.localizedDescription)
        }
    }
    
    func getVideoURL(path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        
        do {
            let url = try await storageRef.downloadURL()
            return url
        } catch {
            throw StorageError.invalidURL
        }
    }
    
    func generateThumbnail(from videoURL: URL, at time: TimeInterval = 0) async throws -> URL {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: time, preferredTimescale: 1), actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            
            let thumbnailURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
            if let imageData = uiImage.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: thumbnailURL)
                return thumbnailURL
            } else {
                throw StorageError.invalidFile
            }
        } catch {
            throw StorageError.invalidFile
        }
    }
    
    func uploadThumbnail(url: URL, courseId: String, lectureId: String) async throws -> String {
        let filename = "\(lectureId)_thumb.jpg"
        let path = "courses/\(courseId)/lectures/\(lectureId)/\(filename)"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await storageRef.putFile(from: url, metadata: metadata)
            return path
        } catch {
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
} 