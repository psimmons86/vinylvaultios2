import Foundation
import FirebaseFirestore

// Simple user model with minimal functionality
struct SimpleUser: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var username: String
    var profileImageUrl: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        email: String,
        username: String,
        profileImageUrl: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convert Firestore data to SimpleUser
    static func fromFirestore(_ data: [String: Any], id: String) -> SimpleUser? {
        guard let email = data["email"] as? String,
              let username = data["username"] as? String else {
            return nil
        }
        
        return SimpleUser(
            id: id,
            email: email,
            username: username,
            profileImageUrl: data["profileImageUrl"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    // Convert SimpleUser to Firestore data
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "email": email,
            "username": username,
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let profileImageUrl = profileImageUrl {
            data["profileImageUrl"] = profileImageUrl
        }
        
        // Only set createdAt when creating a new document
        if createdAt == updatedAt {
            data["createdAt"] = Timestamp(date: createdAt)
        }
        
        return data
    }
    
    static func == (lhs: SimpleUser, rhs: SimpleUser) -> Bool {
        return lhs.id == rhs.id
    }
}

// Simple friend relationship
struct FriendConnection: Identifiable, Codable {
    let id: String
    let userId: String
    let friendId: String
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        friendId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.friendId = friendId
        self.createdAt = createdAt
    }
    
    // Convert Firestore data to FriendConnection
    static func fromFirestore(_ data: [String: Any], id: String) -> FriendConnection? {
        guard let userId = data["userId"] as? String,
              let friendId = data["friendId"] as? String else {
            return nil
        }
        
        return FriendConnection(
            id: id,
            userId: userId,
            friendId: friendId,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    // Convert FriendConnection to Firestore data
    func toFirestore() -> [String: Any] {
        return [
            "userId": userId,
            "friendId": friendId,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
