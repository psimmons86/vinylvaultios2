import Foundation
import FirebaseFirestore

// User role enum
enum UserRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case editor = "Editor"
    case viewer = "Viewer"
}

// User model
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    var username: String
    var role: UserRole
    var profileImageUrl: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String,
        email: String,
        username: String,
        role: UserRole = .owner,
        profileImageUrl: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.role = role
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convert Firestore data to User
    static func fromFirestore(_ data: [String: Any], id: String) -> User? {
        guard let email = data["email"] as? String,
              let username = data["username"] as? String else {
            return nil
        }
        
        let roleString = data["role"] as? String ?? UserRole.viewer.rawValue
        let role = UserRole(rawValue: roleString) ?? .viewer
        
        return User(
            id: id,
            email: email,
            username: username,
            role: role,
            profileImageUrl: data["profileImageUrl"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    // Convert User to Firestore data
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "email": email,
            "username": username,
            "role": role.rawValue,
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
    
    // Check if user has permission for an action
    func canEditRecords() -> Bool {
        return role == .owner || role == .editor
    }
    
    func canManageUsers() -> Bool {
        return role == .owner
    }
    
    func canViewRecords() -> Bool {
        return true // All roles can view records
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

// Collaboration invite model
struct CollaborationInvite: Identifiable, Codable {
    let id: String
    let inviterId: String
    let inviterEmail: String
    let inviterName: String
    let inviteeEmail: String
    let role: UserRole
    let status: InviteStatus
    let createdAt: Date
    let expiresAt: Date
    
    enum InviteStatus: String, Codable {
        case pending = "Pending"
        case accepted = "Accepted"
        case declined = "Declined"
        case expired = "Expired"
    }
    
    init(
        id: String = UUID().uuidString,
        inviterId: String,
        inviterEmail: String,
        inviterName: String,
        inviteeEmail: String,
        role: UserRole = .viewer,
        status: InviteStatus = .pending,
        createdAt: Date = Date(),
        expiresAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    ) {
        self.id = id
        self.inviterId = inviterId
        self.inviterEmail = inviterEmail
        self.inviterName = inviterName
        self.inviteeEmail = inviteeEmail
        self.role = role
        self.status = status
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    // Convert Firestore data to CollaborationInvite
    static func fromFirestore(_ data: [String: Any], id: String) -> CollaborationInvite? {
        guard let inviterId = data["inviterId"] as? String,
              let inviterEmail = data["inviterEmail"] as? String,
              let inviterName = data["inviterName"] as? String,
              let inviteeEmail = data["inviteeEmail"] as? String,
              let roleString = data["role"] as? String,
              let statusString = data["status"] as? String else {
            return nil
        }
        
        let role = UserRole(rawValue: roleString) ?? .viewer
        let status = InviteStatus(rawValue: statusString) ?? .pending
        
        return CollaborationInvite(
            id: id,
            inviterId: inviterId,
            inviterEmail: inviterEmail,
            inviterName: inviterName,
            inviteeEmail: inviteeEmail,
            role: role,
            status: status,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            expiresAt: (data["expiresAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    // Convert CollaborationInvite to Firestore data
    func toFirestore() -> [String: Any] {
        return [
            "inviterId": inviterId,
            "inviterEmail": inviterEmail,
            "inviterName": inviterName,
            "inviteeEmail": inviteeEmail,
            "role": role.rawValue,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "expiresAt": Timestamp(date: expiresAt)
        ]
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}
