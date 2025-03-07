import Foundation
import Firebase
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class FirebaseService {
    static let shared = FirebaseService()
    
    private init() {}
    
    // MARK: - User Management
    
    func fetchCollaborators(completion: @escaping (Result<[User], Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("collections").document(currentUserId).collection("collaborators").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let users = documents.compactMap { document -> User? in
                let data = document.data()
                return User.fromFirestore(data, id: document.documentID)
            }
            
            completion(.success(users))
        }
    }
    
    func inviteUser(email: String, role: UserRole, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // First check if the user already exists in Firebase Auth
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Create the invitation
            let invite = CollaborationInvite(
                inviterId: currentUser.uid,
                inviterEmail: currentUser.email ?? "",
                inviterName: currentUser.displayName ?? "Vinyl Collector",
                inviteeEmail: email,
                role: role
            )
            
            // Store the invitation in Firestore
            db.collection("invites").document(invite.id).setData(invite.toFirestore()) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // If the user already exists, add them to the pending collaborators
                if let existingUserDoc = snapshot?.documents.first {
                    let inviteeId = existingUserDoc.documentID
                    
                    // Add to pending collaborators
                    db.collection("collections").document(currentUser.uid).collection("pendingCollaborators").document(inviteeId).setData([
                        "email": email,
                        "role": role.rawValue,
                        "inviteId": invite.id,
                        "createdAt": Timestamp(date: invite.createdAt)
                    ]) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        completion(.success(()))
                    }
                } else {
                    // User doesn't exist yet, just store the invitation
                    completion(.success(()))
                }
            }
        }
    }
    
    func acceptInvite(inviteId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Get the invite
        db.collection("invites").document(inviteId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = snapshot, document.exists,
                  let data = document.data(),
                  let invite = CollaborationInvite.fromFirestore(data, id: document.documentID) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invite not found"])))
                return
            }
            
            // Verify this invite is for the current user
            guard invite.inviteeEmail.lowercased() == currentUser.email?.lowercased() else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invite is not for this user"])))
                return
            }
            
            // Update invite status
            db.collection("invites").document(inviteId).updateData([
                "status": CollaborationInvite.InviteStatus.accepted.rawValue
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Add user as collaborator to the inviter's collection
                db.collection("collections").document(invite.inviterId).collection("collaborators").document(currentUser.uid).setData([
                    "email": currentUser.email ?? "",
                    "username": currentUser.displayName ?? "Collaborator",
                    "role": invite.role.rawValue,
                    "createdAt": Timestamp(date: Date()),
                    "updatedAt": Timestamp(date: Date())
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    // Remove from pending collaborators if exists
                    db.collection("collections").document(invite.inviterId).collection("pendingCollaborators").document(currentUser.uid).delete()
                    
                    completion(.success(()))
                }
            }
        }
    }
    
    func declineInvite(inviteId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Get the invite
        db.collection("invites").document(inviteId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = snapshot, document.exists,
                  let data = document.data(),
                  let invite = CollaborationInvite.fromFirestore(data, id: document.documentID) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invite not found"])))
                return
            }
            
            // Verify this invite is for the current user
            guard invite.inviteeEmail.lowercased() == currentUser.email?.lowercased() else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invite is not for this user"])))
                return
            }
            
            // Update invite status
            db.collection("invites").document(inviteId).updateData([
                "status": CollaborationInvite.InviteStatus.declined.rawValue
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Remove from pending collaborators if exists
                db.collection("collections").document(invite.inviterId).collection("pendingCollaborators").document(currentUser.uid).delete()
                
                completion(.success(()))
            }
        }
    }
    
    func removeCollaborator(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Remove the collaborator
        db.collection("collections").document(currentUser.uid).collection("collaborators").document(userId).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func updateCollaboratorRole(userId: String, newRole: UserRole, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Update the collaborator's role
        db.collection("collections").document(currentUser.uid).collection("collaborators").document(userId).updateData([
            "role": newRole.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func fetchPendingInvites(completion: @escaping (Result<[CollaborationInvite], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Get invites where the current user is the invitee and status is pending
        db.collection("invites")
            .whereField("inviteeEmail", isEqualTo: currentUser.email ?? "")
            .whereField("status", isEqualTo: CollaborationInvite.InviteStatus.pending.rawValue)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let invites = documents.compactMap { document -> CollaborationInvite? in
                    let data = document.data()
                    return CollaborationInvite.fromFirestore(data, id: document.documentID)
                }
                
                completion(.success(invites))
            }
    }
    
    func fetchSentInvites(completion: @escaping (Result<[CollaborationInvite], Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Get invites where the current user is the inviter
        db.collection("invites")
            .whereField("inviterId", isEqualTo: currentUser.uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let invites = documents.compactMap { document -> CollaborationInvite? in
                    let data = document.data()
                    return CollaborationInvite.fromFirestore(data, id: document.documentID)
                }
                
                completion(.success(invites))
            }
    }
    
    func cancelInvite(inviteId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Get the invite
        db.collection("invites").document(inviteId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = snapshot, document.exists,
                  let data = document.data(),
                  let invite = CollaborationInvite.fromFirestore(data, id: document.documentID) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invite not found"])))
                return
            }
            
            // Verify this invite is from the current user
            guard invite.inviterId == currentUser.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to cancel this invite"])))
                return
            }
            
            // Delete the invite
            db.collection("invites").document(inviteId).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Configuration
    
    func configure() {
        // Firebase is configured in AppDelegate
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            // Create our app's User model from Firebase user
            let user = User(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                username: firebaseUser.displayName ?? "Collector"
            )
            
            completion(.success(user))
        }
    }
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not created"])))
                return
            }
            
            // Update display name
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = username
            changeRequest.commitChanges { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Create user document in Firestore
                let user = User(
                    id: firebaseUser.uid,
                    email: email,
                    username: username
                )
                
                let db = Firestore.firestore()
                db.collection("users").document(user.id).setData([
                    "username": user.username,
                    "email": user.email,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(user))
                }
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - Record Management
    
    func fetchRecords(completion: @escaping (Result<[Record], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // First try to fetch from the user's subcollection (for newly added records)
        db.collection("users").document(userId).collection("records").getDocuments { snapshot, error in
            var userRecords: [Record] = []
            
            // Process user's records if they exist
            if let documents = snapshot?.documents, !documents.isEmpty {
                userRecords = documents.compactMap { document -> Record? in
                    let data = document.data()
                    
                    guard let title = data["title"] as? String,
                          let artist = data["artist"] as? String else {
                        return nil
                    }
                    
                    let formatRaw = data["format"] as? String ?? "LP"
                    let format = RecordFormat(rawValue: formatRaw) ?? .lp
                    
                    let id = UUID(uuidString: document.documentID) ?? UUID()
                    
                    return Record(
                        id: id,
                        title: title,
                        artist: artist,
                        year: data["year"] as? Int,
                        format: format,
                        tags: data["tags"] as? [String] ?? [],
                        plays: data["plays"] as? Int ?? 0,
                        lastPlayed: (data["lastPlayed"] as? Timestamp)?.dateValue(),
                        imageUrl: data["imageUrl"] as? String ?? "default-album",
                        notes: data["notes"] as? String,
                        value: data["value"] as? Double ?? 0.0,
                        discogsId: data["discogsId"] as? String,
                        label: data["label"] as? String,
                        inHeavyRotation: data["inHeavyRotation"] as? Bool ?? false,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
            }
            
            // Now fetch from the top-level records collection (migrated data)
            db.collection("records").getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(userRecords))
                    return
                }
                
                let migratedRecords = documents.compactMap { document -> Record? in
                    let data = document.data()
                    
                    guard let title = data["title"] as? String,
                          let artist = data["artist"] as? String else {
                        return nil
                    }
                    
                    let formatRaw = data["format"] as? String ?? "LP"
                    let format = RecordFormat(rawValue: formatRaw) ?? .lp
                    
                    let id = UUID(uuidString: document.documentID) ?? UUID()
                    
                    return Record(
                        id: id,
                        title: title,
                        artist: artist,
                        year: data["year"] as? Int,
                        format: format,
                        tags: data["tags"] as? [String] ?? [],
                        plays: data["plays"] as? Int ?? 0,
                        lastPlayed: (data["lastPlayed"] as? Timestamp)?.dateValue(),
                        imageUrl: data["imageUrl"] as? String ?? "default-album",
                        notes: data["notes"] as? String,
                        value: data["value"] as? Double ?? 0.0,
                        discogsId: data["discogsId"] as? String,
                        label: data["label"] as? String,
                        inHeavyRotation: data["inHeavyRotation"] as? Bool ?? false,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                
                // Combine user records and migrated records
                let allRecords = userRecords + migratedRecords
                completion(.success(allRecords))
            }
        }
    }
    
    func saveRecord(_ record: Record, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("records").document(record.id.uuidString).setData([
            "title": record.title,
            "artist": record.artist,
            "year": record.year as Any,
            "format": record.format.rawValue,
            "tags": record.tags,
            "plays": record.plays,
            "lastPlayed": record.lastPlayed as Any,
            "imageUrl": record.imageUrl,
            "notes": record.notes as Any,
            "value": record.value,
            "discogsId": record.discogsId as Any,
            "label": record.label as Any,
            "inHeavyRotation": record.inHeavyRotation,
            "createdAt": Timestamp(date: record.createdAt),
            "updatedAt": Timestamp(date: record.updatedAt)
        ]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    func deleteRecord(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("records").document(id.uuidString).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    // MARK: - Collection Stats
    
    func calculateCollectionStats(for userId: String, records: [Record]) -> CollectionStats {
        let totalPlays = records.reduce(0) { $0 + $1.plays }
        let totalValue = records.reduce(0.0) { $0 + $1.value }
        
        let artistCounts = Dictionary(grouping: records) { $0.artist }
            .mapValues { $0.count }
        let topArtists = artistCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { ($0.key, $0.value) }
        
        let yearDistribution = Dictionary(grouping: records.filter { $0.year != nil }) { 
            ($0.year! / 10) * 10 
        }.mapValues { $0.count }
        
        return CollectionStats(
            totalRecords: records.count,
            totalPlays: totalPlays,
            totalValue: totalValue,
            averagePlays: records.isEmpty ? 0 : Double(totalPlays) / Double(records.count),
            topArtists: topArtists,
            yearDistribution: yearDistribution
        )
    }
    
    // MARK: - Storage Operations
    
    func uploadImage(_ image: Data, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child(path)
        
        imageRef.putData(image, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
}
