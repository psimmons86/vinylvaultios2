import Foundation
import Firebase
import SwiftUI

@MainActor
class RecordStore: ObservableObject {
    @Published private(set) var records: [Record] = []
    @Published private(set) var collaborators: [User] = []
    @Published private(set) var pendingInvites: [CollaborationInvite] = []
    @Published private(set) var sentInvites: [CollaborationInvite] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firebaseService = FirebaseService.shared
    private let defaults = UserDefaults.standard
    private let recordsKey = "savedRecords"
    
    init() {
        // First load from local storage for immediate display
        loadLocalRecords()
        
        // Then fetch from Firebase if user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                await fetchRecordsFromFirebase()
            }
        }
    }
    
    private func loadLocalRecords() {
        guard let data = defaults.data(forKey: recordsKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            records = try decoder.decode([Record].self, from: data)
        } catch {
            print("Error loading records from local storage: \(error)")
        }
    }
    
    private func saveLocalRecords() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(records)
            defaults.set(data, forKey: recordsKey)
        } catch {
            print("Error saving records to local storage: \(error)")
        }
    }
    
    func fetchRecordsFromFirebase() async {
        guard Auth.auth().currentUser != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                firebaseService.fetchRecords { result in
                    continuation.resume(with: result)
                }
            }
            
            records = result
            saveLocalRecords() // Cache the records locally
        } catch {
            self.error = error
            print("Error fetching records from Firebase: \(error)")
        }
    }
    
    // MARK: - Record Management
    
    func addRecord(_ record: Record) {
        records.append(record)
        saveLocalRecords()
        
        // Save to Firebase if user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                do {
                    try await withCheckedThrowingContinuation { continuation in
                        firebaseService.saveRecord(record) { result in
                            continuation.resume(with: result)
                        }
                    }
                } catch {
                    self.error = error
                    print("Error saving record to Firebase: \(error)")
                }
            }
        }
    }
    
    func updateRecord(_ record: Record) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveLocalRecords()
            
            // Update in Firebase if user is logged in
            if Auth.auth().currentUser != nil {
                Task {
                    do {
                        try await withCheckedThrowingContinuation { continuation in
                            firebaseService.saveRecord(record) { result in
                                continuation.resume(with: result)
                            }
                        }
                    } catch {
                        self.error = error
                        print("Error updating record in Firebase: \(error)")
                    }
                }
            }
        }
    }
    
    func deleteRecord(_ record: Record) {
        records.removeAll { $0.id == record.id }
        saveLocalRecords()
        
        // Delete from Firebase if user is logged in
        if Auth.auth().currentUser != nil {
            Task {
                do {
                    try await withCheckedThrowingContinuation { continuation in
                        firebaseService.deleteRecord(id: record.id) { result in
                            continuation.resume(with: result)
                        }
                    }
                } catch {
                    self.error = error
                    print("Error deleting record from Firebase: \(error)")
                }
            }
        }
    }
    
    func incrementPlays(for record: Record) {
        if var record = records.first(where: { $0.id == record.id }) {
            record.incrementPlays()
            updateRecord(record)
        }
    }
    
    // MARK: - User Management
    
    func fetchCollaborators() async {
        guard Auth.auth().currentUser != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                firebaseService.fetchCollaborators { result in
                    continuation.resume(with: result)
                }
            }
            
            collaborators = result
        } catch {
            self.error = error
            print("Error fetching collaborators: \(error)")
        }
    }
    
    func inviteUser(email: String, role: UserRole) async throws {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.inviteUser(email: email, role: role) { result in
                continuation.resume(with: result)
            }
        }
        
        // Refresh sent invites
        await fetchSentInvites()
    }
    
    func acceptInvite(inviteId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.acceptInvite(inviteId: inviteId) { result in
                continuation.resume(with: result)
            }
        }
        
        // Refresh pending invites
        await fetchPendingInvites()
    }
    
    func declineInvite(inviteId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.declineInvite(inviteId: inviteId) { result in
                continuation.resume(with: result)
            }
        }
        
        // Refresh pending invites
        await fetchPendingInvites()
    }
    
    func removeCollaborator(userId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.removeCollaborator(userId: userId) { result in
                continuation.resume(with: result)
            }
        }
        
        // Refresh collaborators
        await fetchCollaborators()
    }
    
    func updateCollaboratorRole(userId: String, newRole: UserRole) async throws {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.updateCollaboratorRole(userId: userId, newRole: newRole) { result in
                continuation.resume(with: result)
            }
        }
        
        // Refresh collaborators
        await fetchCollaborators()
    }
    
    func fetchPendingInvites() async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                firebaseService.fetchPendingInvites { result in
                    continuation.resume(with: result)
                }
            }
            
            pendingInvites = result
        } catch {
            self.error = error
            print("Error fetching pending invites: \(error)")
        }
    }
    
    func fetchSentInvites() async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                firebaseService.fetchSentInvites { result in
                    continuation.resume(with: result)
                }
            }
            
            sentInvites = result
        } catch {
            self.error = error
            print("Error fetching sent invites: \(error)")
        }
    }
    
    func cancelInvite(inviteId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.cancelInvite(inviteId: inviteId) { result in
                continuation.resume(with: result)
            }
        }
        
        // Refresh sent invites
        await fetchSentInvites()
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        let user = try await withCheckedThrowingContinuation { continuation in
            firebaseService.signIn(email: email, password: password) { result in
                continuation.resume(with: result)
            }
        }
        
        // Fetch collaborators and invites after sign in
        Task {
            await fetchCollaborators()
            await fetchPendingInvites()
            await fetchSentInvites()
        }
        
        return user
    }
    
    func signUp(email: String, password: String, username: String) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            firebaseService.signUp(email: email, password: password, username: username) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func signOut() throws {
        try firebaseService.signOut()
        // Clear data after sign out
        records = []
        collaborators = []
        pendingInvites = []
        sentInvites = []
        saveLocalRecords()
    }
    
    // MARK: - Filtering and Sorting
    
    func recordsByArtist() -> [String: [Record]] {
        Dictionary(grouping: records) { $0.artist }
            .mapValues { $0.sorted { $0.title < $1.title } }
    }
    
    func recordsByYear() -> [Int: [Record]] {
        Dictionary(grouping: records.filter { $0.year != nil }) { $0.year! }
            .mapValues { $0.sorted { $0.title < $1.title } }
    }
    
    func recordsByTag(_ tag: String) -> [Record] {
        records.filter { $0.tags.contains(tag.lowercased()) }
    }
    
    func mostPlayed(limit: Int = 10) -> [Record] {
        records.sorted { $0.plays > $1.plays }
            .prefix(limit)
            .map { $0 }
    }
    
    func recentlyPlayed(limit: Int = 10) -> [Record] {
        records.filter { $0.lastPlayed != nil }
            .sorted { $0.lastPlayed! > $1.lastPlayed! }
            .prefix(limit)
            .map { $0 }
    }
    
    func heavyRotation() -> [Record] {
        records.filter { $0.inHeavyRotation }
            .sorted { $0.plays > $1.plays }
    }
    
    // MARK: - Statistics
    
    var collectionStats: CollectionStats {
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
}

struct CollectionStats {
    let totalRecords: Int
    let totalPlays: Int
    let totalValue: Double
    let averagePlays: Double
    let topArtists: [(artist: String, count: Int)]
    let yearDistribution: [Int: Int]
    
    var formattedTotalValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$0.00"
    }
}
