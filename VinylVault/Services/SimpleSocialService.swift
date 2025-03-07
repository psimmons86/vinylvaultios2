import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

// A simplified service for social features
class SimpleSocialService {
    static let shared = SimpleSocialService()
    
    private init() {}
    
    // MARK: - User Management
    
    func getCurrentUser() -> SimpleUser? {
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }
        
        return SimpleUser(
            id: currentUser.uid,
            email: currentUser.email ?? "",
            username: currentUser.displayName ?? "Vinyl Collector"
        )
    }
    
    func fetchUserProfile(completion: @escaping (Result<SimpleUser, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = snapshot, document.exists,
                  let data = document.data() else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])))
                return
            }
            
            if let user = SimpleUser.fromFirestore(data, id: document.documentID) {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user data"])))
            }
        }
    }
    
    func updateUserProfile(username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        // Update display name in Firebase Auth
        let changeRequest = currentUser.createProfileChangeRequest()
        changeRequest.displayName = username
        changeRequest.commitChanges { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Update user document in Firestore
            let db = Firestore.firestore()
            db.collection("users").document(currentUser.uid).updateData([
                "username": username,
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Friend Management
    
    func searchUsers(query: String, completion: @escaping (Result<[SimpleUser], Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Search by email or username
        // Note: This is a simple implementation. In a real app, you'd want to use Firestore's
        // array-contains or array-contains-any operators with an array of keywords
        db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: query)
            .whereField("email", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var users: [SimpleUser] = []
                
                // Process email matches
                if let documents = snapshot?.documents {
                    for document in documents {
                        if document.documentID != currentUserId, // Don't include current user
                           let user = SimpleUser.fromFirestore(document.data(), id: document.documentID) {
                            users.append(user)
                        }
                    }
                }
                
                // Also search by username
                db.collection("users")
                    .whereField("username", isGreaterThanOrEqualTo: query)
                    .whereField("username", isLessThanOrEqualTo: query + "\u{f8ff}")
                    .limit(to: 20)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        // Process username matches
                        if let documents = snapshot?.documents {
                            for document in documents {
                                if document.documentID != currentUserId, // Don't include current user
                                   let user = SimpleUser.fromFirestore(document.data(), id: document.documentID),
                                   !users.contains(where: { $0.id == user.id }) { // Avoid duplicates
                                    users.append(user)
                                }
                            }
                        }
                        
                        completion(.success(users))
                    }
            }
    }
    
    func addFriend(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Create a friend connection
        let connection = FriendConnection(userId: currentUserId, friendId: userId)
        
        // Add to Firestore
        db.collection("friendConnections").document(connection.id).setData(connection.toFirestore()) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func removeFriend(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Find and delete the friend connection
        db.collection("friendConnections")
            .whereField("userId", isEqualTo: currentUserId)
            .whereField("friendId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.success(())) // No connection found, consider it a success
                    return
                }
                
                // Delete the connection
                let batch = db.batch()
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(()))
                }
            }
    }
    
    func fetchFriends(completion: @escaping (Result<[SimpleUser], Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let db = Firestore.firestore()
        
        // Get all friend connections where the current user is the userId
        db.collection("friendConnections")
            .whereField("userId", isEqualTo: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.success([])) // No friends found
                    return
                }
                
                // Extract friend IDs
                let friendIds = documents.compactMap { document -> String? in
                    guard let data = document.data() as? [String: Any],
                          let friendId = data["friendId"] as? String else {
                        return nil
                    }
                    return friendId
                }
                
                // Fetch friend user documents
                let group = DispatchGroup()
                var friends: [SimpleUser] = []
                var fetchError: Error?
                
                for friendId in friendIds {
                    group.enter()
                    
                    db.collection("users").document(friendId).getDocument { snapshot, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            fetchError = error
                            return
                        }
                        
                        guard let document = snapshot, document.exists,
                              let data = document.data(),
                              let user = SimpleUser.fromFirestore(data, id: document.documentID) else {
                            return
                        }
                        
                        friends.append(user)
                    }
                }
                
                group.notify(queue: .main) {
                    if let fetchError = fetchError {
                        completion(.failure(fetchError))
                    } else {
                        completion(.success(friends))
                    }
                }
            }
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Result<SimpleUser, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            
            // Create our app's SimpleUser model from Firebase user
            let user = SimpleUser(
                id: firebaseUser.uid,
                email: firebaseUser.email ?? "",
                username: firebaseUser.displayName ?? "Collector"
            )
            
            completion(.success(user))
        }
    }
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<SimpleUser, Error>) -> Void) {
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
                let user = SimpleUser(
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
    
    // MARK: - Storage Operations
    
    func uploadProfileImage(_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profileImages/\(currentUserId).jpg")
        
        // Upload the image
        profileImageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Get the download URL
            profileImageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                // Update the user's profile with the image URL
                let db = Firestore.firestore()
                db.collection("users").document(currentUserId).updateData([
                    "profileImageUrl": downloadURL.absoluteString,
                    "updatedAt": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(downloadURL.absoluteString))
                }
            }
        }
    }
}
