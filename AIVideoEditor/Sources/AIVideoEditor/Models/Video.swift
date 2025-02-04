import Foundation
import FirebaseFirestore

struct Video: Codable, Identifiable {
    let id: String
    let title: String
    let courseId: String
    let courseName: String
    let teacherId: String
    let lectureDate: Date
    let description: String?
    let tags: [String]
    let keywords: [String]
    let summary: String?
    let storagePath: String
    let processingStatus: ProcessingStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum ProcessingStatus: String, Codable {
        case pending
        case processing
        case completed
        case failed
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case courseId = "course_id"
        case courseName = "course_name"
        case teacherId = "teacher_id"
        case lectureDate = "lecture_date"
        case description
        case tags
        case keywords
        case summary
        case storagePath = "storage_path"
        case processingStatus = "processing_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Video {
    static func fromFirestore(_ document: DocumentSnapshot) throws -> Video {
        try document.data(as: Video.self)
    }
} 