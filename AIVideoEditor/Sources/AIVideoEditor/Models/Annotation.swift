import Foundation
import FirebaseFirestore

struct Annotation: Codable, Identifiable {
    let id: String
    let videoId: String
    let transcriptSegmentId: String
    let type: AnnotationType
    let content: String
    let timestamp: TimeInterval
    let createdAt: Date
    let updatedAt: Date
    
    enum AnnotationType: String, Codable {
        case title
        case summary
        case highlight
        case note
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case videoId = "video_id"
        case transcriptSegmentId = "transcript_segment_id"
        case type
        case content
        case timestamp
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Annotation {
    static func fromFirestore(_ document: DocumentSnapshot) throws -> Annotation {
        try document.data(as: Annotation.self)
    }
} 