import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
    
    enum UserRole: String, Codable {
        case teacher
        case student
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension User {
    static func fromFirestore(_ document: DocumentSnapshot) throws -> User {
        try document.data(as: User.self)
    }
} 