import Foundation
import FirebaseFirestore

struct Transcript: Codable, Identifiable {
    let id: String
    let videoId: String
    let segments: [TranscriptSegment]
    let createdAt: Date
    let updatedAt: Date
    
    struct TranscriptSegment: Codable {
        let startTime: TimeInterval
        let endTime: TimeInterval
        let text: String
        let confidence: Double
        
        enum CodingKeys: String, CodingKey {
            case startTime = "start_time"
            case endTime = "end_time"
            case text
            case confidence
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case videoId = "video_id"
        case segments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Transcript {
    static func fromFirestore(_ document: DocumentSnapshot) throws -> Transcript {
        try document.data(as: Transcript.self)
    }
} 