import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum FirestoreError: Error {
    case documentNotFound
    case encodingError
    case decodingError
    case invalidData
    case updateFailed(String)
    case deleteFailed(String)
}

class FirestoreService {
    private let db = Firestore.firestore()
    
    // MARK: - Videos
    
    func createVideo(_ video: Video) async throws {
        let docRef = db.collection("videos").document(video.id)
        try await docRef.setData(from: video)
    }
    
    func getVideo(id: String) async throws -> Video {
        let docRef = db.collection("videos").document(id)
        let document = try await docRef.getDocument()
        
        guard let video = try? document.data(as: Video.self) else {
            throw FirestoreError.documentNotFound
        }
        return video
    }
    
    func updateVideo(_ video: Video) async throws {
        let docRef = db.collection("videos").document(video.id)
        try await docRef.setData(from: video, merge: true)
    }
    
    func deleteVideo(id: String) async throws {
        let docRef = db.collection("videos").document(id)
        try await docRef.delete()
    }
    
    func getVideos(forTeacherId teacherId: String) async throws -> [Video] {
        let snapshot = try await db.collection("videos")
            .whereField("teacher_id", isEqualTo: teacherId)
            .order(by: "created_at", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Video.self)
        }
    }
    
    // MARK: - Transcripts
    
    func createTranscript(_ transcript: Transcript) async throws {
        let docRef = db.collection("transcripts").document(transcript.id)
        try await docRef.setData(from: transcript)
    }
    
    func getTranscript(forVideoId videoId: String) async throws -> Transcript {
        let snapshot = try await db.collection("transcripts")
            .whereField("video_id", isEqualTo: videoId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first,
              let transcript = try? document.data(as: Transcript.self) else {
            throw FirestoreError.documentNotFound
        }
        return transcript
    }
    
    func updateTranscript(_ transcript: Transcript) async throws {
        let docRef = db.collection("transcripts").document(transcript.id)
        try await docRef.setData(from: transcript, merge: true)
    }
    
    // MARK: - Annotations
    
    func createAnnotation(_ annotation: Annotation) async throws {
        let docRef = db.collection("annotations").document(annotation.id)
        try await docRef.setData(from: annotation)
    }
    
    func getAnnotations(forVideoId videoId: String) async throws -> [Annotation] {
        let snapshot = try await db.collection("annotations")
            .whereField("video_id", isEqualTo: videoId)
            .order(by: "timestamp")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Annotation.self)
        }
    }
    
    func updateAnnotation(_ annotation: Annotation) async throws {
        let docRef = db.collection("annotations").document(annotation.id)
        try await docRef.setData(from: annotation, merge: true)
    }
    
    func deleteAnnotation(id: String) async throws {
        let docRef = db.collection("annotations").document(id)
        try await docRef.delete()
    }
    
    // MARK: - Batch Operations
    
    func batchUpdate<T: Encodable>(_ objects: [T], inCollection collection: String) async throws {
        let batch = db.batch()
        
        for object in objects {
            guard let id = (object as? any Identifiable)?.id as? String else {
                throw FirestoreError.invalidData
            }
            let docRef = db.collection(collection).document(id)
            try batch.setData(from: object, forDocument: docRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    func batchDelete(ids: [String], fromCollection collection: String) async throws {
        let batch = db.batch()
        
        for id in ids {
            let docRef = db.collection(collection).document(id)
            batch.deleteDocument(docRef)
        }
        
        try await batch.commit()
    }
} 