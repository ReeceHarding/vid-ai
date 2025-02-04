import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

enum AuthError: Error {
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case userNotFound
    case invalidRole
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published private(set) var currentUser: User?
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task {
                if let user = user {
                    try? await self?.fetchUserData(for: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    private func fetchUserData(for uid: String) async throws {
        let document = try await db.collection("users").document(uid).getDocument()
        currentUser = try document.data(as: User.self)
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await fetchUserData(for: result.user.uid)
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }
    
    func signUp(email: String, password: String, role: User.UserRole) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(
                id: result.user.uid,
                email: email,
                role: role,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await db.collection("users").document(result.user.uid).setData(from: user)
            currentUser = user
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
    
    func getCurrentUser() async throws -> User {
        if let user = currentUser {
            return user
        }
        
        if let uid = auth.currentUser?.uid {
            try await fetchUserData(for: uid)
            if let user = currentUser {
                return user
            }
        }
        
        throw AuthError.userNotFound
    }
} 